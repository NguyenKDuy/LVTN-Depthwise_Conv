`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2026 04:11:15 PM
// Design Name: 
// Module Name: depth_mem
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




module depth_mem #(
    parameter ADDR_W    = 8,
    parameter DATA_W    = 64,
    parameter NUM_BANKS = 9, 
    parameter LATENCY   = 2   
)(
    input                                   i_clk,
    
    // --- Giao di?n Ghi ---
    input  [ADDR_W-1:0]                     i_wr_addr,
    input  [DATA_W-1:0]                     i_wr_data,      // CH? C?N 64-BIT DÙNG CHUNG
    input  [NUM_BANKS-1:0]                  i_wr_ena_mask,  // Quy?t ð?nh d? li?u 64-bit trên vào bank nào
    
    // --- Giao di?n Ð?c t?ng h?p ---
    input  [ADDR_W-1:0]                     i_rd_addr,
    input                                   i_rd_enb,
    
    // --- D? li?u ra (V?n gi? bus l?n ð? ð?c song song cho tính toán) ---
    output [(DATA_W * NUM_BANKS)-1:0]       o_data_all,
    output                                  o_data_vld_all
);

    genvar i;
    generate
        for (i = 0; i < NUM_BANKS; i = i + 1) begin : gen_depth_banks
            
            wire [DATA_W-1:0] w_bank_rd_data;
            wire              w_bank_vld;

            // Kh?i t?o instance point_inst
            depth_inst #(
                .ADDR_W(ADDR_W),
                .DATA_W(DATA_W),
                .LATENCY(LATENCY)
            ) u_depth_core (
                .i_clk      (i_clk),
                
                // Ghi: T?t c? các bank cùng n?i vào i_wr_data, 
                // nhýng ch? bank nào có mask = 1 m?i th?c hi?n ghi.
                .i_wr_addr  (i_wr_addr),
                .i_wr_data  (i_wr_data),      
                .i_wr_ena   (i_wr_ena_mask[i]),
                
                // Ð?c
                .i_rd_addr  (i_rd_addr),
                .i_rd_enb   (i_rd_enb),
                
                // Ð?u ra
                .o_data     (w_bank_rd_data),
                .o_data_vld (o_data_vld_all)
            );

            // Gom d? li?u ra thành bus l?n ð? b? Compute ð?c 1 lúc 16 bank
            assign o_data_all[i*DATA_W +: DATA_W] = w_bank_rd_data;

        end
    endgenerate

endmodule