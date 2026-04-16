`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2026 03:24:55 PM
// Design Name: 
// Module Name: rd_select
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


module rd_select #(
    parameter ADDRESS_DATA = 12
)(
    input [3:0]                i_stage,
    input [1:0]                i_mem_rd_swapping,
    input [ADDRESS_DATA+1:0]   i_mem_rd_addr,
    input                      i_mem_rd_enb,
    input [3:0]                i_lic,
    input [7:0]                i_row,
    input [7:0]                i_col,

    output reg [ADDRESS_DATA+1:0] o_mem_img_addr,
    output reg [ADDRESS_DATA-1:0] o_mem0_addr,
    output reg [ADDRESS_DATA-1:0] o_mem1_addr,
    output reg [ADDRESS_DATA-1:0] o_mem2_addr,
    output reg [ADDRESS_DATA-1:0] o_mem3_addr,
    output reg [ADDRESS_DATA-1:0] o_mem4_addr,
    output reg [ADDRESS_DATA-1:0] o_mem5_addr,
//    output reg [ADDRESS_DATA-1:0] o_mem_stega_addr,

    output reg [5:0]  o_mem_img_enb,
    output reg [15:0] o_mem0_enb, // S?a l?i 16-bit cho kh?p HEAD/DOWNS1
    output reg [7:0]  o_mem1_enb,
    output reg [7:0]  o_mem2_enb,
    output reg [7:0]  o_mem3_enb,
    output reg [7:0]  o_mem4_enb,
    output reg [7:0]  o_mem5_enb
//    output reg [2:0]  o_mem_stega_enb
);

// --- Stage Parameters ---
localparam HEAD = 1, DOWNS1 = 2, DOWNS2 = 3, DOWNS3 = 4, BOTT = 5,
           UPS1 = 6, UPS2 = 7, UPS3 = 8, UPS4 = 9, TAIL = 10, 
           DONE = 11, STREAM_OUT = 12;

wire [ADDRESS_DATA-1:0] common_addr = i_mem_rd_addr[ADDRESS_DATA-1:0];

always @(*) begin
    // 1. Reset all Enables (S?ch s?, tránh Latch)
    o_mem_img_enb = 0; o_mem0_enb = 0; o_mem1_enb = 0; 
    o_mem2_enb = 0;    o_mem3_enb = 0; o_mem4_enb = 0; 
    o_mem5_enb = 0;    
//    o_mem_stega_enb = 0;

    // 2. Default Addresses (Gi? nguyên i_mem_rd_addr ð? gi?m Mux logic)
    o_mem_img_addr   = i_mem_rd_addr;
    o_mem0_addr      = common_addr;
    o_mem1_addr      = common_addr;
    o_mem2_addr      = common_addr;
    o_mem3_addr      = common_addr;
    o_mem4_addr      = common_addr;
    o_mem5_addr      = common_addr;
//    o_mem_stega_addr = common_addr;

    case (i_stage)
        HEAD: begin
            o_mem_img_enb = {6{i_mem_rd_enb}};
        end

        DOWNS1: begin
            o_mem0_enb = (16'h000F << (i_mem_rd_swapping[1:0] * 4)) & {16{i_mem_rd_enb}};
        end

        DOWNS2: begin
            o_mem1_enb = (8'h0F << (i_mem_rd_swapping[0] * 4)) & {8{i_mem_rd_enb}};
        end

        DOWNS3: begin
            o_mem2_enb = (8'h0F << (i_mem_rd_swapping[0] * 4)) & {8{i_mem_rd_enb}};
        end

        BOTT: begin
            o_mem3_enb = (8'h0F << (i_mem_rd_swapping[0] * 4)) & {8{i_mem_rd_enb}};
        end

        UPS1: begin
            if (i_mem_rd_swapping == 0) begin
                o_mem4_enb  = {8{i_mem_rd_enb}};
                o_mem4_addr = {6'b0, i_lic[3:0], i_row[3:1], i_col[3:1]};
            end else begin
                o_mem3_enb  = {8{i_mem_rd_enb}};
            end
        end

        UPS2: begin
            if (i_mem_rd_swapping == 0) begin
                o_mem5_enb  = {8{i_mem_rd_enb}};
                o_mem5_addr = {4'b0, i_lic[3:0], i_row[4:1], i_col[4:1]};
            end else begin
                o_mem2_enb  = {8{i_mem_rd_enb}};
            end
        end

        UPS3: begin
            if (i_mem_rd_swapping == 0) begin
                o_mem3_enb  = {8{i_mem_rd_enb}};
                o_mem3_addr = {2'b0, i_lic[3:0], i_row[5:1], i_col[5:1]};
            end else begin
                o_mem1_enb  = {8{i_mem_rd_enb}};
            end
        end

        UPS4: begin
            // Logic ð?c bi?t: o_mem2 luôn ð?c ð? l?y Skip Connection
            o_mem2_enb  = 8'h0F & {8{i_mem_rd_enb}};
            o_mem2_addr = {i_lic[3:0], i_row[6:1], i_col[6:1]};
            o_mem0_enb  = (16'h000F << (i_mem_rd_swapping[1:0] * 4)) & {16{i_mem_rd_enb}};
        end

        TAIL: begin
            if (i_mem_rd_swapping[1] == 0) // swapping 0,1 -> Mem1
                o_mem1_enb = (8'h0F << (i_mem_rd_swapping[0] * 4)) & {8{i_mem_rd_enb}};
            else                          // swapping 2,3 -> Mem3
                o_mem3_enb = (8'h0F << (i_mem_rd_swapping[0] * 4)) & {8{i_mem_rd_enb}};
        end

        DONE: begin
            o_mem_img_enb = 6'h07 & {6{i_mem_rd_enb}};          // 3 channel
            o_mem2_enb    = (8'h01 << i_mem_rd_swapping[1:0]) & {8{i_mem_rd_enb}};
            //1 bo nho cho 4 channel
        end

        STREAM_OUT: begin
            o_mem1_enb = (3'h1 << i_mem_rd_swapping[1:0]) & {3{i_mem_rd_enb}};
        end
        default: begin 
            o_mem_img_enb = 0; o_mem0_enb = 0; o_mem1_enb = 0;      
            o_mem2_enb = 0;    o_mem3_enb = 0; o_mem4_enb = 0;      
            o_mem5_enb = 0;    
//            o_mem_stega_enb = 0;                 
        end
    endcase
end

endmodule