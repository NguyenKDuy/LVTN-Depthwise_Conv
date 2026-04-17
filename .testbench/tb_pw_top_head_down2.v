`timescale 1ns/1ps

module tb_pw_top_head_down2;

localparam DATA_WIDTH   = 16;
localparam IN_CHANNELS  = 16;
localparam OUT_CHANNELS = 16;
localparam FIFO_MAX_PTR = 64*64;
localparam PIPE_DEPTH   = 10;

localparam WEIGHT_BUS   = 1024;
localparam FEATURE_BUS  = IN_CHANNELS * DATA_WIDTH * 2;
localparam BIAS_BUS     = OUT_CHANNELS * DATA_WIDTH;

reg                    clk;
reg                    rst_n;
reg                    i_weight_valid0;
reg                    i_weight_valid1;
reg  [WEIGHT_BUS-1:0]  i_data_weight_pw;
reg                    i_feature_valid;
reg  [FEATURE_BUS-1:0] i_data_feature;
reg                    i_bias_valid0;
reg                    i_bias_valid1;
reg  [BIAS_BUS-1:0]    i_bias_pw;
reg                    i_mode;
reg                    i_is_first;
reg                    i_is_last;
reg                    i_rst_stage;
reg  [7:0]             i_fifo_mode;

wire [BIAS_BUS-1:0]    o_data_pw0;
wire                   o_valid_pw0;
wire [BIAS_BUS-1:0]    o_data_pw1;
wire                   o_valid_pw1;
wire                   o_stage_done;

integer pass_cnt;
integer fail_cnt;

reg [1:0] phase_id;
integer head_out0_cnt;
integer head_out1_cnt;
integer down2_out0_cnt;
integer down2_out1_cnt;
integer down2_wr0_cnt;
integer down2_wr1_cnt;
integer down2_rd0_cnt;
integer down2_rd1_cnt;

pw_top #(
    .DATA_WIDTH(DATA_WIDTH),
    .IN_CHANNELS(IN_CHANNELS),
    .OUT_CHANNELS(OUT_CHANNELS),
    .FIFO_MAX_PTR(FIFO_MAX_PTR),
    .PIPE_DEPTH(PIPE_DEPTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .i_weight_valid0(i_weight_valid0),
    .i_weight_valid1(i_weight_valid1),
    .i_data_weight_pw(i_data_weight_pw),
    .i_feature_valid(i_feature_valid),
    .i_data_feature(i_data_feature),
    .i_bias_valid0(i_bias_valid0),
    .i_bias_valid1(i_bias_valid1),
    .i_bias_pw(i_bias_pw),
    .i_mode(i_mode),
    .i_is_first(i_is_first),
    .i_is_last(i_is_last),
    .i_rst_stage(i_rst_stage),
    .i_fifo_mode(i_fifo_mode),
    .o_data_pw0(o_data_pw0),
    .o_valid_pw0(o_valid_pw0),
    .o_data_pw1(o_data_pw1),
    .o_valid_pw1(o_valid_pw1),
    .o_stage_done(o_stage_done)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    #700_000;
    $display("[%0t] TIMEOUT", $time);
    $finish;
end

function [WEIGHT_BUS-1:0] make_weight_packet;
    input [15:0] w0;
    input [15:0] w1;
    input [15:0] w2;
    input [15:0] w3;
    integer k;
    reg [WEIGHT_BUS-1:0] t;
begin
    t = 0;
    for (k = 0; k < WEIGHT_BUS/64; k = k + 1) begin
        t[k*64 +: 16]      = w0;
        t[k*64 + 16 +: 16] = w1;
        t[k*64 + 32 +: 16] = w2;
        t[k*64 + 48 +: 16] = w3;
    end
    make_weight_packet = t;
end
endfunction

function [BIAS_BUS-1:0] make_bias_bus;
    input [15:0] b;
    integer oc;
    reg [BIAS_BUS-1:0] t;
begin
    t = 0;
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        t[oc*DATA_WIDTH +: DATA_WIDTH] = b;
    end
    make_bias_bus = t;
end
endfunction

function [FEATURE_BUS-1:0] make_feature_bus;
    input [15:0] f0;
    input [15:0] f1;
    integer ic;
    reg [FEATURE_BUS-1:0] t;
begin
    t = 0;
    for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
        t[ic*DATA_WIDTH +: DATA_WIDTH] = f0;
        t[(IN_CHANNELS + ic)*DATA_WIDTH +: DATA_WIDTH] = f1;
    end
    make_feature_bus = t;
end
endfunction

task clear_inputs;
begin
    i_weight_valid0  = 1'b0;
    i_weight_valid1  = 1'b0;
    i_data_weight_pw = 0;
    i_feature_valid  = 1'b0;
    i_data_feature   = 0;
    i_bias_valid0    = 1'b0;
    i_bias_valid1    = 1'b0;
    i_bias_pw        = 0;
    i_mode           = 1'b0;
    i_is_first       = 1'b0;
    i_is_last        = 1'b0;
    i_rst_stage      = 1'b0;
    i_fifo_mode      = 8'b0000_1000; // depth 64
end
endtask

task do_reset;
begin
    clear_inputs();
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
end
endtask

task load_weight_pw0_4x;
begin
    @(negedge clk);
    i_weight_valid0  = 1'b1;
    i_data_weight_pw = make_weight_packet(16'h0001, 16'h0001, 16'h0001, 16'h0001); // W=1
    @(negedge clk);
    i_data_weight_pw = make_weight_packet(16'h0002, 16'h0002, 16'h0002, 16'h0002); // W=2
    @(negedge clk);
    i_data_weight_pw = make_weight_packet(16'h0003, 16'h0003, 16'h0003, 16'h0003); // W=3
    @(negedge clk);
    i_data_weight_pw = 0; // Padding chu k? 4
    @(negedge clk);
    i_weight_valid0  = 1'b0;
end
endtask

task load_weight_pw1_4x;
begin
    @(negedge clk);
    i_weight_valid0  = 1'b0; // Ð?m b?o valid0 t?t
    i_weight_valid1  = 1'b1;
    
    // N?p tr?ng s? cho pw1 (ví d? cho gi?ng pw0 ð? d? so sánh)
    i_data_weight_pw = make_weight_packet(16'h0001, 16'h0001, 16'h0001, 16'h0001); 
    @(negedge clk);
    i_data_weight_pw = make_weight_packet(16'h0002, 16'h0002, 16'h0002, 16'h0002);
    @(negedge clk);
    i_data_weight_pw = make_weight_packet(16'h0003, 16'h0003, 16'h0003, 16'h0003);
    @(negedge clk);
    i_data_weight_pw = 0;
    
    @(negedge clk);
    i_weight_valid1  = 1'b0;
    i_data_weight_pw = 0;
    
    repeat (2) @(posedge clk);
    $display("[%0t] load pw1 done", $time);
end
endtask

task load_bias_pw0;
begin
    @(negedge clk);
    i_bias_valid0 = 1'b1;
    i_bias_pw     = make_bias_bus(16'h0008); // Bias = 8
    @(negedge clk);
    i_bias_valid0 = 1'b0;
end
endtask

task load_bias_pw1;
begin
    @(negedge clk);
    i_bias_valid0 = 1'b0;
    i_bias_valid1 = 1'b1;
    i_bias_pw     = make_bias_bus(16'h0001);
    @(negedge clk);
    i_bias_valid1 = 1'b0;
    i_bias_pw     = 0;
end
endtask

task send_feature_1cycle;
    input [15:0] f0;
    input [15:0] f1;
    input        first_v;
    input        last_v;
    input        mode_v;
begin
    @(negedge clk);
    i_data_feature  = make_feature_bus(f0, f1);
    i_mode          = mode_v;
    i_is_first      = first_v;
    i_is_last       = last_v;
    i_feature_valid = 1'b1;

    @(negedge clk);
    i_feature_valid = 1'b0;
    i_mode          = 1'b0;
    i_is_first      = 1'b0;
    i_is_last       = 1'b0;
    i_data_feature  = 0;
end
endtask

task send_head_15cycles;
    integer n;
begin
    for (n = 0; n < 15; n = n + 1) begin
        @(negedge clk);
        i_data_feature  = make_feature_bus(16'h0020 + n[15:0], 16'h0018 + n[15:0]);
        i_mode          = 1'b0;
        i_is_first      = 1'b1;
        i_is_last       = 1'b1;
        i_feature_valid = 1'b1;
    end

    @(negedge clk);
    i_feature_valid = 1'b0;
    i_mode          = 1'b0;
    i_is_first      = 1'b0;
    i_is_last       = 1'b0;
    i_data_feature  = 0;
end
endtask

always @(posedge clk) begin
    if (rst_n) begin
        if (o_valid_pw0) begin
            if (phase_id == 2'd1) head_out0_cnt = head_out0_cnt + 1;
            if (phase_id == 2'd2) down2_out0_cnt = down2_out0_cnt + 1;
            $display("[%0t] OUT pw0_valid=1 lane0=%0d phase=%0d",
                     $time, $signed(o_data_pw0[15:0]), phase_id);
        end

        if (o_valid_pw1) begin
            if (phase_id == 2'd1) head_out1_cnt = head_out1_cnt + 1;
            if (phase_id == 2'd2) down2_out1_cnt = down2_out1_cnt + 1;
            $display("[%0t] OUT pw1_valid=1 lane0=%0d phase=%0d",
                     $time, $signed(o_data_pw1[15:0]), phase_id);
        end

        if (phase_id == 2'd2) begin
            if (dut.relu0_fifo_wr_en) down2_wr0_cnt = down2_wr0_cnt + 1;
            if (dut.relu1_fifo_wr_en) down2_wr1_cnt = down2_wr1_cnt + 1;
            if (dut.fifo0_rd_en)      down2_rd0_cnt = down2_rd0_cnt + 1;
            if (dut.fifo1_rd_en)      down2_rd1_cnt = down2_rd1_cnt + 1;

            if (dut.relu0_fifo_wr_en || dut.relu1_fifo_wr_en || dut.fifo0_rd_en || dut.fifo1_rd_en) begin
                $display("[%0t] DOWN2 FIFO: wr0=%b wr1=%b rd0=%b rd1=%b fifo0_empty=%b fifo1_empty=%b",
                         $time,
                         dut.relu0_fifo_wr_en, dut.relu1_fifo_wr_en,
                         dut.fifo0_rd_en, dut.fifo1_rd_en,
                         dut.fifo0_empty, dut.fifo1_empty);
            end
        end
    end
end



reg signed [31:0] golden_pw0;
reg signed [31:0] current_val;

task check_down2_accuracy;
    reg signed [31:0] expected_val;
begin
    expected_val = 200; // S? ð?p ð? tính toán
    
    $display("[%0t] [GOLDEN] Expected: %d (0x%h)", $time, expected_val, expected_val);
    
    wait(o_valid_pw0 == 1'b1);
    #1; // Ð?i signal ?n ð?nh
    
    if ($signed(o_data_pw0[15:0]) == expected_val[15:0]) begin
        $display("[%0t] SUCCESS: PW0 = %d", $time, $signed(o_data_pw0[15:0]));
    end else begin
        $display("[%0t] ERROR: PW0 = %d, Expected = %d", 
                  $time, $signed(o_data_pw0[15:0]), expected_val[15:0]);
    end
end
endtask



initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    phase_id = 0;
    head_out0_cnt = 0;
    head_out1_cnt = 0;
    down2_out0_cnt = 0;
    down2_out1_cnt = 0;
    down2_wr0_cnt = 0;
    down2_wr1_cnt = 0;
    down2_rd0_cnt = 0;
    down2_rd1_cnt = 0;

    $display("============================================================");
    $display("TB pw_top: HEAD + DOWN2");
    $display("1) nap weight pw0/pw1 (moi block 4 lan)");
    $display("2) nap bias");
    $display("3) HEAD: first=last=1 trong 15 chu ky");
    $display("4) DOWN2: bat buoc FIFO partial-sum, quan sat wr/rd");
    $display("============================================================");

    do_reset();
    load_weight_pw0_4x();
    load_weight_pw1_4x();
    load_bias_pw0();
    load_bias_pw1();

//     ------------------------
//     LAYER HEAD
//     is_first = is_last = 1 trong 15 chu ky
//     ------------------------
    phase_id = 2'd1;
    send_head_15cycles();

    // cho pipeline flush het output HEAD
    repeat (40) @(posedge clk);

    if (head_out0_cnt == 15 && head_out1_cnt == 15) begin
        $display("HEAD PASS: so output dung (pw0=%0d, pw1=%0d)", head_out0_cnt, head_out1_cnt);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("HEAD FAIL: so output sai (pw0=%0d, pw1=%0d), ky vong = 15", head_out0_cnt, head_out1_cnt);
        fail_cnt = fail_cnt + 1;
    end

//     ------------------------
//     LAYER DOWN2
//     bat buoc dung FIFO partial-sum:
//     sample0: first=1,last=0 -> write FIFO
//     sample1: first=0,last=0 -> read + write FIFO
//     sample2: first=0,last=1 -> read FIFO va output
//     ------------------------
    phase_id = 2'd2;
    down2_out0_cnt = 0;
    down2_out1_cnt = 0;
    down2_wr0_cnt  = 0;
    down2_wr1_cnt  = 0;
    down2_rd0_cnt  = 0;
    down2_rd1_cnt  = 0;

    send_feature_1cycle(16'h0024, 16'h001C, 1'b1, 1'b0, 1'b0);
    send_feature_1cycle(16'h0025, 16'h001D, 1'b0, 1'b0, 1'b0);
    send_feature_1cycle(16'h0026, 16'h001E, 1'b0, 1'b1, 1'b0);

    // cho pipeline va FIFO settle
    repeat (50) @(posedge clk);

    if (down2_wr0_cnt >= 2 && down2_wr1_cnt >= 2 && down2_rd0_cnt >= 2 && down2_rd1_cnt >= 2) begin
        $display("DOWN2 FIFO PASS: wr0=%0d wr1=%0d rd0=%0d rd1=%0d",
                 down2_wr0_cnt, down2_wr1_cnt, down2_rd0_cnt, down2_rd1_cnt);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("DOWN2 FIFO FAIL: wr0=%0d wr1=%0d rd0=%0d rd1=%0d (ky vong moi loai >=2)",
                 down2_wr0_cnt, down2_wr1_cnt, down2_rd0_cnt, down2_rd1_cnt);
        fail_cnt = fail_cnt + 1;
    end

    if (down2_out0_cnt >= 1 && down2_out1_cnt >= 1) begin
        $display("DOWN2 OUT PASS: co output cuoi (pw0=%0d, pw1=%0d)",
                 down2_out0_cnt, down2_out1_cnt);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("DOWN2 OUT FAIL: thieu output cuoi (pw0=%0d, pw1=%0d)",
                 down2_out0_cnt, down2_out1_cnt);
        fail_cnt = fail_cnt + 1;
    end

    phase_id = 0;

    $display("============================================================");
    $display("RESULT: PASS=%0d FAIL=%0d stage_done=%b", pass_cnt, fail_cnt, o_stage_done);
    if (fail_cnt == 0) $display("ALL TESTS PASSED");
    else               $display("SOME TESTS FAILED");
    $display("============================================================");


//// ... (ðo?n g?i d? li?u DOWN2 c?)
//// Sample 0: first=1, f=1, w=1 -> Out = 32
//    send_feature_1cycle(16'h0001, 16'h0001, 1'b1, 1'b0, 1'b0); 
//    // Sample 1: middle, f=1, w=2 -> Out = 32 + 64 = 96
//    send_feature_1cycle(16'h0001, 16'h0001, 1'b0, 1'b0, 1'b0);
//    // Sample 2: last=1, f=1, w=3 -> Out = 96 + 96 + 8(bias) = 200
//    send_feature_1cycle(16'h0001, 16'h0001, 1'b0, 1'b1, 1'b0);

//    // G?i hàm ki?m tra ð? chính xác
//    check_down2_accuracy(); 

    repeat (50) @(posedge clk);
    // ...
end

endmodule
