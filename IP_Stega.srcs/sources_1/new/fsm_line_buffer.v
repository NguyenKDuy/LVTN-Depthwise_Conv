`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2026 07:34:24 PM
// Design Name: 
// Module Name: fsm_line_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//module fsm_line_buffer #(
//    parameter DATA_IN_W          = 256,
//    parameter KERNEL_W           = 2304,
//    parameter COUNTER_W          = 8,
//    parameter STRIDE_W           = 2,
//    parameter PADDING_W          = 3
//)(
//    // --- Clock & Reset ---
//    input                            i_clk,
//    input                            i_rst_n,

//    // --- Control Signals ---
//    input                            i_enable,
//    input                            i_data_vld,
//    input                            i_padding_vld,

//    // --- Configuration ---
//    input  [STRIDE_W-1:0]            i_config_stride,
//    input  [PADDING_W-1:0]           i_config_padding,
//    input  [COUNTER_W-1:0]           i_config_max_line_in,
//    input  [COUNTER_W-1:0]           i_config_max_line_out,

//    // --- Counters & Data Input ---
////    input  [COUNTER_W-1:0]           i_row_counter,
////    input  [COUNTER_W-1:0]           i_col_counter,
//    input  [DATA_IN_W-1:0]           i_data_in,

//    // --- Data Output ---
//    output reg [KERNEL_W-1:0]        o_kernel_data,
//    output reg                       o_kernel_vld
//);

//localparam NONE         = 3'b000;
//localparam LINE_PADDING = 3'b111;
//localparam PRE          = 3'b100;
//localparam POST         = 3'b001;

//reg [2:0] line_buffer_wr_selection, line_buffer_rd_selection;
//reg [4:0] line_buffer_wr, line_buffer_rd ;
//reg [2:0] line_stage;
//reg [7:0] in_line_counter;
//reg [9:0] rd_kernel_counter;
//wire [4:0] l_padding = (i_config_padding == LINE_PADDING && i_padding_vld) ? 0 : 1;    
//wire [DATA_IN_W  - 1 : 0] lb_data_in = i_padding_vld ? 'd0 : (i_data_vld) ? i_data_in : 'd0;
//genvar i;

//    always @(i_clk) begin
//        if (!i_rst_n) begin
//            in_line_counter <= 0;
//            rd_kernel_counter <= 0;
//        end
//        if (i_enable) begin
//            if (l_padding) begin
//                line_buffer_wr_selection <= line_buffer_wr_selection + 1;
//                in_line_counter <= in_line_counter + i_config_max_line_in + 1;
//            end
//            else if (i_padding_vld || i_padding_vld) begin
//                in_line_counter <= in_line_counter + 1;
//                rd_kernel_counter <= rd_kernel_counter + 1;
//                if (in_line_counter == i_config_max_line_in + 1) begin
//                    in_line_counter <= 0;
//                    line_buffer_wr_selection <= line_buffer_wr_selection + 1;
//                end

//            end
//        end
//    end

//always @(posedge i_clk) begin
//    if (!i_rst_n) begin
//        line_buffer_rd_selection <= 0;
//    end
//    else begin
//       if (rd_kernel_counter == i_config_max_line_in * 3 + 5) begin     
//             line_buffer_rd_selection <= line_buffer_rd_selection + 1;  
//       end
//    end
//end
    
//    always @(*) begin
//        line_buffer_wr = 5'b0;
//        case (i_config_stride)
//        1: begin
//            case (line_buffer_wr_selection)
//                0: line_buffer_wr = 5'b00001;
//                1: line_buffer_wr = 5'b00010;
//                2: line_buffer_wr = 5'b00100;
//                3: line_buffer_wr = 5'b01000;
//            endcase
//        end
//        2: begin
//            case (line_buffer_wr_selection)
//                0: line_buffer_wr = 5'b00000;
//                1: line_buffer_wr = 5'b00001;
//                2: line_buffer_wr = 5'b00010;
//                3: line_buffer_wr = 5'b00100;
//                4: line_buffer_wr = 5'b01000;
//                5: line_buffer_wr = 5'b10000;
//            endcase
//        end
//        default: begin
//        end
//    endcase
//    end
    
//    always @(*) begin
//        line_buffer_wr = 5'b0;
//        case (i_config_stride)
//        1: begin
//            case (line_buffer_rd_selection)
//                0: line_buffer_rd = 5'b00000;
//                1: line_buffer_rd = 5'b00111;
//                2: line_buffer_rd = 5'b01110;
//                3: line_buffer_rd = 5'b01101;
//                4: line_buffer_rd = 5'b01011;
//            endcase
//        end
//        2: begin
//            case (line_buffer_rd_selection)
//                1: line_buffer_rd = 5'b00111;
//                2: line_buffer_rd = 5'b11100;
//                3: line_buffer_rd = 5'b10011;
//                4: line_buffer_rd = 5'b01110;
//                5: line_buffer_rd = 5'b11001;
//                0: line_buffer_rd = 5'b00000;
//            endcase
//        end
//        default: begin end
//    endcase
//    end

//generate
//    for(i=0; i<5; i=i+1) begin : LB_GEN
//        line_buffer lb_inst(
//            .i_clk(i_clk),
//            .i_rst_n(l_padding),
//            .i_linedata(lb_data_in),
//            .i_vld(line_buffer_wr[i] | i_padding_vld),     // Mask này Duy ði?u khi?n ð? ch?n n?p vào Buffer nào
//            .i_rd_data(line_buffer_rd[i]),
//            .i_config_stride(i_config_stride),
//            .i_config_max_line_in(i_config_max_line_in),
//            .i_config_max_line_out(i_config_max_line_out),
//            .o_linedata() // M?i lb_data_out là 3 d?ng (768 bit)
//        );
//    end
//endgenerate    
//endmodule

// =============================================================================
// Module: fsm_line_buffer
// Description: FSM ði?u ph?i 5 line_buffer instances cho sliding window 3x3.
//              - Round-robin ghi vào 5 buffers
//              - Credit counter ð?ng b? t?c ð? n?p/ð?c
//              - Race condition fix: clear lb_filled t?i th?i ði?m wr_sel nh?y
//              - BRAM latency compensation: valid delay 3 cycle (1 BRAM + 2 shift)
//              - Window assembly: shift register ngang 3 c?t
// =============================================================================
//module fsm_line_buffer #(
//    parameter DATA_IN_W = 256,
//    parameter KERNEL_W  = 2304
//)(
//    input                       i_clk,
//    input                       i_rst_n,
//    input                       i_enable,
//    input                       i_data_vld,
//    input                       i_padding_vld,
//    input  [1:0]                i_config_stride,
//    input  [2:0]                i_config_padding,
//    input  [7:0]                i_config_max_line_in,
//    input  [7:0]                i_config_max_line_out,
//    input  [255:0]              i_data_in,
//    output reg [KERNEL_W-1:0]   o_kernel_data,
//    output reg                  o_kernel_vld
//);

//    // -------------------------------------------------------------------------
//    // Internal Signals
//    // -------------------------------------------------------------------------
//    reg  [2:0]  wr_sel;
//    reg  [2:0]  rd_sel;
//    reg  [7:0]  wr_cnt;
//    reg  [4:0]  lb_filled;       // Ready flag m?i buffer
//    reg  [3:0]  lines_available; // Credit counter
//    wire [767:0] lb_raw [4:0];
//    wire [4:0]   lb_done;

//    // -------------------------------------------------------------------------
//    // Next wr_sel combinational (dùng l?i logic c?a b?n, tách ra ð? dùng 2 nõi)
//    // -------------------------------------------------------------------------
//    wire [2:0] next_wr_sel = (i_config_stride == 2'd1) ?
//                                 (wr_sel == 3'd3 ? 3'd0 : wr_sel + 3'd1) :
//                                 (wr_sel == 3'd4 ? 3'd0 : wr_sel + 3'd1);

//    // -------------------------------------------------------------------------
//    // Padding Reset Logic (Active Low)
//    // -------------------------------------------------------------------------
//    wire l_padding_rst = (i_config_padding == 3'b111 && i_padding_vld) ? 1'b0 : i_rst_n;

//    // -------------------------------------------------------------------------
//    // Trigger Signals
//    // -------------------------------------------------------------------------
//    // wr_done_trig: k?t thúc hàng khi:
//    //   1. PAD ROW (111) reset buffer
//    //   2. Pixel cu?i (129) - có th? là data_vld HO?C padding_vld (POST pad)
//    wire wr_last_pixel = (i_data_vld || i_padding_vld) &&
//                         (wr_cnt >= i_config_max_line_in + 8'd1);
//    wire wr_done_trig  =  wr_last_pixel;

//    // rd_done_trig dùng internal valid (trý?c delay) ð? ði?u khi?n FSM
//    wire rd_done_trig_internal = o_kernel_vld_raw && lb_done[rd_sel];

//    // -------------------------------------------------------------------------
//    // 1. Credit Counter
//    // -------------------------------------------------------------------------
//    always @(posedge i_clk) begin
//        if (!i_rst_n)
//            lines_available <= 4'd0;
//        else if (i_enable) begin
//            case ({wr_done_trig, rd_done_trig_internal})
//                2'b10: lines_available <= lines_available + 4'd1;
//                2'b01: lines_available <= lines_available - {2'd0, i_config_stride};
//                2'b11: lines_available <= lines_available + 4'd1 - {2'd0, i_config_stride};
//                default: lines_available <= lines_available;
//            endcase
//        end
//    end

//    // -------------------------------------------------------------------------
//    // 2. Write Logic - Race Condition Fix
//    //    Clear lb_filled[next_wr_sel] t?i th?i ði?m wr_sel nh?y,
//    //    KHÔNG clear vô ði?u ki?n m?i cycle có data (nguyên nhân g?c c?a bug)
//    // -------------------------------------------------------------------------
//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            wr_sel    <= 3'd0;
//            wr_cnt    <= 8'd0;
//            lb_filled <= 5'd0;
//        end else if (i_enable) begin
//            if (wr_done_trig) begin
//                lb_filled[wr_sel]      <= 1'b1;    // Buffer hi?n t?i: DONE
//                lb_filled[next_wr_sel] <= 1'b0;    // Buffer k?: clear ngay khi nh?y
//                wr_sel <= next_wr_sel;
//                wr_cnt <= 8'd0;
//            end else if (i_data_vld || i_padding_vld) begin
//                wr_cnt <= wr_cnt + 8'd1;
//            end
//        end
//    end

//    // -------------------------------------------------------------------------
//    // 3. Read Logic - Stall n?u thi?u hàng
//    // -------------------------------------------------------------------------
//    wire can_read = (lines_available >= 4'd3);

//    // Internal valid signal (trý?c pipeline delay)
//    reg o_kernel_vld_raw;

//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            rd_sel          <= 3'd0;
//            o_kernel_vld_raw <= 1'b0;
//        end else if (i_enable) begin
//            if (can_read && lb_filled[rd_sel]) begin
//                o_kernel_vld_raw <= 1'b1;
//                if (rd_done_trig_internal) begin
//                    if (i_config_stride == 2'd1)
//                        rd_sel <= (rd_sel == 3'd3) ? 3'd0 : rd_sel + 3'd1;
//                    else
//                        rd_sel <= (rd_sel >= 3'd3) ? (rd_sel - 3'd3) : (rd_sel + 3'd2);
//                end
//            end else begin
//                o_kernel_vld_raw <= 1'b0;
//            end
//        end
//    end

//    // -------------------------------------------------------------------------
//    // 4. Line Buffer Instances
//    // -------------------------------------------------------------------------
//    genvar i;
//    generate
//        for (i = 0; i < 5; i = i + 1) begin : LB_GEN
//            line_buffer lb_inst (
//                .i_clk               (i_clk),
//                .i_rst_n             ((wr_sel == i) ? l_padding_rst : i_rst_n),
//                .i_linedata          (i_padding_vld ? 256'd0 : i_data_in),
//                .i_vld               ((wr_sel == i[2:0]) && (i_data_vld | i_padding_vld)),
//                .i_rd_data           (o_kernel_vld_raw && (rd_sel == i[2:0])),
//                .i_config_stride     (i_config_stride),
//                .i_config_max_line_in (i_config_max_line_in),
//                .i_config_max_line_out(i_config_max_line_out),
//                .o_linedata          (lb_raw[i]),
//                .o_almost_done       (lb_done[i])
//            );
//        end
//    endgenerate

//    // -------------------------------------------------------------------------
//    // 5. Window Assembly - Shift Register ngang
//    //    Pipeline:
//    //      Cycle 0: i_rd_data asserts ? BRAM starts read
//    //      Cycle 1: lb_raw valid (BRAM registered output) ? load r0/r1/r2
//    //      Cycle 2: r_s1 valid
//    //      Cycle 3: r_s2 valid ? kernel complete
//    //
//    //    Valid delay: 3 stages ð? kh?p v?i data pipeline
//    // -------------------------------------------------------------------------
//    reg [255:0] r0_s0, r1_s0, r2_s0;   // Stage 0: capture t? lb_raw (combinational)
//    reg [255:0] r0_s1, r1_s1, r2_s1;   // Stage 1
//    reg [255:0] r0_s2, r1_s2, r2_s2;   // Stage 2

//    // Valid delay pipeline: 3 stages
//    reg vld_d1, vld_d2, vld_d3;

//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            vld_d1 <= 1'b0;
//            vld_d2 <= 1'b0;
//            vld_d3 <= 1'b0;
//        end else if (i_enable) begin
//            vld_d1 <= o_kernel_vld_raw;
//            vld_d2 <= vld_d1;
//            vld_d3 <= vld_d2;
//        end
//    end

//    // Capture lb_raw (combinational tap t? lb_raw[rd_sel])
//    always @(*) begin
//        r0_s0 = lb_raw[rd_sel][767:512];
//        r1_s0 = lb_raw[rd_sel][511:256];
//        r2_s0 = lb_raw[rd_sel][255:0];
//    end

//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            {r0_s1, r0_s2} <= 512'd0;
//            {r1_s1, r1_s2} <= 512'd0;
//            {r2_s1, r2_s2} <= 512'd0;
//            o_kernel_data  <= {KERNEL_W{1'b0}};
//            o_kernel_vld   <= 1'b0;
//        end else if (i_enable) begin
//            // Stage shift
//            if (vld_d1) begin
//                r0_s1 <= r0_s0; r0_s2 <= r0_s1;
//                r1_s1 <= r1_s0; r1_s2 <= r1_s1;
//                r2_s1 <= r2_s0; r2_s2 <= r2_s1;
//            end

//            // Output sau 3 cycle - data hoàn toàn ?n ð?nh
//            if (vld_d3) begin
//                o_kernel_data <= {
//                    r0_s0, r0_s1, r0_s2,   // Row 0: col2, col1, col0
//                    r1_s0, r1_s1, r1_s2,   // Row 1
//                    r2_s0, r2_s1, r2_s2    // Row 2
//                };
//            end

//            o_kernel_vld <= vld_d3;
//        end
//    end

//endmodule

// =============================================================================
// Module: fsm_line_buffer
// Description: FSM ði?u ph?i 5 line_buffer instances cho sliding window 3x3.
//              - Round-robin ghi vào 5 buffers
//              - Credit counter ð?ng b? t?c ð? n?p/ð?c
//              - Race condition fix: clear lb_filled t?i th?i ði?m wr_sel nh?y
//              - BRAM latency compensation: valid delay 3 cycle (1 BRAM + 2 shift)
//              - Window assembly: shift register ngang 3 c?t
// =============================================================================
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
//    input  [2:0]                i_config_padding,
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
    reg  [4:0]  lb_filled;       // Ready flag m?i buffer
    reg  [3:0]  lines_available; // Credit counter
    wire [767:0] lb_raw [4:0];
    wire [4:0]   lb_done;
    wire [7:0]   rdPntr[0:4];
 
    // -------------------------------------------------------------------------
    // Next wr_sel combinational (dùng l?i logic c?a b?n, tách ra ð? dùng 2 nõi)
    // -------------------------------------------------------------------------
    wire [2:0] next_wr_sel = (i_config_stride == 2'd1) ?
                                 (wr_sel == 3'd3 ? 3'd0 : wr_sel + 3'd1) :
                                 (wr_sel == 3'd4 ? 3'd0 : wr_sel + 3'd1) ;
 
    // -------------------------------------------------------------------------
    // Padding Reset Logic (Active Low)
    // -------------------------------------------------------------------------
//    wire l_padding_rst = (i_config_padding == 3'b111 && i_padding_vld) ? 1'b0 : i_rst_n;
 
    // -------------------------------------------------------------------------
    // Trigger Signals
    // -------------------------------------------------------------------------
    // wr_done_trig: k?t thúc hàng khi:
    //   1. PAD ROW (111) reset buffer
    //   2. Pixel cu?i (129) - có th? là data_vld HO?C padding_vld (POST pad)
    // i_config_max_line_in = width g?c (không tính padding), vd: 128
    // Pixel cu?i hàng là POST pad t?i index 129 = 128 + 1
    reg o_kernel_vld_raw;
    wire wr_last_pixel = (i_data_vld || i_padding_vld) &&
                         (wr_cnt >= i_config_max_line_in + 8'd1);
    wire wr_done_trig  = wr_last_pixel;
 
    // rd_done_trig dùng internal valid (trý?c delay) ð? ði?u khi?n FSM
    wire rd_done_trig_internal = o_kernel_vld_raw && lb_done[rd_sel];
    

    // -------------------------------------------------------------------------
    // 1. Credit Counter
    // -------------------------------------------------------------------------
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
 
    // -------------------------------------------------------------------------
    // 2. Write Logic - Race Condition Fix
    //    Clear lb_filled[next_wr_sel] t?i th?i ði?m wr_sel nh?y,
    //    KHÔNG clear vô ði?u ki?n m?i cycle có data (nguyên nhân g?c c?a bug)
    // -------------------------------------------------------------------------
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            wr_sel    <= 3'd0;
            wr_cnt    <= 8'd0;
            lb_filled <= 5'd0;
        end else if (i_enable) begin
            if (wr_done_trig) begin
                lb_filled[wr_sel]      <= 1'b1;    // Buffer hi?n t?i: DONE
                lb_filled[next_wr_sel] <= 1'b0;    // Buffer k?: clear ngay khi nh?y
                wr_sel <= next_wr_sel;
                wr_cnt <= 8'd0;
            end else if (i_data_vld || i_padding_vld) begin
                wr_cnt <= wr_cnt + 8'd1;
            end
        end
    end
 
    // -------------------------------------------------------------------------
    // 3. Read Logic - Stall n?u thi?u hàng
    // -------------------------------------------------------------------------
    wire can_read = (lines_available >= 4'd3);
 
    // Internal valid signal (trý?c pipeline delay)
  
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            rd_sel          <= 3'd0;
            o_kernel_vld_raw <= 1'b0;
        end else if (i_enable) begin
            if (can_read && lb_filled[rd_sel]) begin
                o_kernel_vld_raw <= 1'b1;               //allow to read
                if (rd_done_trig_internal) begin
                    if (i_config_stride == 2'd1) begin
                        // Stride 1: Loop 4 d?ng (0-1-2-3)
                        rd_sel <= (rd_sel == 3'd3) ? 3'd0 : rd_sel + 3'd1;
                    end else begin
                        // Stride 2: Loop 5 d?ng (0-2-4-1-3)
                        // Công th?c: (rd_sel + 2) % 5
                        if (rd_sel == 3'd3)      rd_sel <= 3'd0; // (3+2)=5 -> 0
                        else if (rd_sel == 3'd4) rd_sel <= 3'd1; // (4+2)=6 -> 1
                        else                     rd_sel <= rd_sel + 3'd2;
                    end
                end
            end else begin
                o_kernel_vld_raw <= 1'b0;
            end
        end
    end
 
    // -------------------------------------------------------------------------
    // 4. Line Buffer Instances
    //    M?i instance ch?a 1 hàng ?nh (130 pixel x 256-bit).
    //    rdPntr bên trong m?i instance t? d?ch chuy?n theo chi?u ngang.
    //    o_linedata = 768-bit = {pixel[col], pixel[col+1], pixel[col+2]}
    //                           = 3 pixel liên ti?p theo chi?u ngang.
    //
    //    Khi ð?c kernel 3x3:
    //      lb_raw[rd_sel]   ? row 0: {col, col+1, col+2}
    //      lb_raw[rd_sel+1] ? row 1: {col, col+1, col+2}  (cùng col position)
    //      lb_raw[rd_sel+2] ? row 2: {col, col+1, col+2}
    //    ? 3 instance drive i_rd_data Ð?NG TH?I, rdPntr nh?y cùng lúc
    // -------------------------------------------------------------------------
 
    // rd_sel+1 và rd_sel+2 v?i wrap mod 5
    reg [2:0] rd_sel_pipe [1:0];
    always @(posedge i_clk) begin
        rd_sel_pipe[0] <= rd_sel;
        rd_sel_pipe[1] <=  rd_sel_pipe[0];
    end
    
//    wire [2:0] rd_sel_p1 = (rd_sel_pipe[1] >= 3'd4) ? (rd_sel_pipe[1] - 3'd4) : (rd_sel_pipe[1] + 3'd1);
//    wire [2:0] rd_sel_p2 = (rd_sel_pipe[1] >= 3'd3) ? (rd_sel_pipe[1] - 3'd3) : (rd_sel_pipe[1] + 3'd2);
    wire [2:0] rd_p1, rd_p2;
    assign rd_p1 = (i_config_stride == 2'd1) ? 
                   ((rd_sel_pipe[0] == 3'd3) ? 3'd0 : rd_sel_pipe[0] + 3'd1) : // Modulo 4
                   ((rd_sel_pipe[0] == 3'd4) ? 3'd0 : rd_sel_pipe[0] + 3'd1);  // Modulo 5
    
    assign rd_p2 = (i_config_stride == 2'd1) ? 
                   ((rd_p1  == 3'd3) ? 3'd0 : rd_p1  + 3'd1) : // Modulo 4
                   ((rd_p1  == 3'd4) ? 3'd0 : rd_p1  + 3'd1);  // Modulo 5
    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : LB_GEN
            // i_rd_data: assert khi instance này là rd_sel, rd_sel+1, ho?c rd_sel+2
            wire rd_en = can_read &&
                         ((rd_sel_pipe[0]    == i[2:0]) ||
                          (rd_p1 == i[2:0]) ||
                          (rd_p2 == i[2:0]));
            line_buffer lb_inst (
                .i_clk                (i_clk),
                .i_rst_n              (i_rst_n),
                .i_linedata           (i_padding_vld ? 256'd0 : i_data_in),
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
 
    // -------------------------------------------------------------------------
    // 5. Window Assembly
    //    lb_raw[rd_sel]   = {row0_col2, row0_col1, row0_col0} (768-bit)
    //    lb_raw[rd_sel+1] = {row1_col2, row1_col1, row1_col0}
    //    lb_raw[rd_sel+2] = {row2_col2, row2_col1, row2_col0}
    //
    //    Kernel output layout (2304-bit):
    //    {row0_col0, row0_col1, row0_col2,
    //     row1_col0, row1_col1, row1_col2,
    //     row2_col0, row2_col1, row2_col2}
    //
    //    Pipeline: 1 cycle BRAM latency ? valid delay 1 stage
    // -------------------------------------------------------------------------
 
    // Valid delay: 1 cycle cho BRAM registered output
    reg vld_d1;
    always @(posedge i_clk) begin
        if (!i_rst_n)      vld_d1 <= 1'b0;
        else if (i_enable) vld_d1 <= o_kernel_vld_raw;
    end
 
//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            o_kernel_data <= {KERNEL_W{1'b0}};
//            o_kernel_vld  <= 1'b0;
//        end else if (i_enable) begin
//            o_kernel_vld <= vld_d1;
//            if (vld_d1) begin
//                // lb_raw bit layout: [767:512]=col+2, [511:256]=col+1, [255:0]=col
//                // Output theo th? t? t? nhiên: col0, col1, col2
//                o_kernel_data <= {
//                    lb_raw[rd_sel  ][255:0],   // row0 col0
//                    lb_raw[rd_sel  ][511:256], // row0 col1
//                    lb_raw[rd_sel  ][767:512], // row0 col2
//                    lb_raw[rd_sel_p1][255:0],  // row1 col0
//                    lb_raw[rd_sel_p1][511:256],// row1 col1
//                    lb_raw[rd_sel_p1][767:512],// row1 col2
//                    lb_raw[rd_sel_p2][255:0],  // row2 col0
//                    lb_raw[rd_sel_p2][511:256],// row2 col1
//                    lb_raw[rd_sel_p2][767:512] // row2 col2
//                };
//            end
//        end
//    end

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
                        lb_raw[rd_p2][ch*48 +: 48], // Row 2
                        lb_raw[rd_p1][ch*48 +: 48], // Row 1
                        lb_raw[rd_sel_pipe[0]][ch*48 +: 48]  // Row 0 (LSB)
                    };
                end
            end
        end
endmodule
`timescale 1ns / 1ps
// =============================================================================
// Module: fsm_line_buffer
// Thay ð?i so v?i phiên b?n trý?c:
//   - line_buffer gi? t? qu?n l? col_cnt và rdPntr n?i b?
//   - i_rd_data assert liên t?c khi mu?n ð?c (không c?n pulse t?ng cycle)
//   - o_linedata t? line_buffer ch? valid khi window_valid bên trong (t? gate)
//   - fsm ch? c?n track: (1) ð? 3 d?ng chýa, (2) hàng ð?c xong chýa
//   - rd_sel advance sau 1 cycle khi lb_done assert (gi? nguyên fix race condition)
//// =============================================================================
//`timescale 1ns / 1ps
//// =============================================================================
//// Module: fsm_line_buffer
////
//// Timing o_kernel_vld:
////   - line_buffer xu?t o_window_valid ðúng cycle o_linedata ch?a window h?p l?
////   - FSM capture lb_raw vào o_kernel_data khi o_window_valid assert
////   - o_kernel_vld = o_window_valid c?a rd_sel instance (delay 1 reg)
////
//// Không c?n vld_d1/d2/d3/d4 hardcode - dùng o_window_valid làm ngu?n s? th?t.
//// =============================================================================
//module fsm_line_buffer #(
//    parameter DATA_IN_W = 256,
//    parameter KERNEL_W  = 2304
//)(
//    input                       i_clk,
//    input                       i_rst_n,
//    input                       i_enable,
//    input                       i_data_vld,
//    input                       i_padding_vld,
//    input  [1:0]                i_config_stride,
//    input  [7:0]                i_config_max_line_in,
//    input  [7:0]                i_config_max_line_out,
//    input  [255:0]              i_data_in,
//    output reg [KERNEL_W-1:0]   o_kernel_data,
//    output reg                  o_kernel_vld
//);

//    reg  [2:0]  wr_sel;
//    reg  [2:0]  rd_sel;
//    reg  [7:0]  wr_cnt;
//    reg  [4:0]  lb_filled;
//    reg  [3:0]  lines_available;

//    wire [767:0] lb_raw       [4:0];
//    wire [4:0]   lb_done;          // o_almost_done
//    wire [4:0]   lb_win_vld;       // o_window_valid t? m?i instance

//    wire [2:0] rd_sel_p1 = (rd_sel >= 3'd4) ? (rd_sel - 3'd4) : (rd_sel + 3'd1);
//    wire [2:0] rd_sel_p2 = (rd_sel >= 3'd3) ? (rd_sel - 3'd3) : (rd_sel + 3'd2);

//    wire [2:0] next_wr_sel = (i_config_stride == 2'd1) ?
//                                 (wr_sel == 3'd3 ? 3'd0 : wr_sel + 3'd1) :
//                                 (wr_sel == 3'd4 ? 3'd0 : wr_sel + 3'd1);

//    // -------------------------------------------------------------------------
//    // Write triggers
//    // -------------------------------------------------------------------------
//    wire wr_last_pixel = (i_data_vld || i_padding_vld) &&
//                         (wr_cnt >= i_config_max_line_in + 8'd1);

//    // -------------------------------------------------------------------------
//    // rd_row_done: hàng ð?c xong - dùng lb_done[rd_sel]
//    // lb_done assert khi rdPntr >= max_out (look-ahead t? line_buffer)
//    // Ch? count khi ðang th?c s? ð?c (o_kernel_vld_raw)
//    // -------------------------------------------------------------------------
//    reg o_kernel_vld_raw;
//    wire rd_row_done = o_kernel_vld_raw && lb_done[rd_sel];
//    reg  rd_row_done_d1;

//    // -------------------------------------------------------------------------
//    // 1. Credit counter
//    // -------------------------------------------------------------------------
//    always @(posedge i_clk) begin
//        if (!i_rst_n)
//            lines_available <= 4'd0;
//        else if (i_enable) begin
//            case ({wr_last_pixel, rd_row_done})
//                2'b10: lines_available <= lines_available + 4'd1;
//                2'b01: lines_available <= lines_available - {2'd0, i_config_stride};
//                2'b11: lines_available <= lines_available + 4'd1 - {2'd0, i_config_stride};
//                default: ;
//            endcase
//        end
//    end

//    // -------------------------------------------------------------------------
//    // 2. Write logic
//    // -------------------------------------------------------------------------
//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            wr_sel <= 3'd0; wr_cnt <= 8'd0; lb_filled <= 5'd0;
//        end else if (i_enable) begin
//            if (wr_last_pixel) begin
//                lb_filled[wr_sel]      <= 1'b1;
//                lb_filled[next_wr_sel] <= 1'b0;
//                wr_sel <= next_wr_sel;
//                wr_cnt <= 8'd0;
//            end else if (i_data_vld || i_padding_vld) begin
//                wr_cnt <= wr_cnt + 8'd1;
//            end
//        end
//    end

//    // -------------------------------------------------------------------------
//    // 3. Read logic - rd_sel advance delay 1 cycle sau rd_row_done
//    // -------------------------------------------------------------------------
//    wire can_read = (lines_available >= 4'd3);

//    always @(posedge i_clk) begin
//        if (!i_rst_n)        rd_row_done_d1 <= 1'b0;
//        else if (i_enable)   rd_row_done_d1 <= rd_row_done;
//    end

//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            rd_sel           <= 3'd0;
//            o_kernel_vld_raw <= 1'b0;
//        end else if (i_enable) begin
//            if (rd_row_done_d1) begin
//                if (i_config_stride == 2'd1)
//                    rd_sel <= (rd_sel == 3'd3) ? 3'd0 : rd_sel + 3'd1;
//                else
//                    rd_sel <= (rd_sel >= 3'd3) ? (rd_sel - 3'd3) : (rd_sel + 3'd2);
//            end

//            // Pause 2 cycle s?ch khi chuy?n hàng:
//            //   rd_row_done     cycle N   ? d?ng rd_en ngay
//            //   rd_row_done_d1  cycle N+1 ? rd_sel advance, ti?p t?c pause
//            //   cycle N+2                 ? rd_sel ?n ð?nh, có th? ð?c l?i
//            if (rd_row_done || rd_row_done_d1)
//                o_kernel_vld_raw <= 1'b0;
//            else if (can_read && lb_filled[rd_sel])
//                o_kernel_vld_raw <= 1'b1;
//            else
//                o_kernel_vld_raw <= 1'b0;
//        end
//    end

//    // -------------------------------------------------------------------------
//    // 4. Line Buffer Instances
//    // -------------------------------------------------------------------------
//    genvar i;
//    generate
//        for (i = 0; i < 5; i = i + 1) begin : LB_GEN
//            wire rd_en = o_kernel_vld_raw &&
//                         ((rd_sel    == i[2:0]) ||
//                          (rd_sel_p1 == i[2:0]) ||
//                          (rd_sel_p2 == i[2:0]));
//            line_buffer lb_inst (
//                .i_clk                (i_clk),
//                .i_rst_n              (i_rst_n),
//                .i_linedata           (i_padding_vld ? 256'd0 : i_data_in),
//                .i_vld                ((wr_sel == i[2:0]) && (i_data_vld | i_padding_vld)),
//                .i_rd_data            (rd_en),
//                .i_config_stride      (i_config_stride),
//                .i_config_max_line_in (i_config_max_line_in),
//                .i_config_max_line_out(i_config_max_line_out),
//                .o_linedata           (lb_raw[i]),
////                .o_window_valid       (lb_win_vld[i]),
//                .o_almost_done        (lb_done[i])
//            );
//        end
//    endgenerate

//    // -------------------------------------------------------------------------
//    // 5. Window Assembly
//    //
//    // o_window_valid t? rd_sel instance cho bi?t ðúng cycle lb_raw valid.
//    // 3 instance (rd_sel, p1, p2) ch?y ð?ng b? ? lb_win_vld[rd_sel] ð? ð? gate.
//    //
//    // Capture rd_sel/p1/p2 t?i cycle (o_window_valid - 1) ð? dùng cho cycle valid.
//    // V? o_window_valid là REGISTERED bên trong line_buffer (1 cycle tr? sau
//    // win_vld_s1/s2 combinational), c?n capture rd_sel 1 cycle trý?c.
//    // -------------------------------------------------------------------------
//    reg [2:0] rd_sel_r, rd_sel_p1_r, rd_sel_p2_r;

//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            rd_sel_r    <= 3'd0;
//            rd_sel_p1_r <= 3'd0;
//            rd_sel_p2_r <= 3'd0;
//        end else if (i_enable) begin
//            rd_sel_r    <= rd_sel;
//            rd_sel_p1_r <= rd_sel_p1;
//            rd_sel_p2_r <= rd_sel_p2;
//        end
//    end

//    // Gate: dùng lb_win_vld[rd_sel_r] - rd_sel ð? ðý?c registered
//    // lb_win_vld[rd_sel_r] ðúng v?i cycle lb_raw[rd_sel_r] valid
//    wire kernel_capture = lb_win_vld[rd_sel_r];

//    integer ch;
//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            o_kernel_data <= {KERNEL_W{1'b0}};
//            o_kernel_vld  <= 1'b0;
//        end else if (i_enable) begin
//            o_kernel_vld <= kernel_capture;
//            if (kernel_capture) begin
//                for (ch = 0; ch < 16; ch = ch + 1) begin
//                    o_kernel_data[ch*144 +: 144] <= {
//                        lb_raw[rd_sel_p2_r][ch*48 +: 48],  // row2
//                        lb_raw[rd_sel_p1_r][ch*48 +: 48],  // row1
//                        lb_raw[rd_sel_r   ][ch*48 +: 48]   // row0
//                    };
//                end
//            end
//        end
//    end

//endmodule