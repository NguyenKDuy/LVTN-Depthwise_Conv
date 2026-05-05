`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 11:28:49 PM
// Design Name: 
// Module Name: fsm_control
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


module rd_fsm_control(
    i_clk
    ,i_enable
    ,i_rst
    ,i_stage_done
    ,i_n_mem_valid 
    ,i_ld_wb_done
    
    ,o_mode
    ,o_config_dep_para
    ,o_config_point_para
    ,o_config_stride 
    ,o_config_max_line_in
    ,o_config_max_line_out
    ,o_mem_rd_addr
    ,o_mem_rd_enb
    ,o_padding_vld
    ,o_last_loop
    ,o_first_loop
    ,o_last4stage
    ,o_lic_counter
    ,o_row_counter
    ,o_col_counter
    ,o_mem_rd_swapping
    ,o_rst_pw_cmp
    ,o_ld_wb_enable
    ,o_stage
    ,o_done
    ,o_disable_t
    ,o_no_relu
    );
/////////////////////////////////////////////////////////////////
// PARAMETERs
parameter ADDRESS_DATA = 14;
parameter LATENCY = 3;
/////////////////////////////////////////////////////////////////
// PORT DECLARATION:
input   i_clk;
input   i_enable;
input   i_rst;
input   i_stage_done;   
input   i_n_mem_valid;
input   i_ld_wb_done;

output reg   o_mode                 ;
output reg [4:0]  o_config_dep_para      ;
output reg [4:0]  o_config_point_para    ;
output reg [1:0]  o_config_stride        ;
//output reg [2:0]  o_config_padding       ;
output reg [7:0]  o_config_max_line_in   ;
output reg [7:0]  o_config_max_line_out  ;
output reg [ADDRESS_DATA - 1 : 0] o_mem_rd_addr;
output reg                          o_mem_rd_enb ;
output o_padding_vld;
output o_first_loop;
output o_last_loop;
output o_last4stage;
output reg [7:0] o_row_counter, o_col_counter;
output reg [3:0] o_lic_counter;
output reg [1:0] o_mem_rd_swapping;
output reg o_rst_pw_cmp;
output reg o_ld_wb_enable;
output reg [3:0] o_stage;
output reg o_done;
output reg o_disable_t;
output reg o_no_relu;

//////////////////////////////////////////////////////////////////////
// LOCALPARAM:
// Stage:
localparam IDLE = 'd0;
localparam HEAD = 'd1;
localparam DOWNS1 = 'd2;
localparam DOWNS2 = 'd3;
localparam DOWNS3 = 'd4;
localparam BOTT   = 'd5;
localparam UPS1 = 'd6;
localparam UPS2 = 'd7;
localparam UPS3 = 'd8;
localparam UPS4 = 'd9;
localparam TAIL = 'd10;
localparam DONE = 'd11;
//localparam STREAM_OUT = 'd12;

// Magic number for each layers
localparam HEAD_DEP_SS = 6;
localparam HEAD_POINT_SS = 16;
localparam HEAD_MAX_LI   = 128;
localparam HEAD_MAX_LO   = 128;
localparam HEAD_MODE     = 0;
localparam HEAD_CIL      = 1;
localparam HEAD_COL      = 1;
localparam HEAD_MEM_SEL  = 1;
localparam HEAD_MAX_ADDRESS_T = 16384;
localparam HEAD_MAX_ADDRESS_P = 16384/HEAD_MEM_SEL; //Chap nhan magic number


localparam D1_DEP_SS = 16;
localparam D1_POINT_SS = 16;
localparam D1_MAX_LI   = 128;
localparam D1_MAX_LO   = 64;
localparam D1_MODE     = 0;
localparam D1_CIL      = 1;
localparam D1_COL      = 1;
localparam D1_MEM_SEL  = 4;
localparam D1_MAX_ADDRESS_T = 16384;
localparam D1_MAX_ADDRESS_P = 16384/D1_MEM_SEL;

localparam D2_DEP_SS = 16;
localparam D2_POINT_SS = 16;
localparam D2_MAX_LI   = 64;
localparam D2_MAX_LO   = 32;
localparam D2_MODE     = 0;
localparam D2_CIL      = 2;
localparam D2_COL      = 2;
localparam D2_MEM_SEL  = 2;
localparam D2_MAX_ADDRESS_T = 4096;
localparam D2_MAX_ADDRESS_P = 4096;

localparam D3_DEP_SS = 16;
localparam D3_POINT_SS = 16;
localparam D3_MAX_LI   = 32;
localparam D3_MAX_LO   = 16;
localparam D3_MODE     = 0;
localparam D3_CIL      = 4;
localparam D3_COL      = 4;
localparam D3_MEM_SEL  = 2;
localparam D3_MAX_ADDRESS_T = 2048;         //da dang xet chi 1 4subbank
localparam D3_MAX_ADDRESS_P = 1024;         //dont care



localparam B_DEP_SS = 16;
localparam B_POINT_SS = 16;
localparam B_MAX_LI   = 16;
localparam B_MAX_LO   = 8;
localparam B_MODE     = 0;
localparam B_CIL      = 8;
localparam B_COL      = 4;
localparam B_MEM_SEL  = 2;
localparam B_MAX_ADDRESS_T = 2048;
localparam B_MAX_ADDRESS_P = 2048/8;

localparam U1_DEP_SS = 16;
localparam U1_POINT_SS = 16;
localparam U1_MAX_LI   = 16;
localparam U1_MAX_LO   = 16;
localparam U1_MODE     = 1;
localparam U1_CIL      = 8;
localparam U1_COL      = 4;
localparam U1_MEM_SEL  = 2; //X dont care
localparam U1_MAX_ADDRESS_T = 1024;
localparam U1_MAX_ADDRESS_P = 1024;

localparam U2_DEP_SS = 16;
localparam U2_POINT_SS = 16;
localparam U2_MAX_LI   = 32;
localparam U2_MAX_LO   = 32;
localparam U2_MODE     = 1;
localparam U2_CIL      = 4;
localparam U2_COL      = 2;
localparam U2_MEM_SEL  = 2;  //x DONT CARE 
localparam U2_MAX_ADDRESS_T = 2048;
localparam U2_MAX_ADDRESS_P = 2048; //Nh? hõn s? này nó nh?y case (MEM_SWAP thay v? IN_LAYER)

localparam U3_DEP_SS = 16;
localparam U3_POINT_SS = 16;
localparam U3_MAX_LI   = 64;
localparam U3_MAX_LO   = 64;
localparam U3_MODE     = 1;
localparam U3_CIL      = 2;
localparam U3_COL      = 1;
localparam U3_MEM_SEL  = 2; //X dont care
localparam U3_MAX_ADDRESS_T = 4096;
localparam U3_MAX_ADDRESS_P = 4096;

localparam U4_DEP_SS = 16;
localparam U4_POINT_SS = 16;
localparam U4_MAX_LI   = 128;
localparam U4_MAX_LO   = 128;
localparam U4_MODE     = 1;
localparam U4_CIL      = 1;
localparam U4_COL      = 1;
localparam U4_MEM_SEL  = 4;
localparam U4_MAX_ADDRESS_T = 16384;
localparam U4_MAX_ADDRESS_P = 16384/U4_MEM_SEL;

localparam T_DEP_SS = 16;
localparam T_POINT_SS = 3;
localparam T_MAX_LI   = 128;
localparam T_MAX_LO   = 128;
localparam T_MODE     = 0;
localparam T_CIL      = 1;
localparam T_COL      = 1;
localparam T_MEM_SEL  = 4;
localparam T_MAX_ADDRESS_T = 16384;
localparam T_MAX_ADDRESS_P = 16384/T_MEM_SEL;

localparam D_DEP_SS   = 0;
localparam D_POINT_SS = 0;
localparam D_MAX_LI   = 128;
localparam D_MAX_LO   = 128;
localparam D_MODE     = 0;
localparam D_CIL      = 1;
localparam D_COL      = 1;
localparam D_MEM_SEL  = 4;
localparam D_MAX_ADDRESS_T = 16384;
localparam D_MAX_ADDRESS_P = 16384/D_MEM_SEL;

//localparam SO_DEP_SS   = 0;
//localparam SO_POINT_SS = 0;
//localparam SO_MAX_LI   = 64;
//localparam SO_MAX_LO   = 64;
//localparam SO_MODE     = 0;
//localparam SO_CIL      = 3;
//localparam SO_COL      = 1;
//localparam SO_MEM_SEL  = 3;
//localparam SO_MAX_ADDRESS_T = 4096;
//localparam SO_MAX_ADDRESS_P = 4096;





reg [3:0]   mem_sel       ;
reg [ADDRESS_DATA - 1: 0]   max_address_p ;


reg [3:0] loc_counter, max_lic, max_loc; 

(* fsm_encoding = "one_hot" *) 
localparam ADDR_STAGE_COUNT = 11;
reg [ADDR_STAGE_COUNT - 1:0] addr_stage;
localparam INIT = 'd0;
localparam LOAD_WEIGHT = 'd2;
localparam L_PADDING = 'd4;
localparam PRE_PADDING  = 'd8;
localparam POST_PADDING = 'd16;
localparam NONE_PADDING = 'd32;
localparam IN_LAYER = 'd64;
localparam NEXT_STAGE = 'd128;
localparam MEM_SWAP = 'd256;
localparam TRANS_M_C = 'd512;
localparam STABLE_STAGE = 'd1024;


wire loc_done = (loc_counter == max_loc - 1) ? 1: 0;
wire lic_done = (o_lic_counter == max_lic - 1) ? 1: 0;
assign o_last_loop = lic_done;      // ban dau la loc_done && lic_done
assign o_first_loop = (o_lic_counter == 0); // ban dau la them ca loc_counter == 0
assign o_last4stage = lic_done && loc_done;
integer f;
reg padding_vld;
reg [LATENCY-1:0] padding_pipes;

always @(posedge i_clk) begin
    padding_pipes[0] <= padding_vld;
    for (f=1; f<LATENCY; f=f+1) begin
        padding_pipes[f] <= padding_pipes[f-1];
    end
end
assign o_padding_vld = padding_pipes[LATENCY-1];

reg from_post;

always @(posedge i_clk) begin
    if (!i_rst) begin
        o_mem_rd_addr <= 0;
        o_mem_rd_enb <= 0;
//        o_data_vld <= 0;
        addr_stage <= INIT;
        o_stage <= IDLE;
        padding_vld <= 0;
        o_col_counter <= 0;
        o_row_counter <= 0;
        o_lic_counter <= 0; 
        loc_counter <= 0;
        o_mem_rd_swapping <= 0;
        from_post <= 0;
        o_ld_wb_enable <= 0;
        o_rst_pw_cmp <=0;
        o_done <= 0;
    end        
    else begin
            case (addr_stage) 
                INIT: begin
                    o_rst_pw_cmp <= 1'b0; // Use for Itr when finish
                    o_done <= 0;
                    if (i_enable && !o_done) begin
                        addr_stage <= LOAD_WEIGHT;
                        o_stage <= HEAD;
                        //for next stage:
                        o_ld_wb_enable <= 1'b1;
                    end
                end
                LOAD_WEIGHT: begin           
                    o_rst_pw_cmp <= 1'b0;
                    if (i_ld_wb_done) begin
                        addr_stage      <= L_PADDING;
                        //for current stage
                        o_ld_wb_enable  <= 1'b0;
                        //for next stage
                        padding_vld   <= 1'b1;
                    end
                end 
                
                L_PADDING: begin
                    o_rst_pw_cmp <= 1'b0;
                    addr_stage <= L_PADDING;
                    //for this stage:
                    o_col_counter <= o_col_counter + 1;
                    //for next stage:
                    padding_vld   <= 1;
                    o_mem_rd_enb    <= 'd0; 
                    if (o_col_counter == o_config_max_line_in + 1) begin
                        o_col_counter <= 0;
                        addr_stage <=  PRE_PADDING;
//                        o_row_counter <= o_row_counter + 1;
                        if (o_row_counter == o_config_max_line_in) begin
                            o_row_counter <= 0;
                            addr_stage <= TRANS_M_C;
                            padding_vld   <= 0;
                        end
                    end
                end
                PRE_PADDING: begin
                    //for next stage:
                    o_rst_pw_cmp <= 1'b0;
                    padding_vld <= 0;
                    o_mem_rd_enb    <= 'd1; 
//                    o_col_counter <= o_col_counter + 1;
                    addr_stage <= NONE_PADDING;
                end
                NONE_PADDING: begin
                    o_rst_pw_cmp <= 1'b0;
                    padding_vld <= 'd0;
                    o_mem_rd_enb <= 'd1 ;
                    o_mem_rd_addr <= o_mem_rd_addr + 1;
                    o_col_counter <= o_col_counter + 1;
                    if (o_col_counter == o_config_max_line_in - 1) begin
                        addr_stage <= POST_PADDING;
                        o_mem_rd_enb <= 'd0;
                        padding_vld <= 'd1;
                    end
                end 
                POST_PADDING: begin
                    o_mem_rd_enb    <= 1'b0;
                    //for next stage:
                    padding_vld   <= 1'b1;
                    o_col_counter   <= 0;
                    o_row_counter   <= o_row_counter + 1;
                    addr_stage      <= PRE_PADDING;
                    //in case: last line
                    if (o_row_counter == o_config_max_line_in - 1) begin
                        addr_stage  <= L_PADDING;
//                        o_row_counter <= 0;
                    end
                    //in case: change mem to continue to read - DOWNS1, UPS4, TAIL, DONE, STREAMOUT
                    //at this stage: rd_addr for mem still keep
                    else if (o_mem_rd_addr == max_address_p) begin
                        addr_stage <= TRANS_M_C;
//                        o_mem_rd_addr <= 0;
                        from_post   <= 1;
                        padding_vld <= 1'b0;
                    end
                end
                
                TRANS_M_C: begin
                    // for work HEAD                 
                    // for work D1_3       
                    // work for D2_1_1_1    
                    if (o_mem_rd_swapping == mem_sel - 1 && lic_done && loc_done  && !o_padding_vld) begin
                        addr_stage <= IN_LAYER;
                    end
                    
                    //work for, D1_0, D1_1, D1_2
                    //work for (stage_memswap_lic_loc) D2_0_0_0, D2_1_1_0, D2_0_0_1
                    //work for (stage_memswap_lic_loc) D3_0_0_0, D3_1_1_0, D3_0_1_0, D3_1_1_0

                    else if (!i_n_mem_valid) begin
                        addr_stage <= MEM_SWAP;
                    end
                end
                
                MEM_SWAP: begin
                    addr_stage <= IN_LAYER;
                    if (from_post) begin
                        o_mem_rd_swapping <= o_mem_rd_swapping + 1;
                        o_mem_rd_addr <= o_mem_rd_addr - max_address_p; 
                        padding_vld <= 1; 
                        // Cannot happen because it will move to IN_LAYER from TRANS
                        addr_stage <= PRE_PADDING;
                        from_post <= 0;
                    end
                    else begin
                        case (o_mode)
                        0: begin
                            o_mem_rd_swapping <= o_mem_rd_swapping + 1;
                            o_mem_rd_addr <= o_mem_rd_addr - max_address_p;  
                            if (o_mem_rd_swapping == mem_sel - 1) begin
                                o_mem_rd_addr <= o_mem_rd_addr; 
                                o_mem_rd_swapping <= 0;
                            end 
                        end
                        1: begin
                            if (o_lic_counter == max_lic/2-1) begin
                                o_mem_rd_swapping <= o_mem_rd_swapping + 1;
                                o_mem_rd_addr <= o_mem_rd_addr - max_address_p;
                                if (o_mem_rd_swapping == mem_sel - 1) begin
                                    o_mem_rd_addr <= o_mem_rd_addr; 
                                    o_mem_rd_swapping <= 0;
                                end
                            end 
                        end
                        endcase 
                    end
                end 
                IN_LAYER: begin
                    //tin hieu i_pw_done o ngoai to nhat
                    if (i_stage_done) begin
                        o_lic_counter <= o_lic_counter + 1;
                        //for next stage:
                        addr_stage <= LOAD_WEIGHT;
                        o_ld_wb_enable <= 1'b1;
                        o_rst_pw_cmp <= 1'b1;   //Aim to reset pointwise counter (compare)
                        
                        if (o_stage >= 10) begin
                            o_ld_wb_enable <= 1'b0;
                            addr_stage <= NONE_PADDING; 
                            o_mem_rd_enb   <= 1'b1;
                        end
                        
                        if (lic_done && loc_done) begin
                            o_lic_counter <= 0;
                            loc_counter <= 0;
                            o_ld_wb_enable <= 1'b0;
                            addr_stage <= NEXT_STAGE;
                            o_mem_rd_swapping <= 0;
                            o_mem_rd_addr <= 0;
                        end
                        else if (lic_done) begin : skip_load_weight_if_llayer
                            o_lic_counter <= 0;
                            loc_counter <= loc_counter + 1;
                            o_mem_rd_addr <= 0;
                            o_mem_rd_swapping <= 0;
                        end 
                        
                    end
                end
                NEXT_STAGE: begin
                    addr_stage <= LOAD_WEIGHT;
                    o_stage <= o_stage + 1;
                    o_lic_counter <= 0;
                    loc_counter <= 0;
                    o_ld_wb_enable <= 1;
                    o_mem_rd_addr <= 0;
                    o_mem_rd_enb <= 0;
                    if (o_stage == DONE) begin
                        addr_stage <= INIT;
                        o_stage <= IDLE;
                        o_done <= 1;
                        o_ld_wb_enable <=0;
                        o_mem_rd_enb <= 0;
                    end
                    else if (o_stage >= 10) begin : above_TAIL_no_weight
                        o_mem_rd_enb   <= 1'b1;
                        addr_stage <= NONE_PADDING;   
                        o_ld_wb_enable <= 0;      
                    end
                end
                default: begin end
            endcase
        end
    end

 

 
always @(posedge i_clk) begin
    if (!i_rst) begin
        // --- Reset Values (Tr?ng thái an toàn khi kh?i ð?ng) ---
        o_config_stride       <= 1;
        o_config_dep_para      <= 0;
        o_config_point_para    <= 0;
        o_mode                 <= 0;
        o_config_max_line_in   <= 0;
        o_config_max_line_out  <= 0;
        max_lic                <= 0;
        max_loc                <= 0;
        mem_sel                <= 1;
        max_address_p          <= 0;
        o_disable_t            <= 0;
        o_no_relu              <= 0;
    end else begin
        // --- M?c ð?nh cho m?i chu k? clock ---
        // (N?u không rõi vào case nào, gi? giá tr? m?c ð?nh ð? tránh gi? d? li?u c?)
        o_config_stride       <= 1;
        o_config_dep_para      <= 0;
        o_config_point_para    <= 0;
        o_mode                 <= 0;
        o_config_max_line_in   <= 0;
        o_config_max_line_out  <= 0;
        max_lic                <= 0;
        max_loc                <= 0;
        mem_sel                <= 1;
        max_address_p          <= 0;
        o_disable_t            <= 0;
        o_no_relu              <= 0;

        case (o_stage)
            HEAD: begin
                o_config_stride       <= 1;
                o_config_dep_para      <= HEAD_DEP_SS;
                o_config_point_para    <= HEAD_POINT_SS;
                o_mode                 <= HEAD_MODE;
                o_config_max_line_in   <= HEAD_MAX_LI;
                o_config_max_line_out  <= HEAD_MAX_LO;
                max_lic                <= HEAD_CIL;
                max_loc                <= HEAD_COL;
                mem_sel                <= HEAD_MEM_SEL;
                max_address_p          <= HEAD_MAX_ADDRESS_P;
            end

            DOWNS1: begin
                o_config_stride       <= 2;
                o_config_dep_para      <= D1_DEP_SS;
                o_config_point_para    <= D1_POINT_SS;
                o_mode                 <= D1_MODE;
                o_config_max_line_in   <= D1_MAX_LI;
                o_config_max_line_out  <= D1_MAX_LO;
                max_lic                <= D1_CIL;
                max_loc                <= D1_COL;
                mem_sel                <= D1_MEM_SEL;
                max_address_p          <= D1_MAX_ADDRESS_P;
            end

            DOWNS2: begin
                o_config_stride       <= 2;
                o_config_dep_para      <= D2_DEP_SS;
                o_config_point_para    <= D2_POINT_SS;
                o_mode                 <= D2_MODE;
                o_config_max_line_in   <= D2_MAX_LI;
                o_config_max_line_out  <= D2_MAX_LO;
                max_lic                <= D2_CIL;
                max_loc                <= D2_COL;
                mem_sel                <= D2_MEM_SEL;
                max_address_p          <= D2_MAX_ADDRESS_P;
            end

            DOWNS3: begin
                o_config_stride       <= 2;
                o_config_dep_para      <= D3_DEP_SS;
                o_config_point_para    <= D3_POINT_SS;
                o_mode                 <= D3_MODE;
                o_config_max_line_in   <= D3_MAX_LI;
                o_config_max_line_out  <= D3_MAX_LO;
                max_lic                <= D3_CIL;
                max_loc                <= D3_COL;
                mem_sel                <= D3_MEM_SEL;
                max_address_p          <= D3_MAX_ADDRESS_P;
            end

            BOTT: begin
                o_config_stride       <= 2;
                o_config_dep_para      <= B_DEP_SS;
                o_config_point_para    <= B_POINT_SS;
                o_mode                 <= B_MODE;
                o_config_max_line_in   <= B_MAX_LI;
                o_config_max_line_out  <= B_MAX_LO;
                max_lic                <= B_CIL;
                max_loc                <= B_COL;
                mem_sel                <= B_MEM_SEL;
                max_address_p          <= B_MAX_ADDRESS_P;
            end

            UPS1: begin
                o_config_stride       <= 1;
                o_config_dep_para      <= U1_DEP_SS;
                o_config_point_para    <= U1_POINT_SS;
                o_mode                 <= U1_MODE;
                o_config_max_line_in   <= U1_MAX_LI;
                o_config_max_line_out  <= U1_MAX_LO;
                max_lic                <= U1_CIL;
                max_loc                <= U1_COL;
                mem_sel                <= U1_MEM_SEL;
                max_address_p          <= U1_MAX_ADDRESS_P;
            end

            UPS2: begin
                o_config_stride       <= 1;
                o_config_dep_para      <= U2_DEP_SS;
                o_config_point_para    <= U2_POINT_SS;
                o_mode                 <= U2_MODE;
                o_config_max_line_in   <= U2_MAX_LI;
                o_config_max_line_out  <= U2_MAX_LO;
                max_lic                <= U2_CIL;
                max_loc                <= U2_COL;
                mem_sel                <= U2_MEM_SEL;
                max_address_p          <= U2_MAX_ADDRESS_P;
            end

            UPS3: begin
                o_config_stride       <= 1;
                o_config_dep_para      <= U3_DEP_SS;
                o_config_point_para    <= U3_POINT_SS;
                o_mode                 <= U3_MODE;
                o_config_max_line_in   <= U3_MAX_LI;
                o_config_max_line_out  <= U3_MAX_LO;
                max_lic                <= U3_CIL;
                max_loc                <= U3_COL;
                mem_sel                <= U3_MEM_SEL;
                max_address_p          <= U3_MAX_ADDRESS_P;
            end

            UPS4: begin
                o_config_stride       <= 1;
                o_config_dep_para      <= U4_DEP_SS;
                o_config_point_para    <= U4_POINT_SS;
                o_mode                 <= U4_MODE;
                o_config_max_line_in   <= U4_MAX_LI;
                o_config_max_line_out  <= U4_MAX_LO;
                max_lic                <= U4_CIL;
                max_loc                <= U4_COL;
                mem_sel                <= U4_MEM_SEL;
                max_address_p          <= U4_MAX_ADDRESS_P;
            end

            TAIL: begin
                o_config_stride       <= 1;
                o_config_dep_para      <= T_DEP_SS;
                o_config_point_para    <= T_POINT_SS;
                o_mode                 <= T_MODE;
                o_config_max_line_in   <= T_MAX_LI;
                o_config_max_line_out  <= T_MAX_LO;
                max_lic                <= T_CIL;
                max_loc                <= T_COL;
                mem_sel                <= T_MEM_SEL;
                max_address_p          <= T_MAX_ADDRESS_P;
                o_no_relu              <= 1;
            end
            
            DONE: begin
                o_config_stride       <= 1;
                o_config_dep_para      <= D_DEP_SS;
                o_config_point_para    <= D_POINT_SS;
                o_mode                 <= D_MODE;
                o_config_max_line_in   <= D_MAX_LI;
                o_config_max_line_out  <= D_MAX_LO;
                max_lic                <= D_CIL;
                max_loc                <= D_COL;
                mem_sel                <= D_MEM_SEL;
                max_address_p          <= D_MAX_ADDRESS_P;
                o_disable_t            <= 1;
            end
            
//            STREAM_OUT: begin
//                o_config_stride       <= 1;
//                o_config_dep_para      <= SO_DEP_SS;
//                o_config_point_para    <= SO_POINT_SS;
//                o_mode                 <= SO_MODE;
//                o_config_max_line_in   <= SO_MAX_LI;
//                o_config_max_line_out  <= SO_MAX_LO;
//                max_lic                <= SO_CIL;
//                max_loc                <= SO_COL;
//                mem_sel                <= SO_MEM_SEL;
//                max_address_p          <= SO_MAX_ADDRESS_P;
//                o_disable_t            <= 1;
//            end

            default: begin
                o_config_stride        <= 0;
                o_config_dep_para      <= 0;
                o_config_point_para    <= 0;
                o_mode                 <= 0;
                o_config_max_line_in   <= 0;
                o_config_max_line_out  <= 0;
                max_lic                <= 0;
                max_loc                <= 0;
                mem_sel                <= 1;
                max_address_p          <= 0;
                o_disable_t            <= 0;
            end
        endcase
    end
end

endmodule
