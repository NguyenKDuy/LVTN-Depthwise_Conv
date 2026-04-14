`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/09/2026 04:27:07 PM
// Design Name: 
// Module Name: tb_weight_bias_control
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


`timescale 1ns / 1ps

module tb_weight_bias_control;

// ============================================================
// Parameters
// ============================================================
localparam ADDRESS_WEIGHT = 14;
localparam ADDRESS_BIAS   = 5;
localparam CLK_PERIOD     = 10; // 100 MHz

// Stage encoding (ph?i kh?p v?i DUT)
localparam IDLE   = 'd0;
localparam HEAD   = 'd1;
localparam DOWNS1 = 'd2;
localparam DOWNS2 = 'd3;
localparam DOWNS3 = 'd4;
localparam BOTT   = 'd5;
localparam UPS1   = 'd6;
localparam UPS2   = 'd7;
localparam UPS3   = 'd8;
localparam UPS4   = 'd9;
localparam TAIL   = 'd10;

// ============================================================
// DUT Port Declarations
// ============================================================
reg                          i_clk;
reg                          i_rst_n;
reg                          i_ld_wb_enable;
reg  [3:0]                   i_stage;
reg                          i_last_loop;
reg                          i_mode;

wire [ADDRESS_WEIGHT - 1:0]  o_dweight_rd_addr;
wire                         o_dweight_ena;
wire [ADDRESS_WEIGHT - 1:0]  o_pweight_rd_addr;
wire                         o_pweight_ena;
wire [ADDRESS_BIAS - 1:0]    o_bias_rd_addr;
wire                         o_bias_ena;
wire                         o_depth_sel;
wire                         o_point_sel;
wire                         o_bias_sel;
wire                         o_load_done;

// ============================================================
// DUT Instantiation
// ============================================================
weight_bias_control #(
    .ADDRESS_WEIGHT(ADDRESS_WEIGHT),
    .ADDRESS_BIAS  (ADDRESS_BIAS)
) dut (
    .i_clk            (i_clk),
    .i_rst_n          (i_rst_n),
    .i_ld_wb_enable   (i_ld_wb_enable),
    .i_stage          (i_stage),
    .i_last_loop      (i_last_loop),
    .i_mode           (i_mode),
    .o_dweight_rd_addr(o_dweight_rd_addr),
    .o_dweight_ena    (o_dweight_ena),
    .o_pweight_rd_addr(o_pweight_rd_addr),
    .o_pweight_ena    (o_pweight_ena),
    .o_bias_rd_addr   (o_bias_rd_addr),
    .o_bias_ena       (o_bias_ena),
    .o_depth_sel      (o_depth_sel),
    .o_point_sel      (o_point_sel),
    .o_bias_sel       (o_bias_sel),
    .o_load_done      (o_load_done)
);

initial i_clk = 0;
always #(CLK_PERIOD/2) i_clk <= ~i_clk;
task apply_reset;
    begin
        i_rst_n        <= 0;
        i_ld_wb_enable <= 0;
        i_stage        <= IDLE;
        i_last_loop    <= 0;
        i_mode         <= 0;
        @(posedge i_clk); #1;
        @(posedge i_clk); #1;
        i_rst_n <= 1;
        @(posedge i_clk); #1;
        $display("[%0t] Reset released.", $time);
    end
endtask

initial begin
    apply_reset();
end

always @(i_clk) begin
    if (o_load_done) begin
        i_ld_wb_enable <= 0;
    end
end
endmodule
