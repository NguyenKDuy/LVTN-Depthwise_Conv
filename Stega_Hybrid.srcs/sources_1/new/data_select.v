`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2026 02:00:49 PM
// Design Name: 
// Module Name: data_select
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

//module data_select0 (
//    // --- Image Memory Input ---
//    input  [95:0]        i_mem_img_data,   // 16 channels * 16 bits
//    input                i_mem_img_vld,    //or trý?c khi vào

//    // --- Buffer Memory Inputs (0-5) ---
//    input  [1023:0]      i_mem_0_data,
//    input  [512:0]       i_mem_1_data,
//    input  [512:0]       i_mem_2_data,
//    input  [512:0]       i_mem_3_data,
//    input  [512:0]       i_mem_4_data,
//    input  [512:0]       i_mem_5_data,

//    // --- Valid signals for Buffers ---
//    input                i_mem_0_vld,   //or trý?c khi vào
//    input                i_mem_1_vld,   //or trý?c khi vào
//    input                i_mem_2_vld,   //or trý?c khi vào
//    input                i_mem_3_vld,   //or trý?c khi vào
//    input                i_mem_4_vld,   //or trý?c khi vào
//    input                i_mem_5_vld,   //or trý?c khi vào

//    // --- Control Signals ---
//    input  [2:0]         i_mem_swapping,   // Ði?u khi?n ch?n buffer nào
//    input  [3:0]         i_stage,          // Giai ðo?n hi?n t?i c?a Pipeline
////    input  [4:0]         i_config_dep_para,

//    // --- Outputs ---
//    output reg [255:0]   o_pixel,          // D? li?u pixel ch?n ra (16x16)
//    output reg           o_valid           // Tín hi?u valid týõng ?ng
//);

//localparam HEAD = 1, DOWNS1 = 2, DOWNS2 = 3, DOWNS3 = 4, BOTT = 5,
//           UPS1 = 6, UPS2 = 7, UPS3 = 8, UPS4 = 9, TAIL = 10, 
//           DONE = 11, STREAM_OUT = 12;

//    always @(*) begin
//        o_pixel = 0;
//        o_valid = 0;
//        case (i_stage) 
//            HEAD: begin
//                o_pixel = {160'b0, i_mem_img_data};
//                o_valid = i_mem_img_vld;
//            end 
//            DOWNS1: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_0_data[255:0];
//                        o_valid = i_mem_0_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_0_data[511:256];
//                        o_valid = i_mem_0_vld;
//                    end
//                    2: begin
//                        o_pixel = i_mem_0_data[767:512];
//                        o_valid = i_mem_0_vld;
//                    end
//                    3: begin
//                        o_pixel = i_mem_0_data[1023:768];
//                        o_valid = i_mem_0_vld;
//                    end
                    
                    
//                endcase
//            end
//            DOWNS2: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_1_data[255:0];
//                        o_valid = i_mem_1_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_1_data[511:256];
//                        o_valid = i_mem_1_vld;
//                    end
//                endcase
//            end
//            DOWNS3: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_2_data[255:0];
//                        o_valid = i_mem_2_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_2_data[511:256];
//                        o_valid = i_mem_2_vld;
//                    end
//                endcase
//            end
//            BOTT: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_3_data[255:0];
//                        o_valid = i_mem_3_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_3_data[511:256];
//                        o_valid = i_mem_3_vld;
//                    end
//                endcase
//            end
//            UPS1: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_4_data[255:0];
//                        o_valid = i_mem_4_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_3_data[255:0];
//                        o_valid = i_mem_3_vld;
//                    end
//                endcase
//            end
//            UPS2: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_5_data[255:0];
//                        o_valid = i_mem_5_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_2_data[255:0];
//                        o_valid = i_mem_2_vld;
//                    end
//                endcase
//            end
//            UPS3: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_3_data[255:0];
//                        o_valid = i_mem_3_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_1_data[255:0];
//                        o_valid = i_mem_1_vld;
//                    end
//                endcase
//            end
            
//            UPS4: begin
//                o_pixel = i_mem_2_data[255:0];
//                o_valid = i_mem_2_vld;
//            end
//            TAIL: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_1_data[255:0];
//                        o_valid = i_mem_1_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_1_data[511:256];
//                        o_valid = i_mem_1_vld;
//                    end
//                    2: begin
//                        o_pixel = i_mem_3_data[255:0];
//                        o_valid = i_mem_3_vld;
//                    end
//                    3: begin
//                        o_pixel = i_mem_3_data[511:256];
//                        o_valid = i_mem_3_vld;
//                    end
//                endcase
//            end 
//            default: begin
//                o_pixel = 0;
//                o_valid = 0;
//            end
//        endcase
//    end 
    
//endmodule

`timescale 1ns / 1ps

module data_select0 (
    // --- Image Memory Input ---
    input  [95:0]        i_mem_img_data,
    input                i_mem_img_vld,

    // --- Buffer Memory Inputs (0-5) ---
    input  [1023:0]      i_mem_0_data,
    input  [512:0]       i_mem_1_data,
    input  [512:0]       i_mem_2_data,
    input  [512:0]       i_mem_3_data,
    input  [512:0]       i_mem_4_data,
    input  [512:0]       i_mem_5_data,

    // --- Valid signals for Buffers ---
    input                i_mem_0_vld,
    input                i_mem_1_vld,
    input                i_mem_2_vld,
    input                i_mem_3_vld,
    input                i_mem_4_vld,
    input                i_mem_5_vld,

    // --- Control Signals ---
    input  [1:0]         i_mem_swapping,
    input  [3:0]         i_stage,

    // --- Outputs ---
    output reg [255:0]   o_pixel,
    output reg           o_valid
);

// ?????????????????????????????????????????????
// Stage parameters
// ?????????????????????????????????????????????
localparam HEAD       = 4'd1,
           DOWNS1     = 4'd2,
           DOWNS2     = 4'd3,
           DOWNS3     = 4'd4,
           BOTT       = 4'd5,
           UPS1       = 4'd6,
           UPS2       = 4'd7,
           UPS3       = 4'd8,
           UPS4       = 4'd9,
           TAIL       = 4'd10,
           DONE       = 4'd11,
           STREAM_OUT = 4'd12;

// ?????????????????????????????????????????????
// Pre-decode: i_mem_swapping slices
// Tách s?m ð? synthesis tool th?y ðây là constants
// Tránh fanout l?n trên bus i_mem_X_data
// ?????????????????????????????????????????????
wire [255:0] mem0_slice [0:3];
assign mem0_slice[0] = i_mem_0_data[255:0];
assign mem0_slice[1] = i_mem_0_data[511:256];
assign mem0_slice[2] = i_mem_0_data[767:512];
assign mem0_slice[3] = i_mem_0_data[1023:768];

wire [255:0] mem1_slice [0:1];
assign mem1_slice[0] = i_mem_1_data[255:0];
assign mem1_slice[1] = i_mem_1_data[511:256];

wire [255:0] mem2_slice [0:1];
assign mem2_slice[0] = i_mem_2_data[255:0];
assign mem2_slice[1] = i_mem_2_data[511:256];

wire [255:0] mem3_slice [0:1];
assign mem3_slice[0] = i_mem_3_data[255:0];
assign mem3_slice[1] = i_mem_3_data[511:256];

// ?????????????????????????????????????????????
// Pre-decode stage & swapping ? flat select bits
// Gi?m logic depth: 2 t?ng case ? 1 t?ng mux
// ?????????????????????????????????????????????

// M?i wire là 1 lá c?a mux cu?i cùng
// Naming: sel_<source>_<slice>
wire sel_img       = (i_stage == HEAD);

wire sel_m0_s0     = (i_stage == DOWNS1) && (i_mem_swapping == 3'd0);
wire sel_m0_s1     = (i_stage == DOWNS1) && (i_mem_swapping == 3'd1);
wire sel_m0_s2     = (i_stage == DOWNS1) && (i_mem_swapping == 3'd2);
wire sel_m0_s3     = (i_stage == DOWNS1) && (i_mem_swapping == 3'd3);

wire sel_m1_s0     = (i_stage == DOWNS2 && i_mem_swapping == 3'd0)
                   | (i_stage == UPS3   && i_mem_swapping == 3'd1)
                   | (i_stage == TAIL   && i_mem_swapping == 3'd0);
wire sel_m1_s1     = (i_stage == DOWNS2 && i_mem_swapping == 3'd1)
                   | (i_stage == TAIL   && i_mem_swapping == 3'd1);

wire sel_m2_s0     = (i_stage == DOWNS3 && i_mem_swapping == 3'd0)
                   | (i_stage == UPS2   && i_mem_swapping == 3'd1)
                   | (i_stage == UPS4);
wire sel_m2_s1     = (i_stage == DOWNS3 && i_mem_swapping == 3'd1);

wire sel_m3_s0     = (i_stage == BOTT   && i_mem_swapping == 3'd0)
                   | (i_stage == UPS1   && i_mem_swapping == 3'd1)
                   | (i_stage == UPS3   && i_mem_swapping == 3'd0)
                   | (i_stage == TAIL   && i_mem_swapping == 3'd2);
wire sel_m3_s1     = (i_stage == BOTT   && i_mem_swapping == 3'd1)
                   | (i_stage == TAIL   && i_mem_swapping == 3'd3);

wire sel_m4_s0     = (i_stage == UPS1   && i_mem_swapping == 3'd0);
wire sel_m5_s0     = (i_stage == UPS2   && i_mem_swapping == 3'd0);

// ?????????????????????????????????????????????
// Valid: flat OR c?a các select signal có cùng vld source
// Path ng?n hõn v? không qua pixel mux
// ?????????????????????????????????????????????
wire vld_from_img  = sel_img;
wire vld_from_m0   = sel_m0_s0 | sel_m0_s1 | sel_m0_s2 | sel_m0_s3;
wire vld_from_m1   = sel_m1_s0 | sel_m1_s1;
wire vld_from_m2   = sel_m2_s0 | sel_m2_s1;
wire vld_from_m3   = sel_m3_s0 | sel_m3_s1;
wire vld_from_m4   = sel_m4_s0;
wire vld_from_m5   = sel_m5_s0;

// ?????????????????????????????????????????????
// Output: 1 t?ng mux duy nh?t (ýu tiên encoding)
// Synthesis tool s? minimize thành LUT tree t?i ýu
// ?????????????????????????????????????????????
always @(*) begin
    // --- o_valid: path ðõn gi?n, không ph? thu?c o_pixel ---
    o_valid = (vld_from_img  & i_mem_img_vld)
            | (vld_from_m0   & i_mem_0_vld)
            | (vld_from_m1   & i_mem_1_vld)
            | (vld_from_m2   & i_mem_2_vld)
            | (vld_from_m3   & i_mem_3_vld)
            | (vld_from_m4   & i_mem_4_vld)
            | (vld_from_m5   & i_mem_5_vld);

    // --- o_pixel: 1-hot mux ---
    (* parallel_case *) case (1'b1)
        sel_img    : o_pixel = {160'b0, i_mem_img_data};
        sel_m0_s0  : o_pixel = mem0_slice[0];
        sel_m0_s1  : o_pixel = mem0_slice[1];
        sel_m0_s2  : o_pixel = mem0_slice[2];
        sel_m0_s3  : o_pixel = mem0_slice[3];
        sel_m1_s0  : o_pixel = mem1_slice[0];
        sel_m1_s1  : o_pixel = mem1_slice[1];
        sel_m2_s0  : o_pixel = mem2_slice[0];
        sel_m2_s1  : o_pixel = mem2_slice[1];
        sel_m3_s0  : o_pixel = mem3_slice[0];
        sel_m3_s1  : o_pixel = mem3_slice[1];
        sel_m4_s0  : o_pixel = i_mem_4_data[255:0];
        sel_m5_s0  : o_pixel = i_mem_5_data[255:0];
        default    : o_pixel = 256'b0;
    endcase
end

endmodule

//module data_select1 (
//    // --- Image Memory Input ---
//    input  [95:0]        i_mem_img_data,   // 16 channels * 16 bits
//    input                i_mem_img_vld,    //or trý?c khi vào

//    // --- Buffer Memory Inputs (0-5) ---
//    input  [1023:0]      i_mem_0_data,
//    input  [512:0]       i_mem_1_data,
//    input  [512:0]       i_mem_2_data,
//    input  [512:0]       i_mem_3_data,
//    input  [512:0]       i_mem_4_data,
//    input  [512:0]       i_mem_5_data,

//    // --- Valid signals for Buffers ---
//    input                i_mem_0_vld,   //or trý?c khi vào
//    input                i_mem_1_vld,   //or trý?c khi vào
//    input                i_mem_2_vld,   //or trý?c khi vào
//    input                i_mem_3_vld,   //or trý?c khi vào
//    input                i_mem_4_vld,   //or trý?c khi vào
//    input                i_mem_5_vld,   //or trý?c khi vào

//    // --- Control Signals ---
//    input  [2:0]         i_mem_swapping,   // Ði?u khi?n ch?n buffer nào
//    input  [3:0]         i_stage,          // Giai ðo?n hi?n t?i c?a Pipeline
////    input  [4:0]         i_config_dep_para,

//    // --- Outputs ---
//    output reg [255:0]   o_pixel,          // D? li?u pixel ch?n ra (16x16)
//    output reg           o_valid           // Tín hi?u valid týõng ?ng
//);

//localparam HEAD = 1, DOWNS1 = 2, DOWNS2 = 3, DOWNS3 = 4, BOTT = 5,
//           UPS1 = 6, UPS2 = 7, UPS3 = 8, UPS4 = 9, TAIL = 10, 
//           DONE = 11, STREAM_OUT = 12;

//    always @(*) begin
//        o_pixel = 0;
//        o_valid = 0;
//        case (i_stage) 
//            UPS1: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_4_data[511:256];
//                        o_valid = i_mem_4_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_3_data[511:256];
//                        o_valid = i_mem_3_vld;
//                    end
//                endcase
//            end
//            UPS2: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_5_data[511:256];
//                        o_valid = i_mem_5_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_2_data[511:256];
//                        o_valid = i_mem_2_vld;
//                    end
//                endcase
//            end
//            UPS3: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_3_data[511:256];
//                        o_valid = i_mem_3_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_1_data[511:256];
//                        o_valid = i_mem_1_vld;
//                    end
//                endcase
//            end
            
//            UPS4: begin
//                case (i_mem_swapping)
//                    0: begin
//                        o_pixel = i_mem_0_data[255:0];
//                        o_valid = i_mem_0_vld;
//                    end
//                    1: begin
//                        o_pixel = i_mem_0_data[511:256];
//                        o_valid = i_mem_0_vld;
//                    end
//                    2: begin
//                        o_pixel = i_mem_0_data[255:0];
//                        o_valid = i_mem_0_vld;
//                    end
//                    3: begin
//                        o_pixel = i_mem_0_data[511:256];
//                        o_valid = i_mem_0_vld;
//                    end
//                endcase
//            end
//            default: begin
//                o_pixel = 0;
//                o_valid = 0;
//            end
//        endcase
//    end 
    
//endmodule

`timescale 1ns / 1ps

module data_select1 (
    input  [95:0]        i_mem_img_data,
    input                i_mem_img_vld,
    input  [1023:0]      i_mem_0_data,
    input  [512:0]       i_mem_1_data,
    input  [512:0]       i_mem_2_data,
    input  [512:0]       i_mem_3_data,
    input  [512:0]       i_mem_4_data,
    input  [512:0]       i_mem_5_data,
    input                i_mem_0_vld,
    input                i_mem_1_vld,
    input                i_mem_2_vld,
    input                i_mem_3_vld,
    input                i_mem_4_vld,
    input                i_mem_5_vld,
    input  [1:0]         i_mem_swapping,
    input  [3:0]         i_stage,
    output reg [255:0]   o_pixel,
    output reg           o_valid
);

localparam HEAD = 1, DOWNS1 = 2, DOWNS2 = 3, DOWNS3 = 4, BOTT = 5,
           UPS1 = 6, UPS2 = 7, UPS3 = 8, UPS4 = 9, TAIL = 10,
           DONE = 11, STREAM_OUT = 12;

// ?? Pre-slice: gi?m fanout trên bus r?ng ??????????????????
wire [255:0] mem0_lo = i_mem_0_data[255:0];
wire [255:0] mem0_hi = i_mem_0_data[511:256];
wire [255:0] mem1_hi = i_mem_1_data[511:256];
wire [255:0] mem2_hi = i_mem_2_data[511:256];
wire [255:0] mem3_hi = i_mem_3_data[511:256];
wire [255:0] mem4_hi = i_mem_4_data[511:256];
wire [255:0] mem5_hi = i_mem_5_data[511:256];

wire swap0 = (i_mem_swapping == 3'd0);  // decode 1 l?n, dùng l?i nhi?u ch?

// ?? o_valid ???????????????????????????????????????????????
always @(*) begin
    (* full_case, parallel_case *)
    case (i_stage)
        UPS1:    o_valid = swap0 ? i_mem_4_vld : i_mem_3_vld;
        UPS2:    o_valid = swap0 ? i_mem_5_vld : i_mem_2_vld;
        UPS3:    o_valid = swap0 ? i_mem_3_vld : i_mem_1_vld;
        UPS4:    o_valid = i_mem_0_vld;
        default: o_valid = 1'b0;
    endcase
end

// ?? o_pixel ???????????????????????????????????????????????
always @(*) begin
    (* full_case, parallel_case *)
    case (i_stage)
        UPS1:    o_pixel = swap0 ? mem4_hi : mem3_hi;
        UPS2:    o_pixel = swap0 ? mem5_hi : mem2_hi;
        UPS3:    o_pixel = swap0 ? mem3_hi : mem1_hi;
        UPS4:    o_pixel = i_mem_swapping[0] ? mem0_hi : mem0_lo;  // ch? bit[0] có ngh?a
        default: o_pixel = 256'b0;
    endcase
end

endmodule