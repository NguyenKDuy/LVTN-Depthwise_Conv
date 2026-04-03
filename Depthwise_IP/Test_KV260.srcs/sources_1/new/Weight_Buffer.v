`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 08:17:28 PM
// Design Name: 
// Module Name: Weight_Buffer
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


module Weight_Buffer (
    input clk, rst,
    input i_weight_valid,
    input [575:0] i_weight,
    input i_swap,
    output reg o_dw_ready,
    output [2303:0] o_weight_bus
);
    (* ram_style = "block" *) reg [15:0] mem [0:287]; 
    reg active_bank;
    reg [1:0] fill_cnt;
    integer c, w;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active_bank <= 0; fill_cnt <= 0; o_dw_ready <= 1;
        end else begin
            if (i_weight_valid && o_dw_ready) begin
                for (c=0; c<4; c=c+1)
                    for (w=0; w<9; w=w+1)
                        mem[(!active_bank)*144 + (fill_cnt*4+c)*9 + w] <= i_weight[(c*144 + w*16) +: 16];
                if (fill_cnt == 3) begin fill_cnt <= 0; o_dw_ready <= 0; end
                else fill_cnt <= fill_cnt + 1;
            end
            if (i_swap) begin active_bank <= !active_bank; o_dw_ready <= 1; end
        end
    end

    genvar gi, gw;
    generate
        for (gi=0; gi<16; gi=gi+1) begin : gen_w
            for (gw=0; gw<9; gw=gw+1) begin : gen_w_inner
                assign o_weight_bus[(gi*144 + gw*16) +: 16] = mem[active_bank*144 + gi*9 + gw];
            end
        end
    endgenerate
endmodule