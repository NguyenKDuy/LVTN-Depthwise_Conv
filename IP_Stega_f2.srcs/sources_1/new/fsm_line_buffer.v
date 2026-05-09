`timescale 1ns / 1ps
module fsm_line_buffer #(
    parameter DATA_IN_W = 256,
    parameter KERNEL_W  = 2304
)(
    input                       i_clk,
    input                       i_rst_n,
    input                       i_enable,
    input                       i_data_vld,
    input                       i_padding_vld,
    input  [1:0]                i_config_stride,
    input  [7:0]                i_config_max_line_in,
    input  [7:0]                i_config_max_line_out,
    input  [255:0]              i_data_in,
    output reg [KERNEL_W-1:0]   o_kernel_data,
    output reg                  o_kernel_vld
);

    // -------------------------------------------------------------------------
    // Internal Signals
    // -------------------------------------------------------------------------
    reg  [2:0]  wr_sel;
    reg  [2:0]  rd_sel;
    reg  [7:0]  wr_cnt;
    reg  [3:0]   lb_filled;       // 4 buffers -> 4-bit
    reg  [3:0]   lines_available;
    wire [767:0] lb_raw [3:0];    // 4 buffers
    wire [3:0]   lb_done;         // 4 buffers
    wire [7:0]   rdPntr[0:3];     // 4 buffers

    // -------------------------------------------------------------------------
    // next_wr_sel: c? stride=1 và stride=2 ð?u modulo 4 (4 buffers)
    // -------------------------------------------------------------------------
    wire [2:0] next_wr_sel = (wr_sel == 3'd3) ? 3'd0 : wr_sel + 3'd1;

    reg o_kernel_vld_raw;
    wire wr_last_pixel = (i_data_vld || i_padding_vld) &&
                         (wr_cnt >= i_config_max_line_in + 8'd1);
    wire wr_done_trig  = wr_last_pixel;

    wire rd_done_trig_internal = o_kernel_vld_raw && lb_done[rd_sel];

    always @(posedge i_clk) begin
        if (!i_rst_n)
            lines_available <= 4'd0;
        else if (i_enable) begin
            case ({wr_done_trig, rd_done_trig_internal})
                2'b10: lines_available <= lines_available + 4'd1;
                2'b01: lines_available <= lines_available - {2'd0, i_config_stride};
                2'b11: lines_available <= lines_available + 4'd1 - {2'd0, i_config_stride};
                default: lines_available <= lines_available;
            endcase
        end
    end

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            wr_sel    <= 3'd0;
            wr_cnt    <= 8'd0;
            lb_filled <= 4'd0;
        end else if (i_enable) begin
            if (wr_done_trig) begin
                lb_filled[wr_sel]      <= 1'b1;
                lb_filled[next_wr_sel] <= 1'b0;
                wr_sel <= next_wr_sel;
                wr_cnt <= 8'd0;
            end else if (i_data_vld || i_padding_vld) begin
                wr_cnt <= wr_cnt + 8'd1;
            end
        end
    end

    wire can_read = (lines_available >= 4'd3);

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            rd_sel           <= 3'd0;
            o_kernel_vld_raw <= 1'b0;
        end else if (i_enable) begin
            if (can_read && lb_filled[rd_sel]) begin
                o_kernel_vld_raw <= 1'b1;
                if (rd_done_trig_internal) begin
                    if (i_config_stride == 2'd1) begin
                        // Stride 1: 0->1->2->3->0 (modulo 4)
                        rd_sel <= (rd_sel == 3'd3) ? 3'd0 : rd_sel + 3'd1;
                    end else begin
                        // Stride 2: 0->2->0->2 (XOR 2, modulo 4)
                        // Chu k? ð?c: {0,1,2} -> {2,3,0} -> {0,1,2} -> ...
                        rd_sel <= rd_sel ^ 3'd2;
                    end
                end
            end else begin
                o_kernel_vld_raw <= 1'b0;
            end
        end
    end

    // Pipeline rd_sel 2 stage (cho BRAM latency)
    reg [2:0] rd_sel_pipe [1:0];
    always @(posedge i_clk) begin
        rd_sel_pipe[0] <= rd_sel;
        rd_sel_pipe[1] <= rd_sel_pipe[0];
    end

    // rd_p1, rd_p2: c? 2 stride ð?u modulo 4 (4 buffers)
    wire [2:0] rd_p1, rd_p2;
    assign rd_p1 = (rd_sel_pipe[0] == 3'd3) ? 3'd0 : rd_sel_pipe[0] + 3'd1;
    assign rd_p2 = (rd_p1          == 3'd3) ? 3'd0 : rd_p1          + 3'd1;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : LB_GEN   // 4 buffers
            wire rd_en = can_read &&
                         ((rd_sel_pipe[0] == i[2:0]) ||
                          (rd_p1          == i[2:0]) ||
                          (rd_p2          == i[2:0]));
            line_buffer lb_inst (
                .i_clk                (i_clk),
                .i_rst_n              (i_rst_n),
                .i_linedata           (i_padding_vld ? 256'd0 : i_data_in),
                .i_enable             (i_enable),
                .i_vld                ((wr_sel == i[2:0]) && (i_data_vld | i_padding_vld)),
                .i_rd_data            (rd_en),
                .i_config_stride      (i_config_stride),
                .i_config_max_line_in (i_config_max_line_in),
                .i_config_max_line_out(i_config_max_line_out),
                .o_linedata           (lb_raw[i]),
                .o_almost_done        (lb_done[i]),
                .rdPntr               (rdPntr[i])
            );
        end
    endgenerate

    // Valid delay: 1 cycle cho BRAM registered output
    reg vld_d1;
    always @(posedge i_clk) begin
        if (!i_rst_n)      vld_d1 <= 1'b0;
        else if (i_enable) vld_d1 <= o_kernel_vld_raw;
    end

    always @(*) begin
        o_kernel_vld = vld_d1;
    end

    integer ch;
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_kernel_data <= {KERNEL_W{1'b0}};
        end else if (i_enable) begin
            for (ch = 0; ch < 16; ch = ch + 1) begin
                o_kernel_data[ch*144 +: 144] <= {
                    lb_raw[rd_p2][ch*48 +: 48],              // Row 2
                    lb_raw[rd_p1][ch*48 +: 48],              // Row 1
                    lb_raw[rd_sel_pipe[0]][ch*48 +: 48]      // Row 0 (LSB)
                };
            end
        end
    end

endmodule