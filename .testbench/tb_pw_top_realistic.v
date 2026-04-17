`timescale 1ns/1ps

module tb_pw_top_realistic;

localparam DATA_WIDTH   = 16;
localparam IN_CHANNELS  = 16;
localparam OUT_CHANNELS = 16;
localparam FIFO_MAX_PTR = 64*64;
localparam PIPE_DEPTH   = 10;

localparam WEIGHT_BUS   = 1024;
localparam FEATURE_BUS  = IN_CHANNELS * DATA_WIDTH * 2;   // 512
localparam OUTPUT_BUS   = OUT_CHANNELS * DATA_WIDTH;       // 256
localparam BIAS_BUS     = OUT_CHANNELS * DATA_WIDTH;       // 256
localparam WCOUNT       = OUT_CHANNELS * IN_CHANNELS;      // 256
localparam MAX_EXPECTED = 32;

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

wire [OUTPUT_BUS-1:0]  o_data_pw0;
wire                   o_valid_pw0;
wire [OUTPUT_BUS-1:0]  o_data_pw1;
wire                   o_valid_pw1;
wire                   o_stage_done;

reg signed [DATA_WIDTH-1:0] w_pw0 [0:WCOUNT-1];
reg signed [DATA_WIDTH-1:0] w_pw1 [0:WCOUNT-1];
reg signed [DATA_WIDTH-1:0] bias_pw0_model [0:OUT_CHANNELS-1];
reg signed [DATA_WIDTH-1:0] bias_pw1_model [0:OUT_CHANNELS-1];

reg signed [DATA_WIDTH-1:0] fifo0_model [0:OUT_CHANNELS-1];
reg signed [DATA_WIDTH-1:0] fifo1_model [0:OUT_CHANNELS-1];
integer fifo0_level;
integer fifo1_level;

reg [OUTPUT_BUS-1:0] exp_pw0_q [0:MAX_EXPECTED-1];
reg [OUTPUT_BUS-1:0] exp_pw1_q [0:MAX_EXPECTED-1];
reg                  exp_pw1_valid_q [0:MAX_EXPECTED-1];
integer exp_wr_ptr;
integer exp_rd_ptr;

integer pass_cnt;
integer fail_cnt;

integer cmp_mismatch0;
integer cmp_mismatch1;
integer cur_idx;
reg     sample_ok;

integer wait_cycles;

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
//    .o_feature_fire_dbg(),
//    .o_valid_pipe_dbg(),
//    .o_mode_pipe_dbg(),
//    .o_first_pipe_dbg(),
//    .o_last_pipe_dbg(),
//    .o_fifo0_rd_en_dbg(),
//    .o_fifo1_rd_en_dbg(),
//    .o_relu0_fifo_wr_en_dbg(),
//    .o_relu1_fifo_wr_en_dbg(),
//    .o_fifo0_full_dbg(),
//    .o_fifo0_empty_dbg(),
//    .o_fifo1_full_dbg(),
//    .o_fifo1_empty_dbg(),
//    .o_pw0_mac_out_dbg(),
//    .o_pw1_mac_out_dbg(),
//    .o_pw0_adder_out_dbg(),
//    .o_pw1_adder_out_dbg(),
//    .o_fifo0_out_dbg(),
//    .o_fifo1_out_dbg(),
//    .o_fifo0_delay0_dbg(),
//    .o_fifo0_delay1_dbg(),
//    .o_fifo1_delay0_dbg(),
//    .o_fifo1_delay1_dbg(),
//    .o_fifo0_empty_pipe0_dbg(),
//    .o_fifo0_empty_pipe1_dbg(),
//    .o_fifo1_empty_pipe0_dbg(),
//    .o_fifo1_empty_pipe1_dbg(),
//    .o_pw0_psum_out_dbg(),
//    .o_pw1_psum_out_dbg(),
//    .o_relu0_out_dbg(),
//    .o_relu1_out_dbg(),
//    .o_relu0_fifo_data_dbg(),
//    .o_relu1_fifo_data_dbg()
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    #500_000;
    $display("[%0t] TIMEOUT: simulation did not finish", $time);
    $finish;
end

function integer widx;
    input integer oc;
    input integer ic;
begin
    widx = oc * IN_CHANNELS + ic;
end
endfunction

function signed [DATA_WIDTH-1:0] sat16_from_int;
    input integer x;
begin
    if (x > 32767)
        sat16_from_int = 16'sh7FFF;
    else if (x < -32768)
        sat16_from_int = 16'sh8000;
    else
        sat16_from_int = x[DATA_WIDTH-1:0];
end
endfunction

function signed [DATA_WIDTH-1:0] sat_add16;
    input signed [DATA_WIDTH-1:0] a;
    input signed [DATA_WIDTH-1:0] b;
    integer s;
begin
    s = a + b;
    sat_add16 = sat16_from_int(s);
end
endfunction

function signed [DATA_WIDTH-1:0] quant_q10;
    input signed [63:0] in_val;
    reg signed [63:0] rounded;
    reg signed [63:0] shifted;
begin
    if (in_val >= 0)
        rounded = in_val + 64'sd512;
    else
        rounded = in_val - 64'sd512;

    shifted = rounded >>> 10;

    if (shifted > 32767)
        quant_q10 = 16'sh7FFF;
    else if (shifted < -32768)
        quant_q10 = 16'sh8000;
    else
        quant_q10 = shifted[DATA_WIDTH-1:0];
end
endfunction

function signed [DATA_WIDTH-1:0] relu16;
    input signed [DATA_WIDTH-1:0] x;
begin
    if (x[DATA_WIDTH-1])
        relu16 = {DATA_WIDTH{1'b0}};
    else
        relu16 = x;
end
endfunction

function signed [DATA_WIDTH-1:0] gen_feat0;
    input integer sample_id;
    input integer ic;
    integer t;
begin
    t = (((sample_id + 1) * 17 + ic * 5) % 61) - 30;
    if (((sample_id + ic) % 4) == 0)
        t = -t;
    gen_feat0 = t;
end
endfunction

function signed [DATA_WIDTH-1:0] gen_feat1;
    input integer sample_id;
    input integer ic;
    integer t;
begin
    t = (((sample_id + 3) * 11 + ic * 9) % 57) - 28;
    if (((sample_id + ic) % 5) == 0)
        t = -t;
    gen_feat1 = t;
end
endfunction

task clear_inputs;
begin
    i_weight_valid0  = 1'b0;
    i_weight_valid1  = 1'b0;
    i_data_weight_pw = {WEIGHT_BUS{1'b0}};

    i_feature_valid  = 1'b0;
    i_data_feature   = {FEATURE_BUS{1'b0}};

    i_bias_valid0    = 1'b0;
    i_bias_valid1    = 1'b0;
    i_bias_pw        = {BIAS_BUS{1'b0}};

    i_mode           = 1'b0;
    i_is_first       = 1'b0;
    i_is_last        = 1'b0;
    i_rst_stage      = 1'b0;
    i_fifo_mode      = 8'b0000_1000;  // FIFO depth = 64
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

task init_model_tables;
    integer oc;
    integer ic;
    integer idx;
    integer tmp0;
    integer tmp1;
begin
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
            idx = widx(oc, ic);

            tmp0 = ((oc * 13 + ic * 7 + 5) % 41) - 20;
            if (((oc + ic) % 3) == 0) tmp0 = -tmp0;
            w_pw0[idx] = tmp0;

            tmp1 = ((oc * 9 + ic * 11 + 3) % 37) - 18;
            if (((oc + 2*ic) % 4) == 0) tmp1 = -tmp1;
            w_pw1[idx] = tmp1;
        end

        bias_pw0_model[oc] = ((oc * 5 + 7) % 19) - 9;
        bias_pw1_model[oc] = ((oc * 3 + 4) % 17) - 8;

        fifo0_model[oc] = 0;
        fifo1_model[oc] = 0;
    end

    fifo0_level = 0;
    fifo1_level = 0;
    exp_wr_ptr  = 0;
    exp_rd_ptr  = 0;
end
endtask

task build_weight_packet;
    input integer block_id;  // 0 -> pw0, 1 -> pw1
    input integer phase;     // 0..3
    output reg [WEIGHT_BUS-1:0] packet;
    integer oc;
    integer k;
    integer ic;
    integer idx;
    reg signed [DATA_WIDTH-1:0] w_lane;
begin
    packet = {WEIGHT_BUS{1'b0}};
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        for (k = 0; k < 4; k = k + 1) begin
            ic  = phase * 4 + k;
            idx = widx(oc, ic);
            if (block_id == 0)
                w_lane = w_pw0[idx];
            else
                w_lane = w_pw1[idx];

            packet[oc*64 + k*DATA_WIDTH +: DATA_WIDTH] = w_lane;
        end
    end
end
endtask

task load_weights_for_block;
    input integer block_id; // 0 -> pw0, 1 -> pw1
    integer phase;
    integer pushes;
    reg [WEIGHT_BUS-1:0] pkt;
begin
    pushes = 0;
    for (phase = 0; phase < 4; phase = phase + 1) begin
        build_weight_packet(block_id, phase, pkt);
        @(negedge clk);
        i_data_weight_pw = pkt;
        i_weight_valid0  = (block_id == 0);
        i_weight_valid1  = (block_id == 1);
        pushes = pushes + 1;
    end

    @(negedge clk);
    i_weight_valid0  = 1'b0;
    i_weight_valid1  = 1'b0;
    i_data_weight_pw = {WEIGHT_BUS{1'b0}};

    repeat (2) @(posedge clk);

    if (pushes != 4) begin
        $display("[%0t] FAIL: block %0d weight pushes=%0d (must be 4)", $time, block_id, pushes);
        fail_cnt = fail_cnt + 1;
    end

    if (block_id == 0) begin
        if (!dut.pw0_weight_valid) begin
            $display("[%0t] FAIL: pw0_weight_valid is not asserted after 4 pushes", $time);
            fail_cnt = fail_cnt + 1;
        end
    end else begin
        if (!dut.pw1_weight_valid) begin
            $display("[%0t] FAIL: pw1_weight_valid is not asserted after 4 pushes", $time);
            fail_cnt = fail_cnt + 1;
        end
    end

    $display("[%0t] INFO: block %0d loaded with 4 weight pushes", $time, block_id);
end
endtask

task load_bias_for_block;
    input integer block_id; // 0 -> pw0, 1 -> pw1
    integer oc;
    reg [BIAS_BUS-1:0] bias_bus;
begin
    bias_bus = {BIAS_BUS{1'b0}};
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        if (block_id == 0)
            bias_bus[oc*DATA_WIDTH +: DATA_WIDTH] = bias_pw0_model[oc];
        else
            bias_bus[oc*DATA_WIDTH +: DATA_WIDTH] = bias_pw1_model[oc];
    end

    @(negedge clk);
    i_bias_pw     = bias_bus;
    i_bias_valid0 = (block_id == 0);
    i_bias_valid1 = (block_id == 1);

    @(negedge clk);
    i_bias_valid0 = 1'b0;
    i_bias_valid1 = 1'b0;
    i_bias_pw     = {BIAS_BUS{1'b0}};
end
endtask

task compare_bus;
    input [OUTPUT_BUS-1:0] got_bus;
    input [OUTPUT_BUS-1:0] exp_bus;
    input [127:0] tag;
    output integer mismatch_count;
    integer oc;
    reg signed [DATA_WIDTH-1:0] got_lane;
    reg signed [DATA_WIDTH-1:0] exp_lane;
begin
    mismatch_count = 0;
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        got_lane = got_bus[oc*DATA_WIDTH +: DATA_WIDTH];
        exp_lane = exp_bus[oc*DATA_WIDTH +: DATA_WIDTH];
        if (got_lane !== exp_lane) begin
            mismatch_count = mismatch_count + 1;
            $display("[%0t] FAIL %0s ch%0d got=%0d exp=%0d", $time, tag, oc, got_lane, exp_lane);
        end
    end
end
endtask

task model_and_drive_pixel;
    input integer sample_id;
    input mode_val;
    input first_val;
    input last_val;
    integer oc;
    integer ic;
    integer idx;
    reg [FEATURE_BUS-1:0] feat_bus;
    reg [OUTPUT_BUS-1:0] out0_bus;
    reg [OUTPUT_BUS-1:0] out1_bus;
    reg signed [63:0] acc0;
    reg signed [63:0] acc1;
    reg signed [DATA_WIDTH-1:0] f0;
    reg signed [DATA_WIDTH-1:0] f1;
    reg signed [DATA_WIDTH-1:0] mac0;
    reg signed [DATA_WIDTH-1:0] mac1;
    reg signed [DATA_WIDTH-1:0] add0;
    reg signed [DATA_WIDTH-1:0] add1;
    reg signed [DATA_WIDTH-1:0] psum0;
    reg signed [DATA_WIDTH-1:0] psum1;
    reg signed [DATA_WIDTH-1:0] with_bias;
    reg fifo_empty0;
    reg fifo_empty1;
begin
    feat_bus = {FEATURE_BUS{1'b0}};
    out0_bus = {OUTPUT_BUS{1'b0}};
    out1_bus = {OUTPUT_BUS{1'b0}};

    for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
        f0 = gen_feat0(sample_id, ic);
        f1 = gen_feat1(sample_id, ic);
        feat_bus[ic*DATA_WIDTH +: DATA_WIDTH] = f0;
        feat_bus[(IN_CHANNELS + ic)*DATA_WIDTH +: DATA_WIDTH] = f1;
    end

    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        acc0 = 0;
        acc1 = 0;
        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
            idx = widx(oc, ic);
            acc0 = acc0 + $signed(gen_feat0(sample_id, ic)) * $signed(w_pw0[idx]);
            acc1 = acc1 + $signed(gen_feat1(sample_id, ic)) * $signed(w_pw1[idx]);
        end

        mac0 = quant_q10(acc0);
        mac1 = quant_q10(acc1);

        if (mode_val) begin
            add0 = sat_add16(mac0, mac1);
            add1 = 0;
        end else begin
            add0 = mac0;
            add1 = mac1;
        end

        fifo_empty0 = (fifo0_level == 0);
        if (first_val || fifo_empty0)
            psum0 = add0;
        else
            psum0 = sat_add16(add0, fifo0_model[oc]);

        if (!mode_val) begin
            fifo_empty1 = (fifo1_level == 0);
            if (first_val || fifo_empty1)
                psum1 = add1;
            else
                psum1 = sat_add16(add1, fifo1_model[oc]);
        end else begin
            psum1 = 0;
        end

        if (last_val) begin
            with_bias = sat_add16(psum0, bias_pw0_model[oc]);
            out0_bus[oc*DATA_WIDTH +: DATA_WIDTH] = relu16(with_bias);

            if (!mode_val) begin
                with_bias = sat_add16(psum1, bias_pw1_model[oc]);
                out1_bus[oc*DATA_WIDTH +: DATA_WIDTH] = relu16(with_bias);
            end
        end else begin
            fifo0_model[oc] = psum0;
            if (!mode_val)
                fifo1_model[oc] = psum1;
        end
    end

    if (!last_val)
        fifo0_level = 1;
    else
        fifo0_level = 0;

    if (!mode_val) begin
        if (!last_val)
            fifo1_level = 1;
        else
            fifo1_level = 0;
    end

    if (last_val) begin
        if (exp_wr_ptr >= MAX_EXPECTED) begin
            $display("[%0t] FAIL: expected queue overflow", $time);
            fail_cnt = fail_cnt + 1;
        end else begin
            exp_pw0_q[exp_wr_ptr]       = out0_bus;
            exp_pw1_q[exp_wr_ptr]       = out1_bus;
            exp_pw1_valid_q[exp_wr_ptr] = ~mode_val;
            exp_wr_ptr                  = exp_wr_ptr + 1;
        end
    end

    // Drive exactly one valid pulse (1 cycle)
    @(negedge clk);
    i_feature_valid = 1'b1;
    i_mode          = mode_val;
    i_is_first      = first_val;
    i_is_last       = last_val;
    i_data_feature  = feat_bus;

    @(negedge clk);
    i_feature_valid = 1'b0;
    i_mode          = 1'b0;
    i_is_first      = 1'b0;
    i_is_last       = 1'b0;
    i_data_feature  = {FEATURE_BUS{1'b0}};
end
endtask

task stop_feature_stream;
begin
    @(negedge clk);
    i_feature_valid = 1'b0;
    i_mode          = 1'b0;
    i_is_first      = 1'b0;
    i_is_last       = 1'b0;
    i_data_feature  = {FEATURE_BUS{1'b0}};
end
endtask

task gap_cycles;
    input integer n;
    integer g;
begin
    for (g = 0; g < n; g = g + 1) begin
        @(negedge clk);
        i_feature_valid = 1'b0;
        i_mode          = 1'b0;
        i_is_first      = 1'b0;
        i_is_last       = 1'b0;
        i_data_feature  = {FEATURE_BUS{1'b0}};
    end
end
endtask

always @(posedge clk) begin
    if (!rst_n) begin
        // do nothing
    end else begin
        if (o_valid_pw0) begin
            if (exp_rd_ptr >= exp_wr_ptr) begin
                $display("[%0t] FAIL: unexpected pw0 output (queue empty)", $time);
                fail_cnt = fail_cnt + 1;
            end else begin
                cur_idx = exp_rd_ptr;
                sample_ok = 1'b1;

                compare_bus(o_data_pw0, exp_pw0_q[cur_idx], "PW0", cmp_mismatch0);
                if (cmp_mismatch0 != 0)
                    sample_ok = 1'b0;

                if (exp_pw1_valid_q[cur_idx]) begin
                    if (!o_valid_pw1) begin
                        $display("[%0t] FAIL: missing pw1 valid for sample %0d", $time, cur_idx);
                        sample_ok = 1'b0;
                    end else begin
                        compare_bus(o_data_pw1, exp_pw1_q[cur_idx], "PW1", cmp_mismatch1);
                        if (cmp_mismatch1 != 0)
                            sample_ok = 1'b0;
                    end
                end else if (o_valid_pw1) begin
                    $display("[%0t] FAIL: unexpected pw1 valid for sample %0d", $time, cur_idx);
                    sample_ok = 1'b0;
                end

                if (sample_ok) begin
                    pass_cnt = pass_cnt + 1;
                    $display("[%0t] PASS: output sample %0d matched", $time, cur_idx);
                end else begin
                    fail_cnt = fail_cnt + 1;
                end

                exp_rd_ptr = exp_rd_ptr + 1;
            end
        end else if (o_valid_pw1) begin
            $display("[%0t] FAIL: pw1 valid asserted without pw0 valid", $time);
            fail_cnt = fail_cnt + 1;
        end
    end
end

initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    $display("============================================================");
    $display("TB: tb_pw_top_realistic");
    $display("Goal: realistic stream + 4 weight pushes for each pw block");
    $display("============================================================");

    do_reset();
    init_model_tables();

    // 1) Load weights: exactly 4 pushes for pw0 and 4 pushes for pw1
    load_weights_for_block(0);
    load_weights_for_block(1);

    // 2) Load biases independently
    load_bias_for_block(0);
    load_bias_for_block(1);

    // 3) Frame A: mode=0, 3 pixels (first/mid/last)
    model_and_drive_pixel(0, 1'b0, 1'b1, 1'b0);
    gap_cycles(1);
    model_and_drive_pixel(1, 1'b0, 1'b0, 1'b0);
    gap_cycles(1);
    model_and_drive_pixel(2, 1'b0, 1'b0, 1'b1);
    stop_feature_stream();

    repeat (3) @(posedge clk);

    // 4) Frame B: mode=1, 2 pixels (first/last)
    model_and_drive_pixel(10, 1'b1, 1'b1, 1'b0);
    gap_cycles(1);
    model_and_drive_pixel(11, 1'b1, 1'b0, 1'b1);
    stop_feature_stream();

    repeat (2) @(posedge clk);

    // 5) Frame C: mode=0, 1 pixel (first=last)
    model_and_drive_pixel(20, 1'b0, 1'b1, 1'b1);
    stop_feature_stream();

    // wait until all expected outputs are checked
    wait_cycles = 0;
    while ((exp_rd_ptr < exp_wr_ptr) && (wait_cycles < 400)) begin
        @(posedge clk);
        wait_cycles = wait_cycles + 1;
    end

    if (exp_rd_ptr != exp_wr_ptr) begin
        $display("[%0t] FAIL: output timeout exp_rd=%0d exp_wr=%0d",
                 $time, exp_rd_ptr, exp_wr_ptr);
        fail_cnt = fail_cnt + 1;
    end

    $display("============================================================");
    $display("RESULT: PASS=%0d  FAIL=%0d  stage_done=%b", pass_cnt, fail_cnt, o_stage_done);
    if (fail_cnt == 0)
        $display("ALL CHECKS PASSED");
    else
        $display("SOME CHECKS FAILED");
    $display("============================================================");

    $finish;
end

endmodule
