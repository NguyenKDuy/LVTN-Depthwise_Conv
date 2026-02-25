`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/25/2026 09:16:08 PM
// Design Name: 
// Module Name: image_memory
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
`include "default.vh"


module receptor
# (parameter ADDRESS = 15)
        (
        input [`PIXEL_WIDTH * 4 - 1 : 0] i_data_in,
        input i_rst,
        input i_clk,
        input i_data_valid,
        output reg [1:0] o_stage,
        //depthwise
        output [ADDRESS - 1 :0] o_wr_address1,
        output o_data_valid1,
        //pointwise
        output [ADDRESS - 1 :0] o_wr_address2,
        output o_data_valid2,
        //image
        output [ADDRESS - 1 :0] o_wr_address3,
        output o_data_valid3,
        //dataout
        output [`PIXEL_WIDTH * 4 - 1:0] o_data_out
        );
 

////////////////////////////////////////////////////////////////////////////////
// Parameters   
localparam INIT = 'd00;
localparam DEPTHWISE = 'd01;
localparam POINTWISE = 'd02;
localparam IMAGE_IN = 'd03;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [ADDRESS - 1:0] address_counter1;
reg [ADDRESS - 1:0] address_counter2;
reg [ADDRESS - 1:0] address_counter3; 
                                             
    always @(posedge i_clk) begin
    if (!i_rst) begin 
        o_stage <= INIT; 
        address_counter1 <= 'd0;
        address_counter2 <= 'd0;
        address_counter3 <= 0;
    end
    else begin
        case (o_stage)

            INIT: begin
                o_stage <= DEPTHWISE;
            end

            DEPTHWISE: begin
                if (i_data_valid) begin
                    if (address_counter1 < `POINTWISE_64 - 1) begin
                        address_counter1 <= address_counter1 + 1'b1;
                    end    
                    else begin 
                        o_stage <= POINTWISE;
                    end
                end  
            end
            
            POINTWISE: begin
                if (i_data_valid) begin
                    if (address_counter2 < `DEPTHWISE_64 - 1) begin
                        address_counter2 <= address_counter2 + 1'b1;
                    end    
                    else begin 
                        o_stage <= IMAGE_IN;
                    end
                end  
            end

            IMAGE_IN : begin
                if (i_data_valid) begin                       
                    if (address_counter3 < (`COVER + `SECRET - 1)) begin
                        address_counter3 <= address_counter3 + 1'b1;
                    end    
                    else begin : loop_image
                        address_counter3 <= 0;
                    end
                end                                                         
            end     
            
            default: o_stage <= INIT;

        endcase
    end
end

//////////////////////////////////////////////////////////////////////////////////      
// MEMORY FOR WEIGHT
assign o_wr_address1 = address_counter1;
assign o_data_valid1 = (o_stage == DEPTHWISE) ? i_data_valid : 'd0;

assign o_wr_address2 = address_counter2;
assign o_data_valid2 = (o_stage == POINTWISE) ? i_data_valid : 'd0;


//MEMORY FOR COVER & SECRET
assign o_wr_address3 = address_counter3;
assign o_data_valid3 = (o_stage == IMAGE_IN) ? i_data_valid : 'd0;

assign o_data_out = i_data_in;

endmodule

// Simple Dual-Port Block RAM with Two Clocks
// File: simple_dual_two_clocks.v
module simple_dual_two_clocks (clka,clkb,ena,enb,wea,addra,addrb,dia,dob);
parameter DEPTH = 0;
parameter ADDRESS = 15;
parameter INIT_FILE = "";
parameter RAM_STYLE = "block";
parameter DATA_WIDTH = 64;
parameter DELAY = 1;
input clka, clkb, ena,enb,wea;
input [ADDRESS - 1:0] addra,addrb;
input [DATA_WIDTH - 1:0] dia;
output [DATA_WIDTH - 1:0] dob;
(* ram_style = RAM_STYLE *) reg [DATA_WIDTH - 1:0] ram [0: DEPTH-1];
reg [DATA_WIDTH - 1 : 0] regpp[DELAY - 1 : 0];

    always @(posedge clka)
        begin
            if (ena)
                begin
                if (wea)
                ram[addra] <= dia;
                end
            end
generate
integer i;
    always @(posedge clkb)
        begin
            if (enb)
                begin
                    regpp[0] <= ram[addrb];
                    for (i = 0; i < DELAY - 1; i = i + 1) begin: pipeline_reg_shift
                        regpp[i + 1] <= regpp[i];
                    end
                end
        end
endgenerate

generate

if (DELAY == 0) begin
    assign dob = ram[addrb];
end
else begin
    assign dob = regpp[DELAY - 1];
end
endgenerate
endmodule


module simple_dual_one_clock (clk,ena,enb,wea,addra,addrb,dia,dob);
parameter DEPTH = 0;
parameter ADDRESS = 15;
parameter RAM_STYLE = "ultra";
parameter DATA_WIDTH = 64;
parameter DELAY = 1;
input clk,ena,enb,wea;
input [ADDRESS - 1:0] addra,addrb;
input [DATA_WIDTH - 1:0] dia;
output [DATA_WIDTH - 1:0] dob;
(* ram_style = RAM_STYLE *) reg [DATA_WIDTH - 1:0] ram [0: DEPTH-1];
reg [DATA_WIDTH - 1 : 0] regpp[DELAY - 1 : 0];

    always @(posedge clk)
        begin
            if (ena)
                begin
                if (wea)
                ram[addra] <= dia;
                end
            end
generate
integer i;
    always @(posedge clk)
        begin
            if (enb)
                begin
                    regpp[0] <= ram[addrb];
                    for (i = 0; i < DELAY - 1; i = i + 1) begin: pipeline_reg_shift
                        regpp[i + 1] <= regpp[i];
                    end
                end
        end
endgenerate

generate

if (DELAY == 0) begin
    assign dob = ram[addrb];
end
else begin
    assign dob = regpp[DELAY - 1];
end
endgenerate
endmodule





