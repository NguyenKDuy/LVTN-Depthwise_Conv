// module pw_mac #(
//     parameter DATA_WIDTH   = 16,
//     parameter IN_CHANNELS  = 16,
//     parameter OUT_CHANNELS = 16,
//     parameter PSUM_WIDTH   = (DATA_WIDTH * 2) + $clog2(IN_CHANNELS),
//     parameter NUM_LEVELS   = $clog2(IN_CHANNELS) + 1,
//     parameter SHIFT_BITS   = 10
// )(
//     input  wire                                      clk,
//     input  wire                                      rst_n,
//     input  wire                                      i_valid,
//     input  wire [NUM_LEVELS-1:0]                     i_valid_pipe,
//     input  wire [IN_CHANNELS*DATA_WIDTH-1:0]         i_data_feature,
//     input  wire [OUT_CHANNELS*IN_CHANNELS*DATA_WIDTH-1:0] i_data_weight,
//     output reg  [OUT_CHANNELS*DATA_WIDTH-1:0]        o_data
// );

// localparam MULT_WIDTH = DATA_WIDTH * 2;
// localparam L1 = IN_CHANNELS / 2;
// localparam L2 = IN_CHANNELS / 4;
// localparam L3 = IN_CHANNELS / 8;

// integer oc, ic, p;

// function signed [DATA_WIDTH-1:0] quantize_lane;
//     input signed [PSUM_WIDTH-1:0] in_val;
//     reg   signed [PSUM_WIDTH-1:0] rounded_val;
//     reg   signed [PSUM_WIDTH-1:0] shifted_val;
// begin
//     if (in_val >= 0)
//         rounded_val = in_val + ({{(PSUM_WIDTH-1){1'b0}}, 1'b1} <<< (SHIFT_BITS-1));
//     else
//         rounded_val = in_val - ({{(PSUM_WIDTH-1){1'b0}}, 1'b1} <<< (SHIFT_BITS-1));

//     shifted_val = rounded_val >>> SHIFT_BITS;

//     if (shifted_val > $signed(16'sh7FFF))
//         quantize_lane = 16'sh7FFF;
//     else if (shifted_val < $signed(16'sh8000))
//         quantize_lane = 16'sh8000;
//     else
//         quantize_lane = shifted_val[DATA_WIDTH-1:0];
// end
// endfunction

// (* use_dsp = "yes" *)
// reg signed [MULT_WIDTH-1:0] mult_reg [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];

// reg signed [PSUM_WIDTH-1:0] tree_lvl1 [0:OUT_CHANNELS-1][0:L1-1];
// reg signed [PSUM_WIDTH-1:0] tree_lvl2 [0:OUT_CHANNELS-1][0:L2-1];
// reg signed [PSUM_WIDTH-1:0] tree_lvl3 [0:OUT_CHANNELS-1][0:L3-1];
// reg signed [PSUM_WIDTH-1:0] tree_final [0:OUT_CHANNELS-1];

// reg signed [DATA_WIDTH-1:0] i_data_feature_reg [0:IN_CHANNELS-1];


// always @(posedge clk ) begin
//     if (!rst_n) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
//                 mult_reg[oc][ic] <= 0;
//             end
//         end
//     end else if (i_valid) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
//                 mult_reg[oc][ic] <=
//                     $signed(i_data_feature[ic*DATA_WIDTH +: DATA_WIDTH])
//                     * $signed(i_data_weight[(oc*IN_CHANNELS+ic)*DATA_WIDTH +: DATA_WIDTH]);
//             end
//         end
//     end
// end

// always @(posedge clk ) begin
//     if (!rst_n) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             for (p = 0; p < L1; p = p + 1) begin
//                 tree_lvl1[oc][p] <= 0;
//             end
//         end
//     end else if (i_valid_pipe[0]) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             for (p = 0; p < L1; p = p + 1) begin
//                 tree_lvl1[oc][p] <=
//                     $signed(mult_reg[oc][2*p]) + $signed(mult_reg[oc][2*p+1]);
//             end
//         end
//     end
// end

// always @(posedge clk ) begin
//     if (!rst_n) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             for (p = 0; p < L2; p = p + 1) begin
//                 tree_lvl2[oc][p] <= 0;
//             end
//         end
//     end else if (i_valid_pipe[1]) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             for (p = 0; p < L2; p = p + 1) begin
//                 tree_lvl2[oc][p] <=
//                     $signed(tree_lvl1[oc][2*p]) + $signed(tree_lvl1[oc][2*p+1]);
//             end
//         end
//     end
// end

// always @(posedge clk ) begin
//     if (!rst_n) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             for (p = 0; p < L3; p = p + 1) begin
//                 tree_lvl3[oc][p] <= 0;
//             end
//         end
//     end else if (i_valid_pipe[2]) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             for (p = 0; p < L3; p = p + 1) begin
//                 tree_lvl3[oc][p] <=
//                     $signed(tree_lvl2[oc][2*p]) + $signed(tree_lvl2[oc][2*p+1]);
//             end
//         end
//     end
// end

// always @(posedge clk ) begin
//     if (!rst_n) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             tree_final[oc] <= 0;
//         end
//     end else if (i_valid_pipe[3]) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             tree_final[oc] <= $signed(tree_lvl3[oc][0]) + $signed(tree_lvl3[oc][1]);
//         end
//     end
// end

// always @(posedge clk ) begin
//     if (!rst_n) begin
//         o_data <= 0;
//     end else if (i_valid_pipe[4]) begin
//         for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
//             o_data[oc*DATA_WIDTH +: DATA_WIDTH] <= quantize_lane(tree_final[oc]);
//         end
//     end
// end

// endmodule




module pw_mac #(
    parameter DATA_WIDTH   = 16,
    parameter IN_CHANNELS  = 16,
    parameter OUT_CHANNELS = 16,
    parameter PSUM_WIDTH   = (DATA_WIDTH * 2) + $clog2(IN_CHANNELS),
    // parameter NUM_LEVELS   = 7,
    parameter SHIFT_BITS   = 10
)(
    input  wire                                            clk,
    input  wire                                            rst_n,
    input  wire                                            i_valid,
    input  wire [6:0]                                      i_valid_pipe,
    input  wire [256-1:0]                                  i_data_feature,
    input  wire [4096-1:0]                                 i_data_weight,
    output reg  [256-1:0]                                   o_data
);

localparam MULT_WIDTH = DATA_WIDTH * 2;
localparam L1 = IN_CHANNELS / 2;
localparam L2 = IN_CHANNELS / 4;
localparam L3 = IN_CHANNELS / 8;

integer oc, ic, p;

//function signed [DATA_WIDTH-1:0] quantize_lane;
//    input signed [PSUM_WIDTH-1:0] in_val;
//    reg   signed [PSUM_WIDTH-1:0] rounded_val;
//    reg   signed [PSUM_WIDTH-1:0] shifted_val;
//begin
//    if (in_val >= 0)
//        rounded_val = in_val + ({{(PSUM_WIDTH-1){1'b0}}, 1'b1} <<< (SHIFT_BITS-1));
//    else
//        rounded_val = in_val - ({{(PSUM_WIDTH-1){1'b0}}, 1'b1} <<< (SHIFT_BITS-1));

//    shifted_val = rounded_val >>> SHIFT_BITS;

//    if (shifted_val > $signed(16'sh7FFF))
//        quantize_lane = 16'sh7FFF;
//    else if (shifted_val < $signed(16'sh8000))
//        quantize_lane = 16'sh8000;
//    else
//        quantize_lane = shifted_val[DATA_WIDTH-1:0];
//end
//endfunction

function signed [DATA_WIDTH-1:0] quantize_lane;
    input signed [PSUM_WIDTH-1:0] in_val;
    
    // GI?I PHÁP: Tãng thêm 1 bit ð? ch?ng tràn (overflow/underflow) 
    // trong quá tr?nh c?ng ho?c tr? s? làm tr?n.
    reg signed [PSUM_WIDTH:0] rounded_val; 
    reg signed [PSUM_WIDTH:0] shifted_val;
    
    // T?o h?ng s? làm tr?n có ð? r?ng týõng ?ng ð? tránh ép ki?u sai
    reg signed [PSUM_WIDTH:0] round_offset;
begin
    round_offset = $signed({1'b0, {{(PSUM_WIDTH-1){1'b0}}, 1'b1} <<< (SHIFT_BITS-1)});

    // Logic gi? nguyên: Ð?i x?ng qua s? 0
    if (in_val >= 0)
        // Vi?c c?ng vào bi?n [PSUM_WIDTH:0] giúp bit d?u không b? l?t
        rounded_val = $signed({in_val[PSUM_WIDTH-1], in_val}) + round_offset;
    else
        // Vi?c tr? vào bi?n [PSUM_WIDTH:0] giúp tránh underflow quay v?ng lên dýõng
        rounded_val = $signed({in_val[PSUM_WIDTH-1], in_val}) - round_offset;

    // D?ch ph?i s? h?c gi? nguyên bit d?u an toàn
    shifted_val = rounded_val >>> SHIFT_BITS;

    // B?o h?a: So sánh giá tr? d?a trên bi?n ð? ðý?c b?o v? bit d?u
    if (shifted_val > $signed({17'sh0, 16'sh7FFF})) 
        quantize_lane = 16'sh7FFF;
    else if (shifted_val < $signed({17'sh1FFFF, 16'sh8000})) 
        quantize_lane = 16'sh8000;
    else
        // Ch? l?y ðo?n d? li?u mong mu?n sau khi ð? ð?m b?o không tràn
        quantize_lane = shifted_val[DATA_WIDTH-1:0];
end
endfunction


// 1. Thanh ghi TRÆ¯ï¿½?C phÃ©p nhÃ¢n (TÆ°Æ¡ng á»©ng A, B register trong DSP)
reg signed [DATA_WIDTH-1:0] feature_reg [0:IN_CHANNELS-1];
reg signed [DATA_WIDTH-1:0] weight_reg  [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];

// 2. Thanh ghi TRONG phÃ©p nhÃ¢n (TÆ°Æ¡ng á»©ng M register trong DSP)
(* use_dsp = "yes" *)
reg signed [MULT_WIDTH-1:0] mult_reg [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];

// 3. Thanh ghi SAU phÃ©p nhÃ¢n (TÆ°Æ¡ng á»©ng P register trong DSP)
reg signed [MULT_WIDTH-1:0] mult_reg_pipe [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];


// =====================================================================
// KHAI Bï¿½?O CÃ‚Y Cá»˜NG (ADDER TREE) - Giá»¯ nguyÃªn khÃ´ng chÃ¨n thÃªm
// =====================================================================
reg signed [PSUM_WIDTH-1:0] tree_lvl1 [0:OUT_CHANNELS-1][0:L1-1];
reg signed [PSUM_WIDTH-1:0] tree_lvl2 [0:OUT_CHANNELS-1][0:L2-1];
reg signed [PSUM_WIDTH-1:0] tree_lvl3 [0:OUT_CHANNELS-1][0:L3-1];
reg signed [PSUM_WIDTH-1:0] tree_final [0:OUT_CHANNELS-1];


// =====================================================================
// LOGIC PIPELINE CHO Bá»˜ NHÃ‚N (DSP48)
// =====================================================================

always @(posedge clk) begin
    if (!rst_n) begin
        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1)
            feature_reg[ic] <= 0;
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1)
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1)
                weight_reg[oc][ic] <= 0;
    end else if (i_valid) begin
        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
            feature_reg[ic] <= $signed(i_data_feature[ic*DATA_WIDTH +: DATA_WIDTH]);
        end
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
                weight_reg[oc][ic] <= $signed(i_data_weight[(oc*IN_CHANNELS+ic)*DATA_WIDTH +: DATA_WIDTH]);
            end
        end
    end
end

always @(posedge clk ) begin
    if (!rst_n) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1)
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1)
                mult_reg[oc][ic] <= 0;
    end else if (i_valid_pipe[0]) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
                mult_reg[oc][ic] <= feature_reg[ic] * weight_reg[oc][ic];
            end
        end
    end
end

always @(posedge clk ) begin
    if (!rst_n) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1)
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1)
                mult_reg_pipe[oc][ic] <= 0;
    end else if (i_valid_pipe[1]) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
                mult_reg_pipe[oc][ic] <= mult_reg[oc][ic];
            end
        end
    end
end

// =====================================================================
// LOGIC CÃ‚Y Cá»˜NG (ADDER TREE)
// =====================================================================

always @(posedge clk ) begin
    if (!rst_n) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L1; p = p + 1) begin
                tree_lvl1[oc][p] <= 0;
            end
        end
    end else if (i_valid_pipe[2]) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L1; p = p + 1) begin
                // LÆ°u Ã½: Láº¥y dá»¯ liá»‡u tá»« mult_reg_pipe thay vÃ¬ mult_reg
                tree_lvl1[oc][p] <=
                    $signed(mult_reg_pipe[oc][2*p]) + $signed(mult_reg_pipe[oc][2*p+1]);
            end
        end
    end
end

always @(posedge clk ) begin
    if (!rst_n) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L2; p = p + 1) begin
                tree_lvl2[oc][p] <= 0;
            end
        end
    end else if (i_valid_pipe[3]) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L2; p = p + 1) begin
                tree_lvl2[oc][p] <=
                    $signed(tree_lvl1[oc][2*p]) + $signed(tree_lvl1[oc][2*p+1]);
            end
        end
    end
end



always @(posedge clk ) begin
    if (!rst_n) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L3; p = p + 1) begin
                tree_lvl3[oc][p] <= 0;
            end
        end
    end else if (i_valid_pipe[4]) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            for (p = 0; p < L3; p = p + 1) begin
                tree_lvl3[oc][p] <=
                    $signed(tree_lvl2[oc][2*p]) + $signed(tree_lvl2[oc][2*p+1]);
            end
        end
    end
end

always @(posedge clk ) begin
    if (!rst_n) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            tree_final[oc] <= 0;
        end
    end else if (i_valid_pipe[5]) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            tree_final[oc] <= $signed(tree_lvl3[oc][0]) + $signed(tree_lvl3[oc][1]);
        end
    end
end

always @(posedge clk ) begin
    if (!rst_n) begin
        o_data <= 0;
    end else if (i_valid_pipe[6]) begin
        for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
            o_data[oc*DATA_WIDTH +: DATA_WIDTH] <= quantize_lane(tree_final[oc]);
        end
    end
end

endmodule