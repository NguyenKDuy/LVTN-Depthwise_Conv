`timescale 1ns / 1ps

//----%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//----%% Module Name      : FIFO-2N based on LUT RAM
//----%% Description      : Verilog (.v) version of Synchronous FIFO.
//----%%                    Using Wrap-around bit for Full/Empty detection.
//----%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

module fifo_2n_lram #(
   parameter DATA_W = 256,
   parameter DEPTH  = 128,   // Ph?i là l?y th?a c?a 2 (2^N)
   parameter PTR_SZ = $clog2(DEPTH)    // $clog2(DEPTH)
)(
   input              clk,
   input              rstn,
   
   input              i_wren,
   input [DATA_W-1:0] i_wrdata,
   output             o_full,

   input              i_rden,
   output [DATA_W-1:0] o_rddata,
   output             o_empty
);

//------------------------------------------------------------------------------
// Internal Signals
//------------------------------------------------------------------------------
reg [PTR_SZ:0] wrptr_rg; // Pointer + 1 bit wrapover
reg [PTR_SZ:0] rdptr_rg;

wire [PTR_SZ-1:0] wrptr;
wire [PTR_SZ-1:0] rdptr;
wire wren, rden;
wire is_wrap;
wire full, empty;

//------------------------------------------------------------------------------
// RAM Instance
//------------------------------------------------------------------------------
lram #(
   .DATA_W (DATA_W),
   .DEPTH  (DEPTH),
   .ADDR_W (PTR_SZ)
) inst_lram (
   .clk     (clk),
   .i_wren   (wren),
   .i_waddr  (wrptr),
   .i_wdata  (i_wrdata),
   .i_raddr  (rdptr),
   .o_rdata  (o_rddata)
);

//------------------------------------------------------------------------------
// Control Logic
//------------------------------------------------------------------------------
always @(posedge clk) begin
   if (!rstn) begin
      wrptr_rg <= 0;
      rdptr_rg <= 0;
   end
   else begin
      if (wren) wrptr_rg <= wrptr_rg + 1'b1;
      if (rden) rdptr_rg <= rdptr_rg + 1'b1;
   end
end

// Logic xác ð?nh tr?ng thái
assign wrptr   = wrptr_rg[PTR_SZ-1:0];
assign rdptr   = rdptr_rg[PTR_SZ-1:0];
assign is_wrap = (wrptr_rg[PTR_SZ] != rdptr_rg[PTR_SZ]);

assign full    = (wrptr == rdptr) && is_wrap;
assign empty   = (wrptr == rdptr) && !is_wrap;

assign wren    = i_wren && !full;
assign rden    = i_rden && !empty;

assign o_full  = full;
assign o_empty = empty;

endmodule

//------------------------------------------------------------------------------
// Module: DUAL-PORT LUTRAM (Inferred as Distributed RAM)
//------------------------------------------------------------------------------
module lram #(
   parameter DATA_W = 8,
   parameter DEPTH  = 8,
   parameter ADDR_W = 3
)(
   input              clk,
   input              i_wren,
   input [ADDR_W-1:0] i_waddr,
   input [DATA_W-1:0] i_wdata,
   input [ADDR_W-1:0] i_raddr,
   output [DATA_W-1:0] o_rdata
);

// Thu?c tính ép Synthesis dùng LUTRAM (DRAM)
(* ram_style = "distributed" *)
reg [DATA_W-1:0] dt_arr [0:DEPTH-1];

// Ghi ð?ng b?
always @(posedge clk) begin
   if (i_wren) begin
      dt_arr[i_waddr] <= i_wdata;
   end
end

// Ð?c không ð?ng b? (Asynchronous Read) - Ð?c ði?m c?a LUTRAM
assign o_rdata = dt_arr[i_raddr];

endmodule