`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Module: pre_process
//
// Ch?c nãng:
//   Nh?n 128-bit/cycle t? DMA theo format XRGB×4:
//     [127:96] = pix3 {X[7:0], B[7:0], G[7:0], R[7:0]}
//     [ 95:64] = pix2 {X[7:0], B[7:0], G[7:0], R[7:0]}
//     [ 63:32] = pix1 {X[7:0], B[7:0], G[7:0], R[7:0]}
//     [ 31: 0] = pix0 {X[7:0], B[7:0], G[7:0], R[7:0]}
//
//   Convert t?ng kênh uint8 ? Q6.10 (int16):
//     Công th?c t? notebook:
//       float = pixel / 255.0
//       norm  = (float - 0.5) / 0.5  = pixel/127.5 - 1.0
//       q610  = round(norm * 1024)
//            ? round(pixel * 1024 / 127.5 - 1024)
//            ? round(pixel * 8.0502) - 1024
//
//   Reorder sang layout IP_top (192-bit):
//     [191:128] = {B3,B2,B1,B0} 4×16-bit kênh Blue
//     [127: 64] = {G3,G2,G1,G0} 4×16-bit kênh Green
//     [ 63:  0] = {R3,R2,R1,R0} 4×16-bit kênh Red
//
// Interface AXI4-Stream Slave ? DMA (128-bit)
// Interface plain valid/data  ? IP_top (192-bit)
//
// Latency: 2 chu k? pipeline (reg stage + output register)
////////////////////////////////////////////////////////////////////////////////

module pre_process (
    input  wire         i_clk,
    input  wire         i_rst_n,

    // ?? AXI4-Stream Slave ? DMA ??????????????????????????????????????????
    input  wire         s_axis_tvalid,
    input  wire [127:0] s_axis_tdata,   // {pix3,pix2,pix1,pix0} XRGB×4
    // output wire         s_axis_tready,

    // ?? Output ? IP_top ??????????????????????????????????????????????????
    output reg          o_valid,
    output reg  [191:0] o_data          // {BBBB,GGGG,RRRR} 4×int16×3ch
);

    localparam [15:0] K_MULT = 'd16449;
//?????????????????????????????????????????????????????????????????????
    // STAGE 0 - Tách kênh, ðãng k? input vào DSP A/B reg
    //   Ðây là "pre-register" ð? tool có th? map vào DSP48 A1/B1 register,
    //   giúp gi?m fanout và setup time cho DSP.
    // ?????????????????????????????????????????????????????????????????????
 
    // Format: {X[31:24], B[23:16], G[15:8], R[7:0]}
    wire [7:0] r0 = s_axis_tdata[ 7: 0];
    wire [7:0] g0 = s_axis_tdata[15: 8];
    wire [7:0] b0 = s_axis_tdata[23:16];
 
    wire [7:0] r1 = s_axis_tdata[39:32];
    wire [7:0] g1 = s_axis_tdata[47:40];
    wire [7:0] b1 = s_axis_tdata[55:48];
 
    wire [7:0] r2 = s_axis_tdata[71:64];
    wire [7:0] g2 = s_axis_tdata[79:72];
    wire [7:0] b2 = s_axis_tdata[87:80];
 
    wire [7:0] r3 = s_axis_tdata[103: 96];
    wire [7:0] g3 = s_axis_tdata[111:104];
    wire [7:0] b3 = s_axis_tdata[119:112];
 
    // S0 register: capture pixel channels + valid (maps to DSP A/B pre-reg)
    reg        s0_valid;
    reg [7:0]  s0_r0, s0_g0, s0_b0;
    reg [7:0]  s0_r1, s0_g1, s0_b1;
    reg [7:0]  s0_r2, s0_g2, s0_b2;
    reg [7:0]  s0_r3, s0_g3, s0_b3;
 
    always @(posedge i_clk ) begin
        if (!i_rst_n) begin
            s0_valid <= 1'b0;
            // s0_r0 <= 8'h0; s0_g0 <= 8'h0; s0_b0 <= 8'h0;
            // s0_r1 <= 8'h0; s0_g1 <= 8'h0; s0_b1 <= 8'h0;
            // s0_r2 <= 8'h0; s0_g2 <= 8'h0; s0_b2 <= 8'h0;
            // s0_r3 <= 8'h0; s0_g3 <= 8'h0; s0_b3 <= 8'h0;
        end else begin
            s0_valid <= s_axis_tvalid;
            s0_r0 <= r0; s0_g0 <= g0; s0_b0 <= b0;
            s0_r1 <= r1; s0_g1 <= g1; s0_b1 <= b1;
            s0_r2 <= r2; s0_g2 <= g2; s0_b2 <= b2;
            s0_r3 <= r3; s0_g3 <= g3; s0_b3 <= b3;
        end
    end



    // ?????????????????????????????????????????????????????????????????????
    // STAGE 1 - Nhân trong DSP, capture vào P-register c?a DSP48
    //
    //   prod = x * 16449   (8-bit × 14-bit = 22-bit unsigned, store 23-bit)
    //
    //   Attribute (* use_dsp = "yes" *) báo Vivado ýu tiên map vào DSP48.
    //   Vivado t? ð?ng b?t DSP P-register khi timing yêu c?u.
    //
    //   H?ng K = 16449 = 0x4041. V?i DSP48E2:
    //     A = s0_x (8-bit, zero-extended lên 30-bit)
    //     B = K    (14-bit, zero-extended lên 18-bit)
    //     P = A*B  ? l?y [22:0]
    // ?????????????????????????????????????????????????????????????????????
 
    (* use_dsp = "yes" *) reg [22:0] s1_r0, s1_g0, s1_b0;
    (* use_dsp = "yes" *) reg [22:0] s1_r1, s1_g1, s1_b1;
    (* use_dsp = "yes" *) reg [22:0] s1_r2, s1_g2, s1_b2;
    (* use_dsp = "yes" *) reg [22:0] s1_r3, s1_g3, s1_b3;
    reg s1_valid;
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s1_valid <= 1'b0;
            // s1_r0 <= 23'b0; s1_g0 <= 23'b0; s1_b0 <= 23'b0;
            // s1_r1 <= 23'b0; s1_g1 <= 23'b0; s1_b1 <= 23'b0;
            // s1_r2 <= 23'b0; s1_g2 <= 23'b0; s1_b2 <= 23'b0;
            // s1_r3 <= 23'b0; s1_g3 <= 23'b0; s1_b3 <= 23'b0;
        end else begin
            s1_valid <= s0_valid;
            // DSP P-reg: k?t qu? nhân ðý?c gi? trong DSP, không route ra fabric ngay
            s1_r0 <= s0_r0 * K_MULT;  s1_g0 <= s0_g0 * K_MULT;  s1_b0 <= s0_b0 * K_MULT;
            s1_r1 <= s0_r1 * K_MULT;  s1_g1 <= s0_g1 * K_MULT;  s1_b1 <= s0_b1 * K_MULT;
            s1_r2 <= s0_r2 * K_MULT;  s1_g2 <= s0_g2 * K_MULT;  s1_b2 <= s0_b2 * K_MULT;
            s1_r3 <= s0_r3 * K_MULT;  s1_g3 <= s0_g3 * K_MULT;  s1_b3 <= s0_b3 * K_MULT;
        end
    end


    // ?????????????????????????????????????????????????????????????????????
    // STAGE 2 - Shift >> 11, tr? 1024, pack ? output
    //
    //   Sau khi prod ð? ðý?c register trong DSP P-reg (S1),
    //   ch? c?n:
    //     • shift >> 11  : ch? là wire n?i bit (0 logic)
    //     • subtract 1024: 1 adder nh? 12-bit
    //     • pack 192-bit : wiring
    //   ? Path này r?t ng?n, d? meet timing dù Fmax cao.
    // ?????????????????????????????????????????????????????????????????????
 
    // Hàm inline: shift + subtract ? int16
    function automatic signed [15:0] to_q610;
        input [22:0] prod;
        reg [11:0] shifted;
        begin
            shifted = prod[22:11];                          // >> 11 (pure wire, no logic)
            to_q610 = $signed({1'b0, shifted}) - 16'sd1024; // 12-bit adder only
        end
    endfunction
 
    always @(posedge i_clk ) begin
        if (!i_rst_n) begin
            o_valid <= 1'b0;
            // o_data  <= 192'b0;
        end else begin
            o_valid <= s1_valid;
            if (s1_valid) begin
                // Layout: [191:128]=BBBB, [127:64]=GGGG, [63:0]=RRRR
                o_data <= {
                    to_q610(s1_b3), to_q610(s1_b2),
                    to_q610(s1_b1), to_q610(s1_b0),
                    to_q610(s1_g3), to_q610(s1_g2),
                    to_q610(s1_g1), to_q610(s1_g0),
                    to_q610(s1_r3), to_q610(s1_r2),
                    to_q610(s1_r1), to_q610(s1_r0)
                };
            end
        end
    end
 
endmodule









`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Module: post_process
//
// Ch?c nãng:
//   Nh?n 48-bit/cycle t? IP_top (1 pixel, 3 kênh × 16-bit Q6.10):
//     [47:32] = B (int16, Q6.10)
//     [31:16] = G (int16, Q6.10)
//     [15: 0] = R (int16, Q6.10)
//
//   Dequantize Q6.10 ? uint8:
//     Công th?c t? notebook:
//       f32  = q610 / 1024.0
//       rgb8 = clip(round((f32 + 1.0) * 127.5), 0, 255)
//            = clip(round(q610 * 127.5 / 1024 + 127.5), 0, 255)
//            = clip(round(q610 * 255 / 2048)  + 128, 0, 255)
//
//     Dùng phép nhân nguyên:
//       q610 * 255 / 2048 ? q610 * 255 >> 11
//       Nhýng v? q610 có th? âm (signed), dùng signed arithmetic.
//
//     Th?c t?:
//       prod  = q610 * 255  (signed 16-bit × 8-bit = signed 24-bit)
//       shifted = prod >>> 11  (arithmetic right shift)
//       rgb8  = clip(shifted + 128, 0, 255)
//
//   Pack thành XRGB 32-bit:
//     [31:24] = 8'h00 (dump/padding X)
//     [23:16] = B[7:0]
//     [15: 8] = G[7:0]
//     [ 7: 0] = R[7:0]
//
//   Output tr?c ti?p 32-bit ? DMA 
//
// Latency: 2 chu k? pipeline
////////////////////////////////////////////////////////////////////////////////

module post_process (
    input  wire         i_clk,
    input  wire         i_rst_n,

    // ?? Input ? IP_top ???????????????????????????????????????????????????
    input  wire         i_valid,
    input  wire [47:0]  i_data,         // {B[47:32], G[31:16], R[15:0]} Q6.10
    input  wire         i_tlast,         // Tín hi?u last c?a AXI4-Stream

    // ?? AXI4-Stream Master ? DMA ?????????????????????????????????????????
    output reg          m_axis_tvalid,
    output reg  [31:0]  m_axis_tdata,   // {X[31:24], B[23:16], G[15:8], R[7:0]}
    // input  wire         m_axis_tready,
    output reg          m_axis_tlast
);


// ?????????????????????????????????????????????????????????????????????
    // STAGE 0 - Tách kênh, ðãng k? vào DSP A/B pre-register
    //   Tách Q6.10 t? i_data và ðãng k? trý?c khi ðýa vào DSP.
    //   Ði?u này cho phép tool map vào DSP48 A1-reg ho?c B1-reg,
    //   lo?i b? combinational path dài t? input ð?n DSP multiplier.
    // ?????????????????????????????????????????????????????????????????????
 
    reg signed [15:0] s0_q_r, s0_q_g, s0_q_b;
    reg               s0_valid, s0_tlast;
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s0_valid <= 1'b0;
            s0_tlast <= 1'b0;
            // s0_q_r   <= 16'sd0;
            // s0_q_g   <= 16'sd0;
            // s0_q_b   <= 16'sd0;
        end else begin
            s0_valid <= i_valid;
            s0_tlast <= i_tlast;
            s0_q_r   <= $signed(i_data[15: 0]);
            s0_q_g   <= $signed(i_data[31:16]);
            s0_q_b   <= $signed(i_data[47:32]);
        end
    end



       // ?????????????????????????????????????????????????????????????????????
    // STAGE 1 - Nhân trong DSP, capture vào P-register c?a DSP48
    //
    //   prod = q610 * 255   (signed 16-bit × signed 9-bit = signed 25-bit)
    //   Lýu 24-bit (range ð?: max |q610|=1024, 1024*255=261120 < 2^18)
    //
    //   V?i DSP48E2: A=q610(16-bit), B=255(9-bit), OPMODE=multiply
    //   P-register b?t ? k?t qu? lýu trong DSP, không route ra fabric ngay.
    // ?????????????????????????????????????????????????????????????????????
 
    (* use_dsp = "yes" *) reg signed [23:0] s1_prod_r, s1_prod_g, s1_prod_b;
    reg s1_valid, s1_tlast;
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s1_valid  <= 1'b0;
            s1_tlast  <= 1'b0;
            // s1_prod_r <= 24'sd0;
            // s1_prod_g <= 24'sd0;
            // s1_prod_b <= 24'sd0;
        end else begin
            s1_valid  <= s0_valid;
            s1_tlast  <= s0_tlast;
            // DSP P-reg: multiply v?i s0 ð? pre-registered ? path ng?n nh?t
            s1_prod_r <= s0_q_r * $signed(9'sd255);
            s1_prod_g <= s0_q_g * $signed(9'sd255);
            s1_prod_b <= s0_q_b * $signed(9'sd255);
        end
    end


        // ?????????????????????????????????????????????????????????????????????
    // STAGE 2 - Shift, offset, clamp ? uint8, pack XRGB
    //
    //   Sau DSP P-reg:
    //     shifted = prod[23:11]  ? pure wire (arithmetic shift on signed)
    //     val     = shifted + 128
    //     rgb8    = clamp(val, 0, 255)
    //
    //   Path: ch? c?n 1 adder 14-bit + 2 comparator ? r?t ng?n.
    // ?????????????????????????????????????????????????????????????????????
 
    // Arithmetic right shift: l?y bit [23:11] (gi? sign bit [23])
    // s1_prod là signed 24-bit, [23:11] cho 13-bit signed (ð? shift >>> 11)
    wire signed [12:0] shifted_r = s1_prod_r[23:11];
    wire signed [12:0] shifted_g = s1_prod_g[23:11];
    wire signed [12:0] shifted_b = s1_prod_b[23:11];
 
    // M? r?ng 1 bit ð? tránh overflow khi c?ng 128
    wire signed [13:0] val_r = $signed({shifted_r[12], shifted_r}) + 14'sd128;
    wire signed [13:0] val_g = $signed({shifted_g[12], shifted_g}) + 14'sd128;
    wire signed [13:0] val_b = $signed({shifted_b[12], shifted_b}) + 14'sd128;
 
    // Clamp sang uint8
    function automatic [7:0] clamp_u8;
        input signed [13:0] x;
        begin
            if      (x < 14'sd0)   clamp_u8 = 8'd0;
            else if (x > 14'sd255) clamp_u8 = 8'd255;
            else                   clamp_u8 = x[7:0];
        end
    endfunction
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            m_axis_tvalid <= 1'b0;
            // m_axis_tdata  <= 32'h0;
            m_axis_tlast  <= 1'b0;
        end else begin
            m_axis_tvalid <= s1_valid;
            m_axis_tlast  <= s1_tlast;
            if (s1_valid) begin
                m_axis_tdata <= {
                    8'h00,
                    clamp_u8(val_b),
                    clamp_u8(val_g),
                    clamp_u8(val_r)
                };
            end
        end
    end
 
endmodule
 
