`timescale 1ns/1ps

module tb_weight_buffer;

localparam CLUSTER_SIZE = 256;
localparam NUM_CLUSTERS = 16;
localparam INPUT_WIDTH  = 1024;
localparam CHUNK_WIDTH  = 64;
localparam OUT_WIDTH    = 4096;

reg                   clk;
reg                   rst_n;
reg                   i_valid;
reg                   i_done_stage;
reg  [INPUT_WIDTH-1:0] i_data;
wire [OUT_WIDTH-1:0]   cluster_flat;
wire                  o_valid;

integer pass_cnt;
integer fail_cnt;

integer c;
integer p;
reg [63:0] got64;
reg [63:0] exp64;
reg [INPUT_WIDTH-1:0] phase_data [0:3];

weight_buffer #(
    .CLUSTER_SIZE(CLUSTER_SIZE),
    .NUM_CLUSTERS(NUM_CLUSTERS),
    .INPUT_WIDTH(INPUT_WIDTH),
    .CHUNK_WIDTH(CHUNK_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .i_valid(i_valid),
    .i_data(i_data),
    .i_done_stage(i_done_stage),
    .cluster_flat(cluster_flat),
    .o_valid(o_valid)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

task do_reset;
begin
    rst_n        = 1'b0;
    i_valid      = 1'b0;
    i_done_stage = 1'b0;
    i_data       = 0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
end
endtask

task build_phase_data;
    input integer phase;
    integer i;
    reg [INPUT_WIDTH-1:0] tmp;
begin
    tmp = 0;
    for (i = 0; i < INPUT_WIDTH/CHUNK_WIDTH; i = i + 1) begin
        tmp[i*CHUNK_WIDTH +: CHUNK_WIDTH] = (phase + 1) * 100 + i;
    end
    phase_data[phase] = tmp;
end
endtask

task push_phase;
    input integer phase;
begin
    @(negedge clk);
    i_valid = 1'b1;
    i_data  = phase_data[phase];
    @(negedge clk);
    i_valid = 1'b0;
    i_data  = 0;
end
endtask

initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    do_reset();

    if (o_valid !== 1'b0) begin
        $display("FAIL: o_valid must be 0 after reset");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    for (p = 0; p < 4; p = p + 1) begin
        build_phase_data(p);
    end

    push_phase(0);
    if (o_valid !== 1'b0) begin
        $display("FAIL: o_valid asserted too early after phase 0");
        fail_cnt = fail_cnt + 1;
    end

    push_phase(1);
    if (o_valid !== 1'b0) begin
        $display("FAIL: o_valid asserted too early after phase 1");
        fail_cnt = fail_cnt + 1;
    end

    push_phase(2);
    if (o_valid !== 1'b0) begin
        $display("FAIL: o_valid asserted too early after phase 2");
        fail_cnt = fail_cnt + 1;
    end

    push_phase(3);
    @(posedge clk);
    if (o_valid !== 1'b1) begin
        $display("FAIL: o_valid must assert after 4th push");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    for (c = 0; c < NUM_CLUSTERS; c = c + 1) begin
        for (p = 0; p < 4; p = p + 1) begin
            got64 = cluster_flat[c*CLUSTER_SIZE + p*CHUNK_WIDTH +: CHUNK_WIDTH];
            exp64 = phase_data[p][c*CHUNK_WIDTH +: CHUNK_WIDTH];
            if (got64 !== exp64) begin
                $display("FAIL: cluster=%0d phase=%0d got=%0d exp=%0d", c, p, got64, exp64);
                fail_cnt = fail_cnt + 1;
            end
        end
    end

    @(negedge clk);
    i_done_stage = 1'b1;
    @(negedge clk);
    i_done_stage = 1'b0;
    @(posedge clk);
    if (o_valid !== 1'b0) begin
        $display("FAIL: o_valid must clear when i_done_stage is asserted");
        fail_cnt = fail_cnt + 1;
    end else begin
        pass_cnt = pass_cnt + 1;
    end

    $display("tb_weight_buffer RESULT: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    $finish;
end

endmodule

