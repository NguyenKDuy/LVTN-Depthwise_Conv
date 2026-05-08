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
    parameter DATA_128                  = 128,
    parameter DATA_32                   = 32,
    parameter DATA_64                   = 64, //WEIGHT
    parameter WEIGHT_MEM_LATENCY        = 2,            //can increase
    parameter MEM_LATENCY               = 3             //maybe can be 1,2 plus

)(
    input           i_clk,
    input           i_rst_n,

    // --- AXI4-Stream Slave (DMA) ---
    input           s_axis_tvalid0,
    input           s_axis_tvalid1,
    input           [DATA_64-1:0]   s_axis_tdata0,
    input           [DATA_128-1:0]  s_axis_tdata1,
    output          s_axis_tready0,
    output          s_axis_tready1,
    // --- AXI Stream out Interface ---
    output wire                m_axis_tvalid,
    output wire     [DATA_128-1:0]   m_axis_tdata,
    output wire                m_axis_tlast,
    input                      m_axis_tready
);
///////////////////////////////////////////////////////////////////
    localparam DATA_192    = 192;
    localparam ADDR_BIAS   = 8;
    localparam ADDR_DEPTH  = 8;
    localparam ADDR_POINT  = 10;
    localparam ADDR_IMG    = 12;
    localparam ADDR_IMG_R  = 14;
    localparam DATA_16     = 16;
///////////////////////////////////////////////////////////////////
// --- MODULE RECEPTOR
    wire [DATA_64-1:0]    w_shared_data0;
    wire [DATA_192-1:0]   w_shared_data1,top_pre_data;
    wire [12:0]           w_addr_depth_raw, w_addr_point_raw, w_addr_img_raw, w_addr_bias_raw;
    wire top_pre_vld;
    wire [8:0]            w_valid_depth;
    wire [15:0]           w_valid_point;
    wire [15:0]           w_valid_bias;
    wire [5:0]            w_valid_img;
    wire                  top_done;
///////////////////////////////////////////////////////////////////
// --- MODULE DEPTH MEM
    wire [ADDR_DEPTH-1:0]   top_rd_addr_depth;
    wire                    top_rd_enb_depth;
    wire [9*DATA_64-1:0]     top_data_depth  ;
    wire                    top_vld_depth   ;

///////////////////////////////////////////////////////////////////
// --- MODULE POINT_MEM
    wire [ADDR_POINT-1:0]   top_rd_addr_point;
    wire                    top_rd_enb_point ;
    wire [16*DATA_64-1:0]    top_data_point   ;
    wire                    top_vld_point    ;

///////////////////////////////////////////////////////////////////    
// --- MODULE IMAGE_MEM
    wire [ADDR_IMG_R-1:0]   top_rd_addr_img; 
    wire [5:0]              top_rd_enb_img ; 
    wire [6*DATA_64-1:0]    top_data_img   ; 
    wire [5:0]              top_vld_img    ; 
    
///////////////////////////////////////////////////////////////////    
// --- MODULE BIAS_MEM
    wire [ADDR_BIAS-1:0]    top_rd_addr_bias; 
    wire                    top_rd_enb_bias ; 
    wire [16*16-1:0]        top_data_bias   ; 
    wire                    top_vld_bias    ;     
 
///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_0
    wire [16*DATA_64-1:0]        top_data_mem_0   ; 
    wire [15:0]                 top_vld_mem_0    ;
    
///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_1
    wire [8*DATA_64-1:0]         top_data_mem_1   ; 
    wire [7:0]                  top_vld_mem_1    ;  

///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_2
    wire [8*DATA_64-1:0]         top_data_mem_2   ; 
    wire [7:0]                  top_vld_mem_2    ;  
     
///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_3
    wire [8*DATA_64-1:0]         top_data_mem_3   ; 
    wire [7:0]                  top_vld_mem_3    ;  

///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_4
    wire [8*DATA_64-1:0]         top_data_mem_4   ; 
    wire [7:0]                  top_vld_mem_4    ;  
            
///////////////////////////////////////////////////////////////////    
// --- MODULE MEM_5
    wire [8*DATA_64-1:0]         top_data_mem_5   ; 
    wire [7:0]                  top_vld_mem_5    ;  
        

///////////////////////////////////////////////////////////////////    
// --- MODULE RD_FSM_CONTROL

    wire [4:0]  top_config_dep_para      ;
    wire [4:0]  top_config_point_para    ;
    wire [1:0]  top_config_stride        ;
    wire [7:0]  top_config_max_line_in   ;
    wire [7:0]  top_config_max_line_out  ;
    wire [3:0]  top_stage                ;
    wire        top_mode                 ; 
    wire        top_stream_d;
    wire        top_last4stage;
    wire        top_disable_t;
    wire        top_no_relu;
    // --- Memory & Counters ---
    wire [ADDR_IMG_R - 1:0] top_mem_rd_addr  ;        // Ð?a ch? ð?c d? li?u input/feature map
    wire        top_mem_rd_enb               ;
    wire [1:0]  top_mem_rd_swapping          ;
    wire        top_padding_vld              ;
    wire        top_rst_pw_cmp               ;
    wire        top_first_loop               ;
    wire [3:0]  top_lic_counter              ;
    wire [7:0]  top_row_counter              ;
    wire [7:0]  top_col_counter              ;

//////////////////////////////////////////////////////////////////////
//MODULE WEIGHT_BIAS_CONTROL
    wire top_depth_sel; 
    wire top_point_sel; 
    wire top_bias_sel;  
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
    wire [255:0] top_depth_computed0_dl;
    wire [255:0] top_depth_computed1_dl;
//    wire [255:0] top_mux_point_data;
    wire top_depth_computed_vld0;  
    wire top_depth_computed_vld1;   
    wire top_depth_computed_vld0_dl;  
    wire top_depth_computed_vld1_dl;  
//    wire top_mux_point_vld;  
    
    wire [255:0] top_point_computed0, top_point_computed1;  
    wire top_point_computed_vld0, top_point_computed_vld1; 
///////////////////////////////////////////////////////////////////
wire [ADDR_IMG-1:0]       top_stega_64_addr;
wire [DATA_64*3-1:0]     top_stega_64_data;
wire [2:0]              top_stega_64_ena;

// --- Tín hi?u ð?u vào cho MUX (Thý?ng là input c?a module Top ho?c t? kh?i khác) ---
// Tín hi?u t? Stega (16-bit)
wire [ADDR_IMG+1:0]       top_stega_16_addr;
wire [16*3-1:0]         top_stega_16_data;
wire [2:0]              top_stega_16_ena;

// --- Tín hi?u ð?u ra cu?i cùng c?a MUX ---
wire [DATA_64*8-1:0]     top_mem_inf_mux_data;
wire [ADDR_IMG-1:0]       top_mem_inf_mux_addr;
wire [7:0]              top_mem_inf_mux_ena;


//////////////////////////////////////////////////////////////////
//MODULE: STEGA_INTERFACE  (support write 16bit-2-64bit)
//    wire [11:0]             top_stega_addr; // Ð?a ch? d?ng (64-bit row)
//    wire [191:0]            top_stega_data; // D? li?u 3 banks x 64-bit = 192 bits
//    wire [2:0]              top_stega_ena;  // L?nh ghi cho t?ng bank
    
//    wire [511:0]            top_mem1_mux_data; // 16-bit * 8 banks = 128 bits
//    wire [11:0]             top_mem1_mux_addr;
//    wire [7:0]              top_mem1_mux_ena;
    
    wire top_stage_done;   
    wire wb_ld_done, wb_ld_enable, top_last_loop;
    wire [191:0] top_wr_computed_adder, top_computed_adder, top_adder_residual;
    wire top_vld_adder, top_adder_done;
//////////////////////////////////////////////////////////////////
//MODULE: LINE_BUFFER
    wire [2303: 0] top_lb_kernel_0, top_lb_kernel_1;
    wire top_lb_kernel_vld_0, top_lb_kernel_vld_1;
    wire internal_rst_n;
    assign internal_rst_n = i_rst_n && (!top_stage_done);

    
    
    localparam HEAD = 4'd1, DOWNS1 = 4'd2, DOWNS2 = 4'd3, DOWNS3 = 4'd4, 
               BOTT = 4'd5, UPS1 = 4'd6, UPS2 = 4'd7, UPS3 = 4'd8, 
               UPS4 = 4'd9, TAIL = 4'd10, DONE = 4'd11;
// PREPROCESSING:
//Dua 128 bit sang 192 bit


pre_process pre_process(
    .i_clk (i_clk),
    .i_rst_n(i_rst_n),
    .s_axis_tvalid (s_axis_tvalid1),
    .s_axis_tdata (s_axis_tdata1),   // {pix3,pix2,pix1,pix0} XRGBÃ-4
    .o_valid (top_pre_vld),
    .o_data (top_pre_data)   
    );

// --- 1. Module RECEPTOR ---
// VALID: DONE
receptor #(
    .ADDR_W(12)) 
u_receptor (
    .i_clk           (i_clk),
    .i_rst_n         (i_rst_n),
    .s_axis_tvalid0  (s_axis_tvalid0),
    .s_axis_tvalid1  (top_pre_vld),
    .s_axis_tdata0   (s_axis_tdata0),
    .s_axis_tdata1   (top_pre_data),
    .s_axis_tready0  (s_axis_tready0),
    .s_axis_tready1  (s_axis_tready1),
    .i_done          (top_done),           //Use when finish one image
    .o_data0         (w_shared_data0),
    .o_data1         (w_shared_data1),
    .o_addr1         (w_addr_depth_raw [ADDR_IMG-5:0]),
    .o_addr2         (w_addr_point_raw [ADDR_IMG-3:0]),
    .o_addr3         (w_addr_img_raw   [ADDR_IMG-1:0]),
    .o_addr4         (w_addr_bias_raw  [ADDR_BIAS-1:0]),
    .o_valid1        (w_valid_depth),
    .o_valid2        (w_valid_point),
    .o_valid3        (w_valid_img),
    .o_valid4        (w_valid_bias)
    );
    
    

// --- 2. DEPTH_MEM (9 Banks - Config/Weights) ---
//  Be consious: latency = 1, it can be possible to be async
depth_mem #(
    .ADDR_W(ADDR_DEPTH),
    .DATA_W(DATA_64),
    .NUM_BANKS(9),
    .LATENCY(WEIGHT_MEM_LATENCY)) 
u_depth_mem (
    .i_clk          (i_clk),
    .i_wr_addr      (w_addr_depth_raw[ADDR_DEPTH-1:0]),
    .i_wr_data      (w_shared_data0),
    .i_wr_ena_mask  (w_valid_depth),
    .i_rd_addr      (top_rd_addr_depth),          //already declare here
    .i_rd_enb       (top_rd_enb_depth),           //already declare here
    .o_data_all     (top_data_depth),             //already declare here  
    .o_data_vld_all (top_vld_depth)               //already declare here
    );

// --- 3. POINT_MEM (16 Banks - Coordinates/Points) ---
point_mem #(
    .ADDR_W(ADDR_POINT),
    .DATA_W(DATA_64),
    .NUM_BANKS(16),
    .LATENCY(WEIGHT_MEM_LATENCY)) 
u_point_mem (
    .i_clk          (i_clk),
    .i_wr_addr      (w_addr_point_raw[ADDR_POINT-1:0]),
    .i_wr_data      (w_shared_data0),
    .i_wr_ena_mask  (w_valid_point),
    .i_rd_addr      (top_rd_addr_point),          //already declare here 
    .i_rd_enb       (top_rd_enb_point),           //already declare here 
    .o_data_all     (top_data_point),             //already declare here 
    .o_data_vld_all (top_vld_point)               //already declare here 
    );   
    
     
point_mem #(
    .ADDR_W(ADDR_BIAS),
    .DATA_W(16),
    .NUM_BANKS(16),
    .LATENCY(WEIGHT_MEM_LATENCY),
    .RAM_STYLE("block")) 
u_bias_mem (
    .i_clk          (i_clk),
    .i_wr_addr      (w_addr_bias_raw[ADDR_BIAS-1:0]),
    .i_wr_data      (w_shared_data0[15:0]),
    .i_wr_ena_mask  (w_valid_bias),
    .i_rd_addr      (top_rd_addr_bias),          
    .i_rd_enb       (top_rd_enb_bias),           
    .o_data_all     (top_data_bias),             
    .o_data_vld_all (top_vld_bias)               
    );

// --- Instance rd_select ---
//
rd_select #(
    .ADDRESS_DATA (12)) 
u_rd_select (
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



/////////////////////////////////////////////////////////////////////////////////
//MEM_IMG: 6 banks: SAVE HEAD FROM AXI
mem_img #(
    .ADDR_W(ADDR_IMG),
    .ADDR_R(ADDR_IMG_R),
    .DATA_W(DATA_64),
    .NUM_BANKS(6),
    .SUB_W(DATA_16),
    .LATENCY(MEM_LATENCY)) 
u_img_mem (
    .i_clk          (i_clk),
    .i_sel          ((top_stage == DONE)?1:0),
    .i_wr_addr      (w_addr_img_raw[ADDR_IMG-1:0]),
    .i_wr_data_all  ({2{w_shared_data1}}),       // Should have Mux here soon!
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
    .DATA_W    (DATA_64),
    .NUM_BANKS (16),
    .LATENCY   (MEM_LATENCY)) 
mem_0 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_wr_mem0_addr),                          //connect to MUX
    .i_wr_data_all     (top_wr_data_mem0),                          //connect to MUX
    .i_wr_ena_mask     (top_wr_mem0_ena),                          //connect to MUX
    .i_rd_addr         (top_rd_mem0_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem0_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_0),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_0)                           //connect to MUX           
    );


//MEM1: 8 banks
mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_64),
    .NUM_BANKS (8),
    .LATENCY   (MEM_LATENCY)) 
mem_1 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_wr_mem1_addr),          //connect to MUX
    .i_wr_data_all     (top_wr_data_mem1),                         //connect to MUX
    .i_wr_ena_mask     (top_wr_mem1_ena),          //connect to MUX
    .i_rd_addr         (top_rd_mem1_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem1_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_1),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_1)                           //connect to MUX           
    );

/////////////////////////////////////////////////////////////////////////////////
//MEM2: 8 banks

write_16_to_64 u_write_16_to_64 (
        .i_clk           (i_clk),
        .i_rst_n         (i_rst_n),
        
        // Input t? Stega
        .i_stega_wr_addr (top_wr_stega_addr),
        .i_stega_wr_data (top_wr_computed_data[47:0]),
        .i_stega_wr_en   (top_wr_stega_ena),
        
        // Output (ð? g?p thành 64-bit)
        .o_gen_wr_addr   (top_stega_64_addr),
        .o_gen_wr_data   (top_stega_64_data),
        .o_gen_wr_en     (top_stega_64_ena)
    );

    // 2. Instance b? MUX ð? ch?n ngu?n d? li?u ghi vào RAM
    mem_interface_mux  u_mem_interface_mux (
        .i_sel             ((top_stage == TAIL)? 1 :0),
        
        .i_wr_stega_ena    (top_stega_64_ena), 
        .i_wr_stega_addr   (top_stega_64_addr),
        .i_wr_stega_data   (top_stega_64_data),
        
        // Nhánh Memory chính
        .i_wr_mem_ena      (top_wr_mem2_ena),
        .i_wr_mem_addr     (top_wr_mem2_addr),
        .i_wr_mem_data     (top_wr_data_mem2),
        
        // Output cu?i cùng
        .o_wr_mem_mux_data (top_mem_inf_mux_data),
        .o_wr_mem_mux_addr (top_mem_inf_mux_addr),
        .o_wr_mem_mux_ena  (top_mem_inf_mux_ena)
    );


mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_64),
    .NUM_BANKS (8),
    .LATENCY   (MEM_LATENCY))
mem_2 (
    .i_clk             (i_clk),
    .i_wr_addr         (top_mem_inf_mux_addr),          //connect to MUX
    .i_wr_data_all     (top_mem_inf_mux_data),                          //connect to MUX
    .i_wr_ena_mask     (top_mem_inf_mux_ena),           //connect to MUX
    .i_rd_addr         (top_rd_mem2_addr),                          //connect to MUX
    .i_rd_enb_mask     (top_rd_mem2_enb),                          //connect to MUX
    .o_data_all        (top_data_mem_2),                          //connect to MUX
    .o_data_vld_all    (top_vld_mem_2)                           //connect to MUX           
    );

/////////////////////////////////////////////////////////////////////////////////
//MEM3: 8 banks
mem_banks_inst #(
    .ADDR_W    (ADDR_IMG),
    .DATA_W    (DATA_64),
    .NUM_BANKS (8),
    .LATENCY   (MEM_LATENCY)) 
mem_3 (
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
    .DATA_W    (DATA_64),
    .NUM_BANKS (8),
    .LATENCY   (MEM_LATENCY)) 
mem_4 (
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
    .DATA_W    (DATA_64),
    .NUM_BANKS (8),
    .LATENCY   (MEM_LATENCY)) 
mem_5 (
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
data_select0 
u_data_select0 (
    .i_clk             (i_clk),
    .i_rst_n           (i_rst_n),
    .i_mem_img_data    (top_data_img[95:0]),
    .i_mem_0_data      (top_data_mem_0),
    .i_mem_1_data      (top_data_mem_1),
    .i_mem_2_data      (top_data_mem_2),
    .i_mem_3_data      (top_data_mem_3),
    .i_mem_4_data      (top_data_mem_4),
    .i_mem_5_data      (top_data_mem_5),
    
    .i_mem_img_vld     (|top_vld_img),
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
data_select1 
u_data_select1 (
    .i_clk             (i_clk),
    .i_rst_n           (i_rst_n),
    .i_mem_img_data    (top_data_img[95:0]),
    .i_mem_0_data      (top_data_mem_0),
    .i_mem_1_data      (top_data_mem_1),
    .i_mem_2_data      (top_data_mem_2),
    .i_mem_3_data      (top_data_mem_3),
    .i_mem_4_data      (top_data_mem_4),
    .i_mem_5_data      (top_data_mem_5),
    
    .i_mem_img_vld     (|top_vld_img),
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
rd_fsm_control  
    # (.LATENCY (MEM_LATENCY + 1),
       .ADDRESS_DATA (ADDR_IMG_R)
    )
u_rd_fsm_control
    (
    .i_clk                  (i_clk),
    .i_enable               ((!s_axis_tready0 && !s_axis_tready1)),
    .i_rst                  (i_rst_n),           // Lýu ?: ki?m tra i_rst là 1 hay 0 (thý?ng rd_fsm dùng tích c?c cao)
    .i_stage_done           (top_stage_done || top_adder_done), //(top_stage_done && !(top_point_computed_vld0 | top_point_computed_vld1))
    .i_n_mem_valid          (top_ds1_valid || top_ds0_valid),
    .i_ld_wb_done           (wb_ld_done),     // K?t n?i ngý?c t? Weight Control v? FSM
    
    .o_mode                 (top_mode),
    .o_last_loop            (top_last_loop),
    .o_ld_wb_enable         (wb_ld_enable),  // Kích ho?t n?p Weight/Bias
    .o_stage                (top_stage),         // T?ng hi?n t?i
    .o_last4stage           (top_last4stage),
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
    .o_done                 (top_done),
    .o_disable_t            (top_disable_t),
    .o_no_relu              (top_no_relu)
    );


weight_bias_control #(
    .ADDRESS_WEIGHT         (ADDR_IMG_R),
    .ADDRESS_BIAS           (ADDR_BIAS),
    .LATENCY                (WEIGHT_MEM_LATENCY)) 
u_weight_bias_control (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n && !top_disable_t),       
    .i_ld_wb_enable         (wb_ld_enable),  
    .i_stage                (top_stage),         
    .i_last_loop            (top_last4stage),     
    .i_mode                 (top_mode),          
    
    // Memory Interface (K?t n?i t?i BRAM ch?a Weight/Bias)
    .o_dweight_rd_addr      (top_rd_addr_depth[7:0]),
    .o_dweight_ena          (top_rd_enb_depth),
    .o_pweight_rd_addr      (top_rd_addr_point[9:0]),
    .o_pweight_ena          (top_rd_enb_point),
    .o_bias_rd_addr         (top_rd_addr_bias),
    .o_bias_ena             (top_rd_enb_bias),

    // Mux Select (K?t n?i t?i kh?i tính toán / Datapath)
    .o_depth_select            (top_depth_sel),
    .o_point_select            (top_point_sel),
    .o_bias_select             (top_bias_sel),
    
    // Status Output
    .o_load_done            (wb_ld_done)      // Báo v? FSM khi n?p xong
    );




fsm_line_buffer #(
    .DATA_IN_W (256),
    .KERNEL_W  (2304)) 
u_fsm_line_buffer0 (
    .i_clk                 (i_clk),
    .i_rst_n               (internal_rst_n),
    .i_enable              (((!s_axis_tready0 && !s_axis_tready1)) && !top_disable_t),
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
    .KERNEL_W  (2304)) 
u_fsm_line_buffer1 (
    .i_clk                 (i_clk),
    .i_rst_n               (internal_rst_n),
    .i_enable              ((!s_axis_tready0 && !s_axis_tready1) && !top_disable_t && (top_mode == 1)),
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
wr_fsm_control #(
    .DATA_COMPUTED_W (512),
    .ADDR_URAM_W     (12),
    .ADDR_STEGA_W    (14)) 
u_wr_ctrl (
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

mux_mode 
u_mux_mode(
    .i_clk (i_clk),
    .i_rst_n (i_rst_n),
    .i_mode (top_mode),
    .i_depth_vld_0 (top_depth_computed_vld0),
    .i_depth_vld_1 (top_depth_computed_vld1),
    .i_depth_data_0 (top_depth_computed0),
    .i_depth_data_1 (top_depth_computed1),
    .o_pw0_data (top_depth_computed0_dl),
    .o_pw0_vld (top_depth_computed_vld0_dl) ,        
    .o_pw1_data (top_depth_computed1_dl),
    .o_pw1_vld (top_depth_computed_vld1_dl)    
    );

pw_top #(
    .DATA_WIDTH(16),
    .IN_CHANNELS(16),
    .OUT_CHANNELS(16)) 
u_pw_unit (
    .clk                (i_clk),
    .rst_n              (i_rst_n),
    
    // C?p phát Weight & Bias (Duy n?p t? ROM ho?c Controller)
    .i_weight_valid0    (top_vld_point && (top_point_sel == 0)), 
    .i_weight_valid1    (top_vld_point && (top_point_sel == 1)),
    .i_data_weight_pw   (top_data_point),
    .i_bias_valid0      (top_vld_bias && (top_bias_sel == 0)),
    .i_bias_valid1      (top_vld_bias && (top_bias_sel == 1)),
    .i_bias_pw          (top_data_bias),
    .i_rst_stage        (top_rst_pw_cmp),

    // Data Feature & Control
    .i_feature_valid    (top_depth_computed_vld0_dl || top_depth_computed_vld1_dl),          //mux
    .i_mode             (top_mode),          
    .i_is_first         (top_first_loop),
    .i_is_last          (top_last_loop),
    .i_fifo_mode        (top_config_max_line_out),         //rd_fsm_control must add
    .i_data_feature     ({top_depth_computed1_dl,top_depth_computed0_dl}),
    .i_no_relu          (top_no_relu),
    // Outputs (K?t n?i th?ng xu?ng kh?i ghi ho?c kh?i ti?p theo)
    .o_data_pw0         (top_point_computed0),
    .o_valid_pw0        (top_point_computed_vld0),
    .o_data_pw1         (top_point_computed1),
    .o_valid_pw1        (top_point_computed_vld1),
    .o_stage_done       (top_stage_done)
);
    
wr_data_select #(
    .BANK4_W(256),   
    .BANK8_W(512),   
    .BANK16_W(1024), 
    .ADDER_W(48)) 
u_data_sel (
    .i_rst_n            (i_rst_n),
    .i_stage            (top_stage),        
    .i_computed_data    (top_wr_computed_data),       // Data 512-bit t? wr_fsm_control (ð? delay)
//    .i_adder_data       (top_wr_computed_adder),                 //addertree
    
    // K?t n?i ð?n các bus d? li?u t?ng c?a t?ng c?m Mem
    .o_wr_data_mem0     (top_wr_data_mem0),
    .o_wr_data_mem1     (top_wr_data_mem1),
    .o_wr_data_mem2     (top_wr_data_mem2),
    .o_wr_data_mem3     (top_wr_data_mem3),
    .o_wr_data_mem4     (top_wr_data_mem4),
    .o_wr_data_mem5     (top_wr_data_mem5)
//    .o_wr_data_mem_stega(top_wr_data_mem_stega)
    );  
    
//mem2_to_adder 
//u_mem2_to_adder (
//    .i_vld (top_vld_mem_2[3:0]),
//    .i_data (top_data_mem_2[1:0]),
//    .o_data (top_adder_residual)
//    );
    
adder_tree #(
    .WIDTH(64),
    .NUM_CH(3)) 
u_adder_stega (
    .i_clk              (i_clk),
    .i_rst_n            (i_rst_n),
    .i_rst_adder_done   (top_rst_pw_cmp),
    .i_vld      ((|top_vld_mem_2) && (|top_vld_img) && (top_disable_t)), // L?y valid t? Pointwise ra
    .i_data_a   (top_data_img[191:0]), 
    .i_data_b   (top_data_mem_2[191:0]),    
    .o_sum      (top_computed_adder), // N?i vào i_adder_data c?a wr_data_select
    .o_vld      (top_vld_adder),
    .o_adder_done (top_adder_done),
    .m_axis_tready (m_axis_tready),
    .m_axis_tlast (top_axis_tlast)


    );
    
    post_process PP(
    .i_clk (i_clk),
    .i_rst_n(i_rst_n),
    .i_valid(top_vld_adder),
    .i_data(top_computed_adder),         // {B[47:32], G[31:16], R[15:0]} Q6.10
    .i_tlast (top_axis_tlast),         // TÃ­n hiá»‡u last cá»§a AXI4-Stream
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tdata (m_axis_tdata),   // {X[31:24], B[23:16], G[15:8], R[7:0]}
    .m_axis_tlast (m_axis_tlast)
);
    


endmodule

module mux_mode (
    input i_clk,
    input i_rst_n,
    input i_mode,
    input i_depth_vld_0,
    input i_depth_vld_1,
    input [255:0] i_depth_data_0,
    input [255:0] i_depth_data_1,
    output reg [255:0] o_pw0_data,
    output reg  o_pw0_vld,
    output reg [255:0] o_pw1_data,
    output reg  o_pw1_vld
);
    always @(posedge i_clk) begin
        if (!i_mode) begin
            o_pw1_data <= i_depth_data_0;
            o_pw1_vld <=i_depth_vld_0;
        end
        else begin
            o_pw1_data <= i_depth_data_1;
            o_pw1_vld  <= i_depth_vld_1;
        end
    end
    
    always @(posedge i_clk) begin
        o_pw0_data <= i_depth_data_0;
        o_pw0_vld  <= i_depth_vld_0;
    end
endmodule
