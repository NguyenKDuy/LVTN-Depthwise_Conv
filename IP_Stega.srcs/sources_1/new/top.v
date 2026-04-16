`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2026 06:03:15 PM
// Design Name: 
// Module Name: top
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

module top #(
    parameter DATA_W      = 64,
    parameter ADDR_BIAS   = 6,
    parameter ADDR_DEPTH  = 8,
    parameter ADDR_POINT  = 10,
    parameter ADDR_IMG    = 12,
    parameter ADDR_IMG_R  = 14,
    parameter SUB_W       = 16
)(
    input           i_clk,
    input           i_rst_n,

    // --- AXI4-Stream Slave (DMA) ---
    input           s_axis_tvalid,
    input  [DATA_W-1:0] s_axis_tdata,
    output          s_axis_tready,
    // AXI Stream out Interface
    output wire                m_axis_tvalid,
    output wire [DATA_W-1:0]   m_axis_tdata,
    input                      m_axis_tready
    // Interrupt for requesting new data 
//    output reg                 intr,

    // --- Control Signal from Compute Unit ---
//    input           top_done 

    // --- Interface dành cho b? Compute Ð?c ---
//    input  [ADDR_DEPTH-1:0]   i_rd_addr_depth,
//    input             f        i_rd_enb_depth,
//    output [9*DATA_W-1:0]     o_data_depth,
//    output                    o_vld_depth,

//    input  [ADDR_POINT-1:0]   i_rd_addr_point,
//    input                     i_rd_enb_point,
//    output [16*DATA_W-1:0]    o_data_point,
//    output                    o_vld_point,

//    input  [ADDR_IMG_R-1:0]   i_rd_addr_img,
//    input  [5:0]              i_rd_enb_img,
//    output [6*SUB_W-1:0]      o_data_img,
//    output [5:0]              o_vld_img
);

///////////////////////////////////////////////////////////////////
// --- MODULE RECEPTOR
    wire [DATA_W-1:0]     w_shared_data;
    wire [12:0]           w_addr_depth_raw, w_addr_point_raw, w_addr_img_raw, w_addr_bias_raw;
    
    wire [8:0]            w_valid_depth;
    wire [15:0]           w_valid_point;
    wire [15:0]           w_valid_bias;
    wire [5:0]            w_valid_img;
    wire                  top_done;
///////////////////////////////////////////////////////////////////
// --- MODULE DEPTH MEM
    wire [ADDR_DEPTH-1:0]   top_rd_addr_depth;
    wire                    top_rd_enb_depth;
    wire [9*DATA_W-1:0]     top_data_depth  ;
    wire                    top_vld_depth   ;

///////////////////////////////////////////////////////////////////
// --- MODULE POINT_MEM
    wire [ADDR_POINT-1:0]   top_rd_addr_point;
    wire                    top_rd_enb_point ;
    wire [16*DATA_W-1:0]    top_data_point   ;
    wire                    top_vld_point    ;

///////////////////////////////////////////////////////////////////    
// --- MODULE IMAGE_MEM
    wire [ADDR_IMG_R-1:0]   top_rd_addr_img; 
    wire [5:0]              top_rd_enb_img ; 
    wire [6*SUB_W-1:0]      top_data_img   ; 
    wire [5:0]              top_vld_img    ; 
    
///////////////////////////////////////////////////////////////////    
// --- MODULE BIAS_MEM
    wire [ADDR_BIAS-1:0]    top_rd_addr_bias; 
    wire                    top_rd_enb_bias ; 
    wire [16*16-1:0]        top_data_bias   ; 
    wire [5:0]              top_vld_bias    ;     
 
///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_0
    wire [16*DATA_W-1:0]        top_data_mem_0   ; 
    wire [15:0]                 top_vld_mem_0    ;
    
///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_1
    wire [8*DATA_W-1:0]         top_data_mem_1   ; 
    wire [7:0]                  top_vld_mem_1    ;  

///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_2
    wire [8*DATA_W-1:0]         top_data_mem_2   ; 
    wire [7:0]                  top_vld_mem_2    ;  
     
///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_3
    wire [8*DATA_W-1:0]         top_data_mem_3   ; 
    wire [7:0]                  top_vld_mem_3    ;  

///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_4
    wire [8*DATA_W-1:0]         top_data_mem_4   ; 
    wire [7:0]                  top_vld_mem_4    ;  
            
///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_5
    wire [8*DATA_W-1:0]         top_data_mem_5   ; 
    wire [7:0]                  top_vld_mem_5    ;  
        

///////////////////////////////////////////////////////////////////    
// --- MODULE RD_FSM_CONTROL

    (* KEEP = "true" *)    wire [4:0]  top_config_dep_para      ;
    (* KEEP = "true" *)    wire [4:0]  top_config_point_para    ;
    (* KEEP = "true" *)    wire [1:0]  top_config_stride        ;
    (* KEEP = "true" *)    wire [7:0]  top_config_max_line_in   ;
    (* KEEP = "true" *)    wire [7:0]  top_config_max_line_out  ;
    (* KEEP = "true" *)    wire [3:0]  top_stage                ;
    (* KEEP = "true" *)    wire        top_mode                 ; 
    
    // --- Memory & Counters ---
    (* KEEP = "true" *)    wire [ADDR_IMG_R - 1:0] top_mem_rd_addr  ;        // Ð?a ch? ð?c d? li?u input/feature map
    (* KEEP = "true" *)    wire        top_mem_rd_enb               ;
    (* KEEP = "true" *)    wire [1:0]  top_mem_rd_swapping          ;
    (* KEEP = "true" *)    wire        top_padding_vld              ;
    (* KEEP = "true" *)    wire        top_rst_pw_cmp               ;
    (* KEEP = "true" *)    wire        top_first_loop               ;
    (* KEEP = "true" *)    wire [3:0]  top_lic_counter              ;
    (* KEEP = "true" *)    wire [7:0]  top_row_counter              ;
    (* KEEP = "true" *)    wire [7:0]  top_col_counter              ;

//////////////////////////////////////////////////////////////////////
//MODULE WEIGHT_BIAS_CONTROL
    (* KEEP = "true" *) wire        depth_sel;
    (* KEEP = "true" *) wire        point_sel;
    (* KEEP = "true" *) wire        bias_sel;  
    reg top_depth_sel; 
    reg top_point_sel; 
    reg top_bias_sel;  
/////////////////////////////////////////////////////////////////////////////////
//RD_ADDRESS_SELECTION
    wire [ADDR_IMG+1:0] top_rd_mem_img_addr;
    wire [ADDR_IMG-1:0] top_rd_mem0_addr;
    wire [ADDR_IMG-1:0] top_rd_mem1_addr;
    wire [ADDR_IMG-1:0] top_rd_mem2_addr;
    wire [ADDR_IMG-1:0] top_rd_mem3_addr;
    wire [ADDR_IMG-1:0] top_rd_mem4_addr;
    wire [ADDR_IMG-1:0] top_rd_mem5_addr;
    wire [ADDR_IMG-1:0] top_rd_mem_stega_addr;
    
    wire [5:0]  top_rd_mem_img_enb;
    wire [15:0] top_rd_mem0_enb;
    wire [7:0]  top_rd_mem1_enb;
    wire [7:0]  top_rd_mem2_enb;
    wire [7:0]  top_rd_mem3_enb;
    wire [7:0]  top_rd_mem4_enb;
    wire [7:0]  top_rd_mem5_enb;
//    wire [2:0]  top_rd_mem_stega_enb;

////////////////////////////////////////////////////////////////////////////////////
//DATA_SEL: 
    wire [255:0] top_ds0_pixel;
    wire [255:0] top_ds1_pixel;
    wire         top_ds0_valid;
    wire         top_ds1_valid;

////////////////////////////////////////////////////////////////////////////////////
//DATA_SEL: 
wire [15:0]  top_wr_mem0_ena ;
wire [7:0]   top_wr_mem1_ena ;
wire [7:0]   top_wr_mem2_ena ;
wire [7:0]   top_wr_mem3_ena ;
wire [7:0]   top_wr_mem4_ena ;
wire [7:0]   top_wr_mem5_ena ;
wire [2:0]   top_wr_stega_ena ;

wire [ADDR_IMG-1:0]     top_wr_mem0_addr ;
wire [ADDR_IMG-1:0]     top_wr_mem1_addr ;
wire [ADDR_IMG-1:0]     top_wr_mem2_addr ;
wire [ADDR_IMG-1:0]     top_wr_mem3_addr ;
wire [ADDR_IMG-1:0]     top_wr_mem4_addr ;
wire [ADDR_IMG-1:0]     top_wr_mem5_addr ;
wire [ADDR_IMG_R-1:0]    top_wr_stega_addr ;
wire [16 * 16 * 2 - 1:0] top_wr_computed_data;
 
////////////////////////////////////////////////////////////////////////////////////
//WR_DATA_SELECT: 
wire [1023:0]           top_wr_data_mem0;

// Mem 1-5: 8 banks x 64 bits = 512 bits m?i c?m
wire [511:0]            top_wr_data_mem1;
wire [511:0]            top_wr_data_mem2;
wire [511:0]            top_wr_data_mem3;
wire [511:0]            top_wr_data_mem4;
wire [511:0]            top_wr_data_mem5;

// Stega Mem: 16 bits * 3 = 48 bits
wire [47:0]             top_wr_data_mem_stega;

//////////////////////////////////////////////////////////
//DEPTH_WISE & POINTWISE:
wire [255:0] top_depth_computed0;
wire [255:0] top_depth_computed1;
wire [255:0] top_mux_point_data;
wire top_depth_computed_vld0;    
wire top_depth_computed_vld1;  
wire top_mux_point_vld;  

wire [255:0] top_point_computed0, top_point_computed1;  
wire top_point_computed_vld0, top_point_computed_vld1; 

//////////////////////////////////////////////////////////////////
//MODULE: STEGA_INTERFACE  (support write 16bit-2-64bit)
wire [11:0]             top_stega_addr; // Ð?a ch? d?ng (64-bit row)
wire [191:0]            top_stega_data; // D? li?u 3 banks x 64-bit = 192 bits
wire [2:0]              top_stega_ena;  // L?nh ghi cho t?ng bank

wire [511:0]            top_mem1_mux_data; // 16-bit * 8 banks = 128 bits
wire [11:0]             top_mem1_mux_addr;
wire [7:0]              top_mem1_mux_ena;

wire top_stage_done;   
wire wb_ld_done, wb_ld_enable, top_last_loop;
wire [47:0] top_wr_computed_adder, top_computed_adder, top_adder_residual;
wire top_vld_adder;

wire [2303: 0] top_lb_kernel_0, top_lb_kernel_1;
wire top_lb_kernel_vld_0, top_lb_kernel_vld_1;

localparam HEAD = 4'd1, DOWNS1 = 4'd2, DOWNS2 = 4'd3, DOWNS3 = 4'd4, 
               BOTT = 4'd5, UPS1 = 4'd6, UPS2 = 4'd7, UPS3 = 4'd8, 
               UPS4 = 4'd9, TAIL = 4'd10, DONE = 4'd11;




// --- 1. Module RECEPTOR ---
// VALID: DONE
    receptor #(
        .DATA_W(DATA_W),
        .ADDR_W(64) 
    ) u_receptor (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tready  (s_axis_tready),
        .i_done         (top_done),           //Use when finish one image
        .o_data         (w_shared_data),
        .o_addr1        (w_addr_depth_raw [ADDR_IMG-5:0]),
        .o_addr2        (w_addr_point_raw [ADDR_IMG-3:0]),
        .o_addr3        (w_addr_img_raw   [ADDR_IMG-1:0]),
        .o_addr4        (w_addr_bias_raw  [ADDR_IMG-7:0]),
        .o_valid1       (w_valid_depth),
        .o_valid2       (w_valid_point),
        .o_valid3       (w_valid_img),
        .o_valid4       (w_valid_bias)
    );
    
    

// --- 2. DEPTH_MEM (9 Banks - Config/Weights) ---
//  Be consious: latency = 1, it can be possible to be async
(* DONT_TOUCH = "yes" *)
    depth_mem #(
        .ADDR_W(ADDR_DEPTH),
        .DATA_W(DATA_W),
        .NUM_BANKS(9),
        .LATENCY(1)                 //caution
    ) u_depth_mem (
        .i_clk          (i_clk),
        .i_wr_addr      (w_addr_depth_raw[ADDR_DEPTH-1:0]),
        .i_wr_data      (w_shared_data),
        .i_wr_ena_mask  (w_valid_depth),
        .i_rd_addr      (top_rd_addr_depth),          //already declare here
        .i_rd_enb       (top_rd_enb_depth),           //already declare here
        .o_data_all     (top_data_depth),             //already declare here  
        .o_data_vld_all (top_vld_depth)               //already declare here
    );

// --- 3. POINT_MEM (16 Banks - Coordinates/Points) ---
//VALID: DONE
(* DONT_TOUCH = "yes" *)
    point_mem #(
        .ADDR_W(ADDR_POINT),
        .DATA_W(DATA_W),
        .NUM_BANKS(16),
        .LATENCY(1)
    ) u_point_mem (
        .i_clk          (i_clk),
        .i_wr_addr      (w_addr_point_raw[ADDR_POINT-1:0]),
        .i_wr_data      (w_shared_data),
        .i_wr_ena_mask  (w_valid_point),
        .i_rd_addr      (top_rd_addr_point),          //already declare here 
        .i_rd_enb       (top_rd_enb_point),           //already declare here 
        .o_data_all     (top_data_point),             //already declare here 
        .o_data_vld_all (top_vld_point)               //already declare here 
    );    
    (* DONT_TOUCH = "yes" *)
    point_mem #(
        .ADDR_W(ADDR_BIAS),
        .DATA_W(16),
        .NUM_BANKS(16),
        .LATENCY(1),
        .RAM_STYLE("distributed")
    ) u_bias_mem (
        .i_clk          (i_clk),
        .i_wr_addr      (w_addr_bias_raw[ADDR_POINT-1:0]),
        .i_wr_data      (w_shared_data[15:0]),
        .i_wr_ena_mask  (w_valid_bias),
        .i_rd_addr      (top_rd_addr_bias),          //already declare here 
        .i_rd_enb       (top_rd_enb_bias),           //already declare here 
        .o_data_all     (top_data_bias),             //already declare here 
        .o_data_vld_all (top_vld_bias)               //already declare here 
    );



    

// --- Instance rd_select ---
rd_select #(
    .ADDRESS_DATA (12)
) u_rd_select (
    .i_stage           (top_stage),
    .i_mem_rd_swapping (top_mem_rd_swapping), // Ép ki?u 2-bit sang 3-bit n?u c?n
    .i_mem_rd_addr     (top_mem_rd_addr),
    .i_mem_rd_enb      (top_mem_rd_enb),
    .i_lic             (top_lic_counter),
    .i_row             (top_row_counter),
    .i_col             (top_col_counter),

    .o_mem_img_addr    (top_rd_mem_img_addr),
    .o_mem0_addr       (top_rd_mem0_addr),
    .o_mem1_addr       (top_rd_mem1_addr),
    .o_mem2_addr       (top_rd_mem2_addr),
    .o_mem3_addr       (top_rd_mem3_addr),
    .o_mem4_addr       (top_rd_mem4_addr),
    .o_mem5_addr       (top_rd_mem5_addr),
//    .o_mem_stega_addr  (top_rd_mem_stega_addr),

    .o_mem_img_enb     (top_rd_mem_img_enb),
    .o_mem0_enb        (top_rd_mem0_enb),
    .o_mem1_enb        (top_rd_mem1_enb),
    .o_mem2_enb        (top_rd_mem2_enb),
    .o_mem3_enb        (top_rd_mem3_enb),
    .o_mem4_enb        (top_rd_mem4_enb),
    .o_mem5_enb        (top_rd_mem5_enb)
//    .o_mem_stega_enb   (top_rd_mem_stega_enb)
);

// --- K?t n?i ngý?c l?i module mem_0 (Ví d?) ---
// Sau khi g?i rd_select, Duy nh? c?p nh?t l?i các c?ng ð?c c?a module nh?:
//assign w_mem0_rd_addr     = w_sel_mem0_addr;
//assign w_mem0_rd_enb_mask = w_sel_mem0_enb;


/////////////////////////////////////////////////////////////////////////////////
//MEM_IMG: 6 banks: SAVE HEAD FROM AXI
    mem_img #(
        .ADDR_W(ADDR_IMG),
        .ADDR_R(ADDR_IMG_R),
        .DATA_W(DATA_W),
        .NUM_BANKS(6),
        .SUB_W(SUB_W),
        .LATENCY(3) 
    ) u_img_mem (
        .i_clk          (i_clk),
        .i_wr_addr      (w_addr_img_raw[ADDR_IMG-1:0]),
        .i_wr_data_all  ({6{w_shared_data}}),       // Should have Mux here soon!
        .i_wr_en_mask   (w_valid_img),
        .i_rd_addr      (top_rd_mem_img_addr),            //already declare here 
        .i_rd_enb       (top_rd_mem_img_enb),             //already declare here 
        .o_data_all     (top_data_img),               //already declare here 
        .o_data_vld     (top_vld_img)                 //already declare here 
    );


/////////////////////////////////////////////////////////////////////////////////
//MEM0: 16 banks: SAVE HEAD OUTPUT

mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_W),
    .NUM_BANKS (16),
    .LATENCY   (3)
) mem_0 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_wr_mem0_addr),                          //connect to MUX
    .i_wr_data_all     (top_wr_data_mem0),                          //connect to MUX
    .i_wr_ena_mask     (top_wr_mem0_ena),                          //connect to MUX
    .i_rd_addr         (top_rd_mem0_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem0_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_0),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_0)                           //connect to MUX           
);

/////////////////////////////////////////////////////////////////////////////////
//STEGA_MEM_INTERFACE: This module is take the output of add operation between
//cover and residual => Save in 16*3 bit in MEM1
stega_mem_interface #(
        .ADDR_W(12),
        .DATA_W(64),
        .NUM_BANKS(3)
    ) u_stega_bridge (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .i_stega_wr_addr    (top_wr_stega_addr), 
        .i_stega_wr_data    (top_wr_data_mem_stega), // top_wr_data_mem_stega Duy ð?nh ngh?a trý?c ðó
        .i_stega_wr_en      (top_wr_stega_ena),
        
        .o_gen_wr_addr      (top_stega_addr),
        .o_gen_wr_data      (top_stega_data),
        .o_gen_wr_en        (top_stega_ena)
    );

mux_mem1 #(
    .ADDR(12)
) u_mux_mem1 (
    .i_stage            (top_stage),             
   
    .i_wr_stega_ena     (top_stega_ena),    
    .i_wr_stega_addr    (top_stega_addr),
    .i_wr_stega_data    (top_stega_data),
   
    .i_wr_mem_ena       (|top_wr_mem1_ena),          
    .i_wr_mem_addr      (top_wr_mem1_addr),           
    .i_wr_mem_data      (top_wr_data_mem1),    
    
    .o_wr_mem_mux_data  (top_mem1_mux_data),
    .o_wr_mem_mux_addr  (top_mem1_mux_addr),
    .o_wr_mem_mux_ena   (top_mem1_mux_ena)
);

//MEM1: 8 banks
mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_W),
    .NUM_BANKS (8),
    .LATENCY   (3)
) mem_1 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_mem1_mux_addr),          //connect to MUX
    .i_wr_data_all     (top_mem1_mux_data),                         //connect to MUX
    .i_wr_ena_mask     (top_mem1_mux_ena),          //connect to MUX
    .i_rd_addr         (top_rd_mem1_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem1_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_1),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_1)                           //connect to MUX           
);

/////////////////////////////////////////////////////////////////////////////////
//MEM2: 8 banks
mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_W),
    .NUM_BANKS (8),
    .LATENCY   (3)
) mem_2 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_wr_mem2_addr),          //connect to MUX
    .i_wr_data_all     (top_wr_data_mem2),                          //connect to MUX
    .i_wr_ena_mask     (top_wr_mem2_ena),           //connect to MUX
    .i_rd_addr         (top_rd_mem2_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem2_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_2),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_2)                           //connect to MUX           
);

/////////////////////////////////////////////////////////////////////////////////
//MEM3: 8 banks
mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_W),
    .NUM_BANKS (8),
    .LATENCY   (3)
) mem_3 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_wr_mem3_addr),          //connect to MUX
    .i_wr_data_all     (top_wr_data_mem3),                          //connect to MUX
    .i_wr_ena_mask     (top_wr_mem3_ena),           //connect to MUX
    .i_rd_addr         (top_rd_mem3_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem3_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_3),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_3)                           //connect to MUX           
);

/////////////////////////////////////////////////////////////////////////////////
//MEM4: 8 banks
mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_W),
    .NUM_BANKS (8),
    .LATENCY   (3)
) mem_4 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_wr_mem4_addr),         //connect to MUX
    .i_wr_data_all     (top_wr_data_mem4),                         //connect to MUX
    .i_wr_ena_mask     (top_wr_mem4_ena),          //connect to MUX
    .i_rd_addr         (top_rd_mem4_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem4_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_4),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_4)                           //connect to MUX           
);


/////////////////////////////////////////////////////////////////////////////////
//MEM_5: 8 banks
mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_W),
    .NUM_BANKS (8),
    .LATENCY   (3)
) mem_5 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_wr_mem5_addr),          //connect to MUX
    .i_wr_data_all     (top_wr_data_mem5),                          //connect to MUX
    .i_wr_ena_mask     (top_wr_mem5_ena),           //connect to MUX
    .i_rd_addr         (top_rd_mem5_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem5_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_5),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_5)                           //connect to MUX           
);

/////////////////////////////////////////////////////////////////////////////////
//DATA_SEL0: 
data_select0 u_data_select0 (
    .i_mem_img_data    (top_data_img),
    .i_mem_img_vld     (|top_vld_img),
    .i_mem_0_data      (top_data_mem_0),
    .i_mem_1_data      (top_data_mem_1),
    .i_mem_2_data      (top_data_mem_2),
    .i_mem_3_data      (top_data_mem_3),
    .i_mem_4_data      (top_data_mem_4),
    .i_mem_5_data      (top_data_mem_5),
    .i_mem_0_vld       (|top_vld_mem_0),
    .i_mem_1_vld       (|top_vld_mem_1),
    .i_mem_2_vld       (|top_vld_mem_2),
    .i_mem_3_vld       (|top_vld_mem_3),
    .i_mem_4_vld       (|top_vld_mem_4),
    .i_mem_5_vld       (|top_vld_mem_5),
    .i_mem_swapping    (top_mem_rd_swapping),
    .i_stage           (top_stage),
    .o_pixel           (top_ds0_pixel),
    .o_valid           (top_ds0_valid)
);

/////////////////////////////////////////////////////////////////////////////////
//DATA_SEL1: 
data_select1 u_data_select1 (
    .i_mem_img_data    (top_data_img),
    .i_mem_img_vld     (|top_vld_img),
    .i_mem_0_data      (top_data_mem_0),
    .i_mem_1_data      (top_data_mem_1),
    .i_mem_2_data      (top_data_mem_2),
    .i_mem_3_data      (top_data_mem_3),
    .i_mem_4_data      (top_data_mem_4),
    .i_mem_5_data      (top_data_mem_5),
    .i_mem_0_vld       (|top_vld_mem_0),
    .i_mem_1_vld       (|top_vld_mem_1),
    .i_mem_2_vld       (|top_vld_mem_2),
    .i_mem_3_vld       (|top_vld_mem_3),
    .i_mem_4_vld       (|top_vld_mem_4),
    .i_mem_5_vld       (|top_vld_mem_5),
    .i_mem_swapping    (top_mem_rd_swapping),
    .i_stage           (top_stage),
    .o_pixel           (top_ds1_pixel),
    .o_valid           (top_ds1_valid)
);
    
    


    
    // --- Mux Selects (Dùng cho kh?i Datapath/PE) ---

    
    (* DONT_TOUCH = "yes" *)
    rd_fsm_control u_rd_fsm_control (
    .i_clk                  (i_clk),
    .i_enable               (!s_axis_tready),
    .i_rst                  (i_rst_n),           // Lýu ?: ki?m tra i_rst là 1 hay 0 (thý?ng rd_fsm dùng tích c?c cao)
    .i_stage_done           (top_stage_done && !(top_point_computed_vld0 | top_point_computed_vld1)),
    .i_n_mem_valid          (top_ds1_valid || top_ds0_valid),
    .i_ld_wb_done           (wb_ld_done),     // K?t n?i ngý?c t? Weight Control v? FSM
    
    .o_mode                 (top_mode),
    .o_last_loop            (top_last_loop),
    .o_ld_wb_enable         (wb_ld_enable),  // Kích ho?t n?p Weight/Bias
    .o_stage                (top_stage),         // T?ng hi?n t?i
    
    // Các c?ng config khác k?t n?i ra ngoài ho?c vào module khác
    .o_config_dep_para      (top_config_dep_para),
    .o_config_point_para    (top_config_point_para),
    .o_config_stride        (top_config_stride),
    .o_config_max_line_in   (top_config_max_line_in),
    .o_config_max_line_out  (top_config_max_line_out),
    .o_mem_rd_addr          (top_mem_rd_addr),
    .o_mem_rd_enb           (top_mem_rd_enb),
    .o_padding_vld          (top_padding_vld),
    .o_lic_counter          (top_lic_counter),
    .o_row_counter          (top_row_counter),
    .o_col_counter          (top_col_counter),
    .o_mem_rd_swapping      (top_mem_rd_swapping),
    .o_rst_pw_cmp           (top_rst_pw_cmp),
    .o_first_loop           (top_first_loop),
    .o_done                 (top_done)
);
//(* KEEP = "true" *)    reg [3:0] tmp_top_stage;
//    always @(posedge i_clk) begin
//        tmp_top_stage <= top_stage;
//    end
weight_bias_control #(
    .ADDRESS_WEIGHT         (ADDR_IMG_R),
    .ADDRESS_BIAS           (ADDR_BIAS)
) u_weight_bias_control (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),         // must reset follow i_rst_n || i_done
    .i_ld_wb_enable         (wb_ld_enable),  // Nh?n l?nh t? FSM
    .i_stage                (top_stage),         // Nh?n thông tin stage t? FSM
    .i_last_loop            (top_last_loop),     // Nh?n tr?ng thái loop t? FSM
    .i_mode                 (top_mode),          // Ch? ð? ho?t ð?ng (S1/S2 ho?c Depth/Point)
    
    // Memory Interface (K?t n?i t?i BRAM ch?a Weight/Bias)
    .o_dweight_rd_addr      (top_rd_addr_depth),
    .o_dweight_ena          (top_rd_enb_depth),
    .o_pweight_rd_addr      (top_rd_addr_point),
    .o_pweight_ena          (top_rd_enb_point),
    .o_bias_rd_addr         (top_rd_addr_bias),
    .o_bias_ena             (top_rd_enb_bias),

    // Mux Select (K?t n?i t?i kh?i tính toán / Datapath)
    .o_depth_sel            (depth_sel),
    .o_point_sel            (point_sel),
    .o_bias_sel             (bias_sel),
    
    // Status Output
    .o_load_done            (wb_ld_done)      // Báo v? FSM khi n?p xong
);

always @(posedge i_clk) begin
    top_depth_sel <= depth_sel;
    top_point_sel <= point_sel;
    top_bias_sel  <= bias_sel ;
    
end

wire internal_rst_n;
assign internal_rst_n = i_rst_n && (!top_stage_done);

fsm_line_buffer #(
    .DATA_IN_W (256),
    .KERNEL_W  (2304)
) u_fsm_line_buffer0 (
    .i_clk                 (i_clk),
    .i_rst_n               (internal_rst_n),
    .i_enable              (!s_axis_tready),
    .i_data_vld            (top_ds0_valid),        // Dùng data ð? select làm input
    .i_padding_vld         (top_padding_vld),
    .i_config_stride       (top_config_stride),
    .i_config_max_line_in  (top_config_max_line_in),
    .i_config_max_line_out (top_config_max_line_out),
    .i_data_in             (top_ds0_pixel),
    .o_kernel_data         (top_lb_kernel_0),
    .o_kernel_vld          (top_lb_kernel_vld_0)
);

fsm_line_buffer #(
    .DATA_IN_W (256),
    .KERNEL_W  (2304)
) u_fsm_line_buffer1 (
    .i_clk                 (i_clk),
    .i_rst_n               (internal_rst_n),
    .i_enable              (!s_axis_tready && (top_mode == 1)),
    .i_data_vld            (top_ds1_valid),        // Dùng data ð? select làm input
    .i_padding_vld         (top_padding_vld),
    .i_config_stride       (top_config_stride),
    .i_config_max_line_in  (top_config_max_line_in),
    .i_config_max_line_out (top_config_max_line_out),
    .i_data_in             (top_ds1_pixel),
    .o_kernel_data         (top_lb_kernel_1),
    .o_kernel_vld          (top_lb_kernel_vld_1)
);

/////////////////////////////////////////////////////////////////////////////////
//WR_FSM_CONTROL: This use to write to memories according to STAGE, and save valid data.
//This module can work from output from Pointwise and from Adder Tree at Done stage.
    (* DONT_TOUCH = "yes" *)
    wr_fsm_control #(
        .DATA_COMPUTED_W (512),
        .ADDR_URAM_W     (12),
        .ADDR_STEGA_W    (14)
    ) u_wr_ctrl (
        .i_clk               (i_clk),
        .i_rst_n             (i_rst_n),
        
        // Inputs t? Core
        .i_computed_data     ({top_point_computed1,top_point_computed0}),
        .i_vld               (top_point_computed_vld0 | top_point_computed_vld1),
        .i_adder_vld         (top_vld_adder),
        .i_computed_adder    (top_computed_adder),
        .i_stage             (top_stage),
    
        // Outputs Enable
        .o_wr_mem0_ena       (top_wr_mem0_ena),
        .o_wr_mem1_ena       (top_wr_mem1_ena),
        .o_wr_mem2_ena       (top_wr_mem2_ena),
        .o_wr_mem3_ena       (top_wr_mem3_ena),
        .o_wr_mem4_ena       (top_wr_mem4_ena),
        .o_wr_mem5_ena       (top_wr_mem5_ena),
        .o_wr_mem_stega_ena  (top_wr_stega_ena),
    
        // Outputs Addresses
        .o_wr_mem0_addr      (top_wr_mem0_addr),
        .o_wr_mem1_addr      (top_wr_mem1_addr),
        .o_wr_mem2_addr      (top_wr_mem2_addr),
        .o_wr_mem3_addr      (top_wr_mem3_addr),
        .o_wr_mem4_addr      (top_wr_mem4_addr),
        .o_wr_mem5_addr      (top_wr_mem5_addr),
        .o_wr_mem_stega_addr (top_wr_stega_addr),       //top_adder_vld
        
        .o_computed_data     (top_wr_computed_data), // Data ð? delay kh?p v?i Addr/Ena
        .o_computed_adder     (top_wr_computed_adder) // Data ð? delay kh?p v?i Addr/Ena
    );
    
    

 

    (* DONT_TOUCH = "yes" *)
    Depthwise_Core_Top 
    depthwise_0
    (
    .clk (i_clk), 
    .rst_n (i_rst_n),
    .i_weight_valid (top_vld_depth && (top_depth_sel == 0)),         // B?t trong 8 chu k? ð? n?p ð? 32CH
    .i_weight_data(top_data_depth),  // 4 CH * 9 W * 16 bits = 576 bits
    .i_data_valid (top_lb_kernel_vld_0),           // Kh?i trý?c s? t?t cái này khi ðang n?p weight
    .i_all_windows (top_lb_kernel_0), // 16 CH * 9 P * 16 bits
    .o_data (top_depth_computed0),
    .o_data_valid(top_depth_computed_vld0)
);


    (* DONT_TOUCH = "yes" *)
    Depthwise_Core_Top 
    depthwise_1
    (
    .clk (i_clk), 
    .rst_n (i_rst_n),
    .i_weight_valid (top_vld_depth && (top_depth_sel == 1)),         // B?t trong 8 chu k? ð? n?p ð? 32CH
    .i_weight_data(top_data_depth),  // 4 CH * 9 W * 16 bits = 576 bits
    .i_data_valid (top_lb_kernel_vld_1),           // Kh?i trý?c s? t?t cái này khi ðang n?p weight
    .i_all_windows (top_lb_kernel_1), // 16 CH * 9 P * 16 bits
    .o_data (top_depth_computed1),
    .o_data_valid(top_depth_computed_vld1)
);

    (* DONT_TOUCH = "yes" *)
    mux_mode u_mux_mode(
    .i_mode (top_mode),
    .i_depth_vld_0 (top_depth_computed_vld0),
    .i_depth_vld_1 (top_depth_computed_vld1),
    .i_depth_data_0 (top_depth_computed0),
    .i_depth_data_1 (top_depth_computed1),
    .mux_out_data (top_mux_point_data),
    .mux_out_vld (top_mux_point_vld)
);

    (* DONT_TOUCH = "yes" *)
    pw_top #(
        .DATA_WIDTH(16),
        .IN_CHANNELS(16),
        .OUT_CHANNELS(16)
    ) u_pw_unit (
        .clk                (i_clk),
        .rst_n              (i_rst_n),
        
        // C?p phát Weight & Bias (Duy n?p t? ROM ho?c Controller)
        .i_weight_valid0    (top_vld_point && (top_point_sel == 0)), 
        .i_weight_valid1    ((top_vld_point && (top_point_sel == 1)) || (top_vld_point && (top_mode == 1))),
        .i_data_weight_pw   (top_data_point),
        .i_bias_valid0      (top_vld_bias && (top_bias_sel == 0)),
        .i_bias_valid1      ((top_vld_bias && (top_bias_sel == 1)) || (top_vld_bias && (top_mode == 1))),
        .i_bias_pw          (top_data_bias),
        .i_rst_stage        (top_rst_pw_cmp),

        // Data Feature & Control
        .i_valid            (top_mux_point_vld || top_depth_computed_vld0),          //mux
        .i_mode             (top_mode),          
        .i_is_first         (top_first_loop),
        .i_is_last          (top_last_loop),
        .i_fifo_mode        (top_config_max_line_out),         //rd_fsm_control must add
        .i_data_feature     ({top_mux_point_data,top_depth_computed0}),

        // Outputs (K?t n?i th?ng xu?ng kh?i ghi ho?c kh?i ti?p theo)
        .o_data_pw0         (top_point_computed0),
        .o_valid_pw0        (top_point_computed_vld0),
        .o_data_pw1         (top_point_computed1),
        .o_valid_pw1        (top_point_computed_vld1),
        .o_stage_done       (top_stage_done)
    );
    
    wr_data_select #(
        .BANK4_W(256),   // 64 * 4
        .BANK8_W(512),   // 64 * 8
        .BANK16_W(1024), // 64 * 16
        .ADDER_W(48)     // 16 * 3
    ) u_data_sel (
        .i_rst_n            (i_rst_n),
        .i_stage            (top_stage),        
        .i_computed_data    (top_wr_computed_data),       // Data 512-bit t? wr_fsm_control (ð? delay)
        .i_adder_data       (top_wr_computed_adder),                 //addertree
        
        // K?t n?i ð?n các bus d? li?u t?ng c?a t?ng c?m Mem
        .o_wr_data_mem0     (top_wr_data_mem0),
        .o_wr_data_mem1     (top_wr_data_mem1),
        .o_wr_data_mem2     (top_wr_data_mem2),
        .o_wr_data_mem3     (top_wr_data_mem3),
        .o_wr_data_mem4     (top_wr_data_mem4),
        .o_wr_data_mem5     (top_wr_data_mem5),
        .o_wr_data_mem_stega(top_wr_data_mem_stega)
    );  
    
    mem2_to_adder 
    u_mem2_to_adder (
    .i_vld (top_vld_mem_2[3:0]),
    .i_data (top_data_mem_2[255:0]),
    .o_data (top_adder_residual)
    );
    
    adder_tree #(
        .WIDTH(16),
        .NUM_CH(3)
    ) u_adder_stega (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_vld      ((|top_vld_mem_2) && (|top_vld_img) && (top_stage == DONE)), // L?y valid t? Pointwise ra
        .i_data_a   (top_data_img[47:0]), 
        .i_data_b   (top_adder_residual),    
        .o_sum      (top_computed_adder), // N?i vào i_adder_data c?a wr_data_select
        .o_vld      (top_vld_adder)
    );
    
    stream_out u_stream_out (
    .i_stage (top_stage),
    .i_vld(top_vld_mem_1[2:0]),
    .i_ena(m_axis_tready),
    .i_data(top_data_mem_1[191:0]),
    .o_vld(m_axis_tvalid),
    .o_data(m_axis_tdata)
);

endmodule

module mux_mode (
    input i_mode,
    input i_depth_vld_0,
    input i_depth_vld_1,
    input [255:0] i_depth_data_0,
    input [255:0] i_depth_data_1,
    output reg [255:0] mux_out_data,
    output reg  mux_out_vld
);
    always @(*) begin
        if (!i_mode) begin
            mux_out_data = i_depth_data_0;
            mux_out_vld =i_depth_vld_0;
        end
        else begin
            mux_out_data = i_depth_data_1;
            mux_out_vld =i_depth_vld_1;
        end
    end
endmodule
