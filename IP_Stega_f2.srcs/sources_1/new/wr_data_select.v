`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2026 03:18:11 PM
// Design Name: 
// Module Name: wr_data_select
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


module wr_data_select
#(
parameter BANK4_W = 64*4,
parameter BANK8_W = 64*8,
parameter BANK16_W = 64*16,
parameter ADDER_W  =16*3
)
(
    input [3:0]i_stage,
    input i_rst_n,
    input [16*16*2 - 1: 0] i_computed_data,
//    input [ADDER_W - 1:0 ] i_adder_data,
    output reg [BANK16_W - 1: 0] o_wr_data_mem0,
    output reg [BANK8_W - 1: 0] o_wr_data_mem1,
    output reg [BANK8_W - 1: 0] o_wr_data_mem2,
    output reg [BANK8_W - 1: 0] o_wr_data_mem3,
    output reg [BANK8_W - 1: 0] o_wr_data_mem4,
    output reg [BANK8_W - 1: 0] o_wr_data_mem5
//    output reg [ADDER_W - 1: 0] o_wr_data_mem_stega
    );
    localparam HEAD = 1, DOWNS1 = 2, DOWNS2 = 3, DOWNS3 = 4, BOTT = 5,
           UPS1 = 6, UPS2 = 7, UPS3 = 8, UPS4 = 9, TAIL = 10, 
           DONE = 11, STREAM_OUT = 12;
           
    always @(*) begin
        o_wr_data_mem0      = 0; 
        o_wr_data_mem1      = 0;  
        o_wr_data_mem2      = 0;  
        o_wr_data_mem3      = 0;  
        o_wr_data_mem4      = 0;  
        o_wr_data_mem5      = 0;  
//        o_wr_data_mem_stega = 0;

        case(i_stage) 
            HEAD: begin
                o_wr_data_mem0 = {4{i_computed_data[255:0]}};
            end
            DOWNS1: begin
                o_wr_data_mem1 = i_computed_data;
            end
            DOWNS2: begin
                o_wr_data_mem2 = i_computed_data;
            end
            DOWNS3: begin
                o_wr_data_mem3 = i_computed_data;
            end
            BOTT: begin
                o_wr_data_mem4 = i_computed_data;
            end
            UPS1: begin
                o_wr_data_mem5 = {2{i_computed_data[255:0]}};
            end
            UPS2: begin
                o_wr_data_mem3 = {2{i_computed_data[255:0]}};
            end
            UPS3: begin
                o_wr_data_mem2 = {2{i_computed_data[255:0]}};
            end
            UPS4: begin
                o_wr_data_mem1 = {2{i_computed_data[255:0]}};
                o_wr_data_mem3 = {2{i_computed_data[255:0]}};
            end
            TAIL: begin
                o_wr_data_mem2 = {256'b0, {4{i_computed_data[63:0]}}};
            end
//            DONE: begin
//                o_wr_data_mem_stega = i_adder_data;
//            end
            default: begin
                o_wr_data_mem0      = 0; 
                o_wr_data_mem1      = 0;  
                o_wr_data_mem2      = 0;  
                o_wr_data_mem3      = 0;  
                o_wr_data_mem4      = 0;  
                o_wr_data_mem5      = 0;  
//                o_wr_data_mem_stega = 0;
            end
        endcase
    
    end
endmodule
