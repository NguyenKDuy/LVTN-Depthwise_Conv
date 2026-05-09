`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Module: pre_process  (DSP-pipeline fixed)
//
// Pipeline: 3 cycles (tãng t? 2 ? 3 so v?i b?n g?c)
//
//   S0 (AREG):  register raw pixel inputs  ? Vivado maps ? DSP AREG
//   S1 (MREG):  x * K_MULT, result held   ? Vivado maps ? DSP MREG
//   S2 (PREG):  pipeline register of S1   ? Vivado maps ? DSP PREG  (fix DPOP)
//   OUT:        shift >> 11, subtract 1024, pack 192-bit
//
// Fix DPIP: S0 pre-registers A input trý?c DSP, ð? ð? Vivado infer AREG.
// Fix DPOP: thêm S2 sau multiply ð? Vivado infer MREG=1 + PREG=1.
////////////////////////////////////////////////////////////////////////////////

module pre_process (
    input  wire         i_clk,
    input  wire         i_rst_n,

    // AXI4-Stream Slave ? DMA
    input  wire         s_axis_tvalid,
    input  wire [127:0] s_axis_tdata,   // {pix3,pix2,pix1,pix0} XRGB×4

    // Output ? IP_top
    output reg          o_valid,
    output reg  [191:0] o_data          // {BBBB,GGGG,RRRR} 4×int16×3ch
);

    localparam [14:0] K_MULT = 'd16449;

    // ?????????????????????????????????????????????????????????????????????????
    // Tách kênh (pure wire)
    // ?????????????????????????????????????????????????????????????????????????
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

    // ?????????????????????????????????????????????????????????????????????????
    // STAGE 0 - AREG: pre-register A input trý?c DSP
    //   Vivado s? absorb FF này vào AREG bên trong DSP48E2.
    //   Gi?i quy?t DPIP "A is not pipelined".
    // ?????????????????????????????????????????????????????????????????????????
    reg        s0_valid;
    reg [7:0]  s0_r0, s0_g0, s0_b0;
    reg [7:0]  s0_r1, s0_g1, s0_b1;
    reg [7:0]  s0_r2, s0_g2, s0_b2;
    reg [7:0]  s0_r3, s0_g3, s0_b3;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s0_valid <= 1'b0;
        end else begin
            s0_valid <= s_axis_tvalid;
            s0_r0 <= r0; s0_g0 <= g0; s0_b0 <= b0;
            s0_r1 <= r1; s0_g1 <= g1; s0_b1 <= b1;
            s0_r2 <= r2; s0_g2 <= g2; s0_b2 <= b2;
            s0_r3 <= r3; s0_g3 <= g3; s0_b3 <= b3;
        end
    end

    // ?????????????????????????????????????????????????????????????????????????
    // STAGE 1 - MREG: multiply, Vivado maps ? DSP48E2 MREG
    //   prod = pixel[7:0] * 16449  (8-bit × 14-bit = 22-bit unsigned)
    // ?????????????????????????????????????????????????????????????????????????
    (* use_dsp = "yes" *) reg [22:0] s1_r0, s1_g0, s1_b0;
    (* use_dsp = "yes" *) reg [22:0] s1_r1, s1_g1, s1_b1;
    (* use_dsp = "yes" *) reg [22:0] s1_r2, s1_g2, s1_b2;
    (* use_dsp = "yes" *) reg [22:0] s1_r3, s1_g3, s1_b3;
    reg s1_valid;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s1_valid <= 1'b0;
        end else begin
            s1_valid <= s0_valid;
            s1_r0 <= s0_r0 * K_MULT;  s1_g0 <= s0_g0 * K_MULT;  s1_b0 <= s0_b0 * K_MULT;
            s1_r1 <= s0_r1 * K_MULT;  s1_g1 <= s0_g1 * K_MULT;  s1_b1 <= s0_b1 * K_MULT;
            s1_r2 <= s0_r2 * K_MULT;  s1_g2 <= s0_g2 * K_MULT;  s1_b2 <= s0_b2 * K_MULT;
            s1_r3 <= s0_r3 * K_MULT;  s1_g3 <= s0_g3 * K_MULT;  s1_b3 <= s0_b3 * K_MULT;
        end
    end

    // ?????????????????????????????????????????????????????????????????????????
    // STAGE 2 - PREG: pipeline register sau multiply  ? STAGE M?I (fix DPOP)
    //   Vivado maps FF này vào PREG bên trong DSP48E2 (MREG=1, PREG=1).
    //   Không có logic nào ? ðây, ch? là wire/FF.
    // ?????????????????????????????????????????????????????????????????????????
    reg [22:0] s2_r0, s2_g0, s2_b0;
    reg [22:0] s2_r1, s2_g1, s2_b1;
    reg [22:0] s2_r2, s2_g2, s2_b2;
    reg [22:0] s2_r3, s2_g3, s2_b3;
    reg s2_valid;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s2_valid <= 1'b0;
        end else begin
            s2_valid <= s1_valid;
            s2_r0 <= s1_r0;  s2_g0 <= s1_g0;  s2_b0 <= s1_b0;
            s2_r1 <= s1_r1;  s2_g1 <= s1_g1;  s2_b1 <= s1_b1;
            s2_r2 <= s1_r2;  s2_g2 <= s1_g2;  s2_b2 <= s1_b2;
            s2_r3 <= s1_r3;  s2_g3 <= s1_g3;  s2_b3 <= s1_b3;
        end
    end

    // ?????????????????????????????????????????????????????????????????????????
    // STAGE OUT - Shift >> 11, subtract 1024, pack 192-bit
    //   Path r?t ng?n: ch? wire n?i bit + 1 adder 12-bit.
    //   Ð?c t? s2_* (PREG output), không qua fabric dài.
    // ?????????????????????????????????????????????????????????????????????????
    function automatic signed [15:0] to_q610;
        input [22:0] prod;
        reg [11:0] shifted;
        begin
            shifted = prod[22:11];                           // >> 11 (pure wire)
            to_q610 = $signed({1'b0, shifted}) - 16'sd1024; // 12-bit adder
        end
    endfunction

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_valid <= 1'b0;
        end else begin
            o_valid <= s2_valid;
            if (s2_valid) begin
                // Layout: [191:128]=BBBB, [127:64]=GGGG, [63:0]=RRRR
                o_data <= {
                    to_q610(s2_b3), 
                    to_q610(s2_b2),
                    to_q610(s2_b1), 
                    to_q610(s2_b0),
                    to_q610(s2_g3), 
                    to_q610(s2_g2),
                    to_q610(s2_g1), 
                    to_q610(s2_g0),
                    to_q610(s2_r3), 
                    to_q610(s2_r2),
                    to_q610(s2_r1), 
                    to_q610(s2_r0)
                };
            end
        end
    end

endmodule


`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Module: post_process  (DSP-pipeline fixed)
//
// Pipeline: 3 cycles (tãng t? 2 ? 3 so v?i b?n g?c)
//
//   S0 (AREG):  register Q6.10 inputs    ? Vivado maps ? DSP AREG
//   S1 (MREG):  q * 255, result held     ? Vivado maps ? DSP MREG
//   S2 (PREG):  pipeline register of S1  ? Vivado maps ? DSP PREG  (fix DPOP)
//   OUT:        shift >>> 11, +128, clamp, pack XRGB 32-bit
//
// Fix DPIP: S0 pre-registers A input.
// Fix DPOP: thêm S2 ð? Vivado infer MREG=1 + PREG=1.
////////////////////////////////////////////////////////////////////////////////

module post_process (
    input  wire         i_clk,
    input  wire         i_rst_n,

    // Input ? IP_top
    input  wire         i_valid,
    input  wire [191:0]  i_data,         // {B[47:32], G[31:16], R[15:0]}x4 Q6.10
    input  wire         i_tlast,

    // AXI4-Stream Master ? DMA
    output reg          m_axis_tvalid,
    output reg  [127:0]  m_axis_tdata,   // {X[31:24], B[23:16], G[15:8], R[7:0]}x4
    output reg          m_axis_tlast
);

    // ?????????????????????????????????????????????????????????????????????????
    // STAGE 0 - AREG: tách kênh, pre-register vào DSP A input
    //   Vivado absorbs FF vào AREG bên trong DSP48E2 (fix DPIP).
    // ?????????????????????????????????????????????????????????????????????????
    reg signed [15:0] s0_q_r0, s0_q_g0, s0_q_b0;
    reg signed [15:0] s0_q_r1, s0_q_g1, s0_q_b1; // gi? nguyên layout ð? d? debug
    reg signed [15:0] s0_q_r2, s0_q_g2, s0_q_b2; // gi? nguyên layout ð? d? debug
    reg signed [15:0] s0_q_r3, s0_q_g3, s0_q_b3; // gi? nguyên layout ð? d? debug
    reg               s0_valid, s0_tlast;
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s0_valid <= 1'b0;
            s0_tlast <= 1'b0;
        end else begin
            s0_valid <= i_valid;
            s0_tlast <= i_tlast;

            s0_q_r0   <= $signed(i_data[15: 0]);
            s0_q_r1   <= $signed(i_data[31:16]);
            s0_q_r2   <= $signed(i_data[47:32]);
            s0_q_r3   <= $signed(i_data[63:48]);

            s0_q_g0   <= $signed(i_data[79:64]);
            s0_q_g1   <= $signed(i_data[95:80]);
            s0_q_g2   <= $signed(i_data[111:96]);
            s0_q_g3   <= $signed(i_data[127:112]);

            s0_q_b0   <= $signed(i_data[143:128]);
            s0_q_b1   <= $signed(i_data[159:144]);
            s0_q_b2   <= $signed(i_data[175:160]);
            s0_q_b3   <= $signed(i_data[191:176]);
        end
    end

    // ?????????????????????????????????????????????????????????????????????????
    // STAGE 1 - MREG: multiply, Vivado maps ? DSP48E2 MREG
    //   prod = q610 * 255  (signed 16-bit × signed 9-bit = signed 25-bit)
    //   Lýu 24-bit (max |q610|=1024 ? 1024*255=261120 < 2^18, an toàn)
    // ?????????????????????????????????????????????????????????????????????????
    (* use_dsp = "yes" *) reg signed [23:0] s1_prod_r0, s1_prod_g0, s1_prod_b0;
    (* use_dsp = "yes" *) reg signed [23:0] s1_prod_r1, s1_prod_g1, s1_prod_b1; // gi? nguyên layout ð? d? debug
    (* use_dsp = "yes" *) reg signed [23:0] s1_prod_r2, s1_prod_g2, s1_prod_b2; // gi? nguyên layout ð? d? debug
    (* use_dsp = "yes" *) reg signed [23:0] s1_prod_r3, s1_prod_g3, s1_prod_b3; // gi? nguyên layout ð? d? debug

    reg s1_valid, s1_tlast;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s1_valid <= 1'b0;
            s1_tlast <= 1'b0;
        end else begin
            s1_valid  <= s0_valid;
            s1_tlast  <= s0_tlast;

            s1_prod_r0 <= s0_q_r0 * $signed(9'sd255);
            s1_prod_g0 <= s0_q_g0 * $signed(9'sd255);
            s1_prod_b0 <= s0_q_b0 * $signed(9'sd255);

            s1_prod_r1 <= s0_q_r1 * $signed(9'sd255);
            s1_prod_g1 <= s0_q_g1 * $signed(9'sd255);
            s1_prod_b1 <= s0_q_b1 * $signed(9'sd255);

            s1_prod_r2 <= s0_q_r2 * $signed(9'sd255);
            s1_prod_g2 <= s0_q_g2 * $signed(9'sd255);
            s1_prod_b2 <= s0_q_b2 * $signed(9'sd255);

            s1_prod_r3 <= s0_q_r3 * $signed(9'sd255);
            s1_prod_g3 <= s0_q_g3 * $signed(9'sd255);
            s1_prod_b3 <= s0_q_b3 * $signed(9'sd255);

        end
    end

    // ?????????????????????????????????????????????????????????????????????????
    // STAGE 2 - PREG: pipeline register sau multiply  ? STAGE M?I (fix DPOP)
    //   Vivado maps FF này vào PREG (MREG=1, PREG=1).
    // ?????????????????????????????????????????????????????????????????????????
    reg signed [23:0] s2_prod_r0, s2_prod_g0, s2_prod_b0;
    reg signed [23:0] s2_prod_r1, s2_prod_g1, s2_prod_b1; // gi? nguyên layout ð? d? debug
    reg signed [23:0] s2_prod_r2, s2_prod_g2, s2_prod_b2; // gi? nguyên layout ð? d? debug
    reg signed [23:0] s2_prod_r3, s2_prod_g3, s2_prod_b3; // gi? nguyên layout ð? d? debug

    reg s2_valid, s2_tlast;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            s2_valid <= 1'b0;
            s2_tlast <= 1'b0;
        end else begin
            s2_valid  <= s1_valid;
            s2_tlast  <= s1_tlast;

            s2_prod_r0 <= s1_prod_r0;
            s2_prod_g0 <= s1_prod_g0;
            s2_prod_b0 <= s1_prod_b0;

            s2_prod_r1 <= s1_prod_r1;
            s2_prod_g1 <= s1_prod_g1;
            s2_prod_b1 <= s1_prod_b1;

            s2_prod_r2 <= s1_prod_r2;
            s2_prod_g2 <= s1_prod_g2;
            s2_prod_b2 <= s1_prod_b2;

            s2_prod_r3 <= s1_prod_r3;
            s2_prod_g3 <= s1_prod_g3;
            s2_prod_b3 <= s1_prod_b3;

        end
    end

    // ?????????????????????????????????????????????????????????????????????????
    // STAGE OUT - Shift, offset, clamp ? pack XRGB
    //   Ð?c t? s2_* (PREG output).
    //   shifted = prod[23:11]   ? arithmetic shift >>> 11 (pure wire, sign-extend)
    //   val     = shifted + 128 ? 1 adder nh?
    //   rgb8    = clamp(val, 0, 255)
    // ?????????????????????????????????????????????????????????????????????????
    wire signed [12:0] shifted_r0 = s2_prod_r0[23:11];
    wire signed [12:0] shifted_g0 = s2_prod_g0[23:11];
    wire signed [12:0] shifted_b0 = s2_prod_b0[23:11];

    wire signed [12:0] shifted_r1 = s2_prod_r1[23:11];
    wire signed [12:0] shifted_g1 = s2_prod_g1[23:11];
    wire signed [12:0] shifted_b1 = s2_prod_b1[23:11];

    wire signed [12:0] shifted_r2 = s2_prod_r2[23:11];
    wire signed [12:0] shifted_g2 = s2_prod_g2[23:11];
    wire signed [12:0] shifted_b2 = s2_prod_b2[23:11];

    wire signed [12:0] shifted_r3 = s2_prod_r3[23:11];
    wire signed [12:0] shifted_g3 = s2_prod_g3[23:11];
    wire signed [12:0] shifted_b3 = s2_prod_b3[23:11];


    // M? r?ng 1 bit ð? tránh overflow khi c?ng 128
    wire signed [13:0] val_r0 = $signed({shifted_r0[12], shifted_r0}) + 14'sd128;
    wire signed [13:0] val_g0 = $signed({shifted_g0[12], shifted_g0}) + 14'sd128;
    wire signed [13:0] val_b0 = $signed({shifted_b0[12], shifted_b0}) + 14'sd128;

    wire signed [13:0] val_r1 = $signed({shifted_r1[12], shifted_r1}) + 14'sd128;
    wire signed [13:0] val_g1 = $signed({shifted_g1[12], shifted_g1}) + 14'sd128;
    wire signed [13:0] val_b1 = $signed({shifted_b1[12], shifted_b1}) + 14'sd128;

    wire signed [13:0] val_r2 = $signed({shifted_r2[12], shifted_r2}) + 14'sd128;
    wire signed [13:0] val_g2 = $signed({shifted_g2[12], shifted_g2}) + 14'sd128;
    wire signed [13:0] val_b2 = $signed({shifted_b2[12], shifted_b2}) + 14'sd128;

    wire signed [13:0] val_r3 = $signed({shifted_r3[12], shifted_r3}) + 14'sd128;
    wire signed [13:0] val_g3 = $signed({shifted_g3[12], shifted_g3}) + 14'sd128;
    wire signed [13:0] val_b3 = $signed({shifted_b3[12], shifted_b3}) + 14'sd128;

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
            m_axis_tlast  <= 1'b0;
        end else begin
            m_axis_tvalid <= s2_valid;
            m_axis_tlast  <= s2_tlast;
            if (s2_valid) begin
                m_axis_tdata <= {
                    8'h00,
                    clamp_u8(val_b3),
                    clamp_u8(val_g3),
                    clamp_u8(val_r3),
                    8'h00,
                    clamp_u8(val_b2),
                    clamp_u8(val_g2),
                    clamp_u8(val_r2),
                    8'h00,
                    clamp_u8(val_b1),
                    clamp_u8(val_g1),
                    clamp_u8(val_r1),
                    8'h00,
                    clamp_u8(val_b0),
                    clamp_u8(val_g0),
                    clamp_u8(val_r0)    
                };
            end
        end
    end

endmodule
