`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Module: pre_process
//
// Chức năng:
//   Nhận 128-bit/cycle từ DMA theo format XRGB×4:
//     [127:96] = pix3 {X[7:0], B[7:0], G[7:0], R[7:0]}
//     [ 95:64] = pix2 {X[7:0], B[7:0], G[7:0], R[7:0]}
//     [ 63:32] = pix1 {X[7:0], B[7:0], G[7:0], R[7:0]}
//     [ 31: 0] = pix0 {X[7:0], B[7:0], G[7:0], R[7:0]}
//
//   Convert từng kênh uint8 → Q6.10 (int16):
//     Công thức từ notebook:
//       float = pixel / 255.0
//       norm  = (float - 0.5) / 0.5  = pixel/127.5 - 1.0
//       q610  = round(norm * 1024)
//            ≈ round(pixel * 1024 / 127.5 - 1024)
//            ≈ round(pixel * 8.0502) - 1024
//
//   Reorder sang layout IP_top (192-bit):
//     [191:128] = {B3,B2,B1,B0} 4×16-bit kênh Blue
//     [127: 64] = {G3,G2,G1,G0} 4×16-bit kênh Green
//     [ 63:  0] = {R3,R2,R1,R0} 4×16-bit kênh Red
//
// Interface AXI4-Stream Slave �? DMA (128-bit)
// Interface plain valid/data  → IP_top (192-bit)
//
// Latency: 2 chu kỳ pipeline (reg stage + output register)
////////////////////////////////////////////////////////////////////////////////

module pre_process (
    input  wire         i_clk,
    input  wire         i_rst_n,

    // ── AXI4-Stream Slave �? DMA ──────────────────────────────────────────
    input  wire         s_axis_tvalid,
    input  wire [127:0] s_axis_tdata,   // {pix3,pix2,pix1,pix0} XRGB×4
//    output wire         s_axis_tready,

    // ── Output → IP_top ──────────────────────────────────────────────────
    output reg          o_valid,
    output reg  [191:0] o_data          // {BBBB,GGGG,RRRR} 4×int16×3ch
);

    // Luôn sẵn sàng nhận (không có backpressure từ phía trên)
//    assign s_axis_tready = 1'b1;

    // ─────────────────────────────────────────────────────────────────────
    // STAGE 1 – Tách kênh và tính Q6.10
    //
    // Q6.10 = round(x * 1024 / 127.5) - 1024
    //       = round(x * 2048 / 255)   - 1024
    //
    // Dùng phép nhân nguyên:
    //   q = (x * 2048 + 127) / 255 - 1024    (chia nguyên làm tròn đến 0)
    //   Vì 255 không chia hết theo dạng shift, dùng hằng:
    //   2048/255 ≈ 8.0314 → dùng: (x * 16449) >> 11  (sai số < 0.05 LSB)
    //     16449 = round(2048/255 * 2^11) = round(8.0314 * 2048) ≈ 16449
    //   Sau đó trừ 1024.
    //
    //   Kiểm tra biên: x=0   → 0*16449>>11 - 1024 = -1024  ✓ (≈ -1.0*1024)
    //                  x=255 → 255*16449>>11 - 1024 = 1024  ✓ (≈  1.0*1024)
    //                  x=128 → 128*16449>>11 - 1024 ≈ 3     ✓ (≈  0.0*1024)
    // ─────────────────────────────────────────────────────────────────────

    // --- Tách pixel ---
    wire [7:0] r0, g0, b0;
    wire [7:0] r1, g1, b1;
    wire [7:0] r2, g2, b2;
    wire [7:0] r3, g3, b3;

    // Format trong mỗi 32-bit word: {X[31:24], B[23:16], G[15:8], R[7:0]}
    assign {b0, g0, r0} = {s_axis_tdata[23:16], s_axis_tdata[15:8],  s_axis_tdata[7:0]  };
    assign {b1, g1, r1} = {s_axis_tdata[55:48], s_axis_tdata[47:40], s_axis_tdata[39:32] };
    assign {b2, g2, r2} = {s_axis_tdata[87:80], s_axis_tdata[79:72], s_axis_tdata[71:64] };
    assign {b3, g3, r3} = {s_axis_tdata[119:112],s_axis_tdata[111:104],s_axis_tdata[103:96]};

    // --- Stage 1 register: valid + tích nhân ---
    reg         s1_valid;
    reg [22:0]  s1_r0, s1_g0, s1_b0;
    reg [22:0]  s1_r1, s1_g1, s1_b1;
    reg [22:0]  s1_r2, s1_g2, s1_b2;
    reg [22:0]  s1_r3, s1_g3, s1_b3;

    // Hằng nhân: 16449 (= round(2048/255 * 2^11))
    localparam [15:0] K_MULT = 'd16449;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            s1_valid <= 1'b0;
            s1_r0 <= 23'b0; s1_g0 <= 23'b0; s1_b0 <= 23'b0;
            s1_r1 <= 23'b0; s1_g1 <= 23'b0; s1_b1 <= 23'b0;
            s1_r2 <= 23'b0; s1_g2 <= 23'b0; s1_b2 <= 23'b0;
            s1_r3 <= 23'b0; s1_g3 <= 23'b0; s1_b3 <= 23'b0;
        end else begin
            s1_valid <= s_axis_tvalid;
            // x * 16449  (8-bit * 14-bit = 22-bit, store 23-bit for sign)
            s1_r0 <= r0 * K_MULT;  s1_g0 <= g0 * K_MULT;  s1_b0 <= b0 * K_MULT;
            s1_r1 <= r1 * K_MULT;  s1_g1 <= g1 * K_MULT;  s1_b1 <= b1 * K_MULT;
            s1_r2 <= r2 * K_MULT;  s1_g2 <= g2 * K_MULT;  s1_b2 <= b2 * K_MULT;
            s1_r3 <= r3 * K_MULT;  s1_g3 <= g3 * K_MULT;  s1_b3 <= b3 * K_MULT;
        end
    end

    // ─────────────────────────────────────────────────────────────────────
    // STAGE 2 – Shift >> 11, trừ 1024, pack → output
    //   q = (prod >> 11) - 1024
    //   Kết quả nằm trong [-1024, 1024] → fit 16-bit signed
    // ─────────────────────────────────────────────────────────────────────

    // Hàm inline: shift + subtract → int16
    function automatic signed [15:0] to_q610;
        input [22:0] prod;
        reg [11:0] shifted;
        begin
            shifted = prod[22:11];          // >> 11 (unsigned 12-bit)
            to_q610 = $signed({1'b0, shifted}) - 16'sd1024;
        end
    endfunction

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_valid <= 1'b0;
            o_data  <= 192'b0;
        end else begin
            o_valid <= s1_valid;
            if (s1_valid) begin
                // Layout: [191:128]=BBBB, [127:64]=GGGG, [63:0]=RRRR
                // Mỗi nhóm: [pix3][pix2][pix1][pix0] (MSB→LSB)
                o_data <= {
                    // BBBB [191:128]
                    to_q610(s1_b3), to_q610(s1_b2),
                    to_q610(s1_b1), to_q610(s1_b0),
                    // GGGG [127:64]
                    to_q610(s1_g3), to_q610(s1_g2),
                    to_q610(s1_g1), to_q610(s1_g0),
                    // RRRR [63:0]
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
// Chức năng:
//   Nhận 48-bit/cycle từ IP_top (1 pixel, 3 kênh × 16-bit Q6.10):
//     [47:32] = B (int16, Q6.10)
//     [31:16] = G (int16, Q6.10)
//     [15: 0] = R (int16, Q6.10)
//
//   Dequantize Q6.10 → uint8:
//     Công thức từ notebook:
//       f32  = q610 / 1024.0
//       rgb8 = clip(round((f32 + 1.0) * 127.5), 0, 255)
//            = clip(round(q610 * 127.5 / 1024 + 127.5), 0, 255)
//            = clip(round(q610 * 255 / 2048)  + 128, 0, 255)
//
//     Dùng phép nhân nguyên:
//       q610 * 255 / 2048 ≈ q610 * 255 >> 11
//       Nhưng vì q610 có thể âm (signed), dùng signed arithmetic.
//
//     Thực tế:
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
//   Output trực tiếp 32-bit → DMA 
//
// Latency: 2 chu kỳ pipeline
////////////////////////////////////////////////////////////////////////////////

module post_process (
    input  wire         i_clk,
    input  wire         i_rst_n,

    input  wire         i_valid,
    input  wire [47:0]  i_data,         // {B[47:32], G[31:16], R[15:0]} Q6.10
    input  wire         i_tlast,         // Tín hiệu last của AXI4-Stream

    output reg          m_axis_tvalid,
    output reg  [31:0]  m_axis_tdata,   // {X[31:24], B[23:16], G[15:8], R[7:0]}
//    input  wire         m_axis_tready,
    output reg          m_axis_tlast
);

    wire signed [15:0] q_r = $signed(i_data[15: 0]);
    wire signed [15:0] q_g = $signed(i_data[31:16]);
    wire signed [15:0] q_b = $signed(i_data[47:32]);


    reg         s1_tlast;
    reg         s1_valid;
    reg signed [23:0] s1_prod_r, s1_prod_g, s1_prod_b;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            s1_valid  <= 1'b0;
            s1_tlast  <= 1'b0;
            s1_prod_r <= 24'sd0;
            s1_prod_g <= 24'sd0;
            s1_prod_b <= 24'sd0;
        end else begin
            s1_valid  <= i_valid;
            s1_tlast  <= i_tlast;
            // q610 (int16) * 255 (uint8) = signed 24-bit
            s1_prod_r <= q_r * $signed(9'sd255);
            s1_prod_g <= q_g * $signed(9'sd255);
            s1_prod_b <= q_b * $signed(9'sd255);
        end
    end

    function automatic [7:0] clamp_u8;
        input signed [13:0] x;   // shifted(13-bit signed) + 128 → max range [-4096+128..4096+128]
        begin
            if (x < 14'sd0)        clamp_u8 = 8'd0;
            else if (x > 14'sd255) clamp_u8 = 8'd255;
            else                   clamp_u8 = x[7:0];
        end
    endfunction

    // Arithmetic right shift 11 bits (24-bit signed → 13-bit signed)
    wire signed [12:0] shifted_r = s1_prod_r[23:11];
    wire signed [12:0] shifted_g = s1_prod_g[23:11];
    wire signed [12:0] shifted_b = s1_prod_b[23:11];

    wire signed [13:0] val_r = $signed({shifted_r[12], shifted_r}) + 14'sd128;
    wire signed [13:0] val_g = $signed({shifted_g[12], shifted_g}) + 14'sd128;
    wire signed [13:0] val_b = $signed({shifted_b[12], shifted_b}) + 14'sd128;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 32'h0;
            m_axis_tlast  <= 1'b0;
        end else begin
            m_axis_tvalid <= s1_valid;
            m_axis_tlast  <= s1_tlast;
            if (s1_valid) begin
                m_axis_tdata <= {
                    8'h00,          // X (dump/padding)
                    clamp_u8(val_b),
                    clamp_u8(val_g),
                    clamp_u8(val_r)
                };
            end
        end
    end


endmodule