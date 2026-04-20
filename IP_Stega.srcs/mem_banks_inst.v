`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2026 02:13:32 PM
// Design Name: 
// Module Name: mem_banks_inst
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


`timescale 1ns / 1ps

module mem_banks_inst #(
    parameter ADDR_W    = 12,
    parameter DATA_W    = 64,
    parameter NUM_BANKS = 16,   // S? lý?ng bank tùy ch?n (4, 8, 16...)
    parameter LATENCY   = 3
)(
    input                                   i_clk,
    
    input [ADDR_W-1:0]                      i_wr_addr,
    input [(DATA_W * NUM_BANKS)-1:0]        i_wr_data_all,
    input [NUM_BANKS-1:0]                   i_wr_ena_mask,
    
    // --- Interface Ð?c ---
    input [ADDR_W-1:0]                      i_rd_addr,
    input [NUM_BANKS-1:0]                   i_rd_enb_mask,
    
    // --- Output gom l?i t? t?t c? các bank ---
    output [(DATA_W * NUM_BANKS)-1:0]       o_data_all,
    output [NUM_BANKS-1:0]                  o_data_vld_all
);

    // S? d?ng generate ð? t?o ra s? lý?ng instance theo NUM_BANKS
    genvar b;
    generate
        for (b = 0; b < NUM_BANKS; b = b + 1) begin : bank_gen
            
            wire [DATA_W-1:0] bank_wr_data;
            wire [DATA_W-1:0] bank_rd_data;
            wire              bank_vld;

            // C?t d? li?u t? bus t?ng cho t?ng bank
            assign bank_wr_data = i_wr_data_all[b*DATA_W +: DATA_W];

            // Kh?i t?o instance mem_inst
            mem_inst #(
                .ADDR_W(ADDR_W),
                .DATA_W(DATA_W),
                .LATENCY(LATENCY)
            ) u_mem_bank (
                .i_clk(i_clk),
                
                // Ghi
                .i_wr_addr(i_wr_addr),
                .i_wr_data(bank_wr_data),
                .i_wr_ena(i_wr_ena_mask[b]),
                
                // Ð?c
                .i_rd_addr(i_rd_addr),
                .i_rd_enb(i_rd_enb_mask[b]),
                
                // Output
                .o_data(bank_rd_data),
                .o_data_vld(bank_vld)
            );

            // Gom d? li?u t? t?ng bank vào bus output t?ng
            assign o_data_all[b*DATA_W +: DATA_W] = bank_rd_data;
            assign o_data_vld_all[b]              = bank_vld;

        end
    endgenerate

endmodule