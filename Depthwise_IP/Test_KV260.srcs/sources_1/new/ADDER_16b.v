`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2026 03:31:16 PM
// Design Name: 
// Module Name: ADDER_16b
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


module PIXEL_MAC_9IN (
    input clk,
    input reset,
    input [15:0] p1, p2, p3, p4, p5, p6, p7, p8, p9,
    input [15:0] w1, w2, w3, w4, w5, w6, w7, w8, w9,
    output reg [35:0] final_sum,
    
    // Các cổng thêm vào để quan sát (có thể xóa khi nạp chip thật)
    output [31:0] out_stage0, // Xem kết quả sau khi nhân
    output [32:0] out_stage1, // Xem kết quả cộng tầng 1
    output [33:0] out_stage2  // Xem kết quả cộng tầng 2
);

    // --- Tầng 0: Nhân ---
    reg [31:0] m [1:9];
    always @(posedge clk) begin
        if (reset) begin
            m[1]<=0; m[2]<=0; m[3]<=0; m[4]<=0; m[5]<=0; m[6]<=0; m[7]<=0; m[8]<=0; m[9]<=0;
        end else begin
            m[1] <= p1 * w1; m[2] <= p2 * w2; m[3] <= p3 * w3;
            m[4] <= p4 * w4; m[5] <= p5 * w5; m[6] <= p6 * w6;
            m[7] <= p7 * w7; m[8] <= p8 * w8; m[9] <= p9 * w9;
        end
    end
    assign out_stage0 = m[1]; // Quan sát thử tích của cặp số 1
    
    // --- Tầng 1: Cộng cặp ---
    reg [32:0] s1_1, s1_2, s1_3, s1_4, s1_5;
    always @(posedge clk) begin
        s1_1 <= m[1] + m[2];
        s1_2 <= m[3] + m[4];
        s1_3 <= m[5] + m[6];
        s1_4 <= m[7] + m[8];
        s1_5 <= m[9];
    end
    assign out_stage1 = s1_1; // Quan sát tổng cặp đầu tiên

    // --- Tầng 2: Cộng tiếp ---
    reg [33:0] s2_1, s2_2, s2_3;
    always @(posedge clk) begin
        s2_1 <= s1_1 + s1_2;
        s2_2 <= s1_3 + s1_4;
        s2_3 <= s1_5;
    end
    assign out_stage2 = s2_1; // Quan sát tổng 4 số đầu

    // --- Tầng 3: Kết quả cuối ---
    always @(posedge clk) begin
        final_sum <= (s2_1 + s2_2) + s2_3;
    end

endmodule