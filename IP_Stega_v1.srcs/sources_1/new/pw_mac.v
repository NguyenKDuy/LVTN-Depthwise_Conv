
module pw_mac #(
    parameter DATA_WIDTH   = 16,
    parameter IN_CHANNELS  = 16,
    parameter OUT_CHANNELS = 16,
    parameter PSUM_WIDTH   = (DATA_WIDTH * 2) + $clog2(IN_CHANNELS),
    // parameter NUM_LEVELS   = 7,
    parameter SHIFT_BITS   = 10
)(
    input  wire                                            clk,
    // input  wire                                            rst_n,
    input  wire                                            i_valid,
    // input  wire [6:0]                                      i_valid_pipe,
    input  wire [256-1:0]                                  i_data_feature,
    input  wire [4096-1:0]                                 i_data_weight,
    output reg  [256-1:0]                                   o_data
);
localparam signed [PSUM_WIDTH:0] MAX_LIMIT =  (1 << (DATA_WIDTH-1)) - 1;
localparam signed [PSUM_WIDTH:0] MIN_LIMIT = -(1 << (DATA_WIDTH-1));
localparam MULT_WIDTH = DATA_WIDTH * 2;
localparam L1 = IN_CHANNELS / 2;
localparam L2 = IN_CHANNELS / 4;
localparam L3 = IN_CHANNELS / 8;

integer oc, ic, p;


(* max_fanout = "32" *) reg valid_stg0;
(* max_fanout = "32" *) reg valid_stg1;
(* max_fanout = "32" *) reg valid_stg2;
(* max_fanout = "32" *) reg valid_stg3;
(* max_fanout = "32" *) reg valid_stg4;
(* max_fanout = "32" *) reg valid_stg5;
(* max_fanout = "32" *) reg valid_stg6;
(* max_fanout = "32" *) reg valid_stg7;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_stg0 <= 0;
        valid_stg1 <= 0;
        valid_stg2 <= 0;
        valid_stg3 <= 0;
        valid_stg4 <= 0;
        valid_stg5 <= 0;
        valid_stg6 <= 0;
        valid_stg7 <= 0;
    end else begin
        valid_stg0 <= i_valid;
        valid_stg1 <= valid_stg0;
        valid_stg2 <= valid_stg1;
        valid_stg3 <= valid_stg2;
        valid_stg4 <= valid_stg3;
        valid_stg5 <= valid_stg4;
        valid_stg6 <= valid_stg5;
        valid_stg7 <= valid_stg6;
    end
end


// 1. Thanh ghi TRÆ¯ï¿½?C phÃ©p nhÃ¢n (TÆ°Æ¡ng á»©ng A, B register trong DSP)
reg signed [DATA_WIDTH-1:0] feature_reg [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];
reg signed [DATA_WIDTH-1:0] weight_reg  [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];

// 2. Thanh ghi TRONG phÃ©p nhÃ¢n (TÆ°Æ¡ng á»©ng M register trong DSP)
(* use_dsp = "yes" *)
reg signed [MULT_WIDTH-1:0] mult_reg [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];

// 3. Thanh ghi SAU phÃ©p nhÃ¢n (TÆ°Æ¡ng á»©ng P register trong DSP)
reg signed [MULT_WIDTH-1:0] mult_reg_pipe [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];


// =====================================================================
// KHAI Bï¿½?O CÃY Cá»NG (ADDER TREE) - Giá»¯ nguyÃªn khÃ´ng chÃ¨n thÃªm
// =====================================================================
reg signed [PSUM_WIDTH-1:0] tree_lvl1 [0:OUT_CHANNELS-1][0:L1-1];
reg signed [PSUM_WIDTH-1:0] tree_lvl2 [0:OUT_CHANNELS-1][0:L2-1];
reg signed [PSUM_WIDTH-1:0] tree_lvl3 [0:OUT_CHANNELS-1][0:L3-1];
reg signed [PSUM_WIDTH-1:0] tree_final [0:OUT_CHANNELS-1];


// =====================================================================
// LOGIC PIPELINE CHO Bá» NHÃN (DSP48)
// =====================================================================

always @(posedge clk) begin
    // if (!rst_n) begin
    //     for (ic = 0; ic < IN_CHANNELS; ic = ic + 1)
    //         feature_reg[ic] <= 0;
    //     for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1)
    //         for (ic = 0; ic < IN_CHANNELS; ic = ic + 1)
    //             weight_reg[oc][ic] <= 0;
    // end else 
    if (i_valid) begin
        // for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
            // feature_reg[ic] <= $signed(i_data_feature[ic*DATA_WIDTH +: DATA_WIDTH]);
        // end
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
                feature_reg[oc][ic] <= $signed(i_data_feature[ic*DATA_WIDTH +: DATA_WIDTH]);
                weight_reg[oc][ic] <= $signed(i_data_weight[(oc*IN_CHANNELS+ic)*DATA_WIDTH +: DATA_WIDTH]);
            end
        end
    end
end

always @(posedge clk ) begin
    // if (!rst_n) begin
    //     for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1)
    //         for (ic = 0; ic < IN_CHANNELS; ic = ic + 1)
    //             mult_reg[oc][ic] <= 0;
    // end else 
    if (valid_stg0) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
                mult_reg[oc][ic] <= feature_reg[oc][ic] * weight_reg[oc][ic];
            end
        end
    end
end

always @(posedge clk ) begin
    // if (!rst_n) begin
    //     for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1)
    //         for (ic = 0; ic < IN_CHANNELS; ic = ic + 1)
    //             mult_reg_pipe[oc][ic] <= 0;
    // end else 
    if (valid_stg1) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
                mult_reg_pipe[oc][ic] <= mult_reg[oc][ic];
            end
        end
    end
end

// =====================================================================
// LOGIC CÃY Cá»NG (ADDER TREE)
// =====================================================================

always @(posedge clk ) begin
    // if (!rst_n) begin
    //     for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
    //         for (p = 0; p < L1; p = p + 1) begin
    //             tree_lvl1[oc][p] <= 0;
    //         end
    //     end
    // end else 
    if (valid_stg2) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L1; p = p + 1) begin
                tree_lvl1[oc][p] <=
                    $signed(mult_reg_pipe[oc][2*p]) + $signed(mult_reg_pipe[oc][2*p+1]);
            end
        end
    end
end

always @(posedge clk ) begin
    // if (!rst_n) begin
    //     for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
    //         for (p = 0; p < L2; p = p + 1) begin
    //             tree_lvl2[oc][p] <= 0;
    //         end
    //     end
    // end else 
    if (valid_stg3) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L2; p = p + 1) begin
                tree_lvl2[oc][p] <=
                    $signed(tree_lvl1[oc][2*p]) + $signed(tree_lvl1[oc][2*p+1]);
            end
        end
    end
end



always @(posedge clk ) begin
    // if (!rst_n) begin
    //     for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
    //         for (p = 0; p < L3; p = p + 1) begin
    //             tree_lvl3[oc][p] <= 0;
    //         end
    //     end
    // end else 
    if (valid_stg4) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L3; p = p + 1) begin
                tree_lvl3[oc][p] <=
                    $signed(tree_lvl2[oc][2*p]) + $signed(tree_lvl2[oc][2*p+1]);
            end
        end
    end
end

always @(posedge clk ) begin
    // if (!rst_n) begin
    //     for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
    //         tree_final[oc] <= 0;
    //     end
    // end else 
    if (valid_stg5) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            tree_final[oc] <= $signed(tree_lvl3[oc][0]) + $signed(tree_lvl3[oc][1]);
        end
    end
end





wire signed [PSUM_WIDTH:0] round_offset = $signed({1'b0, {{(PSUM_WIDTH-1){1'b0}}, 1'b1} <<< (SHIFT_BITS-1)});
reg signed [PSUM_WIDTH:0] shifted_final [0:OUT_CHANNELS-1];



// =========================================================================
// STAGE 6 — Làm tròn & dịch bit (round + right-shift)
// CE: v_st6  |  Fanout = 1
// =========================================================================
always @(posedge clk) begin
    if (valid_stg6) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            if (tree_final[oc] >= 0)
                shifted_final[oc] <=
                    ($signed({tree_final[oc][PSUM_WIDTH-1], tree_final[oc]}) + round_offset)
                    >>> SHIFT_BITS;
            else
                shifted_final[oc] <=
                    ($signed({tree_final[oc][PSUM_WIDTH-1], tree_final[oc]}) - round_offset)
                    >>> SHIFT_BITS;
        end
    end
end
 
// =========================================================================
// STAGE 7 — Bão hòa & xuất (saturation + output)
// CE: v_st7  |  Fanout = 1
// =========================================================================
always @(posedge clk) begin
    if (valid_stg7) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            if      (shifted_final[oc] > MAX_LIMIT)
                o_data[oc*DATA_WIDTH +: DATA_WIDTH] <= MAX_LIMIT[DATA_WIDTH-1:0];
            else if (shifted_final[oc] < MIN_LIMIT)
                o_data[oc*DATA_WIDTH +: DATA_WIDTH] <= MIN_LIMIT[DATA_WIDTH-1:0];
            else
                o_data[oc*DATA_WIDTH +: DATA_WIDTH] <= shifted_final[oc][DATA_WIDTH-1:0];
        end
    end
end


endmodule