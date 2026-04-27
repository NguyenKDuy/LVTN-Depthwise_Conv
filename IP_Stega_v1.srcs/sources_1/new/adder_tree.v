`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2026 04:55:39 PM
// Design Name: 
// Module Name: adder_tree
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


module adder_tree #(
    parameter WIDTH = 16,
    parameter NUM_CH = 3
)(
    input                      i_clk,
    input                      i_rst_n,
    input                      i_rst_adder_done,
    input                      i_vld,    // Tín hi?u báo d? li?u ð?u vào h?p l?
    input [WIDTH*NUM_CH-1:0]   i_data_a, 
    input [WIDTH*NUM_CH-1:0]   i_data_b,
    
    output reg [47:0]          o_sum,
    output reg                 o_vld,     // Kh?p chính xác v?i d? li?u sau Pipeline
    output reg                 o_adder_done
);

    // H?ng s? Saturation
    localparam [15:0] POS_MAX = 16'h7FFF; 
    localparam [15:0] NEG_MIN = 16'h8000; 

    // --- Pipeline Stage 1 ---
    reg signed [WIDTH:0] sum_raw [0:NUM_CH-1];
    reg                  vld_s1;

    integer i;
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            vld_s1 <= 1'b0;
            for (i = 0; i < NUM_CH; i = i + 1) sum_raw[i] <= 0;
        end else begin
            vld_s1 <= i_vld; // D?ch chuy?n tín hi?u valid
            
            // Ch? th?c hi?n tính toán khi i_vld = 1 ð? ti?t ki?m nãng lý?ng (Dynamic Power)
            if (i_vld) begin
                for (i = 0; i < NUM_CH; i = i + 1) begin
                    sum_raw[i] <= $signed(i_data_a[WIDTH*i +: WIDTH]) + 
                                  $signed(i_data_b[WIDTH*i +: WIDTH]);
                end
            end
        end
    end

    // --- Pipeline Stage 2 ---
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_vld <= 1'b0;
            o_sum <= 0;
        end else begin
            o_vld <= vld_s1; // o_vld tr? ðúng 2 cycle so v?i i_vld
            
            if (vld_s1) begin
                for (i = 0; i < NUM_CH; i = i + 1) begin
                    // Logic Saturation (ki?m tra bit d?u th?c bit 16 vs bit 15)
                    if (sum_raw[i][16] != sum_raw[i][15]) begin
                        o_sum[WIDTH*i +: WIDTH] <= (sum_raw[i][16] == 1'b0) ? POS_MAX : NEG_MIN;
                    end else begin
                        o_sum[WIDTH*i +: WIDTH] <= sum_raw[i][15:0];
                    end
                end
            end
        end
    end
    
    reg [13:0] counter;
    
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter <=0;
            o_adder_done <= 0;
        end
        else if (i_rst_adder_done) begin
            counter <=0;
            o_adder_done <= 0;
        end
        else if (o_vld) begin
            counter <= counter + 1;
            if (counter == 4096) begin
                o_adder_done <= 1;
            end
        end
    end
    

endmodule