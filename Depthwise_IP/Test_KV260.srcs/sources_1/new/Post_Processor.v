`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 08:16:55 PM
// Design Name: 
// Module Name: Post_Processor
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


 


(* use_dsp = "no" *)
module Post_Processor (
    input clk,
    input ce_round, 
    input ce_sat,               
    input [35:0] data_in,      
    output reg [15:0] data_out 
);

    localparam POS_MAX = 16'sh7FFF; 
    localparam NEG_MIN = 16'sh8000; 

    reg [35:0] rounded_data;
    
    // --- PIPELINE STAGE 6: Rounding ---
    always @(posedge clk) begin
        if (ce_round) begin
            rounded_data <= data_in + (1 << 9);
        end
    end

    // --- PIPELINE STAGE 7: saturation 32bit -> 16bit ---

    always @(posedge clk) begin
        if (ce_sat) begin
            if (rounded_data[35] == 0 && |rounded_data[34:25]) begin
                data_out <= POS_MAX;
            end 
            else if (rounded_data[35] == 1 && !(&rounded_data[34:25])) begin
                data_out <= NEG_MIN;
            end 
            else begin
                data_out <= rounded_data[25:10];
            end
        end
    end

endmodule