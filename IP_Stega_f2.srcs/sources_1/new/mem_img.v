`timescale 1ns / 1ps
module mem_img #(
    parameter ADDR_W    = 12,
    parameter ADDR_R    = 14,
    parameter DATA_W    = 64,
    parameter NUM_BANKS = 6,
    parameter SUB_W     = 16,
    parameter LATENCY   = 3
)(
    input                               i_clk,
    input                               i_sel,        // 0: 16-bit/bank, 1: 64-bit/bank

    // --- Giao di?n Ghi ---
    input [ADDR_W-1:0]                  i_wr_addr,
    input [(DATA_W*NUM_BANKS)-1:0]      i_wr_data_all,
    input [NUM_BANKS-1:0]               i_wr_en_mask,

    // --- Giao di?n Ð?c ---
    input  [ADDR_R-1:0]                 i_rd_addr,
    input  [NUM_BANKS-1:0]              i_rd_enb,

    // Mode 0: [95:0]   h?p l? (6×16-bit gom v? LSB), [383:96] = 0
    // Mode 1: [383:0]  h?p l? (6×64-bit)
    output [(DATA_W*NUM_BANKS)-1:0]     o_data_all,
    output [NUM_BANKS-1:0]              o_data_vld
);

    // --- Pipeline n?i b? ---
    reg [DATA_W-1:0] raw_dout_pipe [0:NUM_BANKS-1][0:LATENCY-1];
    reg              ena_pipes     [0:NUM_BANKS-1][0:LATENCY-1];
    reg [1:0]        sub_addr_pipe [0:NUM_BANKS-1][0:LATENCY-1];
    reg              sel_pipe      [0:LATENCY-1];   // pipeline i_sel

    // Trý?c (sai cho mode 1):
//    wire [ADDR_R-3:0] rd_addr     = i_rd_addr[ADDR_R-1:2]; // luôn b? 2 bit
    wire [1:0]        sub_rd_addr = i_rd_addr[1:0];
    
    // Sau (ðúng cho c? 2 mode):
    wire [ADDR_W-1:0] rd_addr     = i_sel ? i_rd_addr[ADDR_W-1:0]  // mode 1: dùng th?ng
                                           : i_rd_addr[ADDR_R-1:2]; // mode 0: b? 2 bit LSB
    // --- RAM Banks ---
    (* ram_style = "ultra" *) reg [DATA_W-1:0] bank0 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *) reg [DATA_W-1:0] bank1 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *) reg [DATA_W-1:0] bank2 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *) reg [DATA_W-1:0] bank3 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *) reg [DATA_W-1:0] bank4 [0:(2**ADDR_W)-1];
    (* ram_style = "ultra" *) reg [DATA_W-1:0] bank5 [0:(2**ADDR_W)-1];

    // --- Logic Ghi ---
    always @(posedge i_clk) begin
        if (i_wr_en_mask[0]) bank0[i_wr_addr] <= i_wr_data_all[0*DATA_W +: DATA_W];
        if (i_wr_en_mask[1]) bank1[i_wr_addr] <= i_wr_data_all[1*DATA_W +: DATA_W];
        if (i_wr_en_mask[2]) bank2[i_wr_addr] <= i_wr_data_all[2*DATA_W +: DATA_W];
        if (i_wr_en_mask[3]) bank3[i_wr_addr] <= i_wr_data_all[3*DATA_W +: DATA_W];
        if (i_wr_en_mask[4]) bank4[i_wr_addr] <= i_wr_data_all[4*DATA_W +: DATA_W];
        if (i_wr_en_mask[5]) bank5[i_wr_addr] <= i_wr_data_all[5*DATA_W +: DATA_W];
    end

    integer b, stage;

    // --- Stage 0: Ð?c RAM + b?t i_sel ---
    always @(posedge i_clk) begin
        sel_pipe[0] <= i_sel;

        for (b = 0; b < NUM_BANKS; b = b + 1)
            ena_pipes[b][0] <= i_rd_enb[b];

        raw_dout_pipe[0][0] <= bank0[rd_addr];  sub_addr_pipe[0][0] <= sub_rd_addr;
        raw_dout_pipe[1][0] <= bank1[rd_addr];  sub_addr_pipe[1][0] <= sub_rd_addr;
        raw_dout_pipe[2][0] <= bank2[rd_addr];  sub_addr_pipe[2][0] <= sub_rd_addr;
        raw_dout_pipe[3][0] <= bank3[rd_addr];  sub_addr_pipe[3][0] <= sub_rd_addr;
        raw_dout_pipe[4][0] <= bank4[rd_addr];  sub_addr_pipe[4][0] <= sub_rd_addr;
        raw_dout_pipe[5][0] <= bank5[rd_addr];  sub_addr_pipe[5][0] <= sub_rd_addr;
    end

    // --- Stage 1 ? LATENCY-1: D?ch chuy?n ð?ng lo?t ---
    always @(posedge i_clk) begin
        for (stage = 1; stage < LATENCY; stage = stage + 1) begin
            sel_pipe[stage] <= sel_pipe[stage-1];

            for (b = 0; b < NUM_BANKS; b = b + 1) begin
                ena_pipes[b][stage]     <= ena_pipes[b][stage-1];
                raw_dout_pipe[b][stage] <= raw_dout_pipe[b][stage-1];
                sub_addr_pipe[b][stage] <= sub_addr_pipe[b][stage-1];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Output wires trung gian
    //   out_full  : 6 × 64-bit x?p liên ti?p                  (mode 1)
    //   out_packed: 6 × 16-bit gom v? LSB, zero-pad lên 384-bit (mode 0)
    // -------------------------------------------------------------------------
    wire [(DATA_W*NUM_BANKS)-1:0] out_full;
    wire [(SUB_W*NUM_BANKS)-1:0]  out_packed_96; // 96-bit th?c s?

    genvar k;
    generate
        for (k = 0; k < NUM_BANKS; k = k + 1) begin : output_assign
            // Mode 1: xu?t th?ng 64-bit
            assign out_full[k*DATA_W +: DATA_W] =
                raw_dout_pipe[k][LATENCY-1];

            // Mode 0: trích ðúng 16-bit theo sub_addr, gom liên ti?p t? bit 0
            assign out_packed_96[k*SUB_W +: SUB_W] =
                raw_dout_pipe[k][LATENCY-1][sub_addr_pipe[k][LATENCY-1]*SUB_W +: SUB_W];

            assign o_data_vld[k] = ena_pipes[k][LATENCY-1];
        end
    endgenerate

    // MUX cu?i: ch?n mode d?a trên sel ð? ðý?c pipeline
    assign o_data_all = sel_pipe[LATENCY-1]
        ? out_full                                                    // 384-bit
        : {{(DATA_W*NUM_BANKS - SUB_W*NUM_BANKS){1'b0}}, out_packed_96}; // 96-bit @ LSB

endmodule