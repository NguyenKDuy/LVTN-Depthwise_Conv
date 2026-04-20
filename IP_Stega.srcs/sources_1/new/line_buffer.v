`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2026 06:03:15 PM
// Design Name: 
// Module Name: line_buffer
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


//module line_buffer(
//    input                  i_clk,
//    input                  i_rst_n,
//    input  [255:0]         i_linedata,
//    input                  i_vld,
//    input                  i_rd_data,
//    input  [1:0]           i_config_stride,
//    input  [7:0]           i_config_max_line_in,
//    input  [7:0]           i_config_max_line_out,
//    output [767:0]         o_linedata,
//    output                 o_almost_done
//);

//    reg [255:0] line [129:0]; 
//    reg [8:0]   wrPntr;
//    reg [8:0]   rdPntr;
//    integer     k;

//    // Logic Ghi
//    always @(posedge i_clk) begin
//        if(!i_rst_n) begin
//            wrPntr <= 9'd0;
//            for (k = 0; k < 130; k = k + 1) line[k] <= 256'd0;
//        end else if(i_vld) begin
//            line[wrPntr] <= i_linedata;
//            if (wrPntr + 1 >= i_config_max_line_in) wrPntr <= 9'd0;
//            else wrPntr <= wrPntr + 1;
//        end
//    end

//    // Logic Ð?c
//    always @(posedge i_clk) begin
//        if(!i_rst_n) rdPntr <= 9'd0;
//        else if(i_rd_data) begin
//            if (rdPntr >= i_config_max_line_out - 1) rdPntr <= 9'd0;
//            else rdPntr <= rdPntr + i_config_stride;
//        end
//    end
    
//    assign o_linedata = {line[rdPntr], line[rdPntr+1], line[rdPntr+2]};
//    assign o_almost_done = (rdPntr >= i_config_max_line_out - 1);

//endmodule

module line_buffer (
    input               i_clk,
    input               i_rst_n,
    input  [255:0]      i_linedata,
    input               i_enable,
    input               i_vld,
    input               i_rd_data,
    input  [1:0]        i_config_stride,
    input  [7:0]        i_config_max_line_in,
    input  [7:0]        i_config_max_line_out,
    output [767:0]      o_linedata,
    output              o_almost_done,
    output              reg [7:0]   rdPntr       
);
 
    // -------------------------------------------------------------------------
    // Internal Memory: 130 entries x 256-bit
    // Infers BRAM18 on Xilinx (256 x 130 = 33,280 bits)
    // -------------------------------------------------------------------------
    (* ram_style = "distributed" *) reg [255:0] line [130:0]; //only use 130
    reg [7:0]   wrPntr;
    integer     k;
 
    // i_config_max_line_in  = width g?c (vd: 128), wrap wrPntr t?i 128+1=129
    // i_config_max_line_out = width g?c (vd: 128), wrap rdPntr t?i 128+1=129
    reg [7:0]   max_line_in_p1;   // max_line_in + 1
    reg [7:0]   max_line_out_p1;  // max_line_out - 1 (dùng cho rdPntr stride)
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            max_line_in_p1  <= 8'd0;
            max_line_out_p1 <= 8'd0;
        end else begin
            max_line_in_p1  <= i_config_max_line_in  + 8'd1;  // 129
            max_line_out_p1 <= i_config_max_line_in - i_config_stride;  // 129 (wrap rdPntr)
        end
    end

    // -------------------------------------------------------------------------
    // Write Logic
    // -------------------------------------------------------------------------
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            wrPntr <= 8'd0;
            
        end else if (i_vld && i_enable) begin
            line[wrPntr] <= i_linedata;
            if (wrPntr >= max_line_in_p1)
                wrPntr <= 8'd0;
            else
                wrPntr <= wrPntr + 8'd1;
        end
    end
    
    // -------------------------------------------------------------------------
    // Read Pointer Logic
    // -------------------------------------------------------------------------
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            rdPntr <= 8'd0;
        end else if (i_rd_data) begin
            if (rdPntr >= max_line_out_p1)
                rdPntr <= 8'd0;
            else
                rdPntr <= rdPntr + {6'd0, i_config_stride};
        end
    end
 
    // -------------------------------------------------------------------------
    // Registered Read Output - BRAM-friendly, breaks combinational path
    // Latency: 1 cycle after i_rd_data asserts
    // -------------------------------------------------------------------------
    reg [255:0] line_rd0, line_rd1, line_rd2;
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            line_rd0 <= 256'd0;
            line_rd1 <= 256'd0;
            line_rd2 <= 256'd0;
        end else begin
            line_rd0 <= line[rdPntr];
            line_rd1 <= line[rdPntr + 8'd1];
            line_rd2 <= line[rdPntr + 8'd2];
        end
    end
 
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pack_channels
            // M?i channel i s? g?p 3 pixel (rd2, rd1, rd0) l?i v?i nhau
            assign o_linedata[i*48 +: 48] = {
                line_rd2[i*16 +: 16], 
                line_rd1[i*16 +: 16], 
                line_rd0[i*16 +: 16]
            };
        end
    endgenerate
 
    // o_almost_done uses pre-computed register - no subtractor on critical path
    assign o_almost_done = (rdPntr >= max_line_out_p1);
 
endmodule
