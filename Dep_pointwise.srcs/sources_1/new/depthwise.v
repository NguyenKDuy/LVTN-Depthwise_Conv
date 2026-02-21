module depth_mem_control (
    i_clk,
    i_rst_n,
    i_stage,
    i_data,
    i_dready,
    o_r_address,
    o_r_enable,
    o_data,
    o_valid
);
///////////////////////////////////////////////////////////////////
// PORTS DECLARATION: 
    input i_clk;
    input i_rst_n;
    input [3:0] i_stage;
    input [63:0] i_data;
    input i_dready;
    output reg [14:0] o_r_address;
    output reg o_r_enable;
    output [9*16 - 1: 0]o_data;
    output reg o_valid;
///////////////////////////////////////////////////////////////////
// INSIDE LOGIC:
    reg [4 * 16 - 1: 0] reg1, reg2, reg3;
    reg [9 * 16 - 1: 0] weight_reg [0:1];
    reg [1:0] buf_count;
    reg [2:0] load_stage;
    reg [1:0] mapping_stage;
    reg [8:0] channel_count;
    reg [3:0] prev_stage;
///////////////////////////////////////////////////////////////////
// FSM:
localparam IDLE = 'd0;
localparam HEAD = 'd1;
localparam DOWNS1 = 'd2;
localparam DOWNS2 = 'd3;
localparam BOTT   = 'd4;
localparam UPS1 = 'd5;
localparam UPS2 = 'd6;
localparam UPS3 = 'd7;
localparam TAIL = 'd8;
localparam TANH = 'd9;

///////////////////////////////////////////////////////////////////
// Base address of depthwise:
localparam HEAD_BASE = 'd0;
localparam DOWNS1_BASE = 'd14; //include 32 bit dump ahead
localparam DOWNS2_BASE = 'd86;
localparam BOTT_BASE = 'd230;
localparam UPS1_BASE = 'd518;
localparam UPS2_BASE = 'd1382;
localparam UPS3_BASE = 'd1814;
localparam END_BASE = 'd2030;

// Max Channels cho t?ng Stage:
localparam HEAD_CH   = 9'd5;  // not need this
localparam DOWNS1_CH = 9'd31;  // 32 channels
localparam DOWNS2_CH = 9'd63;  // 64 channels
localparam BOTT_CH   = 9'd127; // 128 channels
localparam UPS1_CH   = 9'd383; // 384 channels (D?a trên Offset 864)
localparam UPS2_CH   = 9'd191; // 192 channels (D?a trên Offset 432)
localparam UPS3_CH   = 9'd95;  // 96 channels  (D?a trên Offset 216)
///////////////////////////////////////////////////////////////////
// DESIGN::

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            buf_count <= 'd0; 
            o_valid <= 'b0; 
            load_stage <= 'b0;
            channel_count <= 'd0;
            o_r_address <= 'd0;
            o_r_enable <= 'd1;
            prev_stage <= IDLE;
            mapping_stage <= 'd0;
        end
        else begin
            if (i_dready && o_valid) begin
                if (buf_count - 1'b1 <= 1'b0) begin
                    o_valid <= 'b0;    
                    buf_count <= 'b0;
                    o_r_enable <= 'b1;
                end 
                else begin
                    buf_count <= buf_count - 1'b1;
                end
            end
            else begin
                prev_stage <= i_stage;
                if (prev_stage != i_stage) begin
                    load_stage <= 0;
                    mapping_stage <= 0;
                    buf_count <= 0;
                    channel_count <= 0;
                    case (i_stage)
                        HEAD:  o_r_address   <= HEAD_BASE;
                        DOWNS1: o_r_address   <= DOWNS1_BASE;
                        DOWNS2: o_r_address   <= DOWNS2_BASE;
                        BOTT:  o_r_address   <= BOTT_BASE;
                        UPS1: o_r_address   <= UPS1_BASE;
                        UPS2: o_r_address   <= UPS2_BASE;
                        UPS3: o_r_address   <= UPS3_BASE;
                        default: begin
                            o_r_address <= 'd0;
                        end
                    endcase
                end
                else if (i_stage != IDLE && buf_count < 'd2) begin
                    case (load_stage) 
                        3'b000: begin
                            o_r_address <= o_r_address + 1'b1;
                            o_r_enable <= 1'b1;
                            load_stage <= 3'b001;        
                        end
                        3'b001: begin
                            o_r_address <= o_r_address + 1'b1;
                            o_r_enable <= 1'b1;
                            reg1 <= i_data;
                            load_stage <= 3'b010;        
                        end
                        3'b010: begin
                            o_r_address <= o_r_address + 1'b1;
                            o_r_enable <= 1'b1; 
                            reg2 <= i_data;
                            load_stage <= 3'b011;   
                        end
                        3'b011: begin
                            reg3 <= i_data;
                            load_stage <= 3'b100;
                        end
                        3'b100: begin
                            //Ready to export data
                            if (buf_count + 1'b1 >= 'd2) begin
                                o_valid <= 1'd1;
                                o_r_enable <= 1'd0;
                            end
                            buf_count <= buf_count + 1'b1;
                            //
                            load_stage <= 'd0;
                            o_r_address <= o_r_address - 1;
                            case (mapping_stage)
                                'd0: begin
                                    weight_reg[0] <= {reg3[15:0],reg2, reg1};
                                    channel_count <= channel_count + 1'b1;
                                    mapping_stage <= 'd1;
                                end
                                'd1: begin
                                    weight_reg[1] <= {reg3[31:0],reg2, reg1[63:16]};
                                    channel_count <= channel_count + 1'b1;
                                    mapping_stage <= 'd2;
                                    if (i_stage == HEAD && channel_count >= 4) begin
                                        channel_count <= 'd0;
                                        o_r_address <= HEAD_BASE;
                                        o_r_address <= o_r_address + 'd0;
                                        mapping_stage <= 'd0;
                                    end
                                end
                                'd2: begin
                                    weight_reg[0] <= {reg3[47:0], reg2, reg1[63:32]}; 
                                    channel_count <= channel_count + 1'b1;
                                    mapping_stage <= 'd3;
                                end
                                'd3: begin
                                    weight_reg[1] <= {reg3, reg2, reg1[63:48]};
                                    channel_count <= channel_count + 1'b1; 
                                    mapping_stage <= 'd0;
                                    o_r_address <= o_r_address + 'd0;
                                    case (i_stage)
                                        HEAD: begin // this case not happen => upper deal with this.
                                            if (channel_count >= HEAD_CH) begin
                                                channel_count <= 0;
                                                o_r_address   <= HEAD_BASE;
                                            end
                                        end
                                        
                                        DOWNS1: begin
                                            if (channel_count >= DOWNS1_CH) begin
                                                channel_count <= 0;
                                                o_r_address   <= DOWNS1_BASE;
                                            end
                                        end
                                        
                                        DOWNS2: begin
                                            if (channel_count >= DOWNS2_CH) begin
                                                channel_count <= 0;
                                                o_r_address   <= DOWNS2_BASE;
                                            end
                                        end
                                        
                                        BOTT: begin
                                            if (channel_count >= BOTT_CH) begin
                                                channel_count <= 0;
                                                o_r_address   <= BOTT_BASE;
                                            end
                                        end
                                        
                                        UPS1: begin
                                            if (channel_count >= UPS1_CH) begin
                                                channel_count <= 0;
                                                o_r_address   <= UPS1_BASE;
                                            end
                                        end
                                        
                                        UPS2: begin
                                            if (channel_count >= UPS2_CH) begin
                                                channel_count <= 0;
                                                o_r_address   <= UPS2_BASE;
                                            end
                                        end
                                        
                                        UPS3: begin
                                            if (channel_count >= UPS3_CH) begin
                                                channel_count <= 0;
                                                o_r_address   <= UPS3_BASE;
                                            end
                                        end
                                
                                        default: begin
                                            // Trý?ng h?p IDLE ho?c các stage không xác ð?nh
                                            channel_count <= 0;
                                        end
                                    endcase
                                end
                            endcase 
                        end
                        default: begin
                            
                        end
                    endcase
                end              
            end
        end     
    end
    
    assign o_data = (buf_count == 2) ? weight_reg[0] : 
                    (buf_count == 1) ? weight_reg[1] : {144{1'b1}}; 
    
endmodule