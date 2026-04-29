`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2026 03:18:11 PM
// Design Name: 
// Module Name: wr_data_select
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


module wr_data_select
#(
parameter BANK4_W = 64*4,
parameter BANK8_W = 64*8,
parameter BANK16_W = 64*16,
parameter ADDER_W  =16*3
)
(
    input [3:0]i_stage,
    input i_rst_n,
    input [16*16*2 - 1: 0] i_computed_data,
    input [ADDER_W - 1:0 ] i_adder_data,
    output reg [BANK16_W - 1: 0] o_wr_data_mem0,
    output reg [BANK8_W - 1: 0] o_wr_data_mem1,
    output reg [BANK8_W - 1: 0] o_wr_data_mem2,
    output reg [BANK8_W - 1: 0] o_wr_data_mem3,
    output reg [BANK8_W - 1: 0] o_wr_data_mem4,
    output reg [BANK8_W - 1: 0] o_wr_data_mem5,
    output reg [ADDER_W - 1: 0] o_wr_data_mem_stega
    );
    localparam HEAD = 1, DOWNS1 = 2, DOWNS2 = 3, DOWNS3 = 4, BOTT = 5,
           UPS1 = 6, UPS2 = 7, UPS3 = 8, UPS4 = 9, TAIL = 10, 
           DONE = 11, STREAM_OUT = 12;
           
    always @(*) begin
        o_wr_data_mem0      = 0; 
        o_wr_data_mem1      = 0;  
        o_wr_data_mem2      = 0;  
        o_wr_data_mem3      = 0;  
        o_wr_data_mem4      = 0;  
        o_wr_data_mem5      = 0;  
        o_wr_data_mem_stega = 0;

        case(i_stage) 
            HEAD: begin
                o_wr_data_mem0 = {4{i_computed_data[255:0]}};
            end
            DOWNS1: begin
                o_wr_data_mem1 = i_computed_data;
            end
            DOWNS2: begin
                o_wr_data_mem2 = i_computed_data;
            end
            DOWNS3: begin
                o_wr_data_mem3 = i_computed_data;
            end
            BOTT: begin
                o_wr_data_mem4 = i_computed_data;
            end
            UPS1: begin
                o_wr_data_mem5 = {2{i_computed_data[255:0]}};
            end
            UPS2: begin
                o_wr_data_mem3 = {2{i_computed_data[255:0]}};
            end
            UPS3: begin
                o_wr_data_mem2 = {2{i_computed_data[255:0]}};
            end
            UPS4: begin
                o_wr_data_mem1 = {2{i_computed_data[255:0]}};
                o_wr_data_mem3 = {2{i_computed_data[255:0]}};
            end
            TAIL: begin
                o_wr_data_mem2 = {256'b0, {4{i_computed_data[63:0]}}};
            end
            DONE: begin
                o_wr_data_mem_stega = i_adder_data;
            end
            default: begin
                o_wr_data_mem0      = 0; 
                o_wr_data_mem1      = 0;  
                o_wr_data_mem2      = 0;  
                o_wr_data_mem3      = 0;  
                o_wr_data_mem4      = 0;  
                o_wr_data_mem5      = 0;  
                o_wr_data_mem_stega = 0;
            end
        endcase
    
    end
endmodule

module stream_out (
    input             i_clk,
    input             i_rst_n,
    input [3:0]       i_stage,
    input             m_axis_tready,
    input [2:0]       i_vld,
    input [191:0]     i_data,
    input             i_stream_rst,
    output reg        o_vld,
    output reg [63:0] o_data,
    output reg        o_stream_done,
    output            m_axis_tlast
);
    localparam STREAM_OUT = 12;
    reg [13:0] counter, counter1;
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_vld  <= 1'b0;
            o_data <= 64'b0;
        end
        if (i_stage == STREAM_OUT) begin
            case (i_vld)
                3'b001: begin 
                    o_data <= i_data[63:0]; 
                    o_vld  <= 1'b1; 
                end
                3'b010: begin 
                    o_data <= i_data[127:64]; 
                    o_vld  <= 1'b1; 
                end
                3'b100: begin
                    o_data <= i_data[191:128]; 
                    o_vld  <= 1'b1; 
                end
                default: begin
                    o_vld  <= 1'b0;
                    o_data <= 64'b0;
                end
            endcase
        end
    end
    
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter <= 0;
        end
        else if (m_axis_tready && o_vld) begin
            if (counter == 12287) begin
                counter <= 0;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
    
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter1 <= 0;
            o_stream_done <=0;
        end
        else if (i_stream_rst) begin
            counter1 <= 0;
            o_stream_done <=0;
        end
        else if (m_axis_tready && o_vld) begin
            if (counter1 == 4095) begin
                o_stream_done <= 1;
            end
            else begin
                counter1 <= counter1 + 1;
            end
        end
    end
assign m_axis_tlast = (counter == 12287 && o_vld) ? 1: 0;
endmodule

module mem2_to_adder (
    input [3:0]        i_vld,
    input [64*4 - 1:0] i_data,
    output reg [48:0]  o_data
    
);
always @(*) begin
    o_data = 48'b0;
    case (i_vld)
        4'b0001: begin
            o_data = i_data[47:0];
        end
        
        4'b0010: begin
            o_data = i_data[111:64];
        end
        
        4'b0100: begin
            o_data = i_data[175:128];
        end
        
        4'b1000: begin
            o_data = i_data[239:192];
        end
        
        default: begin
            o_data = 48'b0;
        end
    endcase
end
endmodule