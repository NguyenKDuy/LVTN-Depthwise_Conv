`timescale 1ns/1ps

module tb_pw_mac;

localparam DATA_WIDTH   = 16;
localparam IN_CHANNELS  = 16;
localparam OUT_CHANNELS = 16;
localparam BUS_F        = IN_CHANNELS * DATA_WIDTH;
localparam BUS_W        = OUT_CHANNELS * IN_CHANNELS * DATA_WIDTH;
localparam BUS_O        = OUT_CHANNELS * DATA_WIDTH;

reg                 clk;
reg                 rst_n;
reg                 i_valid;
reg  [6:0]          i_valid_pipe;
reg  [BUS_F-1:0]    i_data_feature;
reg  [BUS_W-1:0]    i_data_weight;
wire [BUS_O-1:0]    o_data;

integer pass_cnt;
integer fail_cnt;
integer oc;
integer ic;

reg signed [DATA_WIDTH-1:0] feat [0:IN_CHANNELS-1];
reg signed [DATA_WIDTH-1:0] weight [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];
reg signed [DATA_WIDTH-1:0] exp_lane [0:OUT_CHANNELS-1];
reg signed [DATA_WIDTH-1:0] got_lane;

pw_mac #(
    .DATA_WIDTH(DATA_WIDTH),
    .IN_CHANNELS(IN_CHANNELS),
    .OUT_CHANNELS(OUT_CHANNELS)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .i_valid(i_valid),
    .i_valid_pipe(i_valid_pipe),
    .i_data_feature(i_data_feature),
    .i_data_weight(i_data_weight),
    .o_data(o_data)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

function signed [15:0] quant_q10;
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
        quant_q10 = shifted[15:0];
end
endfunction

task do_reset;
begin
    rst_n         = 1'b0;
    i_valid       = 1'b0;
    i_valid_pipe  = 7'b0;
    i_data_feature = 0;
    i_data_weight  = 0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
end
endtask

task pack_input_bus;
begin
    i_data_feature = 0;
    i_data_weight  = 0;
    for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
        i_data_feature[ic*DATA_WIDTH +: DATA_WIDTH] = feat[ic];
    end
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
            i_data_weight[(oc*IN_CHANNELS+ic)*DATA_WIDTH +: DATA_WIDTH] = weight[oc][ic];
        end
    end
end
endtask

task calc_expected;
    integer sum;
begin
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        sum = 0;
        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
            sum = sum + feat[ic] * weight[oc][ic];
        end
        exp_lane[oc] = quant_q10(sum);
    end
end
endtask

task drive_one_sample;
    integer s;
begin
    @(negedge clk);
    i_valid      = 1'b1;
    i_valid_pipe = 7'b0;
    @(negedge clk);
    i_valid      = 1'b0;

    for (s = 0; s < 7; s = s + 1) begin
        i_valid_pipe = (7'b1 << s);
        @(negedge clk);
    end
    i_valid_pipe = 7'b0;
end
endtask

task check_output;
    input [127:0] tag;
    integer case_fail;
begin
    case_fail = 0;
    @(posedge clk);
    #1;
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        got_lane = o_data[oc*DATA_WIDTH +: DATA_WIDTH];
        if (got_lane !== exp_lane[oc]) begin
            $display("FAIL %0s oc=%0d got=%0d exp=%0d", tag, oc, got_lane, exp_lane[oc]);
            fail_cnt = fail_cnt + 1;
            case_fail = case_fail + 1;
        end
    end
    if (case_fail == 0) begin
        pass_cnt = pass_cnt + 1;
    end
end
endtask

initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    do_reset();

    // CASE 1
    for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
        feat[ic] = 16'sd32;
    end
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
            case (oc)
                0: weight[oc][ic] = 16'sd16;  // expected +8
                1: weight[oc][ic] = 16'sd32;  // expected +16
                2: weight[oc][ic] = -16'sd16; // expected -9 (round away from zero)
                default: weight[oc][ic] = (ic[0]) ? 16'sd20 : -16'sd20;
            endcase
        end
    end

    pack_input_bus();
    calc_expected();
    drive_one_sample();
    check_output("CASE1");

    // CASE 2
    for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
        feat[ic] = (ic < 8) ? 16'sd40 : -16'sd24;
    end
    for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
            weight[oc][ic] = ((oc + ic) % 3) - 1; // -1,0,1 pattern
        end
    end

    pack_input_bus();
    calc_expected();
    drive_one_sample();
    check_output("CASE2");

    $display("tb_pw_mac RESULT: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    $finish;
end

endmodule
