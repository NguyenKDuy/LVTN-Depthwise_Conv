`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 08:16:07 PM
// Design Name: 
// Module Name: MAC_9DSP
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



module MAC_9DSP (
    input clk,
    input ce_mac_p, ce_mac_s1, ce_mac_s2, ce_mac_s, // Tín hiệu Clock Enable từ i_data_valid
    input signed [15:0] p0, p1, p2, p3, p4, p5, p6, p7, p8,
    input signed [15:0] w0, w1, w2, w3, w4, w5, w6, w7, w8, 
    output reg signed [35:0] out_sum
);

    // Tầng 1: NHÂN (144 DSP nằm ở đây)
    (* use_dsp = "yes" *) reg signed [31:0] prod [0:8];
    
    // Tầng 2 & 3: CỘNG (Ép dùng LUT)
    (* use_dsp = "no" *) reg signed [32:0] s1_0, s1_1, s1_2, s1_3;
    (* use_dsp = "no" *) reg signed [33:0] s2_0, s2_1;
    
    // Thanh ghi delay để cân bằng Pipeline cho prod[8]
    reg signed [33:0] prod8_d1, prod8_d2;

    // --- PIPELINE STAGE 1: MULTIPLICATION ---
    always @(posedge clk) begin
        if (ce_mac_p) begin
            prod[0] <= p0 * w0;
            prod[1] <= p1 * w1;
            prod[2] <= p2 * w2;
            prod[3] <= p3 * w3;
            prod[4] <= p4 * w4;
            prod[5] <= p5 * w5;
            prod[6] <= p6 * w6;
            prod[7] <= p7 * w7;
            prod[8] <= p8 * w8;
        end
    end

//     --- PIPELINE STAGE 2, 3, 4: ADDER TREE ---
    always @(posedge clk) begin
        if (ce_mac_s1) begin
//             Nhịp 2: Cộng cặp lần 1 
            s1_0 <= prod[0] + prod[1];
            s1_1 <= prod[2] + prod[3];
            s1_2 <= prod[4] + prod[5];
            s1_3 <= prod[6] + prod[7];
            prod8_d1 <= prod[8];
        end
    end    
        

            // Nhịp 3: Cộng cặp lần 2
    always @(posedge clk) begin
        if (ce_mac_s2) begin
            s2_0 <= s1_0 + s1_1;
            s2_1 <= s1_2 + s1_3;
            prod8_d2 <= prod8_d1;
        end
    end

    always @(posedge clk) begin
        if (ce_mac_s) begin 
            // Nhịp 4: Tổng cuối
            out_sum <= s2_0 + s2_1 + prod8_d2;
        end
    end

endmodule