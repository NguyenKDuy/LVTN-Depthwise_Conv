`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2026 01:33:02 PM
// Design Name: 
// Module Name: mem_stega
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


module stega_mem_interface #(
    parameter ADDR_W    = 12,
    parameter DATA_W    = 64,   // Interface t?ng quát dùng 64-bit
    parameter NUM_BANKS = 3     // S? lý?ng bank b?n dùng cho Stega
)(
    input                            i_clk,
    input                            i_rst_n,

    // --- L?i vào t? Kh?i Steganography (16-bit) ---
    input [ADDR_W+1:0]               i_stega_wr_addr, // Ð?a ch? 16-bit (kèm 2 bit sub-word)
    input [16*NUM_BANKS-1:0]         i_stega_wr_data, // Data 16-bit t? Adder Tree/Stega
    input [NUM_BANKS-1:0]            i_stega_wr_en,   // L?nh ghi t? Stega
    
    // --- L?i ra k?t n?i vào Interface T?ng Quát (64-bit) ---
    output reg [ADDR_W-1:0]          o_gen_wr_addr,
    output reg [DATA_W*NUM_BANKS-1:0]o_gen_wr_data,
    output reg [NUM_BANKS-1:0]       o_gen_wr_en
);

    // Buffer tích l?y cho t?ng Bank (Tái s? d?ng logic c? nhýng không khai báo RAM ? ðây)
    reg [63:0] wr_buffer [0:NUM_BANKS-1];
    integer b;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_gen_wr_en   <= 0;
            o_gen_wr_addr <= 0;
            o_gen_wr_data <= 0;
            for (b = 0; b < NUM_BANKS; b = b + 1) wr_buffer[b] <= 0;
        end else begin
            o_gen_wr_en <= 0; // M?c ð?nh không ghi vào Mem t?ng
            
            for (b = 0; b < NUM_BANKS; b = b + 1) begin
                if (i_stega_wr_en[b]) begin
                    case (i_stega_wr_addr[1:0])
                        2'b00: wr_buffer[b][15:0]  <= i_stega_wr_data[16*b +: 16];
                        2'b01: wr_buffer[b][31:16] <= i_stega_wr_data[16*b +: 16];
                        2'b10: wr_buffer[b][47:32] <= i_stega_wr_data[16*b +: 16];
                        2'b11: begin 
                            wr_buffer[b][63:48] <= i_stega_wr_data[16*b +: 16];
                            
                            // Khi ð? 4 m?nh, xu?t l?nh ghi ra Interface t?ng
                            o_gen_wr_en[b]     <= 1'b1;
                            o_gen_wr_addr      <= i_stega_wr_addr[ADDR_W+1:2];
                            
                            // C?p nh?t d? li?u vào Bus 64-bit týõng ?ng c?a Bank ðó
                            // Lýu ?: Ch? c?p nh?t bank b, các bank khác gi? nguyên data c? trong buffer
                            o_gen_wr_data[DATA_W*b +: DATA_W] <= {i_stega_wr_data[16*b +: 16], wr_buffer[b][47:0]};
                        end
                    endcase
                end
            end
        end
    end

endmodule


module mux_mem1 
#(
parameter ADDR = 12
)
(
    input [3:0]         i_stage,
    input [7:0]         i_wr_stega_ena,
    input [ADDR - 1:0]  i_wr_stega_addr,
    input [64*3 - 1:0]  i_wr_stega_data,
    input [7:0]         i_wr_mem_ena,
    input [ADDR - 1:0]  i_wr_mem_addr,
    input [64*8 - 1:0]  i_wr_mem_data,
    output reg [64*8 - 1:0] o_wr_mem_mux_data,
    output reg [ADDR - 1:0] o_wr_mem_mux_addr,
    output reg [7:0]        o_wr_mem_mux_ena
);
    localparam DONE = 11;
    
    always @(*) begin
        if (i_stage == DONE) begin
            o_wr_mem_mux_data = {320'b0,i_wr_stega_data};
            o_wr_mem_mux_addr = i_wr_stega_addr;
            o_wr_mem_mux_ena  = {5'b0,i_wr_stega_ena};
        end 
        else begin
            o_wr_mem_mux_data = {i_wr_mem_data};
            o_wr_mem_mux_addr = i_wr_mem_addr;
            o_wr_mem_mux_ena  = i_wr_mem_ena;
        end  
    end
    
    
    
endmodule