`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Nguyen Khac Duy
// 
// Create Date: 02/13/2026 09:15:53 PM
// Design Name: 
// Module Name: data_controller
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


module data_controller(
    i_clk,
    i_rst_n,
    i_enable,
    i_pwdone,
    i_data,
    i_dready,
    o_stage,
    o_r_address,
    o_r_enable,
    o_data,
    o_valid,
    tile_z
);
parameter ADDRESS = 17;
    input i_clk;
    input i_rst_n;
    input i_enable;
    input i_pwdone; //
    input [63:0] i_data;    
    input i_dready;
    output reg [3:0] o_stage; //
    output reg [ADDRESS - 1:0] o_r_address;
    output reg o_r_enable;
    output [17*16*2 - 1: 0] o_data;
    output reg o_valid;
    output [8:0] tile_z;

///////////////////////////////////////////////////////////////////
// FSM:    
localparam IDLE = 'd0;
localparam HEAD = 'd1;
localparam DOWNS1 = 'd2;
localparam DOWNS2 = 'd3;
localparam BOTT   = 'd4;
localparam UPS1 = 'd5;
localparam UPS2 = 'd6;
localparam UPS3 = 'd7;
localparam TAIL = 'd8;
localparam TANH = 'd9;

///////////////////////////////////////////////////////////////////
// TILE_SIZE:       
localparam HEAD_TILE_X = 'd16;
localparam HEAD_TILE_Y = 'd16/2;
localparam HEAD_TILE_Z = 'd6;

localparam DOWNS1_TILE_X = 'd8;
localparam DOWNS1_TILE_Y = 'd8/2;
localparam DOWNS1_TILE_Z = 'd32;

localparam DOWNS2_TILE_X = 'd4;
localparam DOWNS2_TILE_Y = 'd4/2;
localparam DOWNS2_TILE_Z = 'd64;


localparam BOTT_TILE_X = 'd2;
localparam BOTT_TILE_Y = 'd2/2;
localparam BOTT_TILE_Z = 'd128;

localparam UPS1_TILE_X = 'd4;
localparam UPS1_TILE_Y = 'd4/2;
localparam UPS1_TILE_Z = 'd384;

localparam UPS2_TILE_X = 'd8;
localparam UPS2_TILE_Y = 'd8/2;
localparam UPS2_TILE_Z = 'd192;

localparam UPS3_TILE_X = 'd16;
localparam UPS3_TILE_Y = 'd16/2;
localparam UPS3_TILE_Z = 'd96;

localparam TAIL_TILE_X = 'd16;
localparam TAIL_TILE_Y = 'd16/2;
localparam TAIL_TILE_Z = 'd32;

///////////////////////////////////////////////////////////////////
// Base address of depthwise:
localparam HEAD_WIDTH = 'd128 /4; //keep
localparam DOWNS1_WIDTH = 'd128 / 'd8; //divide to 2
localparam DOWNS2_WIDTH = 'd32 / 'd2; //not divide by tile but by block of 64-bit
localparam BOTT_WIDTH = 'd32 / 'd4;
localparam UPS1_WIDTH = 'd32 / 'd8;
localparam UPS2_WIDTH = 'd64 / 'd8;
localparam UPS3_WIDTH = 'd64 / 'd8;
localparam TAIL_WIDTH = 'd128 / 'd8;

localparam HEAD_LADDR = HEAD_WIDTH ; //line address for each line buffer
localparam DOWNS1_LADDR = DOWNS1_WIDTH;
localparam DOWNS2_LADDR = DOWNS2_WIDTH / 2;
localparam BOTT_LADDR = BOTT_WIDTH / 2;
localparam UPS1_LADDR = UPS1_WIDTH;
localparam UPS2_LADDR = UPS2_WIDTH;
localparam UPS3_LADDR = UPS3_WIDTH;
localparam TAIL_LADDR = TAIL_WIDTH;

localparam HEAD_QXADDR = HEAD_WIDTH / 2; //line address for each line buffer
localparam DOWNS1_QXADDR = DOWNS1_WIDTH / 2;
localparam DOWNS2_QXADDR = DOWNS2_WIDTH / 2;
localparam BOTT_QXADDR = BOTT_WIDTH / 2 ;
localparam UPS1_QXADDR = UPS1_WIDTH / 2;
localparam UPS2_QXADDR = UPS2_WIDTH / 2;
localparam UPS3_QXADDR = UPS3_WIDTH / 2;
localparam TAIL_QXADDR = TAIL_WIDTH / 2;

localparam HEAD_QYADDR = HEAD_QXADDR * HEAD_LADDR * 'd2 ; //line address for each line buffer
localparam DOWNS1_QYADDR = DOWNS1_QXADDR * DOWNS1_LADDR * 'd2;
localparam DOWNS2_QYADDR = DOWNS2_QXADDR * DOWNS2_LADDR * 'd2;
localparam BOTT_QYADDR = BOTT_LADDR * BOTT_QXADDR * 'd2;
localparam UPS1_QYADDR = UPS1_LADDR * UPS1_QXADDR * 'd2;
localparam UPS2_QYADDR = UPS2_QXADDR * UPS2_LADDR* 'd2;
localparam UPS3_QYADDR = UPS3_QXADDR * UPS3_LADDR* 'd2;
localparam TAIL_QYADDR = TAIL_QXADDR * TAIL_LADDR* 'd2;
reg [14:0] space_size; 

//reg [12:0] t_z;      // Max: 512 * 32768
//reg [5:0]  t_x;      // Max: 16 * 4
//reg [12:0] t_y;      // Max: 8 * 480
//reg [7:0] t_l;      // Max: 31 * 64
//reg [7:0]  t_offset; // Max: 3 * 64
//reg [4:0]  q_x;      // Max: 1 * 16
//reg [11:0] q_y;      // Max: 1 * 2048 // dung roi
//reg [5:0] fl_off_set;
reg [13:0] tile_addr_fixed, base_addr_fixed, dynamic_offset;
reg [7:0] tile;
reg [3:0] tile_x, tile_y;
reg [8:0] tile_z, tile_channel;

reg [1:0] quarter;
reg [3:0] prev_stage;
reg [1:0] stride; // 0 - 1 stride (10), 1 - 2 stride (17), 2 - pointwise only (tile size = 8)
reg [320 - 1: 0] line_buf [1:0][0:2]; //maximum then selection
reg [1:0] buf_cnt;
reg [3:0] load_stage;   
reg channel_swap;
reg stop;


reg [4:0] line_counter;
reg [4:0] line_buffer_size;
reg [5:0] line_addr;
reg [3:0] padding_tile;
reg up_padding;
reg down_padding;
reg pre_padding;
reg post_padding;
reg [2:0] tile_x_addr;
reg [9:0] tile_y_addr;
reg [3:0] tile_ref;
reg [8:0] tile_y_ref;

reg [3:0] quarter_x_addr;
reg [10:0] quarter_y_addr;

reg [1:0] target_idx;
reg buf_s2_load;


always @(*) begin
    line_buffer_size = 'd0; 
    stride = 'd0;
    tile_x_addr = 0;
    case (o_stage)
        HEAD: begin
            line_buffer_size = 'd10;    
            stride = 'd1;
            tile_x_addr = 2;
        end 
        UPS1, UPS2, UPS3: begin
            line_buffer_size = 'd10;    
            stride = 'd1;
            tile_x_addr = 2;
//            tile_y_addr = 'd128;
        end
        DOWNS1, DOWNS2, BOTT: begin
            line_buffer_size = 'd17; 
            stride = 'd2;   
            tile_x_addr = 4;  
//            tile_y_addr = 256;
        end 
        TAIL: begin
            line_buffer_size = 'd8; 
            stride = 'd0;
            tile_x_addr = 2;  
//            tile_y_addr = 'd256;
        end  
        default: begin
        
        end
    endcase
end

always @(*) begin
    padding_tile = 0;
    up_padding   = 1'b0;
    down_padding = 1'b0;
    pre_padding  = 1'b0;
    post_padding = 1'b0;
    space_size = 0;
    padding_tile = 0;
    tile_channel = 0;
    tile_ref = 0;
    line_addr = 0;
    quarter_x_addr = 0;
    quarter_y_addr = 0;
    tile_y_ref = 0;
    tile_y_addr = 0;

    case (o_stage)
        HEAD: begin
            space_size = HEAD_WIDTH * HEAD_WIDTH * 4;
            padding_tile = HEAD_TILE_X;
            tile_channel = HEAD_TILE_Z;
            tile_ref = HEAD_TILE_Y;
            line_addr = HEAD_LADDR;
            quarter_x_addr = HEAD_QXADDR;
            quarter_y_addr = HEAD_QYADDR;
            tile_y_ref = HEAD_TILE_X * HEAD_TILE_Y;
            tile_y_addr = 'd256;

            if (tile < HEAD_TILE_X) 
                up_padding = 1'b1;
            
            if (tile >= (HEAD_TILE_X * HEAD_TILE_X - HEAD_TILE_X)) 
                down_padding = 1'b1;
            
            if (tile[3:0] == 4'b0000) 
                pre_padding = 1'b1;
                
            if (tile[3:0] == 4'b1111) 
                post_padding = 1'b1;
        end
        DOWNS1: begin
            space_size = DOWNS1_WIDTH * DOWNS1_WIDTH * 4;
            padding_tile = DOWNS1_TILE_X;
            tile_channel = DOWNS1_TILE_Z;
            tile_ref = DOWNS1_TILE_Y;
            line_addr = DOWNS1_LADDR;
//            quarter_x_addr = DOWNS1_QXADDR;
//            quarter_y_addr = DOWNS1_QYADDR;
            tile_y_addr = 'd256;
            tile_y_ref = DOWNS1_TILE_X * DOWNS1_TILE_Y;
            if (tile < DOWNS1_TILE_X) 
                up_padding = 1'b1;
            
            if (tile >= (DOWNS1_TILE_X * DOWNS1_TILE_X - DOWNS1_TILE_X)) 
                down_padding = 1'b1;
            
            if (tile[2:0] == 3'b000) 
                pre_padding = 1'b1;
                
            if (tile[2:0] == 3'b111) 
                post_padding = 1'b1;
        end
        DOWNS2: begin
            space_size = DOWNS2_WIDTH * DOWNS2_WIDTH;
            padding_tile = DOWNS2_TILE_X;              
            tile_channel = DOWNS2_TILE_Z;
            tile_ref = DOWNS2_TILE_Y;
            line_addr = DOWNS2_LADDR;
//            quarter_x_addr = DOWNS2_QXADDR;
//            quarter_y_addr = DOWNS2_QYADDR;
            tile_y_ref = DOWNS2_TILE_X * DOWNS2_TILE_Y;
            tile_y_addr = 'd128;
            if (tile < padding_tile) 
                up_padding = 1'b1;
            
            if (tile >= (padding_tile * padding_tile - padding_tile)) 
                down_padding = 1'b1;
            
            if (tile[1:0] == 2'b00) 
                pre_padding = 1'b1;
                
            if (tile[1:0] == 2'b11) 
                post_padding = 1'b1;
        end     
        BOTT: begin
            space_size = BOTT_WIDTH * BOTT_WIDTH;
            padding_tile = BOTT_TILE_X;
            tile_channel = BOTT_TILE_Z;
            tile_ref = BOTT_TILE_Y;
            line_addr = BOTT_LADDR;
            tile_y_addr = 'd64;
//            quarter_x_addr = BOTT_QXADDR;
//            quarter_y_addr = BOTT_QYADDR;
            tile_y_ref = BOTT_TILE_X * BOTT_TILE_Y;
            if (tile < padding_tile) 
                up_padding = 1'b1;
            
            if (tile >= (padding_tile * padding_tile - padding_tile)) 
                down_padding = 1'b1;
            
            if (tile[0] == 1'b0) 
                pre_padding = 1'b1;
                
            if (tile[0] == 1'b1) 
                post_padding = 1'b1;
        end
        UPS1: begin
            space_size =  UPS1_WIDTH * UPS1_WIDTH * 4;
            padding_tile = UPS1_TILE_X;
            tile_channel = UPS1_TILE_Z;
            tile_ref = UPS1_TILE_Y;
            line_addr = UPS1_LADDR;
//            quarter_x_addr = UPS1_QXADDR;
//            quarter_y_addr = UPS1_QYADDR;
            tile_y_ref = UPS1_TILE_X * UPS1_TILE_Y;
            if (tile < padding_tile) 
                up_padding = 1'b1;
            
            if (tile >= (padding_tile * padding_tile - padding_tile)) 
                down_padding = 1'b1;
            
            if (tile[1:0] == 2'b00) 
                pre_padding = 1'b1;
                
            if (tile[1:0] == 2'b11) 
                post_padding = 1'b1;
        end
        UPS2: begin
            space_size =  UPS2_WIDTH * UPS2_WIDTH* 4;
            padding_tile = UPS2_TILE_X;
            tile_channel = UPS2_TILE_Z;
            tile_ref = UPS2_TILE_Y;
            line_addr = UPS2_LADDR;
//            quarter_x_addr = UPS2_QXADDR;
//            quarter_y_addr = UPS2_QYADDR;
            tile_y_ref = UPS2_TILE_X * UPS2_TILE_Y;
            if (tile < padding_tile) 
                up_padding = 1'b1;
            
            if (tile >= (padding_tile * padding_tile - padding_tile)) 
                down_padding = 1'b1;
            
            if (tile[2:0] == 3'b000) 
                pre_padding = 1'b1;
                
            if (tile[2:0] == 3'b111) 
                post_padding = 1'b1;
        end
        UPS3: begin
            space_size =  UPS3_WIDTH * UPS3_WIDTH * 4;
            padding_tile = UPS3_TILE_X;
            tile_channel = UPS3_TILE_Z;
            tile_ref = UPS3_TILE_Y;
            line_addr = UPS3_LADDR;
//            quarter_x_addr = UPS3_QXADDR;
//            quarter_y_addr = UPS3_QYADDR;
            tile_y_ref = UPS3_TILE_X * UPS3_TILE_Y;
            if (tile < padding_tile) 
                up_padding = 1'b1;
            
            if (tile >= (padding_tile * padding_tile - padding_tile)) 
                down_padding = 1'b1;
            
            if (tile[3:0] == 4'b0000) 
                pre_padding = 1'b1;
                
            if (tile[3:0] == 4'b1111) 
                post_padding = 1'b1;
        end
        TAIL: begin
            space_size =  TAIL_WIDTH * TAIL_WIDTH * 4;
            padding_tile = TAIL_TILE_X;
            tile_channel = TAIL_TILE_Z;
            tile_ref = TAIL_TILE_Y;
            line_addr = TAIL_LADDR;
//            quarter_x_addr = TAIL_QXADDR;
//            quarter_y_addr = TAIL_QYADDR;
            tile_y_ref = TAIL_TILE_X * TAIL_TILE_Y;
            up_padding   = 1'b0;
            down_padding = 1'b0;
            pre_padding  = 1'b0;
            post_padding = 1'b0;
        end
        default: begin end
    endcase
end

wire load_enable = ((stride < 'd2 && buf_cnt < 'd2) || (stride == 'd2 && buf_cnt <= 'd3)) && o_stage != IDLE && !stop;

always @(posedge i_clk) begin
    if (!i_rst_n) begin
        load_stage <= 'd0;
        //
        o_r_address <= 'd0;
        o_r_enable <= 'd1;
        //
        buf_cnt <= 'd0;
        channel_swap <= 'd0;
        //
//        t_z <= 0; t_x <= 'd0; t_y <= 'd0; t_l <= 'd0; t_offset <= 'd0; q_x <= 'd0; q_y <= 'd0;
        o_valid <= 'd0;
        tile_addr_fixed <= 'd0; base_addr_fixed <= 'd0; dynamic_offset <= 'd0;
//        fl_off_set <= 'd0;
    end
    else if (i_dready && o_valid && buf_s2_load == 'd0) begin
        if (buf_cnt - 1'b1 <= 1'b0) begin
            o_valid <= 'b0;    
            buf_cnt <= buf_cnt - 1'b1;    
        end
        else begin
            buf_cnt <= buf_cnt - 1'b1;
        end
    end
    else if (load_enable) begin
        case (load_stage)
            4'd0: begin
                o_r_address <= o_r_address + 1'b1;
                o_r_enable  <= 1'd1; // keeping
                load_stage <= load_stage + 1'b1;
                if (up_padding && line_counter == 0) begin
                    load_stage <= 'd9; // mapping stage
                end
                else if (down_padding && line_counter == line_buffer_size - 1'b1) begin
                    load_stage <= 'd10;
                end
                
            end
            4'd1: begin
                o_r_address <= o_r_address + 1'b1;
                load_stage  <= load_stage + 1'b1;
                line_buf[channel_swap][target_idx] <= {256'b0,i_data};
            end
            4'd2: begin
                o_r_address <= o_r_address + 1'b1;
                load_stage  <= load_stage + 1'b1;
                line_buf[channel_swap][target_idx] <= {192'b0,i_data,line_buf[channel_swap][target_idx][63:0]};
                if (stride == 'd0) load_stage <= 4'd11; //xu ly stride = 0, line_buffer = 8 
            end
            4'd3: begin
                o_r_address <= o_r_address + 1'b1;
                load_stage <= load_stage + 'd1;
                line_buf[channel_swap][target_idx] <= {80'b0,i_data,line_buf[channel_swap][target_idx][127:0], 48'b0};
                if (stride == 'd1 && pre_padding) load_stage <= 'd6;
                else if (stride == 'd1 && post_padding) load_stage <= 'd8;
            end
            4'd4: begin : stride_1_non_pre_padding
                o_r_address <= o_r_address + 1'b1;
                line_buf[channel_swap][target_idx] <= {64'b0,i_data,line_buf[channel_swap][target_idx][239:48]};
                case (stride)
                    2'd1: begin 
                        load_stage <= 'd6;
                    end
                    2'd2: begin
                        if (!pre_padding) load_stage <= 'd5;
                        else load_stage <= 'd7;
                    end
                    default: begin
                        load_stage <= 'd5;
                    end
                endcase
            end 
            4'd5: begin : stride_2_non_pre_padding
                load_stage  <= 'd7;
                line_buf[channel_swap][target_idx] <= {16'b0,i_data,line_buf[channel_swap][target_idx][255:16]};
            end
            4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11: begin
                
                load_stage <= 'd12;
                if (channel_swap == 1'b1) begin
                    channel_swap <= 1'b0; 
                    if (target_idx != 2) buf_cnt      <= buf_cnt + 1'b1; 
                end
                else begin
                    channel_swap <= 1'b1; // Ð?o t? 0 lên 1
                end
                case (load_stage)
                    4'd6: if (!pre_padding) line_buf[channel_swap][target_idx] <= {16'b0,line_buf[channel_swap][target_idx][304:16]};
                    4'd7: if (pre_padding) line_buf[channel_swap][target_idx] <= {line_buf[channel_swap][target_idx][271:0],48'b0};
                    4'd8: line_buf[channel_swap][target_idx] <= {64'b0, line_buf[channel_swap][target_idx][255:0]} ; //remove adding 64 bit zero
                    4'd9, 4'd10: line_buf[channel_swap][target_idx] <= 256'b0;
                    4'd11: line_buf[channel_swap][target_idx] <= {line_buf[channel_swap][target_idx][288:0],32'b0};
                endcase
                case ({buf_cnt + 1'b1, stride, channel_swap})
                    5'b10_011, 5'b10_001: begin
                        o_valid <= 1'b1;
                    end
                    5'b10_101: begin
                        o_valid <= 1'b1;
                    end
                    default: o_valid <= 'b0;
                endcase
            end
            4'd12: begin
//                o_r_address <= (tile_z + channel_swap)*space_size + tile_x * tile_x_addr + tile_y * (tile_y_addr) + line_counter * line_addr - 1 * (!pre_padding) - !up_padding * ('d3 - stride) * line_addr + quarter[0] * quarter_x_addr + quarter [1] * quarter_y_addr  ; // chua oke
//                load_stage <= 'd13;
//                t_z      <= (tile_z + channel_swap) * space_size;
//                t_x      <= tile_x * tile_x_addr;
//                t_y      <= tile_y * tile_y_addr;
//                t_l      <= line_counter * line_addr;
//                t_offset <= (!pre_padding ? 1 : 0) + (!up_padding ? (3 - stride) * line_addr : 0);
//                q_x      <= quarter[0] * quarter_x_addr;
//                q_y      <= quarter [1] * quarter_y_addr;
//                fl_off_set <= !first_line * (up_padding ? 1 : 0) * line_addr;
                load_stage <= 4'd13;
                // Nhóm các thành ph?n ít thay ð?i l?i v?i nhau
                base_addr_fixed <= (tile_z + channel_swap) * space_size + quarter[1] * quarter_y_addr + quarter[0] * quarter_x_addr;
                tile_addr_fixed <= tile_y * tile_y_addr + tile_x * tile_x_addr - (!up_padding ? ('d2 - (stride[0] + stride [1])) * line_addr : 0);
                
                // Tính ph?n offset ð?ng
                dynamic_offset  <=  line_counter * line_addr  - ((!first_line && up_padding)? line_addr : 0) ;
                
//                t_l <= line_counter * line_addr;
            end
            4'd13: begin
                load_stage <= 'd0;
                o_r_address <= base_addr_fixed + tile_addr_fixed  + dynamic_offset + (pre_padding ? 0 : -'d1 );
            end 
        endcase
                 
    end
end    
// tile_x, tile_y, tile_z, tile, quarter, o_stage

assign first_line = (line_counter == 'd0) ? 1'b1: 1'b0;

always @(*) begin
    case ({stride, channel_swap, first_line})
        4'b10_01, 4'b10_11: target_idx = 'd2;
        4'b10_00, 4'b10_10: target_idx = !line_counter[0];
        default: target_idx = line_counter[0];
    endcase
    
end

always @(posedge i_clk) begin
    if (!i_rst_n) begin
        buf_s2_load <= 1'b0;      
    end
    else if (target_idx == 'd2 && !o_valid) begin
        buf_s2_load <= 1'b1;
    end
    else if (i_dready && o_valid && buf_s2_load != 'd0) begin
        buf_s2_load <= 0;
    end
    
end

//tam thoi, chay simulation va fix dan 
wire line_done    = (line_counter == line_buffer_size - 1'b1);
wire z_done       = (tile_z == tile_channel - 2'd2) && line_done;
wire x_done       = (tile_x + 1'b1 == tile_ref) && z_done; // Gi? s? TAIL_TILE_X
wire y_done  = (tile_y + 1'b1 == tile_ref) && x_done; // them 1 dieu kien gi nua vi du doi pointwise xong
//wire y_done       = y_done_wait && ;
wire stage_done   = (o_stage == TANH) && y_done;
wire image_done   = 1'b1 && stage_done && (quarter == 2'b11); // tin hieu tu 1 module nao do bao xong thi moi xong 
wire is_updating_stage = (load_stage >= 4'd6 && load_stage <= 4'd11) && (channel_swap == 1'b1);
//handle update line_counter and buffer available
// ... (gi? nguyên ph?n wire khai báo bên trên) ...

always @(posedge i_clk) begin
    if (!i_rst_n) begin
        line_counter <= 'd0;        
        quarter      <= 'd0;
        tile         <= 'd0;
        tile_x       <= 'd0;
        tile_y       <= 'd0;
        tile_z       <= 'd0;
        stop <= 'd0;
        o_stage      <= IDLE;
    end
    else if (i_enable && o_stage == IDLE) begin
        o_stage <= HEAD;
    end  
    else if (stop && i_pwdone) begin
            stop <= 1'b0;
            tile_y  <= 'd0;
            o_stage <= o_stage + 1'b1;
            line_counter <= 'd0;
            tile_x <= 'd0;
            tile_z <= 'd0;
            tile   <= quarter[1] * tile_y_ref + quarter[0] * tile_ref;
    end      
    else if (is_updating_stage) begin
        
        // --- LOGIC Ð?M CÓ TH? T? ---
        if (image_done) begin
            // Reset toàn b? khi xong c? ?nh
            line_counter <= 'd0;
            tile_z       <= 'd0;
            tile_x       <= 'd0;
            tile_y       <= 'd0;
            quarter      <= 'd0;
            o_stage      <= IDLE;
        end 
        
        else if (stage_done) begin
            // Xong m?t stage (ví d? qua l?p TANH)
            o_stage <= IDLE; // Ho?c chuy?n sang stage ti?p theo
            quarter <= quarter + 1'b1;
            line_counter <= 'd0;
            tile_z <= 'd0;
            case (quarter + 1'b1) 
                2'b00: 
                begin
                    tile_y  <= 'd0;
                    tile_x <= 'd0;
                    tile   <= 'd0;
                end
                2'b01:
                begin
                    tile_y  <= 'd0;
                    tile_x <= tile_ref;
                    tile   <=tile_ref;
                end
                2'b10:
                begin
                    tile_y  <= tile_ref;
                    tile_x <= 'd0;
                    tile   <= tile_y_ref;
                end
                2'b11: 
                begin
                    tile_y  <= tile_y_ref;
                    tile_x <= tile_ref;
                    tile   <= tile_y_ref + tile_ref;
                end
            endcase
        end
        
//        else if (prev_stage != o_stage) begin
//            prev_stage <= o_stage;
//            tile   <= quarter[1] * tile_y_ref + quarter[0] * tile_ref; //concern
//        end
        
        else if (y_done) begin
            stop <= 1'b1;
        end
        else if (x_done) begin
            tile_x <= 'd0;
            tile_y <= tile_y + 1'b1;
            tile   <= tile + tile_ref + 1'b1;
            line_counter <= 'd0;
            tile_z <= 'd0;
        end
        else if (z_done) begin
            tile_z <= 'd0;
            tile_x <= tile_x + 1'b1;
            tile   <= tile + 1'b1;
            line_counter <= 'd0;
        end
        else if (line_done) begin
            line_counter <= 'd0;
            tile_z       <= tile_z + 2'd2;
        end
        else begin
            // M?c ð?nh tãng c?p nh? nh?t
            line_counter <= line_counter + 1'b1;
        end
        
    end
end
assign o_data = (stride == 2'd0) ? (
                    (buf_cnt == 2'd2) ? {line_buf[1][0][303:32], line_buf[0][0][303:32]} : 
                    (buf_cnt == 2'd1) ? {line_buf[1][1][303:32], line_buf[0][1][303:32]} : 544'b0
                ) :
                (stride == 2'd1) ? (
                    (buf_cnt == 2'd2) ? {line_buf[1][0][303:32], line_buf[0][0][303:32]} : 
                    (buf_cnt == 2'd1) ? {line_buf[1][1][303:32], line_buf[0][1][303:32]} : 544'b0
                ) :
                (stride == 2'd2) ? (
                    (buf_s2_load != 1'b0) ? {line_buf[1][2][303:32], line_buf[0][2][303:32]} :
                    (buf_cnt == 2'd2) ? {line_buf[1][0][303:32], line_buf[0][0][303:32]} : 
                    (buf_cnt == 2'd1) ? {line_buf[1][1][303:32], line_buf[0][1][303:32]} : 544'b0
                ) : 544'b0; // Giá tr? m?c ð?nh n?u không th?a m?n stride nào
endmodule