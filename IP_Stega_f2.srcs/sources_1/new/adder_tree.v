`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: adder_tree
// Pipeline: 3 stage
//   Stage 0 : Input Register   - c?t net dài 192-bit ð?u vào
//   Stage 1 : Addition         - 12 phép c?ng 16-bit song song
//   Stage 2 : Saturation       - clamp overflow v? POS_MAX / NEG_MIN
//////////////////////////////////////////////////////////////////////////////////
module adder_tree #(
    parameter WIDTH     = 64,
    parameter SUB_WIDTH = 16,
    parameter NUM_CH    = 3
)(
    input                                               i_clk,
    input                                               i_rst_n,
    input                                               i_rst_adder_done,
    input                                               i_vld,
    input                                               m_axis_tready,
    input  [WIDTH*NUM_CH-1:0]                           i_data_a,
    input  [WIDTH*NUM_CH-1:0]                           i_data_b,

    output reg [SUB_WIDTH*(NUM_CH*(WIDTH/SUB_WIDTH))-1:0] o_sum,
    output reg                                          o_vld,
    output reg                                          o_adder_done,
    output                                              m_axis_tlast
);

    localparam NUM_ADDS = NUM_CH * (WIDTH / SUB_WIDTH); // 12

    localparam [SUB_WIDTH-1:0] POS_MAX = {1'b0, {(SUB_WIDTH-1){1'b1}}}; // 0x7FFF
    localparam [SUB_WIDTH-1:0] NEG_MIN = {1'b1, {(SUB_WIDTH-1){1'b0}}}; // 0x8000

    integer i, j;

    // =========================================================================
    // Stage 0 - Input Register
    // M?c ðích: ðóng gói 192-bit bus g?n ngu?n, tránh net dài ð?n 12 adder
    // =========================================================================
    reg [WIDTH*NUM_CH-1:0] data_a_s0;
    reg [WIDTH*NUM_CH-1:0] data_b_s0;
    reg                    vld_s0;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            vld_s0    <= 1'b0;
            data_a_s0 <= 0;
            data_b_s0 <= 0;
        end else begin
            vld_s0 <= i_vld;
            if (i_vld) begin
                data_a_s0 <= i_data_a;
                data_b_s0 <= i_data_b;
            end
        end
    end

    // =========================================================================
    // Stage 1 - Addition  (12 phép c?ng song song, m?i phép 16-bit ? 17-bit)
    // =========================================================================
    reg signed [SUB_WIDTH:0] sum_raw [0:NUM_ADDS-1];
    reg                      vld_s1;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            vld_s1 <= 1'b0;
            for (i = 0; i < NUM_ADDS; i = i + 1)
                sum_raw[i] <= 0;
        end else begin
            vld_s1 <= vld_s0;
            if (vld_s0) begin
                for (i = 0; i < NUM_CH; i = i + 1) begin
                    for (j = 0; j < WIDTH/SUB_WIDTH; j = j + 1) begin
                        sum_raw[i*(WIDTH/SUB_WIDTH) + j] <=
                            $signed(data_a_s0[WIDTH*i + SUB_WIDTH*j +: SUB_WIDTH]) +
                            $signed(data_b_s0[WIDTH*i + SUB_WIDTH*j +: SUB_WIDTH]);
                    end
                end
            end
        end
    end

    // =========================================================================
    // Stage 2 - Saturation
    // bit[SUB_WIDTH] (carry) != bit[SUB_WIDTH-1] (sign) ? overflow
    // =========================================================================
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_vld <= 1'b0;
            o_sum <= 0;
        end else begin
            o_vld <= vld_s1; // o_vld tr? ðúng 3 cycle so v?i i_vld
            if (vld_s1) begin
                for (i = 0; i < NUM_ADDS; i = i + 1) begin
                    if (sum_raw[i][SUB_WIDTH] != sum_raw[i][SUB_WIDTH-1])
                        o_sum[SUB_WIDTH*i +: SUB_WIDTH] <=
                            (sum_raw[i][SUB_WIDTH] == 1'b0) ? POS_MAX : NEG_MIN;
                    else
                        o_sum[SUB_WIDTH*i +: SUB_WIDTH] <= sum_raw[i][SUB_WIDTH-1:0];
                end
            end
        end
    end

    // =========================================================================
    // Counter - adder_done
    // =========================================================================
    reg [13:0] counter;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter      <= 0;
            o_adder_done <= 0;
        end else if (i_rst_adder_done) begin
            counter      <= 0;
            o_adder_done <= 0;
        end else if (o_vld && m_axis_tready) begin
            counter <= counter + 1;
            if (counter == 4095)
                o_adder_done <= 1;
        end
    end

    // =========================================================================
    // Counter - tlast
    // =========================================================================
    reg [13:0] counter_tlast;

//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            counter_tlast <= 0;
//        end else if (m_axis_tready && o_vld) begin
//            counter_tlast <= (counter_tlast == 16383) ? 0 : counter_tlast + 1;
//        end
//    end

    assign m_axis_tlast = (counter == 4095 && o_vld) ? 1'b1 : 1'b0;

endmodule