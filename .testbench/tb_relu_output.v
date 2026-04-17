`timescale 1ns/1ps

module tb_relu_output;

localparam DATA_WIDTH = 16;
localparam CHANNELS   = 4;
localparam BUS_W      = DATA_WIDTH * CHANNELS;

reg              clk;
reg              rst_n;
reg              i_valid;
reg              i_is_last;
reg  [BUS_W-1:0] i_data;
reg  [BUS_W-1:0] i_bias;

wire             o_fifo_wr_en;
wire [BUS_W-1:0] o_fifo_data;
wire [BUS_W-1:0] o_data;
wire             o_valid;

integer pass_cnt;
integer fail_cnt;

reg [BUS_W-1:0] exp_out;

relu_output #(
    .DATA_WIDTH(DATA_WIDTH),
    .CHANNELS(CHANNELS)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .i_valid(i_valid),
    .i_is_last(i_is_last),
    .i_data(i_data),
    .i_bias(i_bias),
    .o_fifo_wr_en(o_fifo_wr_en),
    .o_fifo_data(o_fifo_data),
    .o_data(o_data),
    .o_valid(o_valid)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

task do_reset;
begin
    rst_n      = 1'b0;
    i_valid    = 1'b0;
    i_is_last  = 1'b0;
    i_data     = 0;
    i_bias     = 0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
end
endtask

initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    do_reset();

    if (o_valid !== 1'b0 || o_data !== 0) begin
        $display("FAIL: reset output wrong");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    // case 1: FIFO path (i_is_last=0)
    @(negedge clk);
    i_valid   = 1'b1;
    i_is_last = 1'b0;
    i_data    = {16'h0004, 16'h0003, 16'h0002, 16'h0001};
    i_bias    = {16'h0001, 16'h0001, 16'h0001, 16'h0001};
    @(posedge clk);
    #1;
    if (o_fifo_wr_en !== 1'b1 || o_fifo_data !== i_data || o_valid !== 1'b0) begin
        $display("FAIL: FIFO path behavior wrong");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end
    @(negedge clk);
    i_valid   = 1'b0;
    i_is_last = 1'b0;
    i_data    = 0;
    i_bias    = 0;

    // case 2: output path + sat add + relu
    // lane0: 10 + 5 = 15
    // lane1: -20 + 1 = -19 -> relu 0
    // lane2: 32760 + 20 -> sat 32767
    // lane3: -32760 + (-20) -> sat -32768 -> relu 0
    exp_out = {16'h0000, 16'h7FFF, 16'h0000, 16'h000F};

    @(negedge clk);
    i_valid   = 1'b1;
    i_is_last = 1'b1;
    i_data    = {16'h8008, 16'h7FF8, 16'hFFEC, 16'h000A};
    i_bias    = {16'hFFEC, 16'h0014, 16'h0001, 16'h0005};
    @(posedge clk);
    #1;
    if (o_fifo_wr_en !== 1'b0 || o_valid !== 1'b1 || o_data !== exp_out) begin
        $display("FAIL: output path mismatch got=%h exp=%h valid=%b", o_data, exp_out, o_valid);
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    @(negedge clk);
    i_valid   = 1'b0;
    i_is_last = 1'b0;
    i_data    = 0;
    i_bias    = 0;
    @(posedge clk);
    #1;
    if (o_valid !== 1'b0) begin
        $display("FAIL: o_valid should be pulse only");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    $display("tb_relu_output RESULT: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    $finish;
end

endmodule

