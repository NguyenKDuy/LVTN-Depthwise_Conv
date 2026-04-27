`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/09/2026 03:19:08 PM
// Design Name: 
// Module Name: weight_bias_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module weight_bias_control #(
    parameter ADDRESS_WEIGHT = 10,
    parameter ADDRESS_BIAS   = 8,
    parameter LATENCY        = 2
)(
    // System Signals
    input  wire                         i_clk,           // Clock h? th?ng
    input  wire                         i_rst_n,         // Reset tích c?c m?c th?p
    input  wire                         i_ld_wb_enable,        // Cho phép module ho?t ð?ng
    
    // Control Inputs
    input  wire [3:0]                   i_stage,         // T?ng hi?n t?i c?a m?ng (ví d?: stage 1, 2...)
    input  wire                         i_last_loop,     // Tín hi?u báo ð? tính toán xong m?t v? trí/vùng
    input  wire                         i_mode,
    
    // Memory Interface: Depthwise Weight
    output reg  [ADDRESS_WEIGHT - 3:0]  o_dweight_rd_addr,
    output reg                          o_dweight_ena,
    
    // Memory Interface: Pointwise Weight
    output reg  [ADDRESS_WEIGHT - 1:0]  o_pweight_rd_addr,
    output reg                          o_pweight_ena,
    
    // Memory Interface: Bias
    output reg  [ADDRESS_BIAS - 1:0]    o_bias_rd_addr,
    output reg                          o_bias_ena,
    
    // Mux Select / Control Signals
    output           o_depth_select,     // Ch?n d? li?u t? kh?i Depthwise
    output           o_point_select,     // Ch?n d? li?u t? kh?i Pointwise
    output           o_bias_select,      // Kích ho?t c?ng bias
    
    // Status Output
    output                              o_load_done      // Báo hi?u ð? load xong d? li?u c?n thi?t
);

// DEPTHWISE WEIGHT:
localparam HEAD_DW      = 4;        //mode 0
localparam D1_DW        = 4;        //mode 0
localparam D2_DW        = 8;        //mode 0
localparam D3_DW        = 16;       //mode 0
localparam B_DW         = 32;       //mode 0
localparam U1_DW        = 64;       //mode 1
localparam U2_DW        = 32;       //mode 1
localparam U3_DW        = 16;       //mode 1
localparam U4_DW        = 8;        //mode 1
localparam T_DW         = 4;        //mode 0
// DEPTHWISE BASE ADDRESS:

localparam HEAD_DW_B      = 0  ;    //mode 0  
localparam D1_DW_B        = 4  ;    //mode 0  
localparam D2_DW_B        = 8  ;    //mode 0  
localparam D3_DW_B        = 16 ;    //mode 0  
localparam B_DW_B         = 32 ;    //mode 0  
localparam U1_DW_B        = 64 ;    //mode 1  
localparam U2_DW_B        = 128;    //mode 1  
localparam U3_DW_B        = 160;    //mode 1  
localparam U4_DW_B        = 176;    //mode 1  
localparam T_DW_B         = 184;    //mode 0  

// DEPTHWISE WEIGHT:
localparam HEAD_PW      = 8;        //mode 0 
localparam D1_PW        = 8;        //mode 0 
localparam D2_PW        = 32;       //mode 0 
localparam D3_PW        = 128;      //mode 0 
localparam B_PW         = 256;      //mode 0 
localparam U1_PW        = 256;      //mode 1 - bi xai chung
localparam U2_PW        = 64;       //mode 1 - bi xai chung
localparam U3_PW        = 16;       //mode 1 - bi xai chung
localparam U4_PW        = 8;        //mode 1 - bi xai chung
localparam T_PW         = 8;        //mode 0 - s?a t? 4 thành 8
// DEPTHWISE BASE ADDRESS:

localparam HEAD_PW_B      =0  ;   
localparam D1_PW_B        =8  ;
localparam D2_PW_B        =16 ;
localparam D3_PW_B        =48 ;   
localparam B_PW_B         =176;
localparam U1_PW_B        =432;
localparam U2_PW_B        =688;   
localparam U3_PW_B        =752;
localparam U4_PW_B        =768;
localparam T_PW_B         =776;

localparam HEAD_B      =2 ; //0       // 16 bo 
localparam D1_B        =2 ; //1
localparam D2_B        =8 ; //3
localparam D3_B        =32 ; //7  
localparam B_B         =64 ; //15
localparam U1_B        =32 ; //23
localparam U2_B        =8 ; //27  
localparam U3_B        =2 ; //29
localparam U4_B        =1 ; //30
localparam T_B         =2 ; //3       // them + 1 

localparam HEAD_B_B    = 0 ;      // 16 bo 
localparam D1_B_B      = 2 ;
localparam D2_B_B      = 4 ;
localparam D3_B_B      = 12 ; 
localparam B_B_B       = 44;
localparam U1_B_B      = 108;
localparam U2_B_B      = 140;  
localparam U3_B_B      = 148;
localparam U4_B_B      = 150;
localparam T_B_B       = 151;

localparam IDLE = 'd0;
localparam HEAD = 'd1;
localparam DOWNS1 = 'd2;
localparam DOWNS2 = 'd3;
localparam DOWNS3 = 'd4;
localparam BOTT   = 'd5;
localparam UPS1 = 'd6;
localparam UPS2 = 'd7;
localparam UPS3 = 'd8;
localparam UPS4 = 'd9;
localparam TAIL = 'd10;
localparam DONE = 'd11;
localparam STREAM_OUT = 'd12;


//(* fsm_encoding = "one_hot" *) 
reg [ADDRESS_WEIGHT-3:0] depth_loop;
reg [ADDRESS_WEIGHT-3:0] depth_base_addr;

reg [ADDRESS_WEIGHT- 1:0] point_loop;
reg [ADDRESS_WEIGHT- 1:0] point_base_addr;

reg [ADDRESS_BIAS-1:0] bias_base_addr;
reg [ADDRESS_BIAS-1:0] bias_loop;

reg o_depth_sel, o_point_sel, o_bias_sel;
reg [LATENCY-1:0] o_depth_sel_pipe  ;
reg [LATENCY-1:0] o_point_sel_pipe  ;
reg [LATENCY-1:0] o_bias_sel_pipe   ;

always @(*) begin
    // Kh?i t?o giá tr? m?c ð?nh ð? tránh t?o ra Latches (r?t quan tr?ng trong always @*)
    depth_base_addr = 0; depth_loop = 0;
    point_base_addr = 0; point_loop = 0;
    bias_base_addr  = 0; bias_loop  = 0;

    case (i_stage) 
        HEAD: begin
            depth_base_addr = HEAD_DW_B; depth_loop = HEAD_DW;
            point_base_addr = HEAD_PW_B; point_loop = HEAD_PW;
            bias_base_addr  = HEAD_B_B;  bias_loop  = HEAD_B;
        end
        DOWNS1: begin
            depth_base_addr = D1_DW_B;   depth_loop = D1_DW;
            point_base_addr = D1_PW_B;   point_loop = D1_PW;
            bias_base_addr  = D1_B_B;    bias_loop  = D1_B;
        end
        DOWNS2: begin
            depth_base_addr = D2_DW_B;   depth_loop = D2_DW;
            point_base_addr = D2_PW_B;   point_loop = D2_PW;
            bias_base_addr  = D2_B_B;    bias_loop  = D2_B;
        end
        DOWNS3: begin
            depth_base_addr = D3_DW_B;   depth_loop = D3_DW;
            point_base_addr = D3_PW_B;   point_loop = D3_PW;
            bias_base_addr  = D3_B_B;    bias_loop  = D3_B;
        end
        BOTT: begin
            depth_base_addr = B_DW_B;    depth_loop = B_DW;
            point_base_addr = B_PW_B;    point_loop = B_PW;
            bias_base_addr  = B_B_B;     bias_loop  = B_B;
        end
        UPS1: begin
            depth_base_addr = U1_DW_B;   depth_loop = U1_DW;
            point_base_addr = U1_PW_B;   point_loop = U1_PW;
            bias_base_addr  = U1_B_B;    bias_loop  = U1_B;
        end
        UPS2: begin
            depth_base_addr = U2_DW_B;   depth_loop = U2_DW;
            point_base_addr = U2_PW_B;   point_loop = U2_PW;
            bias_base_addr  = U2_B_B;    bias_loop  = U2_B;
        end
        UPS3: begin
            depth_base_addr = U3_DW_B;   depth_loop = U3_DW;
            point_base_addr = U3_PW_B;   point_loop = U3_PW;
            bias_base_addr  = U3_B_B;    bias_loop  = U3_B;
        end
        UPS4: begin
            depth_base_addr = U4_DW_B;   depth_loop = U4_DW;
            point_base_addr = U4_PW_B;   point_loop = U4_PW;
            bias_base_addr  = U4_B_B;    bias_loop  = U4_B;
        end
        TAIL: begin
            depth_base_addr = T_DW_B;    depth_loop = T_DW;
            point_base_addr = T_PW_B;    point_loop = T_PW;
            bias_base_addr  = T_B_B;     bias_loop  = T_B;
        end
        default: begin
            depth_base_addr = 0; depth_loop = 0;
            point_base_addr = 0; point_loop = 0;
            bias_base_addr  = 0; bias_loop  = 0;
        end
    endcase
end

wire dweight_one_iter       = ((depth_loop + depth_base_addr - 1) ==  o_dweight_rd_addr) ? 1 : 0;
wire pweight_one_iter       = ((point_loop + point_base_addr - 1) ==  o_pweight_rd_addr) ? 1 : 0;
wire bias_one_iter          = ((bias_loop + bias_base_addr - 1) ==  o_bias_rd_addr) ? 1 : 0;
reg [2:0] dweight_cnt;
reg [2:0] pweight_cnt;
reg [2:0] bias_cnt;
wire dweight_done_s1 =  (dweight_cnt == 3) ? 1 : 0;
wire dweight_done_s2 =  (dweight_cnt == 7) ? 1 : 0;
wire pweight_done_s1 =  (pweight_cnt == 3) ? 1 : 0;
wire pweight_done_s2 =  (pweight_cnt == 7) ? 1 : 0;
wire bias_done_s1 =  (bias_cnt == 1-1) ? 1 : 0;
wire bias_done_s2 =  (bias_cnt == 2-1) ? 1 : 0;

reg d_finished, p_finished, b_finished;

reg [1:0] depth_stage, point_stage, bias_stage;

localparam LOAD_S1 = 1;
localparam LOAD_S2 = 2;
localparam LOAD_DONE = 3;

assign o_load_done = d_finished && p_finished && b_finished;

// --- LOGIC CHO DWEIGHT ---
always @(posedge i_clk) begin
    if (!i_rst_n) begin
        o_dweight_rd_addr <= 0;
        dweight_cnt       <= 0;
        o_dweight_ena     <= 0;
        o_depth_sel       <= 0;
        d_finished        <= 0;
        depth_stage      <=  IDLE;
    end 
    else if (i_ld_wb_enable) begin
        case (depth_stage)
            IDLE: begin
                o_dweight_ena <= 1;  
                d_finished <= 0; // co the bi sai do i_ld_wb_enable da = 0 roi  
                depth_stage <= LOAD_S1;
            end
            LOAD_S1: begin
                dweight_cnt         <= dweight_cnt + 1;     
                o_dweight_rd_addr   <= o_dweight_rd_addr + 1;
                if (dweight_done_s1) begin
                    if (i_mode == 1) begin
                        depth_stage <= LOAD_S2;
                        o_depth_sel <= 1;
                    end
                    else begin
                        depth_stage <= LOAD_DONE;
                        d_finished <= 1;
                        dweight_cnt <= 0;
                        o_dweight_ena <= 0;
                        //lam sao de reset
                    end
                end
                if (dweight_one_iter && !i_last_loop) begin
                    o_dweight_rd_addr <= depth_base_addr;               
                end
            end
            LOAD_S2: begin
                dweight_cnt         <= dweight_cnt + 1;     
                o_dweight_rd_addr   <= o_dweight_rd_addr + 1;
                if (dweight_done_s2) begin
                    o_depth_sel    <= 0;
                    dweight_cnt    <= 0;
                    o_dweight_ena  <= 0;
                    depth_stage <= LOAD_DONE;
                end
                if (dweight_one_iter && !i_last_loop) begin
                    o_dweight_rd_addr <= depth_base_addr;               
                end
            end
            LOAD_DONE: begin
                d_finished <= 1;
                if (d_finished && p_finished && b_finished) begin
                    d_finished <= 0;
                    depth_stage <= IDLE;
                end
            end
        endcase
    end
end

always @(posedge i_clk) begin
    if (!i_rst_n) begin
        o_pweight_rd_addr <= 0;
        pweight_cnt       <= 0;
        o_pweight_ena     <= 0;
        o_point_sel       <= 0;
        p_finished        <= 0;
        point_stage      <=  IDLE;
    end 
    else if (i_ld_wb_enable) begin
        case (point_stage)
            IDLE: begin
                o_pweight_ena <= 1;  
                p_finished <= 0; // co the bi sai do i_ld_wb_enable da = 0 roi 
                point_stage <= LOAD_S1; 
            end
            LOAD_S1: begin
                pweight_cnt         <= pweight_cnt + 1;     
                o_pweight_rd_addr   <= o_pweight_rd_addr + 1;
                if (pweight_done_s1) begin
//                    if (i_mode == 0) begin
                        point_stage <= LOAD_S2;
                        o_point_sel <= 1;
//                    end
//                    else begin
//                        point_stage <= LOAD_DONE;
//                        pweight_cnt <= 0;
//                        p_finished <= 1;
//                        o_pweight_ena <= 0;
//                    end
                end
//                if (pweight_one_iter && !i_last_loop) begin
//                    o_pweight_rd_addr <= point_base_addr;               
//                end
            end
            LOAD_S2: begin
                pweight_cnt         <= pweight_cnt + 1;     
                o_pweight_rd_addr   <= o_pweight_rd_addr + 1;
                if (pweight_done_s2) begin
                    o_point_sel    <= 0;
                    pweight_cnt    <= 0;
                    o_pweight_ena  <= 0;
                    point_stage <= LOAD_DONE;
                    p_finished <= 1;
                end
                if (pweight_one_iter && !i_last_loop) begin
                    o_pweight_rd_addr <= point_base_addr;               
                end
            end
            LOAD_DONE: begin
                
                if (d_finished && p_finished && b_finished) begin
                    p_finished <= 0;
                    point_stage <= IDLE;
                end
            end
        endcase
    end
end

 always @(posedge i_clk) begin
    if (!i_rst_n) begin
        o_bias_rd_addr <= 0;
        bias_cnt       <= 0;
        o_bias_ena     <= 0;
        o_bias_sel     <= 0;
        b_finished     <= 0;
        bias_stage     <= IDLE;
    end 
    else if (i_ld_wb_enable) begin
        case (bias_stage)
            IDLE: begin
                o_bias_ena <= 1;  
                b_finished <= 0;
                // N?u c?n b?t ð?u ngay l?p t?c t? IDLE sang LOAD_S1 
                // có th? thêm ði?u ki?n chuy?n state t?i ðây
                bias_stage <= LOAD_S1; 
            end

            LOAD_S1: begin
                bias_cnt        <= bias_cnt + 1;     
                o_bias_rd_addr  <= o_bias_rd_addr + 1;
                
                if (bias_done_s1) begin
                    if (i_mode == 0) begin
                        bias_stage <= LOAD_S2;
                        o_bias_sel <= 1;
                        
                    end
                    else begin
                        bias_stage <= LOAD_DONE;
                        bias_cnt   <= 0;
                        b_finished <= 1;
                        o_bias_ena <= 0; // T?m d?ng ð?c ho?c chuy?n mode

                    end
                end

                // Reset ð?a ch? n?u l?p l?i vùng nh? (cho streaming/tiling)
                if (bias_one_iter && !i_last_loop) begin
                    o_bias_rd_addr <= bias_base_addr; 
                end
                
            end

            LOAD_S2: begin
                bias_cnt        <= bias_cnt + 1;     
                o_bias_rd_addr  <= o_bias_rd_addr + 1;
                
                if (bias_done_s2) begin
                    o_bias_sel     <= 0;
                    bias_cnt       <= 0;
                    o_bias_ena     <= 0;
                    bias_stage     <= LOAD_DONE;
                    b_finished     <= 1;
                end

                if (bias_one_iter && !i_last_loop) begin
                    o_bias_rd_addr <= bias_base_addr;                
                end
            end

            LOAD_DONE: begin
                // Ð?i t?t c? các thành ph?n (Depth, Point, Bias) xong m?i quay v? IDLE
                if (d_finished && p_finished && b_finished) begin
                    b_finished <= 0;
                    bias_stage <= IDLE;
                end
            end
            
            default: bias_stage <= IDLE;
        endcase
    end
end

//HANDLE DELAY
integer k;
always @(posedge i_clk) begin
    o_depth_sel_pipe[0] <= o_depth_sel;
    o_point_sel_pipe[0] <= o_point_sel;
    o_bias_sel_pipe[0]  <= o_bias_sel ;
    for (k = 1; k < LATENCY; k = k + 1) begin
        o_depth_sel_pipe[k] <=  o_depth_sel_pipe[k-1]  ;
        o_point_sel_pipe[k] <=  o_point_sel_pipe[k-1]  ;
        o_bias_sel_pipe [k] <=  o_bias_sel_pipe [k-1];
    end
end

assign o_depth_select = o_depth_sel_pipe[LATENCY-1];
assign o_point_select = o_point_sel_pipe[LATENCY-1];
assign o_bias_select  = o_bias_sel_pipe [LATENCY-1];

endmodule
