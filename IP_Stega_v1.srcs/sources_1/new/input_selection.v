`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2026 06:01:16 PM
// Design Name: 
// Module Name: input_selection
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



//module input_selection #(
//    parameter ADDRESS_DATA = 12
//)(
//    // Inputs t? FSM Control
//    input [3:0]              i_stage,           // Stage hi?n t?i (HEAD, D1, D2...)
//    input [3:0]              i_mem_rd_swapping, // Tín hi?u ch?n bank/c?u h?nh t? FSM
//    input [ADDRESS_DATA+1:0] i_mem_rd_addr,     // Ð?a ch? ð?c chung t? FSM
//    input                    i_mem_rd_enb,      // Enable ð?c chung t? FSM
//    input [3:0]              i_lic,
//    input [7:0]              i_row,
//    input [7:0]              i_col,
    

//    // Outputs t?i các kh?i Memory (Image + 6 Banks)
//    output reg [ADDRESS_DATA+1:0] o_mem_img_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem0_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem1_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem2_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem3_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem4_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem5_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem_stega_addr,


//    output reg [6:0] o_mem_img_enb,
//    output reg [16:0] o_mem0_enb,
//    output reg [8:0] o_mem1_enb,
//    output reg [8:0] o_mem2_enb,
//    output reg [8:0] o_mem3_enb,
//    output reg [8:0] o_mem4_enb,
//    output reg [8:0] o_mem5_enb,
//    output reg [2:0] o_mem_stega_enb
//);

//localparam IDLE = 'd0;
//localparam HEAD = 'd1;
//localparam DOWNS1 = 'd2;
//localparam DOWNS2 = 'd3;
//localparam DOWNS3 = 'd4;
//localparam BOTT   = 'd5;
//localparam UPS1 = 'd6;
//localparam UPS2 = 'd7;
//localparam UPS3 = 'd8;
//localparam UPS4 = 'd9;
//localparam TAIL = 'd10;
//localparam DONE = 'd11;
//localparam STREAM_OUT = 'd12;

//always @(*) begin
//    o_mem_img_addr = 0;
//    o_mem0_addr    = 0;
//    o_mem1_addr    = 0;
//    o_mem2_addr    = 0;
//    o_mem3_addr    = 0;
//    o_mem4_addr    = 0;
//    o_mem5_addr    = 0;
//    o_mem_img_enb = 0; o_mem0_enb = 0; o_mem1_enb = 0; 
//    o_mem2_enb = 0;    o_mem3_enb = 0; o_mem4_enb = 0; o_mem5_enb = 0;
//    case (i_stage) 
//        HEAD: begin
//            o_mem_img_enb = { {6{i_mem_rd_enb}} };
//            o_mem_img_addr = i_mem_rd_addr; //Ð?m t?i 16384
//        end
//        DOWNS1: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem0_enb = {12'b0, {4{i_mem_rd_enb}}};
//                    o_mem0_addr = i_mem_rd_addr[ADDRESS_DATA-1:0]; //4096
//                end
//                1: begin
//                    o_mem0_enb = {8'b0, {4{i_mem_rd_enb}}, 4'b0};
//                    o_mem0_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end
//                2: begin
//                    o_mem0_enb = {4'b0, {4{i_mem_rd_enb}}, 8'b0};
//                    o_mem0_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end
//                3: begin
//                    o_mem0_enb = {{4{i_mem_rd_enb}}, 12'b0};
//                    o_mem0_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];                    
//                end
//            endcase
//        end
//        DOWNS2: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem1_enb = {4'b0, {4{i_mem_rd_enb}}}; //4096
//                    o_mem1_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];       
//                end      
//                1: begin 
//                    o_mem1_enb = {{4{i_mem_rd_enb}}, 4'b0};
//                    o_mem1_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end      
                                  
//            endcase
//        end
//        DOWNS3: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem2_enb = {4'b0, {4{i_mem_rd_enb}}};
//                    o_mem2_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];    //2048
//                end      
//                1: begin 
//                    o_mem2_enb = {{4{i_mem_rd_enb}}, 4'b0};
//                    o_mem2_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end      
//            endcase
//        end
//        BOTT: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem3_enb = {4'b0, {4{i_mem_rd_enb}}};
//                    o_mem3_addr = i_mem_rd_addr[ADDRESS_DATA-1:0]; //1024
//                end      
//                1: begin 
//                    o_mem3_enb = {{4{i_mem_rd_enb}}, 4'b0};
//                    o_mem3_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end      
//            endcase
//        end
        
//        UPS1: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem4_enb = {{8{i_mem_rd_enb}}}; //256
//                    o_mem4_addr = {6'b0,i_lic[3:0],i_row[3:1],i_col[3:1]};
//                end      
//                1: begin 
//                    o_mem3_enb = {{8{i_mem_rd_enb}}};
//                    o_mem3_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end      
//            endcase
//        end
//        UPS2: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem5_enb = {{8{i_mem_rd_enb}}};
//                    o_mem5_addr = {4'b0,i_lic[3:0],i_row[4:1],i_col[4:1]};
//                end      
//                1: begin 
//                    o_mem2_enb = {8{i_mem_rd_enb}};
//                    o_mem2_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end      
//            endcase
//        end
//        UPS3: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem3_enb = {{8{i_mem_rd_enb}}};
//                    o_mem3_addr = {2'b0,i_lic[3:0],i_row[5:1],i_col[5:1]};
//                end      
//                1: begin 
//                    o_mem1_enb = {8{i_mem_rd_enb}};
//                    o_mem1_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end      
//            endcase
//        end
//        UPS4: begin
//            o_mem2_enb = {4'b0,{4{i_mem_rd_enb}}};
//            o_mem2_addr = {i_lic[3:0],i_row[6:1],i_col[6:1]}; //4096
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem0_enb = {12'b0, {4{i_mem_rd_enb}}};               
//                    o_mem0_addr = i_mem_rd_addr[ADDRESS_DATA-1:0]; //4096

//                end      
//                1: begin 
//                    o_mem0_enb = {8'b0, {4{i_mem_rd_enb}},4'b0};               
//                    o_mem0_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end 
//                2: begin
//                    o_mem0_enb = {4'b0, {4{i_mem_rd_enb}},8'b0};
//                    o_mem0_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end      
//                3: begin 
//                    o_mem0_enb = {{4{i_mem_rd_enb}},12'b0};
//                    o_mem0_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end 
                     
//            endcase
//        end
//        TAIL: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem1_enb = {4'b0, {4{i_mem_rd_enb}}};
//                    o_mem1_addr = i_mem_rd_addr[ADDRESS_DATA-1:0]; //4096
//                end  
//                1: begin
//                    o_mem1_enb = {{4{i_mem_rd_enb}}, 4'b0};
//                    o_mem1_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end    
//                2: begin 
//                    o_mem3_enb = {4'b0, {4{i_mem_rd_enb}}};
//                    o_mem3_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end 
//                3: begin
//                    o_mem3_enb = {{4{i_mem_rd_enb}}, 4'b0};
//                    o_mem3_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end     
//            endcase
//        end
//        DONE: begin
//            o_mem_img_enb = {13'b0, {3{i_mem_rd_enb}}};
//            o_mem_img_addr = i_mem_rd_addr; //ð?m t?i 16384
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem2_enb = {7'b0, {i_mem_rd_enb}};
//                    o_mem2_addr = i_mem_rd_addr[ADDRESS_DATA-1:0]; //ð?m t?i 4096 l?y bit width chu?n
//                end
//                1: begin
//                    o_mem2_enb = {6'b0, {i_mem_rd_enb}, 1'b0};
//                    o_mem2_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end
//                2: begin
//                    o_mem2_enb = {5'b0, i_mem_rd_enb, 2'b0};
//                    o_mem2_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end
//                3: begin
//                    o_mem2_enb = {4 'b0, i_mem_rd_enb, 3'b0};
//                    o_mem2_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];                    
//                end
//            endcase
//        end
//        STREAM_OUT: begin
//            case (i_mem_rd_swapping)
//                0: begin
//                    o_mem_stega_enb = {2'b0, {i_mem_rd_enb}};
//                    o_mem_stega_addr = i_mem_rd_addr[ADDRESS_DATA-1:0]; //ð?m t?i 4096 l?y bit width chu?n
//                end
//                1: begin
//                    o_mem_stega_enb = {1'b0, {i_mem_rd_enb}, 1'b0};
//                    o_mem_stega_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end
//                2: begin
//                    o_mem_stega_enb = { i_mem_rd_enb, 2'b0};
//                    o_mem_stega_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];
//                end
//            endcase
//        end
//    endcase
    
//end


//endmodule 


//module rd_selection #(
//    parameter ADDRESS_DATA = 14
//)(
//    input                    clk,
//    input                    rst_n,
//    // Inputs t? FSM Control
//    input [3:0]              i_stage,           
//    input [3:0]              i_mem_rd_swapping, 
//    input [ADDRESS_DATA-1:0] i_mem_rd_addr,     
//    input                    i_mem_rd_enb,      
//    input [3:0]              i_lic,
//    input [7:0]              i_row,
//    input [7:0]              i_col,

//    // Outputs ð? ðý?c Register (Pipelined) ð? ð?t hi?u su?t cao nh?t
//    output reg [ADDRESS_DATA-1:0] o_mem_img_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem0_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem1_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem2_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem3_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem4_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem5_addr,

//    output reg [15:0] o_mem_img_enb,
//    output reg [15:0] o_mem0_enb,
//    output reg [15:0] o_mem1_enb,
//    output reg [15:0] o_mem2_enb,
//    output reg [15:0] o_mem3_enb,
//    output reg [15:0] o_mem4_enb,
//    output reg [15:0] o_mem5_enb
//);

//    // Ð?nh ngh?a Stage
//    localparam HEAD = 4'd1, DOWNS1 = 4'd2, DOWNS2 = 4'd3, DOWNS3 = 4'd4, 
//               BOTT = 4'd5, UPS1 = 4'd6, UPS2 = 4'd7, UPS3 = 4'd8, 
//               UPS4 = 4'd9, TAIL = 4'd10, DONE = 4'd11;

//    // Logic tính toán Mask linh ho?t (Common Mask Logic)
//    wire [15:0] mask_4b = (16'h000F << (i_mem_rd_swapping[1:0] * 4));
//    wire [15:0] mask_8b = (16'h00FF); // Luôn ? 8-bit th?p cho UPS
//    wire [15:0] mask_1b = (16'h0001 << i_mem_rd_swapping[1:0]);

//    // Lu?ng Data Path chính
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            // Reset toàn b? Output v? 0
//            {o_mem_img_enb, o_mem0_enb, o_mem1_enb, o_mem2_enb, o_mem3_enb, o_mem4_enb, o_mem5_enb} <= 0;
//            {o_mem_img_addr, o_mem0_addr, o_mem1_addr, o_mem2_addr, o_mem3_addr, o_mem4_addr, o_mem5_addr} <= 0;
//        end else begin
//            // M?c ð?nh: Gán ð?a ch? chung và t?t Enable
//            {o_mem_img_enb, o_mem0_enb, o_mem1_enb, o_mem2_enb, o_mem3_enb, o_mem4_enb, o_mem5_enb} <= 0;
//            {o_mem_img_addr, o_mem0_addr, o_mem1_addr, o_mem2_addr, o_mem3_addr, o_mem4_addr, o_mem5_addr} <= {7{i_mem_rd_addr}};

//            case (i_stage)
//                HEAD: begin
//                    o_mem_img_enb <= {10'b0, {6{i_mem_rd_enb}}};
//                end

//                DOWNS1: o_mem0_enb <= i_mem_rd_enb ? mask_4b : 16'h0;
//                DOWNS2: o_mem1_enb <= i_mem_rd_enb ? mask_4b : 16'h0;
//                DOWNS3: o_mem2_enb <= i_mem_rd_enb ? mask_4b : 16'h0;
//                BOTT:   o_mem3_enb <= i_mem_rd_enb ? mask_4b : 16'h0;

//                UPS1: begin
//                    if (i_mem_rd_swapping[0] == 0) begin
//                        o_mem4_enb  <= i_mem_rd_enb ? mask_8b : 16'h0;
//                        o_mem4_addr <= {6'b0, i_lic[3:0], i_row[3:1], i_col[3:1]};
//                    end else o_mem3_enb <= i_mem_rd_enb ? mask_8b : 16'h0;
//                end

//                UPS2: begin
//                    if (i_mem_rd_swapping[0] == 0) begin
//                        o_mem5_enb  <= i_mem_rd_enb ? mask_8b : 16'h0;
//                        o_mem5_addr <= {4'b0, i_lic[3:0], i_row[4:1], i_col[4:1]};
//                    end else o_mem2_enb <= i_mem_rd_enb ? mask_8b : 16'h0;
//                end

//                UPS3: begin
//                    if (i_mem_rd_swapping[0] == 0) begin
//                        o_mem3_enb  <= i_mem_rd_enb ? mask_8b : 16'h0;
//                        o_mem3_addr <= {2'b0, i_lic[3:0], i_row[5:1], i_col[5:1]};
//                    end else o_mem1_enb <= i_mem_rd_enb ? mask_8b : 16'h0;
//                end

//                UPS4: begin
//                    o_mem2_addr <= {i_lic[3:0], i_row[6:1], i_col[6:1]};
//                    o_mem2_enb  <= i_mem_rd_enb ? mask_4b : 16'h0;
//                    o_mem0_enb  <= i_mem_rd_enb ? mask_4b : 16'h0;
//                end

//                TAIL: begin
//                    if (i_mem_rd_swapping[0] == 0) o_mem3_enb <= i_mem_rd_enb ? mask_8b : 16'h0;
//                    else                          o_mem1_enb <= i_mem_rd_enb ? mask_8b : 16'h0;
//                end

//                DONE: begin
//                    o_mem_img_enb <= {13'b0, {3{i_mem_rd_enb}}};
//                    o_mem2_enb    <= i_mem_rd_enb ? mask_1b : 16'h0;
//                end
                
//                default: ; // Gi? nguyên tr?ng thái reset
//            endcase
//        end
//    end
//endmodule

module wr_fsm_control #(
    parameter DATA_COMPUTED_W = 16*16*2,
    parameter ADDER_COMPUTED_W = 16*3,
    parameter ADDR_URAM_W     = 12,
    parameter ADDR_STEGA_W    = 14,
    parameter STAGE_W          = 4
)(
    input                            i_clk,
    input                            i_rst_n,
    
    // --- Inputs t? Processing Core ---
    input [DATA_COMPUTED_W-1:0]      i_computed_data, // D? li?u 512-bit sau x? l?
    input [ADDER_COMPUTED_W-1:0]     i_computed_adder,
    input                            i_vld,           // Data valid t? Core
    input                            i_adder_vld,
    input [STAGE_W-1:0]              i_stage,         // Stage hi?n t?i (HEAD, DOWNS1...)

    // --- Output Enable (Giao ti?p v?i b? gom 64-bit) ---
    // Lýu ?: ena này ði?u khi?n vi?c ghi 16-bit vào buffer trý?c khi ð?y vào URAM
    output reg [15:0]                o_wr_mem0_ena,   
    output reg [7:0]                 o_wr_mem1_ena,
    output reg [7:0]                 o_wr_mem2_ena,
    output reg [7:0]                 o_wr_mem3_ena,
    output reg [7:0]                 o_wr_mem4_ena,
    output reg [7:0]                 o_wr_mem5_ena,
    output reg [2:0]                 o_wr_mem_stega_ena,

    // --- Output Addresses ---
    output reg [ADDR_URAM_W-1:0]     o_wr_mem0_addr,
    output reg [ADDR_URAM_W-1:0]     o_wr_mem1_addr,
    output reg [ADDR_URAM_W-1:0]     o_wr_mem2_addr,
    output reg [ADDR_URAM_W-1:0]     o_wr_mem3_addr,
    output reg [ADDR_URAM_W-1:0]     o_wr_mem4_addr,
    output reg [ADDR_URAM_W-1:0]     o_wr_mem5_addr,
    output reg [ADDR_STEGA_W-1:0]    o_wr_mem_stega_addr,
    output reg [DATA_COMPUTED_W-1:0] o_computed_data,
    output reg [ADDER_COMPUTED_W-1:0] o_computed_adder
);

localparam HEAD = 4'd1, DOWNS1 = 4'd2, DOWNS2 = 4'd3, DOWNS3 = 4'd4, 
               BOTT = 4'd5, UPS1 = 4'd6, UPS2 = 4'd7, UPS3 = 4'd8, 
               UPS4 = 4'd9, TAIL = 4'd10, DONE = 4'd11;

//localparam stop address
localparam WR_ADDR_ADDR_H = 4096;
localparam WR_ADDR_ADDR_D1 = 4096;
localparam WR_ADDR_ADDR_D2 = 2048;
localparam WR_ADDR_ADDR_D3 = 1024;
localparam WR_ADDR_ADDR_B = 256;   //8*8*8 (16 kenh moi lan)
localparam WR_ADDR_ADDR_U1 = 256;  
localparam WR_ADDR_ADDR_U2 = 1024;
localparam WR_ADDR_ADDR_U3 = 4096;
localparam WR_ADDR_ADDR_U4 = 4096;
localparam WR_ADDR_ADDR_T = 4096;
localparam WR_ADDR_ADDR_D = 16384;

localparam WR_ADDR_ADDR_U1_T = 512;  
localparam WR_ADDR_ADDR_U2_T = 1024;
localparam WR_ADDR_ADDR_U3_T = 4096;
localparam WR_ADDR_ADDR_U4_T = 4096;
localparam WR_ADDR_ADDR_T_T = 4096;
localparam WR_ADDR_ADDR_D_T = 16384;


reg [14:0] r_wr_addr_limit, r_wr_addr_t_limit, tmp_wr_addr;
reg [1:0] mem_rd_swapping;
always @(*) begin
    // --- Default Values (Tránh t?o Latch) ---
    r_wr_addr_limit = 4096;
    r_wr_addr_t_limit = 0;
//    r_wr_lic_limit  = 1;
//    r_wr_loc_limit  = 1;

    case (i_stage)
        HEAD: begin
            r_wr_addr_limit = WR_ADDR_ADDR_H;
        end
        DOWNS1: begin
            r_wr_addr_limit = WR_ADDR_ADDR_D1;
        end
        DOWNS2: begin
            r_wr_addr_limit = WR_ADDR_ADDR_D2;
        end
        DOWNS3: begin
            r_wr_addr_limit = WR_ADDR_ADDR_D3;
        end
        BOTT: begin
            r_wr_addr_limit = WR_ADDR_ADDR_B;
        end
        UPS1: begin
            r_wr_addr_limit = WR_ADDR_ADDR_U1;
            r_wr_addr_t_limit = WR_ADDR_ADDR_U1_T;
        end
        UPS2: begin
            r_wr_addr_limit = WR_ADDR_ADDR_U2;
            r_wr_addr_t_limit = WR_ADDR_ADDR_U2_T;

        end
        UPS3: begin
            r_wr_addr_limit = WR_ADDR_ADDR_U3;
            r_wr_addr_t_limit = WR_ADDR_ADDR_U3_T;
        end
        UPS4: begin
            r_wr_addr_limit = WR_ADDR_ADDR_U4;
            r_wr_addr_t_limit = WR_ADDR_ADDR_U4_T;
        end
        TAIL: begin
            r_wr_addr_limit = WR_ADDR_ADDR_T;
            r_wr_addr_t_limit = WR_ADDR_ADDR_T_T;
        end
        DONE: begin
            r_wr_addr_limit = WR_ADDR_ADDR_D;
            r_wr_addr_t_limit = WR_ADDR_ADDR_D_T;
        end
        default: ; // S? d?ng giá tr? m?c ð?nh ð? gán ? ð?u block
    endcase
end
reg [1:0] pipe_mem_swap;
reg [14:0] wr_addr;
always @(posedge i_clk) begin
    if (!i_rst_n) begin
        wr_addr <=0;
        mem_rd_swapping <= 0;
        pipe_mem_swap   <= 0;
    end
   else begin
        o_computed_data <= i_computed_data;
        o_computed_adder <= i_computed_adder;
        o_wr_mem0_addr <= 0;
        o_wr_mem1_addr <= 0;
        o_wr_mem2_addr <= 0;
        o_wr_mem3_addr <= 0;
        o_wr_mem4_addr <= 0;
        o_wr_mem5_addr <= 0;
        o_wr_mem_stega_addr <= 0;
        o_wr_mem0_ena <= 0;
        o_wr_mem1_ena <= 0;
        o_wr_mem2_ena <= 0;
        o_wr_mem3_ena <= 0;
        o_wr_mem4_ena <= 0;
        o_wr_mem5_ena <= 0;
        o_wr_mem_stega_ena <= 0;
        if (i_vld || i_adder_vld) begin
            case (i_stage)
                HEAD: begin
                    o_wr_mem0_addr <= wr_addr;
                    wr_addr <= wr_addr + 1;
    //                pipe_mem_swap <= mem_rd_swapping;
                     case (mem_rd_swapping)
                        0: begin
                            o_wr_mem0_ena <= {12'b0, {4{i_vld}}};
                            if (wr_addr == r_wr_addr_limit - 1) begin
                                wr_addr <= 0;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                        end
                        1: begin
                            o_wr_mem0_ena <= {8'b0, {4{i_vld}}, 4'b0};
    
                            if (wr_addr == r_wr_addr_limit - 1) begin
                                wr_addr <= 0;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                        end
                        2: begin
                            o_wr_mem0_ena <= {4'b0, {4{i_vld}}, 8'b0};
    //                        o_wr_mem0_addr <= wr_addr;
    //                        wr_addr <= wr_addr + 1;
                            if (wr_addr == r_wr_addr_limit - 1) begin
                                wr_addr <= 0;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                        end
                        3: begin
                            o_wr_mem0_ena <= {{4{i_vld}}, 12'b0};
    //                        o_wr_mem0_addr <= wr_addr; 
    //                        wr_addr <= wr_addr + 1;
                            if (wr_addr == r_wr_addr_limit - 1) begin
                                wr_addr <= 0;
                                mem_rd_swapping <= 0;
//                                pipe_mem_swap <= 0;
                            end                   
                        end
                    endcase
                end
                DOWNS1: begin
                    o_wr_mem1_ena <= {8{i_vld}};
                    o_wr_mem1_addr <= wr_addr;
                    wr_addr <= wr_addr + 1;
                    if (wr_addr == r_wr_addr_limit -1) begin
                        wr_addr <= 0;
                    end
                end
                DOWNS2: begin
                    o_wr_mem2_ena <= {8{i_vld}};
                    o_wr_mem2_addr <= wr_addr;
                    wr_addr <= wr_addr + 1;
                    if (wr_addr == r_wr_addr_limit -1) begin
                        wr_addr <= 0;
                    end
                end
                DOWNS3: begin
                    o_wr_mem3_ena <= {8{i_vld}};
                    o_wr_mem3_addr <= wr_addr;
                    wr_addr <= wr_addr + 1;
                    if (wr_addr == r_wr_addr_limit -1) begin
                        wr_addr <= 0;
                    end
                end
                BOTT: begin
                    o_wr_mem4_ena <= {8{i_vld}};
                    o_wr_mem4_addr <= wr_addr;
                    wr_addr <= wr_addr + 1;
                    if (wr_addr == r_wr_addr_limit -1) begin
                        wr_addr <= 0;
                    end
                end
                UPS1: begin
                    o_wr_mem5_addr <= wr_addr;
                    wr_addr <= wr_addr + 1;
                    tmp_wr_addr <=  r_wr_addr_limit - 1;
//                    pipe_mem_swap <= mem_rd_swapping;
                    case (mem_rd_swapping) 
                        0: begin
                            o_wr_mem5_ena <= {4'b0,{4{i_vld}}};
                            if (wr_addr == r_wr_addr_t_limit -1) begin
                                wr_addr <= wr_addr - tmp_wr_addr;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                            else if (wr_addr == r_wr_addr_limit -1) begin
                                wr_addr <= wr_addr - tmp_wr_addr;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                        end
                        1: begin
                            o_wr_mem5_ena <= {{4{i_vld}},4'b0};
                            if (wr_addr == r_wr_addr_t_limit -1) begin
                                wr_addr <=0;
                                mem_rd_swapping <=0;
                            end
                            else if (wr_addr == r_wr_addr_limit -1) begin
                                mem_rd_swapping <= 0;
                                
                            end
                        end
                    endcase
                end
                UPS2: begin
                    o_wr_mem3_addr <= wr_addr;
                    wr_addr <= wr_addr + 1;
                    tmp_wr_addr <=  r_wr_addr_limit - 1;
//                    pipe_mem_swap <= mem_rd_swapping;
                    case (mem_rd_swapping) 
                        0: begin
                            o_wr_mem3_ena <= {4'b0,{4{i_vld}}};
                            if (wr_addr == r_wr_addr_limit -1) begin
                                wr_addr <= wr_addr - tmp_wr_addr;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                        end
                        1: begin
                            o_wr_mem3_ena <= {{4{i_vld}},4'b0};
                            if (wr_addr == r_wr_addr_t_limit -1) begin
                                wr_addr <=0;
                                mem_rd_swapping <=0;
                            end
                        end
                    endcase 
                end
                UPS3: begin
                    o_wr_mem2_ena <= {4'b0,{4{i_vld}}};
                    o_wr_mem2_addr <= wr_addr;
                    wr_addr <= wr_addr + 1;
                    
                    if (wr_addr == r_wr_addr_t_limit - 1) begin
                        wr_addr <= 0;
                        mem_rd_swapping <= 0;
                    end
    
                 end
                 UPS4: begin
                    tmp_wr_addr <=  r_wr_addr_limit - 1;
                    case (mem_rd_swapping)
                        0: begin
                            o_wr_mem1_ena <= {4'b0, {4{i_vld}}};
                            o_wr_mem1_addr <= wr_addr;
                            wr_addr <= wr_addr + 1;
                            if (wr_addr == r_wr_addr_limit -1) begin
                                wr_addr <= wr_addr - tmp_wr_addr;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                        end
                        1: begin
                            o_wr_mem1_ena <= {{4{i_vld}}, 4'b0};
                            o_wr_mem1_addr  <= wr_addr;
                            wr_addr <= wr_addr + 1;
                            if (wr_addr == r_wr_addr_limit -1) begin
                                wr_addr <= wr_addr - tmp_wr_addr;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                        end
                        2: begin
                            o_wr_mem3_ena  <= {4'b0, {4{i_vld}}};
                            o_wr_mem3_addr <= wr_addr;
                            wr_addr <= wr_addr + 1;
                            if (wr_addr == r_wr_addr_limit -1) begin
                                wr_addr <= wr_addr - tmp_wr_addr;
                                mem_rd_swapping <= mem_rd_swapping + 1;
                            end
                        end
                        3: begin
                            o_wr_mem3_ena  <= {{4{i_vld}}, 4'b0};
                            o_wr_mem3_addr <= wr_addr; 
                            wr_addr <= wr_addr + 1;
                            if (wr_addr == r_wr_addr_t_limit - 1) begin
                                wr_addr <= 0;
                                mem_rd_swapping <= 0;
                            end
                        end
                    endcase
                    end
                    
                    TAIL: begin
                        tmp_wr_addr <=  r_wr_addr_limit - 1;
                        o_wr_mem2_addr  <= wr_addr;
                        wr_addr <= wr_addr + 1;
//                        pipe_mem_swap <= mem_rd_swapping;
                        case (mem_rd_swapping)
                            0: begin
                                o_wr_mem2_ena <= {7'b0, {{i_vld}}};
    //                            o_wr_mem2_addr <= wr_addr;
    //                            wr_addr <= wr_addr + 1;
                                if (wr_addr == r_wr_addr_limit -1) begin
                                    wr_addr <= wr_addr - tmp_wr_addr;
                                    mem_rd_swapping <= mem_rd_swapping + 1;
                                end
                            end
                            1: begin
                                o_wr_mem2_ena <= {6'b0, {{i_vld}}, 1'b0};
                                
                                if (wr_addr == r_wr_addr_limit -1) begin
                                    wr_addr <= wr_addr - tmp_wr_addr;
                                    mem_rd_swapping <= mem_rd_swapping + 1;
                                end
                            end
                            2: begin
                                o_wr_mem2_ena <= {5'b0, {{i_vld}}, 2'b0};
    
                                if (wr_addr == r_wr_addr_limit -1) begin
                                    wr_addr <= wr_addr - tmp_wr_addr;
                                    mem_rd_swapping <= mem_rd_swapping + 1;
                                end
                            end
                            3: begin
                                o_wr_mem2_ena <= {4'b0,{{i_vld}}, 3'b0};
    
                                if (wr_addr == r_wr_addr_t_limit - 1) begin
                                    wr_addr <= 0;
                                    mem_rd_swapping <= 0;
//                                    pipe_mem_swap <= 0;
                                end                  
                            end
                        endcase
                 end
//                 DONE: begin
//                    o_wr_mem_stega_ena <= {{3{i_adder_vld}}};
//                    o_wr_mem_stega_addr <= wr_addr;
//                    wr_addr <= wr_addr + 1;
//                    if (wr_addr == r_wr_addr_limit -1) begin
//                        mem_rd_swapping <= 0;
//                        wr_addr <= 0;
//                    end  
//                 end
//                 default: begin 
//                        mem_rd_swapping <= 0;
//                        wr_addr <= 0;
//                 end
                default: begin
                end
            endcase
        end
    end
end


endmodule