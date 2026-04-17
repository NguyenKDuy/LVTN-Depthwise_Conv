`timescale 1ns/1ps

module tb_psum_fifo;

localparam MAX_PTR    = 64;
localparam DATA_WIDTH = 16;
localparam OC         = 16;
localparam BUS_W      = OC * DATA_WIDTH;

reg                 clk;
reg                 rst_n;
reg  [7:0]          i_mode;
reg  [BUS_W-1:0]    i_data;
reg                 wr_en;
reg                 rd_en;
wire [BUS_W-1:0]    o_data;
wire                full;
wire                empty;

integer pass_cnt;
integer fail_cnt;
integer i;
integer lane0;
integer lane1;

reg [BUS_W-1:0] expected_mem [0:63];
reg [BUS_W-1:0] rcv;
reg [BUS_W-1:0] val;

psum_fifo #(
    .MAX_PTR(MAX_PTR),
    .DATA_WIDTH(DATA_WIDTH),
    .OC(OC)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .i_mode(i_mode),
    .i_data(i_data),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .o_data(o_data),
    .full(full),
    .empty(empty)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

task do_reset;
begin
    rst_n  = 1'b0;
    i_mode = 8'b0000_1000; // depth 64
    i_data = 0;
    wr_en  = 1'b0;
    rd_en  = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
end
endtask

task do_write;
    input [BUS_W-1:0] din;
begin
    @(negedge clk);
    i_data = din;
    wr_en  = 1'b1;
    rd_en  = 1'b0;
    @(negedge clk);
    wr_en  = 1'b0;
    i_data = 0;
end
endtask

task do_read;
    output [BUS_W-1:0] dout;
begin
    @(negedge clk);
    rd_en = 1'b1;
    wr_en = 1'b0;
    @(posedge clk);
    #1 dout = o_data;
    @(negedge clk);
    rd_en = 1'b0;
end
endtask

initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    do_reset();

    if (empty !== 1'b1 || full !== 1'b0) begin
        $display("FAIL: reset flags wrong empty=%b full=%b", empty, full);
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    // single write/read
    val = {16'h1234, 16'h00A5};
    do_write(val);
    if (empty !== 1'b0) begin
        $display("FAIL: empty should be 0 after one write");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    do_read(rcv);
    if (rcv !== val) begin
        $display("FAIL: single read mismatch got=%h exp=%h", rcv, val);
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    if (empty !== 1'b1) begin
        $display("FAIL: empty should return 1 after read back");
        fail_cnt = fail_cnt + 1;
    end

    // fill 64 entries and check full
    for (i = 0; i < 64; i = i + 1) begin
        lane1 = i;
        lane0 = i + 16;
        expected_mem[i] = {lane1[15:0], lane0[15:0]};
        do_write(expected_mem[i]);
    end

    if (full !== 1'b1) begin
        $display("FAIL: full should assert after 64 writes");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    // extra write should be blocked
    do_write({16'hDEAD, 16'hBEEF});
    if (full !== 1'b1) begin
        $display("FAIL: full deasserted unexpectedly after blocked write");
        fail_cnt = fail_cnt + 1;
    end

    // read all and verify FIFO order
    for (i = 0; i < 64; i = i + 1) begin
        do_read(rcv);
        if (rcv !== expected_mem[i]) begin
            $display("FAIL: FIFO order mismatch idx=%0d got=%h exp=%h", i, rcv, expected_mem[i]);
            fail_cnt = fail_cnt + 1;
        end
    end

    if (empty !== 1'b1) begin
        $display("FAIL: empty should assert after draining FIFO");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    $display("tb_psum_fifo RESULT: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    $finish;
end

endmodule
