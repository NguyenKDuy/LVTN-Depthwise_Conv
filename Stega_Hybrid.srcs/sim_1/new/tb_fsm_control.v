`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 03/27/2026 02:06:32 PM
//// Design Name: 
//// Module Name: tb_fsm_control
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////

////==============================================================================
//// Testbench  : tb_rd_fsm_control
//// DUT        : rd_fsm_control
//// Reset      : Active-HIGH (i_rst=1 ? reset) - theo kh?i chính
////              C?NH BÁO: Kh?i weight trong DUT dùng !i_rst (active-low).
////              TB này dùng active-high nh?t quán theo yêu c?u.
////              Sau khi s?a DUT v? nh?t quán, không c?n thay ð?i g? ? TB.
////
//// Ki?n trúc:
////   ????????????????    stimulus    ???????????
////   ?  Driver/Task ? ?????????????? ?   DUT   ? ??? outputs
////   ????????????????                ???????????
////                                        ?
////                    ??????????????????????????????????????????
////                    ?                   ?                     ?
////             ??????????????   ????????????????????  ????????????????
////             ? Scoreboard ?   ? Functional Cover. ?  ?   Monitor    ?
////             ?(check logic?   ?(coverage groups)  ?  ? (X/Z/bound)  ?
////             ??????????????   ????????????????????  ????????????????
////
//// Test Groups:
////   [RST]    Reset correctness
////   [STG]    Stage sequencing & config outputs
////   [WLD]    Weight loading (depth / point / bias)
////   [PAD]    Padding FSM (L/PRE/NONE/POST)
////   [CTR]    Counter logic (lic/loc/row/col, first/last loop)
////   [MEM]    Memory address & swap logic
////   [COV]    Coverage summary
////==============================================================================

//module tb_rd_fsm_control;

////??????????????????????????????????????????????????????????????????????????????
//// 0. PARAMETERS
////??????????????????????????????????????????????????????????????????????????????
//parameter CLK_HALF       = 5;
//parameter ADDRESS_DATA   = 14;
//parameter ADDRESS_WEIGHT = 14;
//parameter ADDRESS_BIAS   = 5;
//parameter TIMEOUT_SHORT  = 300;
//parameter TIMEOUT_LONG   = 5000;

////??????????????????????????????????????????????????????????????????????????????
//// 1. SIGNAL DECLARATIONS
////??????????????????????????????????????????????????????????????????????????????
//reg         i_clk;
//reg         i_enable;
//reg         i_rst;
//reg         i_stage_done;
//reg         i_pw_cmp;
//reg         i_n_mem_valid;

//wire [1:0]  o_mode;
//wire [4:0]  o_config_dep_para;
//wire [4:0]  o_config_point_para;
//wire [1:0]  o_config_stride;
//wire [7:0]  o_config_max_line_in;
//wire [7:0]  o_config_max_line_out;
//wire [ADDRESS_DATA-1:0]   o_mem_rd_addr;
//wire                      o_mem_rd_enb;
//wire        o_padding_vld;
//wire        o_data_vld;
//wire [ADDRESS_WEIGHT-1:0] o_dweight_rd_addr;
//wire        o_dweight_ena;
//wire [ADDRESS_WEIGHT-1:0] o_pweight_rd_addr;
//wire        o_pweight_ena;
//wire [ADDRESS_BIAS-1:0]   o_bias_rd_addr;
//wire        o_bias_ena;
//wire        o_last_loop;
//wire        o_first_loop;
//wire        o_depth_sel;
//wire        o_point_sel;
//wire        o_bias_sel;
//wire [7:0]  o_lic_counter;
//wire [7:0]  o_row_counter;
//wire [7:0]  o_col_counter;
//wire [1:0]  o_mem_rd_swapping;
//wire [3:0]  o_stage;

////??????????????????????????????????????????????????????????????????????????????
//// 2. STAGE / ADDR_STAGE ENCODING (mirror from DUT)
////??????????????????????????????????????????????????????????????????????????????
//localparam S_IDLE        = 4'd0;
//localparam S_HEAD        = 4'd1;
//localparam S_DOWNS1      = 4'd2;
//localparam S_DOWNS2      = 4'd3;
//localparam S_DOWNS3      = 4'd4;
//localparam S_BOTT        = 4'd5;
//localparam S_UPS1        = 4'd6;
//localparam S_UPS2        = 4'd7;
//localparam S_UPS3        = 4'd8;
//localparam S_UPS4        = 4'd9;
//localparam S_TAIL        = 4'd10;
//localparam S_DONE        = 4'd11;
//localparam S_STREAM_OUT  = 4'd12;

//localparam AS_INIT         = 10'd0;
//localparam AS_LOAD_WEIGHT  = 10'd2;
//localparam AS_L_PADDING    = 10'd4;
//localparam AS_PRE_PADDING  = 10'd8;
//localparam AS_POST_PADDING = 10'd16;
//localparam AS_NONE_PADDING = 10'd32;
//localparam AS_IN_LAYER     = 10'd64;
//localparam AS_NEXT_STAGE   = 10'd128;
//localparam AS_MEM_SWAP     = 10'd256;
//localparam AS_TRANS_M_C    = 10'd512;

////??????????????????????????????????????????????????????????????????????????????
//// 3. DUT INSTANTIATION
////??????????????????????????????????????????????????????????????????????????????
//rd_fsm_control #(
//    .ADDRESS_DATA   (ADDRESS_DATA),
//    .ADDRESS_WEIGHT (ADDRESS_WEIGHT),
//    .ADDRESS_BIAS   (ADDRESS_BIAS)
//) dut (
//    .i_clk                (i_clk),
//    .i_enable             (i_enable),
//    .i_rst                (i_rst),
//    .i_stage_done         (i_stage_done),
//    .i_pw_cmp             (i_pw_cmp),
//    .i_n_mem_valid        (o_data_vld | o_padding_vld),
//    .o_mode               (o_mode),
//    .o_config_dep_para    (o_config_dep_para),
//    .o_config_point_para  (o_config_point_para),
//    .o_config_stride      (o_config_stride),
//    .o_config_max_line_in (o_config_max_line_in),
//    .o_config_max_line_out(o_config_max_line_out),
//    .o_mem_rd_addr        (o_mem_rd_addr),
//    .o_mem_rd_enb         (o_mem_rd_enb),
//    .o_padding_vld        (o_padding_vld),
//    .o_data_vld           (o_data_vld),
//    .o_dweight_rd_addr    (o_dweight_rd_addr),
//    .o_dweight_ena        (o_dweight_ena),
//    .o_pweight_rd_addr    (o_pweight_rd_addr),
//    .o_pweight_ena        (o_pweight_ena),
//    .o_bias_rd_addr       (o_bias_rd_addr),
//    .o_bias_ena           (o_bias_ena),
//    .o_last_loop          (o_last_loop),
//    .o_first_loop         (o_first_loop),
//    .o_depth_sel          (o_depth_sel),
//    .o_point_sel          (o_point_sel),
//    .o_bias_sel           (o_bias_sel),
//    .o_lic_counter        (o_lic_counter),
//    .o_row_counter        (o_row_counter),
//    .o_col_counter        (o_col_counter),
//    .o_mem_rd_swapping    (o_mem_rd_swapping),
//    .o_stage              (o_stage)
//);

////??????????????????????????????????????????????????????????????????????????????
//// 4. CLOCK & WAVEFORM
////??????????????????????????????????????????????????????????????????????????????
//initial i_clk = 0;
//always  #CLK_HALF i_clk = ~i_clk;

////initial begin
////    $dumpfile("tb_rd_fsm_control.vcd");
////    $dumpvars(0, tb_rd_fsm_control);
////end

//////??????????????????????????????????????????????????????????????????????????????
////// 5. SCOREBOARD
//////??????????????????????????????????????????????????????????????????????????????
////integer sb_pass  = 0;
////integer sb_fail  = 0;
////integer sb_total = 0;

////task sb_check;
////    input [255:0] grp;
////    input [255:0] desc;
////    input         got;
////    input         exp;
////    begin
////        sb_total = sb_total + 1;
////        if (got === exp) begin
////            sb_pass = sb_pass + 1;
////            $display("  [PASS] %s %s", grp, desc);
////        end else begin
////            sb_fail = sb_fail + 1;
////            $display("  [FAIL] %s %s | got=%0b exp=%0b @ t=%0t",
////                     grp, desc, got, exp, $time);
////        end
////    end
////endtask

////task sb_check_val;
////    input [255:0] grp;
////    input [255:0] desc;
////    input [31:0]  got;
////    input [31:0]  exp;
////    begin
////        sb_total = sb_total + 1;
////        if (got === exp) begin
////            sb_pass = sb_pass + 1;
////            $display("  [PASS] %s %s (=%0d)", grp, desc, got);
////        end else begin
////            sb_fail = sb_fail + 1;
////            $display("  [FAIL] %s %s | got=%0d exp=%0d @ t=%0t",
////                     grp, desc, got, exp, $time);
////        end
////    end
////endtask

//////??????????????????????????????????????????????????????????????????????????????
////// 6. FUNCTIONAL COVERAGE COUNTERS (Verilog-2001 manual coverage)
//////??????????????????????????????????????????????????????????????????????????????
////integer cov_stage      [0:12];
////integer cov_as_load    = 0;
////integer cov_as_lpad    = 0;
////integer cov_as_pre     = 0;
////integer cov_as_none    = 0;
////integer cov_as_post    = 0;
////integer cov_as_inlay   = 0;
////integer cov_as_next    = 0;
////integer cov_as_swap    = 0;
////integer cov_as_trans   = 0;
////integer cov_dw_ena     = 0;
////integer cov_pw_ena     = 0;
////integer cov_bias_ena   = 0;
////integer cov_dw_fin     = 0;
////integer cov_pw_fin     = 0;
////integer cov_bias_fin   = 0;
////integer cov_depth_sel1 = 0;
////integer cov_point_sel1 = 0;
////integer cov_bias_sel1  = 0;
////integer cov_pad_lpad   = 0;
////integer cov_pad_pre    = 0;
////integer cov_pad_none   = 0;
////integer cov_pad_post   = 0;
////integer cov_pad_vld1   = 0;
////integer cov_pad_vld0   = 0;
////integer cov_first_loop = 0;
////integer cov_last_loop  = 0;
////integer cov_both_loop  = 0;
////integer cov_mem_nonzero = 0;
////integer cov_mem_enb1    = 0;
////integer cov_n_mem_low   = 0;

////integer ci;
////initial begin
////    for (ci = 0; ci <= 12; ci = ci + 1)
////        cov_stage[ci] = 0;
////end

////always @(posedge i_clk) begin
////    if (dut.stage <= 12)
////        cov_stage[dut.stage] = cov_stage[dut.stage] + 1;
////    case (dut.addr_stage)
////        AS_LOAD_WEIGHT:  cov_as_load  = cov_as_load  + 1;
////        AS_L_PADDING:    cov_as_lpad  = cov_as_lpad  + 1;
////        AS_PRE_PADDING:  cov_as_pre   = cov_as_pre   + 1;
////        AS_NONE_PADDING: cov_as_none  = cov_as_none  + 1;
////        AS_POST_PADDING: cov_as_post  = cov_as_post  + 1;
////        AS_IN_LAYER:     cov_as_inlay = cov_as_inlay + 1;
////        AS_NEXT_STAGE:   cov_as_next  = cov_as_next  + 1;
////        AS_MEM_SWAP:     cov_as_swap  = cov_as_swap  + 1;
////        AS_TRANS_M_C:    cov_as_trans = cov_as_trans + 1;
////    endcase
////    if (o_dweight_ena)  cov_dw_ena     = cov_dw_ena    + 1;
////    if (o_pweight_ena)  cov_pw_ena     = cov_pw_ena    + 1;
////    if (o_bias_ena)     cov_bias_ena   = cov_bias_ena  + 1;
////    if (dut.d_finished) cov_dw_fin     = cov_dw_fin    + 1;
////    if (dut.p_finished) cov_pw_fin     = cov_pw_fin    + 1;
////    if (dut.b_finished) cov_bias_fin   = cov_bias_fin  + 1;
////    if (o_depth_sel)    cov_depth_sel1 = cov_depth_sel1+ 1;
////    if (o_point_sel)    cov_point_sel1 = cov_point_sel1+ 1;
////    if (o_bias_sel)     cov_bias_sel1  = cov_bias_sel1 + 1;
////    if (dut.addr_stage === AS_L_PADDING)    cov_pad_lpad = cov_pad_lpad + 1;
////    if (dut.addr_stage === AS_PRE_PADDING)  cov_pad_pre  = cov_pad_pre  + 1;
////    if (dut.addr_stage === AS_NONE_PADDING) cov_pad_none = cov_pad_none + 1;
////    if (dut.addr_stage === AS_POST_PADDING) cov_pad_post = cov_pad_post + 1;
////    if (o_padding_vld === 1) cov_pad_vld1 = cov_pad_vld1 + 1;
////    if (o_padding_vld === 0) cov_pad_vld0 = cov_pad_vld0 + 1;
////    if (o_first_loop)                cov_first_loop = cov_first_loop + 1;
////    if (o_last_loop)                 cov_last_loop  = cov_last_loop  + 1;
////    if (o_first_loop && o_last_loop) cov_both_loop  = cov_both_loop  + 1;
////    if (o_mem_rd_addr > 0)  cov_mem_nonzero = cov_mem_nonzero + 1;
////    if (o_mem_rd_enb  > 0)  cov_mem_enb1    = cov_mem_enb1    + 1;
////    if (!i_n_mem_valid)     cov_n_mem_low   = cov_n_mem_low   + 1;
////end

////task print_coverage;
////    integer s;
////    integer covered_items;
////    integer total_cov_items;
////    begin
////        $display("\n????????????????????????????????????????????????????????");
////        $display("?              FUNCTIONAL COVERAGE REPORT               ?");
////        $display("????????????????????????????????????????????????????????");

////        $display("\n?? Stage Coverage ?????????????????????????????????????");
////        covered_items   = 0;
////        total_cov_items = 13;
////        for (s = 0; s <= 12; s = s + 1) begin
////            if (cov_stage[s] > 0) begin
////                $display("  [HIT ] stage %2d  (%0d cycles)", s, cov_stage[s]);
////                covered_items = covered_items + 1;
////            end else
////                $display("  [MISS] stage %2d", s);
////        end
////        $display("  Stage coverage: %0d / %0d = %0d%%",
////                 covered_items, total_cov_items,
////                 (covered_items * 100) / total_cov_items);

////        $display("\n?? addr_stage Coverage ????????????????????????????????");
////        $display("  LOAD_WEIGHT  : %s (%0d cy)", cov_as_load  > 0 ? "HIT " : "MISS", cov_as_load );
////        $display("  L_PADDING    : %s (%0d cy)", cov_as_lpad  > 0 ? "HIT " : "MISS", cov_as_lpad );
////        $display("  PRE_PADDING  : %s (%0d cy)", cov_as_pre   > 0 ? "HIT " : "MISS", cov_as_pre  );
////        $display("  NONE_PADDING : %s (%0d cy)", cov_as_none  > 0 ? "HIT " : "MISS", cov_as_none );
////        $display("  POST_PADDING : %s (%0d cy)", cov_as_post  > 0 ? "HIT " : "MISS", cov_as_post );
////        $display("  IN_LAYER     : %s (%0d cy)", cov_as_inlay > 0 ? "HIT " : "MISS", cov_as_inlay);
////        $display("  NEXT_STAGE   : %s (%0d cy)", cov_as_next  > 0 ? "HIT " : "MISS", cov_as_next );
////        $display("  MEM_SWAP     : %s (%0d cy)", cov_as_swap  > 0 ? "HIT " : "MISS", cov_as_swap );
////        $display("  TRANS_M_C    : %s (%0d cy)", cov_as_trans > 0 ? "HIT " : "MISS", cov_as_trans);

////        $display("\n?? Weight Loading Coverage ????????????????????????????");
////        $display("  dweight_ena   : %s", cov_dw_ena    > 0 ? "HIT " : "MISS");
////        $display("  pweight_ena   : %s", cov_pw_ena    > 0 ? "HIT " : "MISS");
////        $display("  bias_ena      : %s", cov_bias_ena  > 0 ? "HIT " : "MISS");
////        $display("  d_finished    : %s", cov_dw_fin    > 0 ? "HIT " : "MISS");
////        $display("  p_finished    : %s", cov_pw_fin    > 0 ? "HIT " : "MISS");
////        $display("  b_finished    : %s", cov_bias_fin  > 0 ? "HIT " : "MISS");
////        $display("  depth_sel=1   : %s (mode=1)", cov_depth_sel1 > 0 ? "HIT " : "MISS");
////        $display("  point_sel=1   : %s (mode=0)", cov_point_sel1 > 0 ? "HIT " : "MISS");
////        $display("  bias_sel=1    : %s (mode=0)", cov_bias_sel1  > 0 ? "HIT " : "MISS");

////        $display("\n?? Padding Coverage ???????????????????????????????????");
////        $display("  L_PADDING  reached  : %s (%0d cy)", cov_pad_lpad > 0 ? "HIT " : "MISS", cov_pad_lpad);
////        $display("  PRE_PADDING reached : %s (%0d cy)", cov_pad_pre  > 0 ? "HIT " : "MISS", cov_pad_pre );
////        $display("  NONE_PADDING reached: %s (%0d cy)", cov_pad_none > 0 ? "HIT " : "MISS", cov_pad_none);
////        $display("  POST_PADDING reached: %s (%0d cy)", cov_pad_post > 0 ? "HIT " : "MISS", cov_pad_post);
////        $display("  padding_vld=1 seen  : %s (%0d cy)", cov_pad_vld1 > 0 ? "HIT " : "MISS", cov_pad_vld1);
////        $display("  padding_vld=0 seen  : %s (%0d cy)", cov_pad_vld0 > 0 ? "HIT " : "MISS", cov_pad_vld0);

////        $display("\n?? Loop Flag Coverage ?????????????????????????????????");
////        $display("  first_loop=1        : %s (%0d cy)", cov_first_loop > 0 ? "HIT " : "MISS", cov_first_loop);
////        $display("  last_loop=1         : %s (%0d cy)", cov_last_loop  > 0 ? "HIT " : "MISS", cov_last_loop );
////        $display("  first&&last (1-iter): %s (%0d cy)", cov_both_loop  > 0 ? "HIT " : "MISS", cov_both_loop );

////        $display("\n?? Memory Coverage ????????????????????????????????????");
////        $display("  mem_rd_addr > 0 : %s (%0d cy)", cov_mem_nonzero > 0 ? "HIT " : "MISS", cov_mem_nonzero);
////        $display("  mem_rd_enb  > 0 : %s (%0d cy)", cov_mem_enb1    > 0 ? "HIT " : "MISS", cov_mem_enb1   );
////        $display("  n_mem_valid = 0 : %s (%0d cy)", cov_n_mem_low   > 0 ? "HIT " : "MISS", cov_n_mem_low  );
////    end
////endtask

//////??????????????????????????????????????????????????????????????????????????????
////// 7. UTILITY TASKS
//////??????????????????????????????????????????????????????????????????????????????
////task clk_n;
////    input integer n;
////    integer k;
////    begin
////        for (k = 0; k < n; k = k+1) @(posedge i_clk);
////        #1;
////    end
////endtask

//// Active-HIGH reset
//task apply_reset;
//    begin
//        i_rst = 1;
//        @(posedge i_clk);
//        i_rst         = 0;
//        i_enable      = 0;
//        i_stage_done  = 0;
//        i_pw_cmp      = 0;
//        i_n_mem_valid = 1;
        
//        @(posedge i_clk);
//        @(posedge i_clk);
//        i_rst = 1;
//        i_enable      = 1;
//        @(posedge i_clk);
//        @(posedge i_clk);
//        i_enable      = 0;
//    end
//endtask

////task pulse_stage_done;
////    begin
////        @(posedge i_clk); #1;
////        i_stage_done = 1;
////        @(posedge i_clk); #1;
////        i_stage_done = 0;
////    end
////endtask

////task wait_as;
////    input [9:0]   target;
////    input integer timeout;
////    integer cnt;
////    begin
////        cnt = 0;
////        while (dut.addr_stage !== target) begin
////            if (cnt >= timeout) begin
////                $display("  [TIMEOUT] wait_as(%0d): stuck at %0d @ t=%0t",
////                         target, dut.addr_stage, $time);
////                disable wait_as;
////            end
////            @(posedge i_clk); #1;
////            cnt = cnt + 1;
////        end
////    end
////endtask

////task wait_stage_val;
////    input [3:0]   target;
////    input integer timeout;
////    integer cnt;
////    begin
////        cnt = 0;
////        while (dut.stage !== target) begin
////            if (cnt >= timeout) begin
////                $display("  [TIMEOUT] wait_stage(%0d): stuck at %0d @ t=%0t",
////                         target, dut.stage, $time);
////                disable wait_stage_val;
////            end
////            @(posedge i_clk); #1;
////            cnt = cnt + 1;
////        end
////    end
////endtask

////task fsm_start;
////    begin
////        i_enable = 1;
////        @(posedge i_clk); #1;
////        i_enable = 0;
////    end
////endtask

////// Advance ð?n target stage qua nhi?u NEXT_STAGE + stage_done
////task advance_to_stage;
////    input [3:0] target;
////    integer safety;
////    begin
////        safety = 0;
////        while (dut.stage !== target && safety < 60) begin
////            wait_as(AS_NEXT_STAGE, TIMEOUT_LONG);
////            pulse_stage_done();
////            clk_n(3);
////            safety = safety + 1;
////        end
////        if (dut.stage !== target)
////            $display("  [WARN] advance_to_stage: không ð?t stage %0d (hi?n=%0d)",
////                     target, dut.stage);
////    end
////endtask

//////??????????????????????????????????????????????????????????????????????????????
////// 8. MONITORS
//////??????????????????????????????????????????????????????????????????????????????

////// Monitor A: stage transition logger
////reg [3:0] mon_prev_stage = 4'd0;
////always @(posedge i_clk) begin
////    if (dut.stage !== mon_prev_stage) begin
////        $display("  [MON-STG] t=%0t: stage %0d ? %0d",
////                 $time, mon_prev_stage, dut.stage);
////        mon_prev_stage <= dut.stage;
////    end
////end

////// Monitor B: addr_stage transition logger
////reg [9:0] mon_prev_as = 10'd0;
////always @(posedge i_clk) begin
////    if (dut.addr_stage !== mon_prev_as) begin
////        $display("  [MON-AS ] t=%0t: addr_stage %0d ? %0d",
////                 $time, mon_prev_as, dut.addr_stage);
////        mon_prev_as <= dut.addr_stage;
////    end
////end

////// Monitor C: X/Z trên output quan tr?ng
////always @(posedge i_clk) begin
////    if (i_rst === 0) begin
////        if (^o_mem_rd_addr === 1'bx)
////            $display("  [MON-X] o_mem_rd_addr=X @ t=%0t", $time);
////        if (^o_config_dep_para === 1'bx)
////            $display("  [MON-X] o_config_dep_para=X @ t=%0t", $time);
////        if (o_dweight_ena && ^o_dweight_rd_addr === 1'bx)
////            $display("  [MON-X] dweight_rd_addr=X khi ena=1 @ t=%0t", $time);
////        if (o_pweight_ena && ^o_pweight_rd_addr === 1'bx)
////            $display("  [MON-X] pweight_rd_addr=X khi ena=1 @ t=%0t", $time);
////        if (o_bias_ena && ^o_bias_rd_addr === 1'bx)
////            $display("  [MON-X] bias_rd_addr=X khi ena=1 @ t=%0t", $time);
////    end
////end

////// Monitor D: mem_rd_addr overflow
////always @(posedge i_clk) begin
////    if ((dut.addr_stage === AS_NONE_PADDING || dut.addr_stage === AS_PRE_PADDING)
////        && dut.max_address_p > 0
////        && o_mem_rd_addr > dut.max_address_p)
////        $display("  [MON-OVF] mem_rd_addr=%0d > max_address_p=%0d @ t=%0t",
////                 o_mem_rd_addr, dut.max_address_p, $time);
////end

////// Monitor E: collision load_valid và data_vld
////always @(posedge i_clk) begin
////    if (dut.load_valid_tmp && o_data_vld)
////        $display("  [MON-COL] load_valid_tmp=1 && data_vld=1 cùng lúc @ t=%0t", $time);
////end

//////??????????????????????????????????????????????????????????????????????????????
////// 9. MAIN TEST SEQUENCE
//////??????????????????????????????????????????????????????????????????????????????
////integer i;

//initial begin
//    apply_reset();
//end

////initial begin
////    $display("????????????????????????????????????????????????????????");
////    $display("?       TB rd_fsm_control  -  Chuyên Sâu               ?");
////    $display("?  Reset: Active-HIGH  |  All stages + WLD + PAD       ?");
////    $display("????????????????????????????????????????????????????????");

////    //==========================================================================
////    // [RST] Reset tests
////    //==========================================================================
////    $display("\n?? [RST] Power-on reset ??????????????????????????????");
////    apply_reset();
////    sb_check    ("[RST]", "stage=IDLE",          dut.stage === S_IDLE,       1);
////    sb_check    ("[RST]", "addr_stage=INIT",      dut.addr_stage === AS_INIT, 1);
////    sb_check_val("[RST]", "mem_rd_addr=0",        o_mem_rd_addr,              0);
////    sb_check_val("[RST]", "lic_counter=0",        o_lic_counter,              0);
////    sb_check_val("[RST]", "row_counter=0",        o_row_counter,              0);
////    sb_check_val("[RST]", "col_counter=0",        o_col_counter,              0);
////    sb_check    ("[RST]", "padding_vld=0",        o_padding_vld,              0);
////    sb_check    ("[RST]", "data_vld=0",           o_data_vld,                 0);
////    $display("  [INFO-RST] Kh?i weight dùng active-low: dw_ena=%0b pw_ena=%0b bias_ena=%0b",
////             o_dweight_ena, o_pweight_ena, o_bias_ena);

////    $display("\n?? [RST] i_enable=0 gi? IDLE ??????????????????????");
////    i_enable = 0; clk_n(10);
////    sb_check("[RST]", "stage=IDLE khi enable=0",     dut.stage === S_IDLE,    1);
////    sb_check("[RST]", "addr_stage=INIT khi enable=0", dut.addr_stage === AS_INIT, 1);

////    $display("\n?? [RST] Reset gi?a ch?ng ??????????????????????????");
////    fsm_start(); clk_n(15);
////    apply_reset();
////    sb_check    ("[RST]", "stage=IDLE sau mid-reset",      dut.stage === S_IDLE,    1);
////    sb_check    ("[RST]", "addr_stage=INIT sau mid-reset", dut.addr_stage === AS_INIT, 1);
////    sb_check_val("[RST]", "mem_rd_addr=0 sau mid-reset",   o_mem_rd_addr,           0);

////    //==========================================================================
////    // [STG] Stage config - t?t c? 12 stages
////    //==========================================================================
////    $display("\n?? [STG] Stage sequencing & config ??????????????????");

////    $display("\n?? [STG] IDLE ? HEAD ???????????????????????????????");
////    apply_reset();
////    fsm_start(); clk_n(2);
////    sb_check    ("[STG]", "stage=HEAD sau enable",         dut.stage === S_HEAD,           1);
////    sb_check    ("[STG]", "addr_stage=LOAD_WEIGHT",        dut.addr_stage === AS_LOAD_WEIGHT, 1);
////    @(posedge i_clk); #1;
////    sb_check_val("[STG]", "HEAD dep_para=6",               o_config_dep_para,    6);
////    sb_check_val("[STG]", "HEAD point_para=16",            o_config_point_para,  16);
////    sb_check_val("[STG]", "HEAD max_line_in=128",          o_config_max_line_in, 128);
////    sb_check_val("[STG]", "HEAD max_line_out=128",         o_config_max_line_out,128);
////    sb_check_val("[STG]", "HEAD mode=0",                   o_mode,               0);
////    sb_check_val("[STG]", "HEAD stride=1",                 o_config_stride,      1);

////    $display("\n?? [STG] Config t?t c? stages HEAD?STREAM_OUT ??????");
////    // B?ng k? v?ng {stride, dep, point, mli, mlo, mode}
////    begin : stg_all
////        reg [7:0] exp_stride [1:12];
////        reg [7:0] exp_dep    [1:12];
////        reg [7:0] exp_point  [1:12];
////        reg [7:0] exp_mli    [1:12];
////        reg [7:0] exp_mlo    [1:12];
////        reg [1:0] exp_mode   [1:12];

////        exp_stride[1]=1;  exp_dep[1]=6;  exp_point[1]=16; exp_mli[1]=128; exp_mlo[1]=128; exp_mode[1]=0;
////        exp_stride[2]=2;  exp_dep[2]=16; exp_point[2]=16; exp_mli[2]=128; exp_mlo[2]=64;  exp_mode[2]=0;
////        exp_stride[3]=2;  exp_dep[3]=16; exp_point[3]=16; exp_mli[3]=64;  exp_mlo[3]=32;  exp_mode[3]=0;
////        exp_stride[4]=2;  exp_dep[4]=16; exp_point[4]=16; exp_mli[4]=32;  exp_mlo[4]=16;  exp_mode[4]=0;
////        exp_stride[5]=2;  exp_dep[5]=16; exp_point[5]=16; exp_mli[5]=16;  exp_mlo[5]=8;   exp_mode[5]=0;
////        exp_stride[6]=1;  exp_dep[6]=16; exp_point[6]=16; exp_mli[6]=16;  exp_mlo[6]=16;  exp_mode[6]=1;
////        exp_stride[7]=1;  exp_dep[7]=16; exp_point[7]=16; exp_mli[7]=32;  exp_mlo[7]=32;  exp_mode[7]=1;
////        exp_stride[8]=1;  exp_dep[8]=16; exp_point[8]=16; exp_mli[8]=64;  exp_mlo[8]=64;  exp_mode[8]=1;
////        exp_stride[9]=1;  exp_dep[9]=16; exp_point[9]=16; exp_mli[9]=128; exp_mlo[9]=128; exp_mode[9]=1;
////        exp_stride[10]=1; exp_dep[10]=16;exp_point[10]=3; exp_mli[10]=128;exp_mlo[10]=128;exp_mode[10]=0;
////        exp_stride[11]=1; exp_dep[11]=0; exp_point[11]=0; exp_mli[11]=128;exp_mlo[11]=128;exp_mode[11]=0;
////        exp_stride[12]=1; exp_dep[12]=0; exp_point[12]=0; exp_mli[12]=128;exp_mlo[12]=128;exp_mode[12]=0;

////        // Ðang ? HEAD (stage 1), l?n lý?t check t?ng stage r?i advance
////        for (i = 1; i <= 12; i = i + 1) begin
////            @(posedge i_clk); #1;
////            $display("  --- stage %0d ---", i);
////            sb_check_val("[STG]", "stride",      o_config_stride,       exp_stride[i]);
////            sb_check_val("[STG]", "dep_para",    o_config_dep_para,     exp_dep[i]);
////            sb_check_val("[STG]", "point_para",  o_config_point_para,   exp_point[i]);
////            sb_check_val("[STG]", "max_line_in", o_config_max_line_in,  exp_mli[i]);
////            sb_check_val("[STG]", "max_line_out",o_config_max_line_out, exp_mlo[i]);
////            sb_check_val("[STG]", "mode",        o_mode,                exp_mode[i]);
////            if (i < 12) begin
////                wait_as(AS_NEXT_STAGE, TIMEOUT_LONG);
////                pulse_stage_done();
////                clk_n(3);
////            end
////        end
////    end

////    //==========================================================================
////    // [WLD] Weight loading tests
////    //==========================================================================
////    $display("\n?? [WLD] Weight loading ??????????????????????????????");

////    $display("\n?? [WLD] HEAD: load_valid_tmp và ena signals ????????");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    wait_as(AS_LOAD_WEIGHT, TIMEOUT_SHORT);
////    clk_n(2);
////    sb_check("[WLD]", "load_valid_tmp=1 trong LOAD_WEIGHT", dut.load_valid_tmp, 1);
////    $display("  [INFO-WLD] dw_ena=%0b pw_ena=%0b bias_ena=%0b",
////             o_dweight_ena, o_pweight_ena, o_bias_ena);
////    $display("  [INFO-WLD] dw_addr=%0d pw_addr=%0d bias_addr=%0d",
////             o_dweight_rd_addr, o_pweight_rd_addr, o_bias_rd_addr);
////    sb_check("[WLD]", "dweight_ena lên 1 (c?n bug addr_lcnt s?a)",
////             (cov_dw_ena > 0), 1);
////    sb_check("[WLD]", "pweight_ena lên 1 (c?n bug addr_lcnt s?a)",
////             (cov_pw_ena > 0), 1);
////    sb_check("[WLD]", "bias_ena lên 1 (c?n bug addr_lcnt s?a)",
////             (cov_bias_ena > 0), 1);

////    $display("\n?? [WLD] Ch? d/p/b_finished ?????????????????????????");
////    begin : wld_fin_wait
////        integer wc;
////        wc = 0;
////        while (!(dut.d_finished && dut.p_finished && dut.b_finished)) begin
////            if (wc > TIMEOUT_LONG) begin
////                $display("  [TIMEOUT-WLD] Finished flags stuck - bug addr_lcnt chýa s?a");
////                disable wld_fin_wait;
////            end
////            @(posedge i_clk); #1;
////            wc = wc + 1;
////        end
////    end
////    sb_check("[WLD]", "d_finished set", dut.d_finished, 1);
////    sb_check("[WLD]", "p_finished set", dut.p_finished, 1);
////    sb_check("[WLD]", "b_finished set", dut.b_finished, 1);
////    wait_as(AS_L_PADDING, TIMEOUT_SHORT);
////    sb_check("[WLD]", "Sau finished ? addr_stage=L_PADDING", dut.addr_stage === AS_L_PADDING, 1);
////    sb_check("[WLD]", "load_valid_tmp=0 sau finish",          dut.load_valid_tmp, 0);

////    $display("\n?? [WLD] HEAD: base address check ???????????????????");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    wait_as(AS_LOAD_WEIGHT, TIMEOUT_SHORT);
////    clk_n(1);
////    sb_check_val("[WLD]", "HEAD: dweight base addr = 0 (HEAD_DW_B)",   o_dweight_rd_addr, 0);
////    sb_check_val("[WLD]", "HEAD: pweight base addr = 0 (HEAD_PW_B)",   o_pweight_rd_addr, 0);
////    sb_check_val("[WLD]", "HEAD: bias base addr    = 0 (HEAD_B_B)",    o_bias_rd_addr,    0);

////    $display("\n?? [WLD] BOTT: base address check ???????????????????");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    advance_to_stage(S_BOTT);
////    wait_as(AS_LOAD_WEIGHT, TIMEOUT_SHORT);
////    clk_n(1);
////    sb_check_val("[WLD]", "BOTT: dweight base addr = 30 (B_DW_B)",  o_dweight_rd_addr, 30);
////    sb_check_val("[WLD]", "BOTT: pweight base addr = 170 (B_PW_B)", o_pweight_rd_addr, 170);
////    sb_check_val("[WLD]", "BOTT: bias base addr    = 15 (B_B_B)",   o_bias_rd_addr,    15);

////    $display("\n?? [WLD] UPS1 mode=1: depth_sel timing ??????????????");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    advance_to_stage(S_UPS1);
////    wait_as(AS_LOAD_WEIGHT, TIMEOUT_SHORT);
////    clk_n(1);
////    sb_check("[WLD]", "UPS1: mode=1", o_mode === 1, 1);
////    // mode=1 ? depth_sel lên ? dweight_cnt==3
////    begin : wld_ups1
////        integer wu;
////        wu = 0;
////        while (!o_depth_sel && !dut.d_finished && wu < TIMEOUT_SHORT) begin
////            @(posedge i_clk); #1;
////            wu = wu + 1;
////        end
////    end
////    $display("  [INFO-WLD-UPS1] depth_sel=%0b d_finished=%0b",
////             o_depth_sel, dut.d_finished);
////    sb_check("[WLD]", "UPS1: depth_sel lên 1 khi dweight_cnt==3",
////             (cov_depth_sel1 > 0), 1);

////    $display("\n?? [WLD] UPS3 (mode=1): base address check ??????????");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    advance_to_stage(S_UPS3);
////    wait_as(AS_LOAD_WEIGHT, TIMEOUT_SHORT);
////    clk_n(1);
////    // U3_DW_B=160, U3_PW_B=746, U3_B_B=29
////    sb_check_val("[WLD]", "UPS3: dweight base = 160", o_dweight_rd_addr, 160);
////    sb_check_val("[WLD]", "UPS3: pweight base = 746", o_pweight_rd_addr, 746);
////    sb_check_val("[WLD]", "UPS3: bias base    = 29",  o_bias_rd_addr,    29);

////    //==========================================================================
////    // [PAD] Padding FSM tests
////    //==========================================================================
////    $display("\n?? [PAD] Padding FSM ????????????????????????????????");

////    $display("\n?? [PAD] HEAD: full padding sequence ????????????????");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);

////    // L_PADDING
////    wait_as(AS_L_PADDING, TIMEOUT_LONG);
////    sb_check("[PAD]", "Ð?t L_PADDING",              dut.addr_stage === AS_L_PADDING, 1);
////    sb_check("[PAD]", "padding_vld=1 t?i L_PADDING", o_padding_vld, 1);
////    sb_check("[PAD]", "mem_rd_enb=0 t?i L_PADDING",  o_mem_rd_enb === 0, 1);

////    // PRE_PADDING
////    wait_as(AS_PRE_PADDING, TIMEOUT_LONG);
////    sb_check("[PAD]", "Ð?t PRE_PADDING",              dut.addr_stage === AS_PRE_PADDING, 1);
////    sb_check("[PAD]", "padding_vld=0 t?i PRE_PADDING", o_padding_vld, 0);
////    sb_check("[PAD]", "mem_rd_enb=1 t?i PRE_PADDING",  o_mem_rd_enb > 0, 1);

////    // NONE_PADDING
////    wait_as(AS_NONE_PADDING, TIMEOUT_SHORT);
////    sb_check("[PAD]", "Ð?t NONE_PADDING",              dut.addr_stage === AS_NONE_PADDING, 1);
////    sb_check("[PAD]", "padding_vld=0 t?i NONE_PADDING", o_padding_vld, 0);
////    sb_check("[PAD]", "mem_rd_enb=1 t?i NONE_PADDING",  o_mem_rd_enb > 0, 1);

////    // POST_PADDING (sau khi col == max_line_in)
////    wait_as(AS_POST_PADDING, TIMEOUT_LONG);
////    sb_check("[PAD]", "Ð?t POST_PADDING",              dut.addr_stage === AS_POST_PADDING, 1);
////    sb_check("[PAD]", "padding_vld=1 t?i POST_PADDING", o_padding_vld, 1);
////    sb_check("[PAD]", "mem_rd_enb=0 t?i POST_PADDING",  o_mem_rd_enb === 0, 1);
////    sb_check_val("[PAD]", "col_counter reset=0 t?i POST", o_col_counter, 0);

////    // POST ? PRE (row chýa ð?)
////    wait_as(AS_PRE_PADDING, TIMEOUT_SHORT);
////    sb_check("[PAD]", "POST ? PRE_PADDING (row chýa max)", dut.addr_stage === AS_PRE_PADDING, 1);
////    sb_check_val("[PAD]", "row_counter tãng = 1",            o_row_counter, 1);

////    $display("\n?? [PAD] Ki?m tra padding_vld trên 30 cycles ????????");
////    begin : pad_vld_obs
////        integer p;
////        integer ok_lpad  = 0;
////        integer ok_pre   = 0;
////        integer ok_none  = 0;
////        integer ok_post  = 0;
////        for (p = 0; p < 30; p = p + 1) begin
////            @(posedge i_clk); #1;
////            case (dut.addr_stage)
////                AS_L_PADDING:    if (o_padding_vld === 1) ok_lpad = 1;
////                AS_PRE_PADDING:  if (o_padding_vld === 0) ok_pre  = 1;
////                AS_NONE_PADDING: if (o_padding_vld === 0) ok_none = 1;
////                AS_POST_PADDING: if (o_padding_vld === 1) ok_post = 1;
////            endcase
////        end
////        sb_check("[PAD]", "L_PADDING:    padding_vld=1", ok_lpad, 1);
////        sb_check("[PAD]", "PRE_PADDING:  padding_vld=0", ok_pre,  1);
////        sb_check("[PAD]", "NONE_PADDING: padding_vld=0", ok_none, 1);
////        sb_check("[PAD]", "POST_PADDING: padding_vld=1", ok_post, 1);
////    end

////    //==========================================================================
////    // [CTR] Counter tests
////    //==========================================================================
////    $display("\n?? [CTR] Counter & loop flag tests ??????????????????");

////    $display("\n?? [CTR] HEAD (max_lic=1, max_loc=1): first=last=1 ?");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    @(posedge i_clk); #1;
////    sb_check("[CTR]", "HEAD: first_loop=1 (lic=0,loc=0)", o_first_loop, 1);
////    sb_check("[CTR]", "HEAD: last_loop=1  (max=1,1)",      o_last_loop,  1);

////    $display("\n?? [CTR] DOWNS2 (max_lic=2, max_loc=2) ?????????????");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    advance_to_stage(S_DOWNS2);
////    @(posedge i_clk); #1;
////    sb_check("[CTR]", "DOWNS2: first_loop=1  khi lic=0,loc=0", o_first_loop, 1);
////    sb_check("[CTR]", "DOWNS2: last_loop=0   khi lic=0,loc=0", o_last_loop,  0);

////    // Advance IN_LAYER ? lic_counter tãng
////    wait_as(AS_IN_LAYER, TIMEOUT_LONG);
////    sb_check("[CTR]", "DOWNS2: ð?t IN_LAYER", dut.addr_stage === AS_IN_LAYER, 1);
////    @(posedge i_clk); #1;
////    $display("  [INFO-CTR] Sau IN_LAYER: lic=%0d loc=%0d",
////             o_lic_counter, dut.loc_counter);

////    $display("\n?? [CTR] BOTT (max_lic=8, max_loc=8): multi-iter ???");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    advance_to_stage(S_BOTT);
////    @(posedge i_clk); #1;
////    sb_check("[CTR]", "BOTT: first_loop=1", o_first_loop, 1);
////    sb_check("[CTR]", "BOTT: last_loop=0 t?i ð?u (max=8×8)", o_last_loop, 0);

////    //==========================================================================
////    // [MEM] Memory address tests
////    //==========================================================================
////    $display("\n?? [MEM] Memory address & control ???????????????????");

////    $display("\n?? [MEM] mem_rd_addr tãng trong NONE_PADDING ????????");
////    apply_reset();
////    fsm_start();
////    wait_stage_val(S_HEAD, TIMEOUT_SHORT);
////    wait_as(AS_NONE_PADDING, TIMEOUT_LONG);
////    begin : mem_addr_inc
////        reg [ADDRESS_DATA-1:0] prev_a;
////        reg [ADDRESS_DATA-1:0] curr_a;
////        integer m;
////        integer inc_ok;
////        prev_a = o_mem_rd_addr;
////        inc_ok = 0;
////        for (m = 0; m < 10; m = m + 1) begin
////            @(posedge i_clk); #1;
////            curr_a = o_mem_rd_addr;
////            if (curr_a === prev_a + 1) inc_ok = 1;
////            prev_a = curr_a;
////        end
////        sb_check("[MEM]", "mem_rd_addr tãng 1/cycle trong NONE_PADDING", inc_ok, 1);
////    end

////    $display("\n?? [MEM] mem_rd_enb=0 trong L_PADDING ??????????????");
////    wait_as(AS_L_PADDING, TIMEOUT_LONG);
////    @(posedge i_clk); #1;
////    sb_check("[MEM]", "mem_rd_enb=0 trong L_PADDING", o_mem_rd_enb === 0, 1);

////    $display("\n?? [MEM] TRANS_M_C ? MEM_SWAP khi n_mem_valid=0 ????");
////    wait_as(AS_TRANS_M_C, TIMEOUT_LONG);
////    if (dut.addr_stage === AS_TRANS_M_C) begin
////        sb_check("[MEM]", "Ð?t TRANS_M_C", dut.addr_stage === AS_TRANS_M_C, 1);
////        i_n_mem_valid = 0;
////        @(posedge i_clk); #1;
////        wait_as(AS_MEM_SWAP, TIMEOUT_SHORT);
////        sb_check("[MEM]", "TRANS_M_C?MEM_SWAP khi n_mem_valid=0",
////                 dut.addr_stage === AS_MEM_SWAP, 1);
////        i_n_mem_valid = 1;
////    end else begin
////        i_n_mem_valid = 0; clk_n(5);
////        $display("  [INFO-MEM] Chýa ð?t TRANS_M_C (addr_stage=%0d), ph? thu?c bug addr_lcnt",
////                 dut.addr_stage);
////        i_n_mem_valid = 1;
////    end

////    $display("\n?? [MEM] mem_rd_addr reset=0 sau NEXT_STAGE ?????????");
////    wait_as(AS_NEXT_STAGE, TIMEOUT_LONG);
////    pulse_stage_done();
////    clk_n(3);
////    sb_check_val("[MEM]", "mem_rd_addr=0 sau NEXT_STAGE", o_mem_rd_addr, 0);

////    //==========================================================================
////    // [COV] Coverage report
////    //==========================================================================
////    print_coverage();

////    //==========================================================================
////    // SCOREBOARD SUMMARY
////    //==========================================================================
////    $display("\n????????????????????????????????????????????????????????");
////    $display("?                  SCOREBOARD SUMMARY                   ?");
////    $display("????????????????????????????????????????????????????????");
////    $display("?  PASS  : %-5d                                        ?", sb_pass);
////    $display("?  FAIL  : %-5d                                        ?", sb_fail);
////    $display("?  TOTAL : %-5d                                        ?", sb_total);
////    $display("????????????????????????????????????????????????????????");
////    if (sb_fail === 0)
////        $display("?  ALL PASS                                            ?");
////    else
////        $display("?  CO %0d TEST THAT BAI - xem log o tren              ?", sb_fail);
////    $display("????????????????????????????????????????????????????????");

////    #100; $finish;
////end

//////??????????????????????????????????????????????????????????????????????????????
////// 10. GLOBAL TIMEOUT
//////??????????????????????????????????????????????????????????????????????????????
////initial begin
////    #10_000_000;
////    $display("[GLOBAL TIMEOUT] >10ms. PASS=%0d FAIL=%0d", sb_pass, sb_fail);
////    print_coverage();
////    $finish;
////end

//endmodule

`timescale 1ns/1ps

module tb_fsm_control;

// ??? Parameters ???????????????????????????????????????????
parameter CLK_PERIOD = 10;

// ??? DUT Ports ????????????????????????????????????????????
reg         i_clk;
reg         i_enable;
reg         i_rst;          // active LOW
reg         i_stage_done;
wire         o_rst_pw_cmp;
reg         i_n_mem_valid;

wire [7:0]  o_mode;
wire [7:0]  o_config_dep_para;
wire [7:0]  o_config_point_para;
wire [7:0]  o_config_stride;
wire [7:0]  o_config_max_line_in;
wire [7:0]  o_config_max_line_out;
wire [13:0] o_mem_rd_addr;
wire        o_mem_rd_enb;
wire        o_padding_vld;
wire [15:0] o_dweight_rd_addr;
wire        o_dweight_ena;
wire [15:0] o_pweight_rd_addr;
wire        o_pweight_ena;
wire [15:0] o_bias_rd_addr;
wire        o_bias_ena;
wire        o_last_loop;
wire        o_first_loop;
wire [3:0]  o_depth_sel;
wire [3:0]  o_point_sel;
wire [3:0]  o_bias_sel;
wire [3:0]  o_lic_counter;
wire [7:0]  o_row_counter;
wire [7:0]  o_col_counter;
wire [1:0]  o_mem_rd_swapping;
wire [3:0]  o_stage;

// ??? DUT Instantiation ????????????????????????????????????
rd_fsm_control u_dut (
    .i_clk              (i_clk),
    .i_enable           (i_enable),
    .i_rst              (i_rst),
    .i_stage_done       (i_stage_done),

    .i_n_mem_valid      (i_n_mem_valid),

    .o_mode             (o_mode),
    .o_config_dep_para  (o_config_dep_para),
    .o_config_point_para(o_config_point_para),
    .o_config_stride    (o_config_stride),
    .o_config_max_line_in (o_config_max_line_in),
    .o_config_max_line_out(o_config_max_line_out),
    .o_mem_rd_addr      (o_mem_rd_addr),
    .o_mem_rd_enb       (o_mem_rd_enb),
    .o_padding_vld      (o_padding_vld),
    .o_dweight_rd_addr  (o_dweight_rd_addr),
    .o_dweight_ena      (o_dweight_ena),
    .o_pweight_rd_addr  (o_pweight_rd_addr),
    .o_pweight_ena      (o_pweight_ena),
    .o_bias_rd_addr     (o_bias_rd_addr),
    .o_bias_ena         (o_bias_ena),
    .o_last_loop        (o_last_loop),
    .o_first_loop       (o_first_loop),
    .o_depth_sel        (o_depth_sel),
    .o_point_sel        (o_point_sel),
    .o_bias_sel         (o_bias_sel),
    .o_lic_counter      (o_lic_counter),
    .o_row_counter      (o_row_counter),
    .o_col_counter      (o_col_counter),
    .o_mem_rd_swapping  (o_mem_rd_swapping),
    .o_rst_pw_cmp       (o_rst_pw_cmp),
    .o_stage            (o_stage)
);

// ??? Clock Gen ????????????????????????????????????????????
initial i_clk = 0;
always #(CLK_PERIOD/2) i_clk = ~i_clk;

// ??? Monitor: in ra ngay khi tín hi?u quan tâm thay ð?i ??
// Dùng $monitor ð? auto-fire - không c?n vi?t trong always block
//initial begin
//    $display("=== MONITOR START ===");
//    $display("%-8s | %-5s | %-5s | %-5s | STG | SWP | LIC | ROW | COL | RD_ADDR | ENB | PAD",
//             "TIME", "SDONE", "PWCMP", "NVAL");
//    $display("---------|-------|-------|-------|-----|-----|-----|-----|-----|---------|-----|----");
//    $monitor("%8t | %5b | %5b | %5b |  %1h  |  %b  | %3d | %3d | %3d | 0x%04h  |  %b  |  %b",
//             $time,
//             i_stage_done, i_pw_cmp, i_n_mem_valid,
//             o_stage, o_mem_rd_swapping,
//             o_lic_counter, o_row_counter, o_col_counter,
//             o_mem_rd_addr, o_mem_rd_enb, o_padding_vld);
//end
// ??? Header (in 1 l?n) ????????????????????????????????????
initial begin
    $display("               TIME | SDONE |  NVAL | STG | SWP | LIC | ROW | COL | RD_ADDR | ENB | PAD");
    $display("-------|-------|-------|-----|-----|-----|-----|-----|---------|-----|-----");
end

// ??? Log m?i posedge ??????????????????????????????????????
always @(posedge i_clk) begin
    $display("%6t |   %b   |   %b   |  %1h  |  %b  | %3d | %3d | %3d | %6d  |  %b  |  %b",
        $time,
        i_stage_done,
        i_n_mem_valid,
        o_stage,
        o_mem_rd_swapping,
        o_lic_counter,
        o_row_counter,
        o_col_counter,
        o_mem_rd_addr,
        o_mem_rd_enb,
        o_padding_vld);
end

// ??? Per-clock snapshot (ð? xem ð?u ð?n theo cycle) ??????
//integer cycle_cnt;
//initial cycle_cnt = 0;
//always @(posedge i_clk) begin
//    cycle_cnt = cycle_cnt + 1;
//    // In m?i N cycle - ð?i s? 1 thành 5, 10 tu? mu?n
//    if (cycle_cnt % 1 == 0)
//        $display("[CYC %0d] stage=%0d swap=%b | lic=%0d row=%0d col=%0d | addr=0x%04h enb=%b pad=%b",
//                 cycle_cnt, o_stage, o_mem_rd_swapping,
//                 o_lic_counter, o_row_counter, o_col_counter,
//                 o_mem_rd_addr, o_mem_rd_enb, o_padding_vld);
//end

// ??? Tasks ????????????????????????????????????????????????
task do_reset;
    begin
        $display("\n>>> RESET ASSERT at %0t", $time);
        i_rst        = 0;   // active low
        i_enable     = 0;
        i_stage_done = 0;
        i_n_mem_valid = 1;
        @(posedge i_clk); #1;
        @(posedge i_clk); #1;
        i_rst = 1;          // release reset
        $display(">>> RESET RELEASE at %0t\n", $time);
    end
endtask

task send_stage_done;
    input integer hold_cycles;
    begin
        $display(">>> STAGE_DONE pulse (%0d cycles) at %0t", hold_cycles, $time);
        i_stage_done = 1;
        repeat(hold_cycles) @(posedge i_clk);
        #1;
        i_stage_done = 0;
    end
endtask

task wait_cycles;
    input integer n;
    begin
        repeat(n) @(posedge i_clk);
        #1;
    end
endtask

// ??? Stimulus ?????????????????????????????????????????????
initial begin
    // Init
    i_rst         = 0;
    i_enable      = 0;
    i_stage_done  = 0;
    i_n_mem_valid = 1;

    // Dump waveform n?u dùng GTKWave
//    $dumpfile("tb_your_module.vcd");
//    $dumpvars(0, tb_your_module);

    // ?? Test 1: basic reset + enable ??
    $display("\n=== TEST 1: Reset + Enable ===");
    do_reset;
    i_enable = 1;
    
    
    
//    // ?? Test 2: kích stage_done 3 l?n ??
//    $display("\n=== TEST 2: 3x stage transitions ===");
//    repeat(3) begin
//        wait_cycles(4);
//        send_stage_done(2);
//    end
//    wait_cycles(8);

//    // ?? Test 3: n_mem_valid = 0 (stall) ??
//    $display("\n=== TEST 3: mem stall ===");
//    i_n_mem_valid = 0;
//    wait_cycles(5);
//    i_n_mem_valid = 1;
//    wait_cycles(5);

//    // ?? Test 4: disable r?i re-enable ??
//    $display("\n=== TEST 4: Disable / Re-enable ===");
//    i_enable = 0;
//    wait_cycles(4);
//    i_enable = 1;
//    wait_cycles(6);

//    $display("\n=== SIMULATION DONE ===");
//    $finish;
end

endmodule