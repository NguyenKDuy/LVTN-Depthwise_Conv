`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2026 03:35:23 PM
// Design Name: 
// Module Name: tb_ADDER_32b_9in
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

module tb_PIXEL_MAC_9IN();
    reg clk;
    reg reset;
    reg [15:0] p1, p2, p3, p4, p5, p6, p7, p8, p9;
    reg [15:0] w1, w2, w3, w4, w5, w6, w7, w8, w9;
    wire [35:0] final_sum;
    wire [31:0] stage0; wire [32:0] stage1; wire [33:0] stage2;

    PIXEL_MAC_9IN uut (
        .clk(clk), .reset(reset),
        .p1(p1), .p2(p2), .p3(p3), .p4(p4), .p5(p5), .p6(p6), .p7(p7), .p8(p8), .p9(p9),
        .w1(w1), .w2(w2), .w3(w3), .w4(w4), .w5(w5), .w6(w6), .w7(w7), .w8(w8), .w9(w9),
        .final_sum(final_sum), .out_stage0(stage0), .out_stage1(stage1), .out_stage2(stage2)
    );

    always #5 clk = ~clk;

    initial begin
        // Khởi tạo
        clk = 0; reset = 1;
        {p1,p2,p3,p4,p5,p6,p7,p8,p9} = 0;
        {w1,w2,w3,w4,w5,w6,w7,w8,w9} = 0;

        #30 reset = 0;

        // CASE 1: Bộ số nhỏ (1, 2, 3...) nạp tại T=30ns
        @(posedge clk);
        p1=1; p2=2; p3=3; p4=4; p5=5; p6=6; p7=7; p8=8; p9=9;
        w1=1; w2=1; w3=1; w4=1; w5=1; w6=1; w7=1; w8=1; w9=1;

        // CASE 2: Bộ số khác nạp ngay tại T=40ns (Dữ liệu liên tục)
        @(posedge clk);
        p1=10; p2=10; p3=10; p4=10; p5=10; p6=10; p7=10; p8=10; p9=10;
        w1=2;  w2=2;  w3=2;  w4=2;  w5=2;  w6=2;  w7=2;  w8=2;  w9=2;

        // CASE 3: Bộ số lớn tại T=50ns
        @(posedge clk);
        p1=500; p2=500; p3=500; p4=500; p5=500; p6=500; p7=500; p8=500; p9=500;
        w1=3;   w2=3;   w3=3;   w4=3;   w5=3;   w6=3;   w7=3;   w8=3;   w9=3;

        // Ngừng cấp, đợi dữ liệu chạy hết ống
        @(posedge clk);
        {p1,p2,p3,p4,p5,p6,p7,p8,p9} = 0;
        
        #100 $finish;
    end
endmodule