`timescale 1ns/1ps

// =============================================================================
//  Testbench: tb_pw_top.v
//  DUT      : pw_top
//  Params   : DATA_WIDTH=16, IN_CHANNELS=16, OUT_CHANNELS=16
//  Tests    :
//    TC1 – Reset & idle
//    TC2 – Load weights & bias (pw0 và pw1 riêng biệt)
//    TC3 – Mode 0: dual-stream, 1 pixel (first=1, last=1)
//    TC4 – Mode 0: dual-stream, nhiều pixel PSUM (first/last)
//    TC5 – Mode 1: merged (pw0+pw1), 1 pixel
//    TC6 – Kiểm tra stage_done và rst_stage
//    TC7 – Overflow / saturation (feature = 0x7FFF, weight = 0x7FFF)
// =============================================================================

module tb_pw_top;

// ---------------------------------------------------------------------------
// Parameters (phải khớp DUT)
// ---------------------------------------------------------------------------
localparam DW   = 16;
localparam IC   = 16;
localparam OC   = 16;
localparam FIFO_MAX_PTR = 64;     // thu nhỏ để sim nhanh
localparam PIPE = 10;

localparam FEAT_W    = IC * DW * 2;   // 512 bit (pw0 + pw1 feature)
localparam WEIGHT_W  = 1024;
localparam OUT_W     = OC * DW;       // 256 bit
localparam BIAS_W    = OC * DW;

// ---------------------------------------------------------------------------
// Clock & DUT signals
// ---------------------------------------------------------------------------
reg clk, rst_n;

reg                 i_weight_valid0, i_weight_valid1;
reg  [1023:0]       i_data_weight_pw;

reg                 i_feature_valid;
reg  [FEAT_W-1:0]   i_data_feature;

reg                 i_bias_valid0, i_bias_valid1;
reg  [BIAS_W-1:0]   i_bias_pw;

reg                 i_mode;
reg                 i_is_first;
reg                 i_is_last;
reg                 i_rst_stage;
reg  [7:0]          i_fifo_mode;

wire [OUT_W-1:0]    o_data_pw0;
wire                o_valid_pw0;
wire [OUT_W-1:0]    o_data_pw1;
wire                o_valid_pw1;
wire                o_stage_done;

// ---------------------------------------------------------------------------
// Instantiate DUT
// ---------------------------------------------------------------------------
pw_top #(
    .DATA_WIDTH   (DW),
    .IN_CHANNELS  (IC),
    .OUT_CHANNELS (OC),
    .FIFO_MAX_PTR (FIFO_MAX_PTR),
    .PIPE_DEPTH   (PIPE)
) dut (
    .clk             (clk),
    .rst_n           (rst_n),
    .i_weight_valid0 (i_weight_valid0),
    .i_weight_valid1 (i_weight_valid1),
    .i_data_weight_pw(i_data_weight_pw),
    .i_feature_valid (i_feature_valid),
    .i_data_feature  (i_data_feature),
    .i_bias_valid0   (i_bias_valid0),
    .i_bias_valid1   (i_bias_valid1),
    .i_bias_pw       (i_bias_pw),
    .i_mode          (i_mode),
    .i_is_first      (i_is_first),
    .i_is_last       (i_is_last),
    .i_rst_stage     (i_rst_stage),
    .i_fifo_mode     (i_fifo_mode),
    .o_data_pw0      (o_data_pw0),
    .o_valid_pw0     (o_valid_pw0),
    .o_data_pw1      (o_data_pw1),
    .o_valid_pw1     (o_valid_pw1),
    .o_stage_done    (o_stage_done)
);

// ---------------------------------------------------------------------------
// Clock: 10 ns period
// ---------------------------------------------------------------------------
initial clk = 0;
always #5 clk = ~clk;

// ---------------------------------------------------------------------------
// Dump waveform
// ---------------------------------------------------------------------------
initial begin
    $dumpfile("tb_pw_top.vcd");
    $dumpvars(0, tb_pw_top);
end

// ---------------------------------------------------------------------------
// Helper tasks
// ---------------------------------------------------------------------------

// Reset DUT
task do_reset;
begin
    rst_n           = 0;
    i_weight_valid0 = 0;
    i_weight_valid1 = 0;
    i_data_weight_pw= 0;
    i_feature_valid = 0;
    i_data_feature  = 0;
    i_bias_valid0   = 0;
    i_bias_valid1   = 0;
    i_bias_pw       = 0;
    i_mode          = 0;
    i_is_first      = 0;
    i_is_last       = 0;
    i_rst_stage     = 0;
    i_fifo_mode     = 8'b00001000;  // depth=64 (khớp FIFO_MAX_PTR thu nhỏ)
    repeat(4) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
end
endtask

// Nạp weight cho một trong hai buffer (4 chu kỳ = 1 lần load đủ)
// weight_val: giá trị 16-bit cho mọi lane (đơn giản hoá)
task load_weight;
    input         which;      // 0 = pw0, 1 = pw1
    input [15:0]  weight_val;
    integer cycle;
    integer oc_i, ic_i;
    reg [1023:0] w_bus;
begin
    // Xây dựng weight bus: OC*IC*DW = 16*16*16 = 4096 bit
    // weight_buffer nhận 1024 bit / lần, cần 4 lần
    // Mỗi lần: 16 chunks × 64 bit
    // Mỗi chunk = weight cho 4 IC của cùng 1 OC
    // Để đơn giản: đặt tất cả weight = weight_val
    for (cycle = 0; cycle < 4; cycle = cycle + 1) begin
        // Tạo 1024-bit bus: 16 chunks × 64 bit
        // Chunk i chứa weight[oc=i][ic = cycle*4 .. cycle*4+3]
        w_bus = 0;
        begin : BUILD_BUS
            integer ch;
            for (ch = 0; ch < 16; ch = ch + 1) begin
                // 64-bit chunk cho cluster ch: 4 weights × 16 bit
                w_bus[ch*64 +: 16] = weight_val;
                w_bus[ch*64+16 +: 16] = weight_val;
                w_bus[ch*64+32 +: 16] = weight_val;
                w_bus[ch*64+48 +: 16] = weight_val;
            end
        end

        @(posedge clk);
        i_data_weight_pw = w_bus;
        if (which == 0) begin
            i_weight_valid0 = 1;
            i_weight_valid1 = 0;
        end else begin
            i_weight_valid0 = 0;
            i_weight_valid1 = 1;
        end
    end
    @(posedge clk);
    i_weight_valid0 = 0;
    i_weight_valid1 = 0;
end
endtask

// Nạp bias (1 chu kỳ)
task load_bias;
    input [15:0] bval;
    integer ch;
    reg [BIAS_W-1:0] b;
begin
    b = 0;
    for (ch = 0; ch < OC; ch = ch + 1)
        b[ch*DW +: DW] = bval;
    @(posedge clk);
    i_bias_pw    = b;
    i_bias_valid0 = 1;
    i_bias_valid1 = 1;
    @(posedge clk);
    i_bias_valid0 = 0;
    i_bias_valid1 = 0;
end
endtask

// Gửi 1 pixel feature (cả pw0 và pw1 channel)
// feat_val_pw0, feat_val_pw1: giá trị 16-bit cho tất cả IC lanes
task send_feature;
    input [15:0] feat_val_pw0;
    input [15:0] feat_val_pw1;
    input        is_first;
    input        is_last;
    input        mode;
    integer ch;
    reg [FEAT_W-1:0] f;
begin
    f = 0;
    for (ch = 0; ch < IC; ch = ch + 1) begin
        f[ch*DW +: DW]          = feat_val_pw0;   // lower half = pw0 feature
        f[(IC+ch)*DW +: DW]     = feat_val_pw1;   // upper half = pw1 feature
    end
    @(posedge clk);
    i_data_feature  = f;
    i_feature_valid = 1;
    i_is_first      = is_first;
    i_is_last       = is_last;
    i_mode          = mode;
    @(posedge clk);
    i_feature_valid = 0;
    i_is_first      = 0;
    i_is_last       = 0;
end
endtask

// Chờ output với timeout
task wait_output;
    input integer timeout;
    integer cnt;
begin
    cnt = 0;
    while (!o_valid_pw0 && cnt < timeout) begin
        @(posedge clk);
        cnt = cnt + 1;
    end
    if (cnt >= timeout)
        $display("  [WARN] wait_output timeout at t=%0t", $time);
end
endtask

// ---------------------------------------------------------------------------
// Test counter
// ---------------------------------------------------------------------------
integer pass_cnt, fail_cnt;

task check;
    input [255:0] label_str;  // phần mô tả (dùng string ngắn)
    input         cond;
begin
    if (cond) begin
        $display("  [PASS] %s", label_str);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] %s  (t=%0t)", label_str, $time);
        fail_cnt = fail_cnt + 1;
    end
end
endtask

// ---------------------------------------------------------------------------
// MAIN TEST
// ---------------------------------------------------------------------------
integer i;

initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    // =========================================================
    // TC1: Reset & Idle
    // =========================================================
    $display("\n=== TC1: Reset & Idle ===");
    do_reset;
    repeat(5) @(posedge clk);
    check("o_valid_pw0 = 0 after reset",  o_valid_pw0 === 1'b0);
    check("o_valid_pw1 = 0 after reset",  o_valid_pw1 === 1'b0);
    check("o_stage_done = 0 after reset", o_stage_done === 1'b0);

    // =========================================================
    // TC2: Load weight & bias — kiểm tra weight_buffer o_valid
    // =========================================================
    $display("\n=== TC2: Load weight & bias ===");
    do_reset;
    // pw0 weight = 1, pw1 weight = 2, bias = 0
    load_weight(0, 16'sh0001);   // pw0: tất cả weight = 1
    repeat(2) @(posedge clk);
    check("pw0_weight_valid after 4-cycle load",
          dut.pw0_weight_valid === 1'b1);

    load_weight(1, 16'sh0002);   // pw1: tất cả weight = 2
    repeat(2) @(posedge clk);
    check("pw1_weight_valid after 4-cycle load",
          dut.pw1_weight_valid === 1'b1);

    load_bias(16'sh0000);

    // =========================================================
    // TC3: Mode 0 — 1 pixel, first=1 last=1 (đơn giản nhất)
    //   feature_pw0 = 1 → MAC = 16×1×1 = 16 → quant(16<<10)/1024 = ?
    //   Tất cả weights = 1, features = 1
    //   Dot product = IC * 1 * 1 = 16 (int), sau quantize >> 10:
    //   16 * (2^16) / 1024 = 16 kết quả nguyên gần 0 (vì input là Q1.15)
    //   → testbench chỉ kiểm tra o_valid và o_data_pw0 != 0
    // =========================================================
    $display("\n=== TC3: Mode 0, single pixel first=last=1 ===");
    do_reset;
    load_weight(0, 16'sh0100);   // weight = 256 (Q1.15 ~ small positive)
    load_weight(1, 16'sh0100);
    load_bias(16'sh0000);        // bias = 0

    i_fifo_mode = 8'b00001000;
    send_feature(16'sh0100, 16'sh0100, 1'b1, 1'b1, 1'b0);
    wait_output(PIPE + 5);

    check("TC3: o_valid_pw0 asserted", o_valid_pw0 === 1'b1);
    check("TC3: o_valid_pw1 asserted", o_valid_pw1 === 1'b1);
    check("TC3: o_data_pw0 != 0",      o_data_pw0 !== {OUT_W{1'b0}});
    check("TC3: o_data_pw1 != 0",      o_data_pw1 !== {OUT_W{1'b0}});
    $display("  TC3 o_data_pw0[15:0] = %0d", $signed(o_data_pw0[15:0]));

    // =========================================================
    // TC4: Mode 0 — 3 pixel PSUM (first, middle, last)
    //   Mỗi pixel đóng góp thêm → output cuối > output pixel đơn
    // =========================================================
    $display("\n=== TC4: Mode 0, 3-pixel PSUM accumulation ===");
    do_reset;
    load_weight(0, 16'sh0100);
    load_weight(1, 16'sh0100);
    load_bias(16'sh0000);

    i_fifo_mode = 8'b00001000;
    send_feature(16'sh0100, 16'sh0100, 1'b1, 1'b0, 1'b0); // first
    send_feature(16'sh0100, 16'sh0100, 1'b0, 1'b0, 1'b0); // middle
    send_feature(16'sh0100, 16'sh0100, 1'b0, 1'b1, 1'b0); // last

    wait_output(PIPE + 10);
    check("TC4: o_valid_pw0 asserted (last pixel)", o_valid_pw0 === 1'b1);
    $display("  TC4 o_data_pw0[15:0] = %0d (expect > TC3)", $signed(o_data_pw0[15:0]));

    // =========================================================
    // TC5: Mode 1 — merged output (pw0 out = pw0_mac + pw1_mac)
    //    pw1_valid nên = 0
    // =========================================================
    $display("\n=== TC5: Mode 1, merged output ===");
    do_reset;
    load_weight(0, 16'sh0100);
    load_weight(1, 16'sh0100);
    load_bias(16'sh0000);

    i_fifo_mode = 8'b00001000;
    send_feature(16'sh0100, 16'sh0100, 1'b1, 1'b1, 1'b1);  // mode=1
    wait_output(PIPE + 5);

    check("TC5: o_valid_pw0 asserted (mode 1)",  o_valid_pw0 === 1'b1);
    // Khi mode=1, pw1_adder được bypass (mode_pipe gated), relu1 không fire
    check("TC5: o_valid_pw1 = 0 in mode 1",      o_valid_pw1 === 1'b0);
    $display("  TC5 o_data_pw0[15:0] = %0d", $signed(o_data_pw0[15:0]));

    // =========================================================
    // TC6: stage_done & rst_stage
    // =========================================================
    $display("\n=== TC6: stage_done and rst_stage ===");
    do_reset;
    load_weight(0, 16'sh0100);
    load_weight(1, 16'sh0100);
    load_bias(16'sh0000);

    // fifo_mode = 8 → mode_max = 7 → stage_done cần 8*8 = 64 valid pulses
    // Để sim nhanh, dùng fifo_mode = 8'b00000010 (mode_max = 1 → 4 valid pulses)
    i_fifo_mode = 8'b00000010;

    // Gửi đủ pixel để trigger stage_done
    // count1_done khi count1 == 1 (mode_max=1), count2_done khi count2 == 1
    // Cần 4 last-pixel output: last=1 cho cả 4
    repeat(4) begin
        send_feature(16'sh0100, 16'sh0100, 1'b1, 1'b1, 1'b0);
    end

    repeat(PIPE + 5) @(posedge clk);
    check("TC6: o_stage_done asserted", o_stage_done === 1'b1);

    // Reset stage
    @(posedge clk);
    i_rst_stage = 1;
    @(posedge clk);
    i_rst_stage = 0;
    @(posedge clk);
    check("TC6: o_stage_done cleared after rst_stage", o_stage_done === 1'b0);

    // =========================================================
    // TC7: Overflow / saturation
    //   feature = 0x7FFF, weight = 0x7FFF → product rất lớn
    //   Sau quantize + sat → kết quả = 0x7FFF (max positive)
    //   Sau bias=0, relu → vẫn 0x7FFF
    // =========================================================
    $display("\n=== TC7: Saturation (large positive) ===");
    do_reset;
    load_weight(0, 16'sh7FFF);
    load_weight(1, 16'sh7FFF);
    load_bias(16'sh0000);

    i_fifo_mode = 8'b00001000;
    send_feature(16'sh7FFF, 16'sh7FFF, 1'b1, 1'b1, 1'b0);
    wait_output(PIPE + 5);

    check("TC7: o_valid_pw0 asserted",           o_valid_pw0 === 1'b1);
    check("TC7: pw0[15:0] saturated = 0x7FFF",   o_data_pw0[15:0] === 16'h7FFF);
    $display("  TC7 o_data_pw0[15:0] = 0x%04X", o_data_pw0[15:0]);

    // =========================================================
    // TC8: ReLU — kết quả âm phải bị clamp về 0
    //   feature = 0x0100 (dương nhỏ), weight = 0xFF00 (âm lớn ~= -256)
    //   → dot product âm → sau relu = 0
    // =========================================================
    $display("\n=== TC8: ReLU clamp negative to 0 ===");
    do_reset;
    load_weight(0, 16'shFF00);   // âm: -256
    load_weight(1, 16'shFF00);
    load_bias(16'sh0000);

    i_fifo_mode = 8'b00001000;
    send_feature(16'sh0100, 16'sh0100, 1'b1, 1'b1, 1'b0);
    wait_output(PIPE + 5);

    check("TC8: o_valid_pw0 asserted",       o_valid_pw0 === 1'b1);
    check("TC8: ReLU clamps negative to 0",  o_data_pw0[15:0] === 16'h0000);
    $display("  TC8 o_data_pw0[15:0] = 0x%04X", o_data_pw0[15:0]);

    // =========================================================
    // Summary
    // =========================================================
    $display("\n======================================");
    $display("  TOTAL PASS: %0d", pass_cnt);
    $display("  TOTAL FAIL: %0d", fail_cnt);
    $display("======================================\n");

    repeat(10) @(posedge clk);
    $finish;
end

// ---------------------------------------------------------------------------
// Monitor: in ra khi có output hợp lệ
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (o_valid_pw0)
        $display("  [MON] t=%0t | o_valid_pw0=1 | pw0[15:0]=%0d | pw1[15:0]=%0d | stage_done=%b",
                 $time,
                 $signed(o_data_pw0[15:0]),
                 $signed(o_data_pw1[15:0]),
                 o_stage_done);
end

// Timeout toàn cục
initial begin
    #500000;
    $display("[TIMEOUT] Simulation exceeded limit");
    $finish;
end

endmodule