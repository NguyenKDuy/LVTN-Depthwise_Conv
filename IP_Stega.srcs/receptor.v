`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2026 03:00:48 PM
// Design Name: 
// Module Name: receptor
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

module receptor #(
    parameter DATA_W = 64,    // Ð? r?ng d? li?u ng? vào/ra
    parameter ADDR_W = 12     // Ð? r?ng ð?a ch? ng? ra
)(
    // --- Clock & Reset ---
    input                   i_clk,
    input                   i_rst_n,   // Nên có chân Reset ð? kh?i t?o h? th?ng

    // --- Input Interface ---
    input                   s_axis_tvalid,
    input  [DATA_W-1:0]     s_axis_tdata,
    input                   i_done,


    // --- Output Interface (Data & Addresses) ---
    output reg [ADDR_W-5:0]     o_addr1,
    output reg [ADDR_W-3:0]     o_addr2,
    output reg [ADDR_W-1:0]     o_addr3,
    output reg [ADDR_W-5:0]     o_addr4,
    output reg [DATA_W-1:0]     o_data,

    // --- Output Control (Valids) ---
    output reg [8:0]           o_valid1,
    output reg [15:0]          o_valid2,
    output reg [5:0]           o_valid3,
    output reg [15:0]          o_valid4,
    output reg                 s_axis_tready
);

    // TODO: Hi?n th?c logic x? l? t?i ðây
///////////////////////////////////////////////////////////////////////
// LOCAL_PARAM    
    localparam LOAD_DEPTH = 0;
    localparam LOAD_POINT = 1;
    localparam LOAD_BIAS =  2;
    localparam LOAD_IMAGE = 3;
    localparam COMPUTE    = 4;
    
    localparam DEPTH_BANK_DONE  = 188;
    localparam DEPTH_LOOP_DONE  = 9;
    
    localparam POINT_BANK_DONE   = 784;
    localparam POINT_LOOP_DONE   = 16;
    
    localparam BIAS_BANK_DONE    = 153;    
    localparam BIAS_LOOP_DONE    = 16;  
    
    localparam IMAGE_BANK_DONE   = 4096;    
    localparam IMAGE_LOOP_DONE   = 6;    
    
    
    reg [ADDR_W - 1: 0] counter;
    reg [4:0] depth_lcnt, point_lcnt, bias_lcnt, image_lcnt; 
    (* fsm_encoding = "one_hot" *) reg [2:0] loading_stage;
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            loading_stage <= 0; 
            o_addr1 <= 0;
            o_addr2 <= 0;
            o_addr3 <= 0;
            o_addr4 <= 0;
            o_data <= 0;
            depth_lcnt <= 0;
            point_lcnt <= 0;
            image_lcnt <= 0;
            bias_lcnt  <= 0;
            s_axis_tready   <= 1;
            counter <= 0;
        end 
        else begin
            o_valid4 <= 0;
            o_valid3 <= 0;
            o_valid2 <= 0;
            o_valid1 <= 0;
            
            case (loading_stage) 
                LOAD_DEPTH: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        o_valid1[depth_lcnt] <= 1;
                        counter <= counter + 1;
                        o_addr1 <= counter;
                        o_data <= s_axis_tdata;
                        if (counter == DEPTH_BANK_DONE - 1) begin
//                            o_addr1 <= 0;
                            counter <= 0;
                            depth_lcnt <= depth_lcnt + 1;
                            if (depth_lcnt == DEPTH_LOOP_DONE - 1) begin
                                loading_stage <= LOAD_POINT;
                            end
                        end
                    end
                end
                LOAD_POINT: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        o_valid2[point_lcnt] <= 1;
                        counter <= counter + 1;
                        o_addr2 <= counter;
                        o_data <= s_axis_tdata;
                        if (counter == POINT_BANK_DONE - 1) begin
//                            o_addr2 <= 0;
                            counter <= 0;
                            point_lcnt <= point_lcnt + 1;
                            if (point_lcnt == POINT_LOOP_DONE - 1) begin
                                loading_stage <= LOAD_BIAS;
                            end
                        end
                    end
                end
                
                LOAD_BIAS: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        o_valid4[bias_lcnt] <= 1;
                        o_addr4 <= counter;
                        counter <= counter + 1;
                        o_data <= s_axis_tdata;
                        if (counter == BIAS_BANK_DONE - 1) begin
//                            o_addr4 <= 0;
                            counter <= 0;
                            bias_lcnt <= bias_lcnt + 1;
                            if (bias_lcnt == BIAS_LOOP_DONE - 1) begin
                                loading_stage <= LOAD_IMAGE;
                            end
                        end
                    end
                end
                
                LOAD_IMAGE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        o_valid3[image_lcnt] <= 1;
                        o_addr3 <= counter;
                        counter <= counter + 1;
                        o_data <= s_axis_tdata;
                        if (counter == IMAGE_BANK_DONE - 1) begin
//                            o_addr3 <= 0;
                            counter <= 0;
                            image_lcnt <= image_lcnt + 1;
                            if (image_lcnt == IMAGE_LOOP_DONE - 1) begin
                                loading_stage <= COMPUTE;
                                image_lcnt <= 0;
                            end
                        end
                    end
                end
                COMPUTE: begin
                    o_addr3 <= 0;
                    s_axis_tready <= 0;
                    if (i_done) begin
                        loading_stage <= LOAD_IMAGE;
                        s_axis_tready <= 1;
                        o_addr3 <= 0;
                    end
                end
                default: begin
                    o_valid4 <= 0;
                    o_valid3 <= 0;
                    o_valid2 <= 0;
                    o_valid1 <= 0;
                end
                
            endcase
        end
    end
    
endmodule
