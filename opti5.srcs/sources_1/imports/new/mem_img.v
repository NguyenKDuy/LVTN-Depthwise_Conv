`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2026 12:16:36 PM
// Design Name: 
// Module Name: mem_img
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



module mem_img #(
    parameter ADDR_W = 12,
    parameter ADDR_R = 14,
    parameter DATA_W = 64,
    parameter NUM_BANKS = 6,
    parameter SUB_W = 16,
    parameter LATENCY = 3  // Tùy ch?nh Latency (Nên >= 2 ð? t?i ýu URAM)
)(
    input                       i_clk,
    
    // --- Giao di?n Ghi (384 bit) ---
    input [ADDR_W-1:0]              i_wr_addr,
    input [(DATA_W*NUM_BANKS)-1:0]  i_wr_data_all,
    input [NUM_BANKS-1:0]           i_wr_en_mask,
    
    // --- Giao di?n Ð?c (96 bit) ---
    input  [ADDR_R-1:0]              i_rd_addr,
    input  [NUM_BANKS-1:0]           i_rd_enb, 
    
    output [(SUB_W*NUM_BANKS)-1:0]  o_data_all,
    output [NUM_BANKS-1:0]          o_data_vld 
);
        // Các t?ng Pipeline cho d? li?u thô (64-bit)
    reg [DATA_W-1:0] raw_dout_pipe [0:NUM_BANKS-1][0:LATENCY-1];
    reg  ena_pipes [0: NUM_BANKS - 1][0: LATENCY-1];
    wire [ADDR_R - 3: 0] rd_addr =  i_rd_addr[ADDR_R-1:2];
    wire [1:0] sub_rd_addr =  i_rd_addr[1:0];
    reg [1:0] sub_addr_pipe [0:NUM_BANKS-1][0:LATENCY-1];
    // M?ng nh? 6 bank riêng bi?t ð? Synthesis ra 6 con URAM v?t l?
    (* ram_style = "ultra" *)reg [DATA_W-1:0] bank0 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *)reg [DATA_W-1:0] bank1 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *)reg [DATA_W-1:0] bank2 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *)reg [DATA_W-1:0] bank3 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *)reg [DATA_W-1:0] bank4 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *)reg [DATA_W-1:0] bank5 [0:(2**ADDR_W)-1];


    // --- Logic Ghi (Write) ---
    always @(posedge i_clk) begin
        if (i_wr_en_mask[0]) bank0[i_wr_addr] <= i_wr_data_all[0*DATA_W +: DATA_W];
        if (i_wr_en_mask[1]) bank1[i_wr_addr] <= i_wr_data_all[1*DATA_W +: DATA_W];
        if (i_wr_en_mask[2]) bank2[i_wr_addr] <= i_wr_data_all[2*DATA_W +: DATA_W];
        if (i_wr_en_mask[3]) bank3[i_wr_addr] <= i_wr_data_all[3*DATA_W +: DATA_W];
        if (i_wr_en_mask[4]) bank4[i_wr_addr] <= i_wr_data_all[4*DATA_W +: DATA_W];
        if (i_wr_en_mask[5]) bank5[i_wr_addr] <= i_wr_data_all[5*DATA_W +: DATA_W];
    end

    // --- Logic Ð?c & Pipeline (Read) ---
    integer b, stage;
    always @(posedge i_clk) begin
        // Stage 0: Ð?c tr?c ti?p t? Memory Array
        for (b = 0; b < NUM_BANKS; b = b + 1) begin
            ena_pipes[b][0] <= i_rd_enb[b];
        end
//        if (i_rd_enb[0]) begin 
            raw_dout_pipe[0][0] <= bank0[rd_addr];
            sub_addr_pipe[0][0] <= sub_rd_addr;
//        end  
//        if (i_rd_enb[1]) begin 
            raw_dout_pipe[1][0] <= bank1[rd_addr];
            sub_addr_pipe[1][0] <= sub_rd_addr;
//        end 
//        if (i_rd_enb[2]) begin 
            raw_dout_pipe[2][0] <= bank2[rd_addr];
            sub_addr_pipe[2][0] <= sub_rd_addr;
//        end         
//        if (i_rd_enb[3]) begin 
            raw_dout_pipe[3][0] <= bank3[rd_addr];
            sub_addr_pipe[3][0] <= sub_rd_addr;
//        end
//        if (i_rd_enb[4]) begin 
            raw_dout_pipe[4][0] <= bank4[rd_addr];
            sub_addr_pipe[4][0] <= sub_rd_addr;
//        end
//        if (i_rd_enb[5]) begin 
            raw_dout_pipe[5][0] <= bank5[rd_addr];
            sub_addr_pipe[5][0] <= sub_rd_addr;
//        end
    end
    
    always @(posedge i_clk) begin
        // Các t?ng Pipeline ti?p theo (N?u LATENCY > 1)
        for (stage = 1; stage < LATENCY; stage = stage + 1) begin
            for (b = 0; b < NUM_BANKS; b = b + 1) begin
                ena_pipes[b][stage] <= ena_pipes[b][stage-1];
//                if (ena_pipes[b][stage-1]) begin
                    raw_dout_pipe[b][stage] <= raw_dout_pipe[b][stage-1];
                    sub_addr_pipe[b][stage] <= sub_addr_pipe[b][stage-1];
                    
//                end
            end
        end
    end

    // --- Output Mapping (D?a trên t?ng Pipeline cu?i cùng) ---
    genvar k;
    generate
        for (k = 0; k < NUM_BANKS; k = k + 1) begin : output_assign
            assign o_data_all[k*SUB_W +: SUB_W] = raw_dout_pipe[k][LATENCY-1][sub_addr_pipe[k][LATENCY-1]*16 +: 16];
            assign o_data_vld[k] = ena_pipes[k][LATENCY - 1];
        end
    endgenerate

endmodule
