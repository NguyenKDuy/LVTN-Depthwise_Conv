`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2026 04:16:32 PM
// Design Name: 
// Module Name: 
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


module tb_Depthwise_Core_Top;

    // ==========================================
    // 1. KHAI BÁO THÔNG SỐ VÀ TÍN HIỆU
    // ==========================================
    parameter IMG_W = 128;
    parameter IMG_H = 128;
    parameter CHANNELS_FILE = 16;  // Số channel thực tế trong file data
    parameter CHANNELS_HW   = 16; // Số channel thiết kế trên phần cứng
    parameter PIXELS_PER_CH = IMG_W * IMG_H; 
    parameter TOTAL_PIXELS  = CHANNELS_FILE * PIXELS_PER_CH; 

    reg clk;
    reg rst_n;
//    reg i_en;
    
    // Tín hiệu nạp Weight
    reg i_weight_valid;
    reg [575:0] i_weight_data;  // 4 CH * 9 W * 16 bit
    
    // Tín hiệu nạp Data (Pixels)
    reg i_data_valid;
    reg [2303:0] i_all_windows; // 16 CH * 9 P * 16 bit

    // Tín hiệu thu từ DUT
    wire [255:0] o_data;        // 16 CH * 16 bit
    wire o_data_valid;

    // Mảng RAM chứa file .mem
    reg [15:0] weight_mem [0 : (CHANNELS_FILE * 9) - 1]; // 144 weights
    reg [15:0] pixel_mem  [0 : TOTAL_PIXELS - 1];        // 262144 pixels

    integer file_out;
    integer cyc, c, w, p, y, x, real_ch, p_start;

    // ==========================================
    // 2. KHỞI TẠO DUT (Device Under Test)
    // ==========================================
    Depthwise_Core_Top dut (
        .clk(clk),
        .rst_n(rst_n),
//        .i_en(i_en),
        .i_weight_valid(i_weight_valid),
        .i_weight_data(i_weight_data),
        .i_data_valid(i_data_valid),
        .i_all_windows(i_all_windows),
        .o_data(o_data),
        .o_data_valid(o_data_valid)
    );

    // Tạo Clock 100MHz (Chu kỳ 10ns)
    always #5 clk = ~clk;

    // ==========================================
    // 3. KỊCH BẢN CHẠY TESTBENCH KHONG LOI
    // ==========================================
//    initial begin
//        // Đọc data từ file
//        $readmemh("weights.mem", weight_mem);
//        $readmemh("pixels.mem", pixel_mem);
//        $display("TEST ĐỌC FILE: Pixel đầu tiên = %04X", pixel_mem[0]);
//        $display("TEST ĐỌC FILE: Weight đầu tiên = %04X", weight_mem[0]);
//        file_out = $fopen("tb_output_16bit.hex", "w");

//        // Khởi tạo trạng thái ban đầu
//        clk = 0;
//        rst_n = 0;
//        i_en = 0;
//        i_weight_valid = 0;
//        i_data_valid = 0;
//        i_weight_data = 576'b0;
//        i_all_windows = 2304'b0;

//        #25;
//        rst_n = 1; // Nhả reset
//        i_en = 1;  // Bật Enable toàn hệ thống
//        #20;

//        // -----------------------------------------------------------
//        // GIAI ĐOẠN 1: NẠP WEIGHT (4 CHU KỲ x 4 KÊNH = 16 KÊNH)
//        // -----------------------------------------------------------
//        $display(">> Dang nap Weight cho 16 Channel...");
        
//        for (cyc = 0; cyc < 4; cyc = cyc + 1) begin
//            @(posedge clk);
          
//            i_weight_valid = 1; 
//            i_data_valid = 0;   
            
//            // Xây dựng gói 576-bit chứa 4 Channel cho chu kỳ hiện tại
//            for (c = 0; c < 4; c = c + 1) begin
//                real_ch = cyc * 4 + c; // Channel thực tế (0 -> 15)
                
//                for (w = 0; w < 9; w = w + 1) begin
//                    if (real_ch < CHANNELS_FILE) begin
//                        // Nếu nằm trong 6 channel thật -> lấy data từ mảng
//                        i_weight_data[(c*144 + w*16) +: 16] = weight_mem[real_ch * 9 + w];
//                    end else begin
//                        // Nếu từ channel 6 trở đi -> độn số 0
//                        i_weight_data[(c*144 + w*16) +: 16] = 16'h0000;
//                    end
//                end
//            end
//        end
        
//        // Hoàn thành 4 chu kỳ nạp, hạ valid
//        @(posedge clk);
//        i_weight_valid = 0;
//        i_weight_data = 576'b0;
        
//        #50; // Đợi một chút cho hệ thống ổn định

//        // -----------------------------------------------------------
//        // GIAI ĐOẠN 2: TRƯỢT CỬA SỔ NẠP PIXEL
//        // (Tính toán song song 16 kênh trong cùng 1 Window 3x3)
//        // -----------------------------------------------------------
//        $display(">> Dang truot cua so Pixel (Stride = 1)...");
        
//        for (y = 0; y < IMG_H - 2; y = y + 1) begin
//            for (x = 0; x < IMG_W - 2; x = x + 1) begin
//                @(posedge clk);
                
//                i_data_valid = 1; 
                
//                // Xây dựng gói 2304-bit chứa (16 Kênh x 9 Pixel)
//                for (c = 0; c < CHANNELS_HW; c = c + 1) begin
//                    if (c < CHANNELS_FILE) begin
//                        // Lấy 9 pixel thực tế cho các channel từ 0 đến 5
//                        p_start = c * PIXELS_PER_CH;
                        
//                        i_all_windows[(c*144 + 0*16) +: 16] = pixel_mem[p_start + (y+0)*IMG_W + (x+0)];
//                        i_all_windows[(c*144 + 1*16) +: 16] = pixel_mem[p_start + (y+0)*IMG_W + (x+1)];
//                        i_all_windows[(c*144 + 2*16) +: 16] = pixel_mem[p_start + (y+0)*IMG_W + (x+2)];
                        
//                        i_all_windows[(c*144 + 3*16) +: 16] = pixel_mem[p_start + (y+1)*IMG_W + (x+0)];
//                        i_all_windows[(c*144 + 4*16) +: 16] = pixel_mem[p_start + (y+1)*IMG_W + (x+1)];
//                        i_all_windows[(c*144 + 5*16) +: 16] = pixel_mem[p_start + (y+1)*IMG_W + (x+2)];
                        
//                        i_all_windows[(c*144 + 6*16) +: 16] = pixel_mem[p_start + (y+2)*IMG_W + (x+0)];
//                        i_all_windows[(c*144 + 7*16) +: 16] = pixel_mem[p_start + (y+2)*IMG_W + (x+1)];
//                        i_all_windows[(c*144 + 8*16) +: 16] = pixel_mem[p_start + (y+2)*IMG_W + (x+2)];
//                    end else begin
//                        // Các kênh giả (6 -> 15) bơm toàn 0
//                        for (p = 0; p < 9; p = p + 1) begin
//                            i_all_windows[(c*144 + p*16) +: 16] = 16'h0000;
//                        end
//                    end
//                end
//            end
//        end
        
//        // Quét hết ảnh, hạ valid
//        @(posedge clk);
//        i_data_valid = 0;
//        i_all_windows = 2304'b0;
        

//        // Đợi Pipeline chảy nốt các kết quả cuối cùng (Pipeline của bạn là 6 bậc)
//        repeat(20) @(posedge clk);
        
//        $fclose(file_out);
//        $display(">> HOAN TAT MO PHONG! Kiem tra file tb_output_16bit.hex");
//        $finish;
//    end



// ==========================================
    // 3. KỊCH BẢN CHẠY TESTBENCH (CÓ BƠM LỖI TH1, TH2, TH3)
    // ==========================================
    initial begin
        // Đọc data từ file
        $readmemh("weights.mem", weight_mem);
        $readmemh("pixels.mem", pixel_mem);
        $display("TEST ĐỌC FILE: Pixel đầu tiên = %04X", pixel_mem[0]);
        $display("TEST ĐỌC FILE: Weight đầu tiên = %04X", weight_mem[0]);
        file_out = $fopen("tb_output_16bit.hex", "w");

        // Khởi tạo trạng thái ban đầu
        clk = 0;
        rst_n = 0;
//        i_en = 0;
        i_weight_valid = 0;
        i_data_valid = 0;
        i_weight_data = 576'b0;
        i_all_windows = 2304'b0;

        #25;
        rst_n = 1; // Nhả reset
//        i_en = 1;  // Bật Enable toàn hệ thống
        #20;

        // -----------------------------------------------------------
        // GIAI ĐOẠN 1: NẠP WEIGHT + [TEST TH1]
        // TH1: Đang nạp weight thì i_weight_valid = 0, sau đó nạp lại từ đầu
        // -----------------------------------------------------------
        $display(">> [TH1] Bat dau nap Weight nhung se ngat giua chung...");
        
        // Cố tình nạp dở dang 2 chu kỳ rồi ngắt
        for (cyc = 0; cyc < 2; cyc = cyc + 1) begin
            @(posedge clk);
            i_weight_valid = 1; 
            for (c = 0; c < 4; c = c + 1) begin
                real_ch = cyc * 4 + c;
                for (w = 0; w < 9; w = w + 1) begin
//                    if (real_ch < CHANNELS_FILE) i_weight_data[(c*144 + w*16) +: 16] = weight_mem[real_ch * 9 + w];
                    if (real_ch < CHANNELS_FILE) i_weight_data[(c*144 + w*16) +: 16] = 16'h0000;
                    else i_weight_data[(c*144 + w*16) +: 16] = 16'h0000;
                end
            end
        end
        
        // Ngắt Valid giữa chừng
        @(posedge clk);
        i_weight_valid = 0;
        i_weight_data = 576'b0;
        $display(">> [TH1] Da ngat i_weight_valid = 0. Cho 5 chu ky...");
        repeat(5) @(posedge clk);
        
        // Tùy vào thiết kế mạch của bạn, nếu mạch cần rst_n để reset bộ đếm weight thì bật dòng dưới
        // rst_n = 0; #10; rst_n = 1; 

        $display(">> [TH1] Nap lai Weight tu dau (chay du 4 chu ky)...");
        for (cyc = 0; cyc < 4; cyc = cyc + 1) begin
            @(posedge clk);
            i_weight_valid = 1; 
            for (c = 0; c < 4; c = c + 1) begin
                real_ch = cyc * 4 + c;
                for (w = 0; w < 9; w = w + 1) begin
                    if (real_ch < CHANNELS_FILE) i_weight_data[(c*144 + w*16) +: 16] = weight_mem[real_ch * 9 + w];
                    else i_weight_data[(c*144 + w*16) +: 16] = 16'h0000;
                end
            end
        end
        
        @(posedge clk);
        i_weight_valid = 0;
        i_weight_data = 576'b0;
        #50;

        // -----------------------------------------------------------
        // GIAI ĐOẠN 2: TRƯỢT CỬA SỔ NẠP PIXEL + [TEST TH2, TH3]
        // -----------------------------------------------------------
        $display(">> Dang truot cua so Pixel (Kem cac truong hop ngat)...");
        
        for (y = 0; y < IMG_H - 2; y = y + 1) begin
            for (x = 0; x < IMG_W - 2; x = x + 1) begin
                
                // --- TEST TH3: Ngắt Enable (i_en) ---
                // Xảy ra khi đang quét tới dòng thứ 2, cột thứ 10
                if (y == 2 && x == 10) begin
                    $display("   -> [TH3] y=%0d, x=%0d: Tat i_data_valid trong 5 chu ky", y, x);
                    @(posedge clk);
//                    i_en = 0;
                    i_data_valid = 0; 
                    repeat(7) @(posedge clk);
//                    i_en = 1;
//                    i_data_valid = 1;
                    $display("   -> [TH3] Bat lai i_data_valid, tiep tuc chay...");
                end

                // --- TEST TH2: Ngắt i_data_valid (Vài chu kỳ ngắn) ---
                // Xảy ra khi đang quét tới dòng thứ 5, cột thứ 20
                if (y == 5 && x == 20) begin
                    $display("   -> [TH2.1] y=%0d, x=%0d: Ngat Data Valid trong 3 chu ky", y, x);
                    @(posedge clk);
                    i_data_valid = 0;
                    i_all_windows = 2304'b0;
                    repeat(3) @(posedge clk);
                    $display("   -> [TH2.1] Tiep tuc cap Data...");
                end 
                
                // --- TEST TH2: Ngắt i_data_valid (Vài chục chu kỳ dài) ---
                // Xảy ra khi đang quét tới dòng thứ 10, cột thứ 50
                else if (y == 10 && x == 50) begin
                    $display("   -> [TH2.2] y=%0d, x=%0d: Ngat Data Valid TRONG 30 chu ky", y, x);
                    @(posedge clk);
                    i_data_valid = 0;
                    i_all_windows = 2304'b0;
                    repeat(30) @(posedge clk);
                    $display("   -> [TH2.2] Tiep tuc cap Data...");
                end

                // --- NẠP DATA BÌNH THƯỜNG CHO PIXEL HIỆN TẠI ---
                @(posedge clk);
                i_data_valid = 1; 
                
                for (c = 0; c < CHANNELS_HW; c = c + 1) begin
                    if (c < CHANNELS_FILE) begin
                        p_start = c * PIXELS_PER_CH;
                        i_all_windows[(c*144 + 0*16) +: 16] = pixel_mem[p_start + (y+0)*IMG_W + (x+0)];
                        i_all_windows[(c*144 + 1*16) +: 16] = pixel_mem[p_start + (y+0)*IMG_W + (x+1)];
                        i_all_windows[(c*144 + 2*16) +: 16] = pixel_mem[p_start + (y+0)*IMG_W + (x+2)];
                        i_all_windows[(c*144 + 3*16) +: 16] = pixel_mem[p_start + (y+1)*IMG_W + (x+0)];
                        i_all_windows[(c*144 + 4*16) +: 16] = pixel_mem[p_start + (y+1)*IMG_W + (x+1)];
                        i_all_windows[(c*144 + 5*16) +: 16] = pixel_mem[p_start + (y+1)*IMG_W + (x+2)];
                        i_all_windows[(c*144 + 6*16) +: 16] = pixel_mem[p_start + (y+2)*IMG_W + (x+0)];
                        i_all_windows[(c*144 + 7*16) +: 16] = pixel_mem[p_start + (y+2)*IMG_W + (x+1)];
                        i_all_windows[(c*144 + 8*16) +: 16] = pixel_mem[p_start + (y+2)*IMG_W + (x+2)];
                    end else begin
                        for (p = 0; p < 9; p = p + 1) begin
                            i_all_windows[(c*144 + p*16) +: 16] = 16'h0000;
                        end
                    end
                end
            end
        end
        
        // Quét hết ảnh, hạ valid
        @(posedge clk);
        i_data_valid = 0;
        i_all_windows = 2304'b0;

        // Đợi Pipeline chảy nốt các kết quả
        repeat(20) @(posedge clk);
        
        $fclose(file_out);
        $display(">> HOAN TAT MO PHONG! Kiem tra file tb_output_16bit.hex");
        $finish;
    end


 
    // ==========================================
    // 4. BẮT KẾT QUẢ VÀ GHI RA FILE (Ghi 6 kênh thật)
    // ==========================================
    always @(posedge clk) begin
        if (o_data_valid) begin
            // Vì bạn chỉ cần so sánh 6 kênh thực tế, mình in ra 6 giá trị trên 1 dòng
            // CH0 CH1 CH2 CH3 CH4 CH5
            $fdisplay(file_out, "%04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X", 
                o_data[(0*16) +: 16],
                o_data[(1*16) +: 16],
                o_data[(2*16) +: 16],
                o_data[(3*16) +: 16],
                o_data[(4*16) +: 16],
                o_data[(5*16) +: 16],
                o_data[(6*16) +: 16],
                o_data[(7*16) +: 16],
                o_data[(8*16) +: 16],
                o_data[(9*16) +: 16],
                o_data[(10*16) +: 16],
                o_data[(11*16) +: 16],
                o_data[(12*16) +: 16],
                o_data[(13*16) +: 16],
                o_data[(14*16) +: 16],
                o_data[(15*16) +: 16]
            );
        end
    end

endmodule