`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2026 02:22:26 PM
// Design Name: 
// Module Name: mem_inst
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


module mem_inst #(
    parameter ADDR_W = 12,
    parameter DATA_W = 64,
    parameter LATENCY = 3  // Tùy ch?nh Latency (Nên >= 2 ð? t?i ýu URAM)
)(
    input                       i_clk,
    
    // --- Giao di?n Ghi (384 bit) ---
    input [ADDR_W-1:0]      i_wr_addr,
    input [(DATA_W)-1:0]    i_wr_data,
    input                   i_wr_ena,
    // --- Giao di?n Ð?c (96 bit) ---
    input  [ADDR_W-1:0]     i_rd_addr,
    input                   i_rd_enb, 
    
    output reg [DATA_W - 1:0]   o_data,
    output reg              o_data_vld 
);

(* ram_style = "ultra" *)reg [DATA_W-1:0] ram [0:(2**ADDR_W)-1];
reg [DATA_W-1:0] raw_dout_pipe [0:LATENCY-1];
reg  ena_pipes [0: LATENCY-1];
    
    always @(posedge i_clk) begin
        if (i_wr_ena) begin
            ram[i_wr_addr] <= i_wr_data;
        end
    end
    
    always @(posedge i_clk) begin
        ena_pipes[0] <= i_rd_enb;
//        if (i_rd_enb) begin
        raw_dout_pipe[0] <= ram[i_rd_addr];
//        end
    end
    integer stage;
    always @(posedge i_clk) begin
        for (stage = 1; stage < LATENCY; stage = stage + 1) begin
            ena_pipes[stage] <= ena_pipes[stage-1];
//            if (ena_pipes[stage-1]) begin
            raw_dout_pipe[stage] <= raw_dout_pipe[stage-1];
//            end
        end
    end

    always @(*) begin
        o_data_vld = ena_pipes[LATENCY - 1];
        o_data = raw_dout_pipe[LATENCY-1];
    end
endmodule
