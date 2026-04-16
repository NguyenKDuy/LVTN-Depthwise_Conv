`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 08:18:23 PM
// Design Name: 
// Module Name: Depthwise_Top
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



module Depthwise_Core_Top (
    input clk, 
    input rst_n,
//    input i_en,
    
    input i_weight_valid,         // Bật trong 8 chu kỳ để nạp đủ 32CH
    input [575:0] i_weight_data,  // 4 CH * 9 W * 16 bits = 576 bits
    
    input i_data_valid,           // Khối trước sẽ tắt cái này khi đang nạp weight
    input [2303:0] i_all_windows, // 16 CH * 9 P * 16 bits
    
    output [255:0] o_data,
    output o_data_valid
);

    // 1. Hệ thống lưu trữ Weight 16 Channel
    reg [15:0] weight_regs [0:15][0:8];
    
    // Bộ đếm để biết đang nạp cho nhóm 4 channel nào (0, 1, 2, 3)
    reg [1:0] weight_group_cnt;
    integer c, w;
// --- KHỐI 1: Quản lý bộ đếm (Có Reset) ---
    always @(posedge clk) begin
        if (!rst_n) begin
            weight_group_cnt <= 2'b0;
        end else if (rst_n) begin
            if (i_weight_valid) begin
                weight_group_cnt <= weight_group_cnt + 1;
            end else begin
                weight_group_cnt <= 2'b0; // Reset bộ đếm khi tắt valid
            end
        end
    end

    // --- KHỐI 2: Mảng lưu dữ liệu (KHÔNG Reset để tránh Warning và Fan-out) ---
    always @(posedge clk) begin
        if (i_weight_valid) begin
            for (c = 0; c < 4; c = c + 1) begin
                for (w = 0; w < 9; w = w + 1) begin
                    weight_regs[{weight_group_cnt, c[1:0]}][w] <= i_weight_data[(c*16 + w*64) +: 16];
                end
            end
        end
    end

//     2. Pipeline Valid (Chỉ cho phép chạy khi i_data_valid lên)
    reg [7:0] v_pipe; 

    
    always @(posedge clk) begin
        if (!rst_n) begin
            v_pipe <= 8'b0;
        end else begin
            v_pipe <= {v_pipe[6:0], i_data_valid};
        end
    end
    
    assign o_data_valid = v_pipe[7];

//    reg [5:0] v_pipe; 

    
//    always @(posedge clk) begin
//        if (!rst_n) begin
//            v_pipe <= 6'b0;
//        end else begin
//            v_pipe <= {v_pipe[4:0], i_data_valid};
//        end
//    end
    
//    assign o_data_valid = v_pipe[5];
    // 3. Khởi tạo 16 bộ MAC (Giữ nguyên phần nối dây p0-p8 và w0-w8 như trước)
    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : GEN_CH
            wire [35:0] mac_out;
            MAC_9DSP mac_inst (
                .clk(clk),
                .ce_mac_pw(i_data_valid),
                .ce_mac_p(v_pipe[0]),
                .ce_mac_pr(v_pipe[1]),                
                .ce_mac_s1(v_pipe[2]),                
                .ce_mac_s2(v_pipe[3]),
                .ce_mac_s(v_pipe[4]),
                
//                .push_weight(i_weight_valid),
                .p0(i_all_windows[(gi*144 + 0*16) +: 16]), .p1(i_all_windows[(gi*144 + 1*16) +: 16]),
                .p2(i_all_windows[(gi*144 + 2*16) +: 16]), .p3(i_all_windows[(gi*144 + 3*16) +: 16]),
                .p4(i_all_windows[(gi*144 + 4*16) +: 16]), .p5(i_all_windows[(gi*144 + 5*16) +: 16]),
                .p6(i_all_windows[(gi*144 + 6*16) +: 16]), .p7(i_all_windows[(gi*144 + 7*16) +: 16]),
                .p8(i_all_windows[(gi*144 + 8*16) +: 16]),
                
                .w0(weight_regs[gi][0]), .w1(weight_regs[gi][1]), .w2(weight_regs[gi][2]),
                .w3(weight_regs[gi][3]), .w4(weight_regs[gi][4]), .w5(weight_regs[gi][5]),
                .w6(weight_regs[gi][6]), .w7(weight_regs[gi][7]), .w8(weight_regs[gi][8]),
                .out_sum(mac_out)
            );
            Post_Processor post_inst (.clk(clk),
                                      .ce_round(v_pipe[5]),
                                      .ce_sat(v_pipe[6]),
                                      .data_in(mac_out),
                                      .data_out(o_data[(gi*16) +: 16]));
        end
    endgenerate
endmodule