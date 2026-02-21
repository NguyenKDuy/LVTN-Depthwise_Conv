`include "default.vh"

module controller 
# (
parameter ADDRESS = 15
)
(
    input  wire        i_clk,
    input  wire        i_rst_n,

    input       [ADDRESS - 1:0] i_daddress, //data address from image mem
    input       [`PIXEL_WIDTH * 4 - 1 : 0] i_image_data,
    input       [`PIXEL_WIDTH * 4 - 1 : 0] i_dweight,
    input       [`PIXEL_WIDTH * 4 - 1 : 0] i_pweight,
    
    input  wire        i_data_valid_count,  // use to count for depthwise or pointwise
    input  wire        i_dwready,           // signal from depthwise ask for weight
    input  wire        i_pwready,           // signal from pointwise ask for weight
    input  wire        i_ddready,           // signal from depthwise ask for data

    output reg  [3:0]  oc_stage,
    output reg  [ADDRESS - 1:0] o_r_address1,  // ði?u khi?n v? trí ð?c weight
    output reg  [ADDRESS - 1:0] o_r_address2,  // ði?u khi?n v? trí ð?c data
    output reg  [ADDRESS - 1:0] o_r_address3,  // ði?u khi?n v? trí ð?c data
    output reg         r_enable1,     // read enable for mem1
    output reg         r_enable2,     // read enable for mem2
    output reg         r_enable3,     // read enable for mem2
    output             o_dweight_valid, // weight_valid signal to depthwise
    output reg         o_pweight_valid, // weight_valid signal to pointwise
    output reg         o_data_valid,    // data_valid signal to depthwise
    
    output       [`PIXEL_WIDTH * `UC * 9 - 1 : 0]   o_data_out,
    output       [`PIXEL_WIDTH * 9 - 1: 0]          o_dweight_data, // dwata signal to depthwise
    output       [`PIXEL_WIDTH * 32 - 1: 0]         o_pweight_data // pweight_data signal to pointwise
);
/////////////////////////////////////////////////////////////////////////////
// PARAMETERS
parameter DATA_UNROLLING = 1;
parameter TILE_SIZE = 9*9;
/////////////////////////////////////////////////////////////////////////////
// STAGE
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
localparam OUPTUT = 'd10;
localparam COMPUTING = 'd11;

/////////////////////////////////////////////////////////////////////////////
// INTERNAL LOGICS
// Layer DOWNS1: weight
reg [1:0] d1_cw; // maximum count = 7 // downs1 counter weight
reg [9 * 16 - 1: 0] d1weight_reg [0:1];
reg [4 * 16 - 1: 0] d1_reg1, d1_reg2, d1_reg3;
reg [1:0] db_d1_write; //double buffer downs1 - write
reg [1:0] db_regcnt_d1;  // count from 0 - 3 => process of read dweight 
reg [1:0] db_d1_case;    // 4 pattern of mapping 3 16-bit fixedpoint to 9 * 16 bit reg
reg [2:0] db_d1_channel; // count from 0 - 6
always @(posedge i_clk) begin
    if (i_dwready && o_dweight_valid) begin
        db_d1_write <= db_d1_write - 1;
    end
    if (oc_stage == DOWNS1 && db_d1_write < 'd2) begin
        case (db_regcnt_d1) 
            2'b00: begin
                o_r_address1 <= o_r_address1 + 1'b1;
                r_enable1 <= 1'b1;
                d1_reg1 <= i_dweight;
                db_regcnt_d1 <= db_regcnt_d1 + 1'b1;        
            end
            2'b01: begin
                o_r_address1 <= o_r_address1 + 1'b1;
                d1_reg2 <= i_dweight;
                db_regcnt_d1 <= db_regcnt_d1 + 1'b1;   
            end
            2'b10: begin
                d1_reg3 <= i_dweight;
                db_regcnt_d1 <= db_regcnt_d1 + 1'b1;
            end
            2'b11: begin
                db_regcnt_d1 <= 'd0;
                case (db_d1_write)
                    2'b00: begin
                            
                    end
                    2'b01: begin
                    
                    end
                    2'b10: begin
                    
                    end
                    2'b11: begin
                    
                    end
                endcase
                case (db_d1_case)
                    'd0: begin
                        d1weight_reg[0] <= {d1_reg3[15:0],d1_reg2,d1_reg1};
                        db_d1_case <= db_d1_case + 1'b1;   
                        db_d1_channel <= db_d1_channel + 1'b1;
                        db_d1_write <= db_d1_write + 1'b1;
                    end
                    'd1: begin
                        d1weight_reg[1] <= {d1_reg3[31:0],d1_reg2,d1_reg1[63:16]};
                        db_d1_write <= db_d1_write + 1'b1;
                        if (db_d1_channel <= 2) begin
                            db_d1_case <= db_d1_case + 1'b1; 
                        end 
                        else begin
                            db_d1_case <= 0; 
                            o_r_address1 <= 'd0;
                        end 
                    end
                    'd2: begin
                        d1weight_reg[0] <= {d1_reg3[47:0],d1_reg2,d1_reg1[63:32]}; 
                        db_d1_case <= db_d1_case + 1'b1;   
                        db_d1_channel <= db_d1_channel + 1'b1;
                        db_d1_write <= db_d1_write + 1'b1;
                    end
                    
                    'd3: begin
                        d1weight_reg[1] <= {d1_reg3,d1_reg2,d1_reg1[63:48]}; 
                        db_d1_case <= db_d1_case + 1'b1;   
                        db_d1_channel <= db_d1_channel + 1'b1;
                        db_d1_write <= db_d1_write + 1'b1;
                        o_r_address1 <= o_r_address1 + 1'b1;
                    end
                endcase    
            end
        endcase  
    end        
end
assign o_dweight_valid = (db_d1_write >= 2'd1) ? 1'b1 : 1'b0;
assign db_ping_pong_d1 = db_d1_channel % 2;

assign o_dweight_data = (i_dwready && o_dweight_valid) ?  d1weight_reg[db_ping_pong_d1] : 'd0;
// Layer DOWNS1: data
//reg [3:0] cl_d1;
//reg [3:0] cr_d1;
//reg [2:0] cc_d1;


reg [10:0] d2_cw;
reg [10:0] d3_cw;
reg [10:0] b_cw;
reg [10:0] u1_cw;
reg [10:0] u2_cw;
reg [10:0] u3_cw;



reg [16:0] downs2_counter_data;
reg [16:0] downs3_counter_data;
reg [16:0] bottle_counter_data;
reg [16:0] ups1_counter_data;
reg [16:0] ups2_counter_data;
reg [16:0] ups3_counter_data;

reg [1:0] tiles;
reg [7:0] d1_subtiles; 

integer i;
generate
/////////////////////////////////////////////////////////////////////////////
    
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            oc_stage <= IDLE; 
            //layer 1
            o_r_address1 <= 'd0; 
            d1_reg1 <= 0;
            d1_reg2 <= 0; 
            d1_reg3 <= 0;
        end
        else begin
            case (oc_stage)
                IDLE: begin
                    if (i_daddress >= DATA_UNROLLING*128*128 + TILE_SIZE) begin // dieu kien de bat dau transfer
                        oc_stage <= DOWNS1;          
                    end
                end             
                DOWNS1: begin
                    if (i_dwready && o_dweight_valid) begin
                        d1_subtiles <= d1_subtiles + 1'b1;
                    end          
                end
            endcase 
        end     
    end
endgenerate
endmodule
