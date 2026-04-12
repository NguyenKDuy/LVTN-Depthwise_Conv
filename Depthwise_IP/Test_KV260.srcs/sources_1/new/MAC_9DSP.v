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
    input ce_mac_p, ce_mac_s1, ce_mac_s2, ce_mac_s, ce_mac_pw, ce_mac_pr, // Tín hiệu Clock Enable từ i_data_valid
    input signed [15:0] p0, p1, p2, p3, p4, p5, p6, p7, p8,
    input signed [15:0] w0, w1, w2, w3, w4, w5, w6, w7, w8, 
    output reg signed [35:0] out_sum
);



    // Tầng NHÂN (144 DSP nằm ở đây)
    (* use_dsp = "yes" *) reg signed [31:0] prod [0:8];
    
    // Tầng CỘNG dùng LUT
    (* use_dsp = "no" *) reg signed [32:0] s1_0, s1_1, s1_2, s1_3;
    (* use_dsp = "no" *) reg signed [33:0] s2_0, s2_1;
    
    reg signed [15:0] p_in [0:8];
    reg signed [15:0] w_in [0:8];   

    reg signed [33:0] prod8_d1, prod8_d2;

    reg signed [31:0] p_reg [0:8];


  // --- PIPELINE STAGE 0: INPUT REGISTER ---
    always @(posedge clk) begin
        if (ce_mac_pw) begin 
            p_in[0] <= p0; w_in[0] <= w0;
            p_in[1] <= p1; w_in[1] <= w1;
            p_in[2] <= p2; w_in[2] <= w2;
            p_in[3] <= p3; w_in[3] <= w3;
            p_in[4] <= p4; w_in[4] <= w4;
            p_in[5] <= p5; w_in[5] <= w5;
            p_in[6] <= p6; w_in[6] <= w6;
            p_in[7] <= p7; w_in[7] <= w7;
            p_in[8] <= p8; w_in[8] <= w8;
        end
    end
    

    // --- PIPELINE STAGE 1: MULTIPLICATION ---
    always @(posedge clk) begin
        if (ce_mac_p) begin
            // Thay p0*w0 thành p_in[0]*w_in[0]
            prod[0] <= p_in[0] * w_in[0];
            prod[1] <= p_in[1] * w_in[1];
            prod[2] <= p_in[2] * w_in[2];
            prod[3] <= p_in[3] * w_in[3];
            prod[4] <= p_in[4] * w_in[4];
            prod[5] <= p_in[5] * w_in[5];
            prod[6] <= p_in[6] * w_in[6];
            prod[7] <= p_in[7] * w_in[7];
            prod[8] <= p_in[8] * w_in[8];
        end
    end

    // --- PIPELINE STAGE 2: use reg_DSP to pipeline ---
      always @(posedge clk) begin
        if (ce_mac_pr) begin
            p_reg[0] <= prod[0];
            p_reg[1] <= prod[1];
            p_reg[2] <= prod[2]; 
            p_reg[3] <= prod[3];
            p_reg[4] <= prod[4]; 
            p_reg[5] <= prod[5];
            p_reg[6] <= prod[6]; 
            p_reg[7] <= prod[7]; 
            p_reg[8] <= prod[8];
        end
    end
    
    // --- PIPELINE STAGE 3: adder tree level1 - partial sum1 ---
    always @(posedge clk) begin
        if (ce_mac_s1) begin
//             Nhịp 2: Cộng cặp lần 1 
            s1_0 <= p_reg[0] + p_reg[1];
            s1_1 <= p_reg[2] + p_reg[3];
            s1_2 <= p_reg[4] + p_reg[5];
            s1_3 <= p_reg[6] + p_reg[7];
            prod8_d1 <= p_reg[8];
        end
    end    
        

    // --- PIPELINE STAGE 4: adder tree level2 - partial sum2 ---
    always @(posedge clk) begin
        if (ce_mac_s2) begin
            s2_0 <= s1_0 + s1_1;
            s2_1 <= s1_2 + s1_3;
            prod8_d2 <= prod8_d1;
        end
    end


    // --- PIPELINE STAGE 5: Total_sum ---
    always @(posedge clk) begin
        if (ce_mac_s) begin 
            // Nhịp 4: Tổng cuối
            out_sum <= s2_0 + s2_1 + prod8_d2;
        end
    end

endmodule