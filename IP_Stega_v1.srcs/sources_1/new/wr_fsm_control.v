//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 04/02/2026 03:22:45 PM
//// Design Name: 
//// Module Name: wr_fsm_control
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//module wr_fsm_control #(
//    parameter DATA_COMPUTED_W = 512,
//    parameter ADDR_URAM_W     = 12,
//    parameter ADDR_STEGA_W    = 14,
//    parameter STAGE_W         = 4
//)(
//    input                             i_clk,
//    input                             i_rst_n,
//    input                             i_vld,
//    input [STAGE_W-1:0]               i_stage,
////    input [ADDR_STEGA_W-1:0]          i_mem_wr_addr,

//    // --- Output Enable ---
//    output reg [15:0]                 o_wr_mem0_ena,   
//    output reg [7:0]                  o_wr_mem1_ena,
//    output reg [7:0]                  o_wr_mem2_ena,
//    output reg [7:0]                  o_wr_mem3_ena,
//    output reg [7:0]                  o_wr_mem4_ena,
//    output reg [7:0]                  o_wr_mem5_ena,
//    output reg [2:0]                  o_wr_mem_stega_ena,

//    // --- Output Addresses (Gom chung tín hi?u) ---
//    output [ADDR_URAM_W-1:0]          o_wr_mem0_addr,
//    output [ADDR_URAM_W-1:0]          o_wr_mem1_addr,
//    output [ADDR_URAM_W-1:0]          o_wr_mem2_addr,
//    output [ADDR_URAM_W-1:0]          o_wr_mem3_addr,
//    output [ADDR_URAM_W-1:0]          o_wr_mem4_addr,
//    output [ADDR_URAM_W-1:0]          o_wr_mem5_addr,
//    output [ADDR_STEGA_W-1:0]         o_wr_mem_stega_addr
//);

//localparam HEAD = 4'd1, DOWNS1 = 4'd2, DOWNS2 = 4'd3, DOWNS3 = 4'd4, 
//           BOTT = 4'd5, UPS1 = 4'd6,   UPS2 = 4'd7,   UPS3 = 4'd8, 
//           UPS4 = 4'd9, TAIL = 4'd10,  DONE = 4'd11;

//reg [15:0] r_wr_addr_limit, r_wr_addr_t_limit;
//reg [11:0] wr_addr;
//reg [1:0]  mem_rd_swapping;
//wire [15:0] tmp_wr_addr = r_wr_addr_limit - 1;

//// --- 1. GOM CHUNG TÍN HI?U Ð?A CH? (Optimized for Physical Design) ---
//// Các URAM ch? l?y 12 bit th?p, Stega l?y ð? 14 bit t? input
//assign o_wr_mem0_addr = i_mem_wr_addr[ADDR_URAM_W-1:0];
//assign o_wr_mem1_addr = i_mem_wr_addr[ADDR_URAM_W-1:0];
//assign o_wr_mem2_addr = i_mem_wr_addr[ADDR_URAM_W-1:0];
//assign o_wr_mem3_addr = i_mem_wr_addr[ADDR_URAM_W-1:0];
//assign o_wr_mem4_addr = i_mem_wr_addr[ADDR_URAM_W-1:0];
//assign o_wr_mem5_addr = i_mem_wr_addr[ADDR_URAM_W-1:0];
//assign o_wr_mem_stega_addr = i_mem_wr_addr;

//// --- 2. Combinational Limits ---
//always @(*) begin
//    r_wr_addr_limit = 4096; r_wr_addr_t_limit = 0;
//    case (i_stage)
//        HEAD:   r_wr_addr_limit = 4096;
//        DOWNS1: r_wr_addr_limit = 4096;
//        DOWNS2: r_wr_addr_limit = 2048;
//        DOWNS3: r_wr_addr_limit = 1024;
//        BOTT:   r_wr_addr_limit = 256;
//        UPS1:   begin r_wr_addr_limit = 256;  r_wr_addr_t_limit = 512;  end
//        UPS2:   begin r_wr_addr_limit = 1024; r_wr_addr_t_limit = 1024; end
//        UPS3:   begin r_wr_addr_limit = 4096; r_wr_addr_t_limit = 4096; end
//        UPS4:   begin r_wr_addr_limit = 4096; r_wr_addr_t_limit = 4096; end
//        TAIL:   begin r_wr_addr_limit = 4096; r_wr_addr_t_limit = 4096; end
//        DONE:   begin r_wr_addr_limit = 16384; r_wr_addr_t_limit = 16384; end
//        default:;
//    endcase
//end

//always @(posedge i_clk) begin
//    if (!i_rst_n) begin
//        wr_addr <= 0;
//        mem_rd_swapping <= 0;
//        {o_wr_mem0_ena, o_wr_mem1_ena, o_wr_mem2_ena, o_wr_mem3_ena, 
//         o_wr_mem4_ena, o_wr_mem5_ena, o_wr_mem_stega_ena} <= 0;
//    end 
//    else begin
//        // M?c ð?nh là 0, ch? có giá tr? khi i_vld = 1 và th?a case
//        {o_wr_mem0_ena, o_wr_mem1_ena, o_wr_mem2_ena, o_wr_mem3_ena, 
//         o_wr_mem4_ena, o_wr_mem5_ena, o_wr_mem_stega_ena} <= 0;

//        if (i_vld) begin
//            case (i_stage)
//                HEAD: begin
//                    case (mem_rd_swapping)
//                        // Gán mask k?t h?p v?i i_vld (Duy có th? vi?t th?ng mask v? ð? n?m trong if(i_vld))
//                        0: o_wr_mem0_ena <= 16'h000F; 
//                        1: o_wr_mem0_ena <= 16'h00F0;
//                        2: o_wr_mem0_ena <= 16'h0F00; 
//                        3: o_wr_mem0_ena <= 16'hF000;
//                    endcase
//                end
//                DOWNS1: o_wr_mem1_ena <= 8'hFF; // Týõng ðýõng {8{i_vld}} khi i_vld=1
//                DOWNS2: o_wr_mem2_ena <= 8'hFF;
//                DOWNS3: o_wr_mem3_ena <= 8'hFF;
//                BOTT:   o_wr_mem4_ena <= 8'hFF;
//                UPS1:   o_wr_mem5_ena <= (mem_rd_swapping == 0) ? 8'h0F : 8'hF0;
//                UPS2:   o_wr_mem3_ena <= (mem_rd_swapping == 0) ? 8'h0F : 8'hF0;
//                UPS3:   o_wr_mem2_ena <= (mem_rd_swapping == 0) ? 8'h0F : 8'hF0;
//                UPS4:   begin
//                    case (mem_rd_swapping)
//                        0, 1: o_wr_mem1_ena <= (mem_rd_swapping == 0) ? 8'h0F : 8'hF0;
//                        2, 3: o_wr_mem3_ena <= (mem_rd_swapping == 2) ? 8'h0F : 8'hF0;
//                    endcase
//                end
//                TAIL:   begin
//                    case (mem_rd_swapping)
//                        0: o_wr_mem2_ena <= 8'h01; 1: o_wr_mem2_ena <= 8'h02;
//                        2: o_wr_mem2_ena <= 8'h04; 3: o_wr_mem2_ena <= 8'h08;
//                    endcase
//                end
//                DONE:   o_wr_mem_stega_ena <= 3'b111;
//            endcase

//            // Logic ð?m wr_addr và swapping (Ch? ch?y khi i_vld = 1)
//            if (wr_addr == r_wr_addr_t_limit - 1 && r_wr_addr_t_limit != 0) begin
//                wr_addr <= 0;
//                mem_rd_swapping <= 0;
//            end 
//            else if (wr_addr == r_wr_addr_limit - 1) begin
//                mem_rd_swapping <= mem_rd_swapping + 1;
//                wr_addr <= wr_addr - tmp_wr_addr; 
//            end 
//            else begin
//                wr_addr <= wr_addr + 1;
//            end
//        end
//    end
//end

//endmodule
