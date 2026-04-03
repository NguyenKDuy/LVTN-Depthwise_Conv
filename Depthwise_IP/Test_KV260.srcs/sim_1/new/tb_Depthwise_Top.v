`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2026 08:23:57 PM
// Design Name: 
// Module Name: tb_Depthwise_Top
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



//`timescale 1ns / 1ps

//module tb_Depthwise_Core();
//    // Khai báo signals
//    reg clk, rst_n, i_en, i_weight_valid, i_data_valid;
//    reg [2303:0] i_all_windows;
//    reg [575:0] i_weight_data;
//    wire [255:0] o_data;
//    wire o_data_valid;

//    // Khai báo biến chạy
//    integer w_idx, c_idx, p_idx;

//    // Khởi tạo Module (UUT)
//    Depthwise_Core_Top uut (
//        .clk(clk), .rst_n(rst_n), .i_en(i_en),
//        .i_weight_valid(i_weight_valid), .i_data_valid(i_data_valid),
//        .i_weight_data(i_weight_data), .i_all_windows(i_all_windows),
//        .o_data(o_data), .o_data_valid(o_data_valid)
//    );

//    // Clock 100MHz
//    always #5 clk = ~clk;

//    initial begin
//        // --- Bước 1: Khởi tạo ---
//        clk = 0; rst_n = 0; i_en = 0; 
//        i_weight_valid = 0; i_data_valid = 0;
//        i_weight_data = 0; i_all_windows = 0;
        
//        #25 rst_n = 1; i_en = 1; // Bật hệ thống
//        #10;

//        // --- Bước 2: Truyền Weight (1 chu kỳ duy nhất) ---
//    // --- Bước 2: Nạp Weight trong 4 chu kỳ liên tiếp ---
//        @(posedge clk);
//        i_weight_valid = 1;
//        i_data_valid = 0; // Đảm bảo data_valid tắt
    
//        for (w_idx = 0; w_idx < 2; w_idx = w_idx + 1) begin
//            // Chu kỳ 1: CH 0-3, Chu kỳ 2: CH 4-7...
//            for (c_idx = 0; c_idx < 4; c_idx = c_idx + 1) begin
//                for (p_idx = 0; p_idx < 9; p_idx = p_idx + 1) begin
//                    i_weight_data[(c_idx*144 + p_idx*16) +: 16] = 16'd1024; 
//                end
//            end
//            @(posedge clk); // Đợi nhịp tiếp theo để nạp 4 CH kế tiếp
//        end          
            
//        i_weight_valid = 0; // Xong 8 chu kỳ thì tắt
        
//        #10;
        
//        for (w_idx = 1; w_idx <= 6; w_idx = w_idx + 1) begin
//            @(posedge clk);
//            i_data_valid = 1;
//            for (c_idx = 0; c_idx < 16; c_idx = c_idx + 1) begin
//                for (p_idx = 0; p_idx < 9; p_idx = p_idx + 1) begin
//                    // Giả sử mỗi window có giá trị pixel tăng dần để dễ phân biệt
//                    // Window 1: pixels = 1.0, Window 2: pixels = 2.0...
//                    i_all_windows[(c_idx*144 + p_idx*16) +: 16] = w_idx * 1024; 
//                end
//            end
//            $display("T=%t | Dang truyen Window thu %d", $time, w_idx);
//        end
        
//        @(posedge clk);
//        i_data_valid = 0;
//        i_all_windows = 0;

        
//        #20;
        
//         @(posedge clk);
//        i_weight_valid = 1;
//        i_data_valid = 0; // Đảm bảo data_valid tắt
    
//        for (w_idx = 0; w_idx < 4; w_idx = w_idx + 1) begin
//            // Chu kỳ 1: CH 0-3, Chu kỳ 2: CH 4-7...
//            for (c_idx = 0; c_idx < 4; c_idx = c_idx + 1) begin
//                for (p_idx = 0; p_idx < 9; p_idx = p_idx + 1) begin
//                    i_weight_data[(c_idx*144 + p_idx*16) +: 16] = 16'd1024; 
//                end
//            end
//            @(posedge clk); // Đợi nhịp tiếp theo để nạp 4 CH kế tiếp
//        end         
//        i_weight_valid =0;
//        // --- Bước 3: Truyền Data 6 chu kỳ liên tiếp (Trượt 6 lần) ---
//        // Tại mỗi cạnh lên của clock, một Window mới (9 pixels x 16 CH) được đẩy vào
//        for (w_idx = 1; w_idx <= 8; w_idx = w_idx + 1) begin
//            @(posedge clk);
//            i_data_valid = 1;
//            for (c_idx = 0; c_idx < 16; c_idx = c_idx + 1) begin
//                for (p_idx = 0; p_idx < 9; p_idx = p_idx + 1) begin
//                    // Giả sử mỗi window có giá trị pixel tăng dần để dễ phân biệt
//                    // Window 1: pixels = 1.0, Window 2: pixels = 2.0...
//                    i_all_windows[(c_idx*144 + p_idx*16) +: 16] = w_idx * 1024; 
//                end
//            end
//            $display("T=%t | Dang truyen Window thu %d", $time, w_idx);
//        end

//        // Sau 6 chu kỳ liên tiếp, ngắt i_data_valid
//        @(posedge clk);
//        i_data_valid = 0;
//        i_all_windows = 0;

//        // Đợi kết quả "chảy" ra hết (5 chu kỳ latency)
//        #200;
//        $display("Mo phong hoan tat!");
//        $stop;
//    end

//    // Monitor kết quả
//    always @(posedge clk) begin
//        if (o_data_valid) begin
//            $display("T=%t | KET QUA RA | CH0: %d", $time, o_data[15:0]);
//        end
//    end

//endmodule




module tb_Depthwise_Top();

    // -----------------------------------------------------------
    // 1. KHAI BÁO TÍN HIỆU (SIGNALS)
    // -----------------------------------------------------------
    reg clk;
    reg rst_n;
    reg i_en;
    
    reg i_weight_valid;
    reg [575:0] i_weight_data; 
    
    reg i_data_valid;
    reg [2303:0] i_all_windows;
    
    // Tín hiệu ngõ ra
    wire o_data_valid;
    wire [255:0] o_data; // 16 channel * 16 bits = 256 bits

    // -----------------------------------------------------------
    // 2. KHỞI TẠO MODULE CẦN TEST (DUT - Device Under Test)
    // -----------------------------------------------------------
    Depthwise_Core_Top uut (
        .clk(clk),
        .rst_n(rst_n),
        .i_en(i_en),
        .i_weight_valid(i_weight_valid),
        .i_weight_data(i_weight_data),
        .i_data_valid(i_data_valid),
        .i_all_windows(i_all_windows),
        .o_data_valid(o_data_valid),
        .o_data(o_data)
    );

    // -----------------------------------------------------------
    // 3. TẠO XUNG CLOCK (100MHz -> Chu kỳ 10ns)
    // -----------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // -----------------------------------------------------------
    // 4. CÁC TASK HỖ TRỢ TEST (TASKS)
    // -----------------------------------------------------------
    
    // Task 1: Nạp toàn bộ 16 channel Weight (Mất 4 nhịp clock)
    task load_all_weights;
        input [15:0] w_val; // Giá trị gán chung cho dễ test
        integer i;
        begin
            @(posedge clk);
            i_weight_valid = 1;
            // Nạp 4 lần (mỗi lần 4 channel, mỗi channel 9 cục weight)
            for (i = 0; i < 4; i = i + 1) begin
                // Gán tất cả các bit của i_weight_data bằng giá trị w_val lặp lại
                i_weight_data = {36{w_val}}; 
                @(posedge clk);
            end
            i_weight_valid = 0;
            i_weight_data = 0;
            $display("[%0t] DA NAP XONG WEIGHT: Gia tri = %d", $time, w_val);
        end
    endtask

    // Task 2: Gửi 1 Window Data
    task send_single_window;
        input [15:0] d_val; 
        begin
            @(posedge clk);
            i_data_valid = 1;
            // Gán 144 pixel (16x9) bằng cùng 1 giá trị d_val
            i_all_windows = {144{d_val}};
            @(posedge clk);
            i_data_valid = 0;
            i_all_windows = 0;
        end
    endtask

    // -----------------------------------------------------------
    // 5. KỊCH BẢN KIỂM THỬ CHÍNH (MAIN TEST SEQUENCE)
    // -----------------------------------------------------------
    initial begin
        // Khởi tạo trạng thái ban đầu
        rst_n = 0;
        i_en = 0;
        i_weight_valid = 0;
        i_weight_data = 0;
        i_data_valid = 0;
        i_all_windows = 0;

        // [TEST 1] Reset Hệ thống
        #20;
        rst_n = 1;
        i_en = 1;
        $display("[%0t] TEST 1: He thong da Reset va Enable.", $time);
        #20;

        // [TEST 2] Nạp Weight (Sử dụng giá trị 1 để dễ nhẩm: P*1 = P)
        load_all_weights(16'd1024);
        #30;

        // [TEST 3] Basic Data Flow & Latency (Đo trễ)
        $display("[%0t] TEST 3: Gui 1 Window doc lap (Gia tri = 1).", $time);
        // Nếu pixel=5, weight=1 -> Tổng 9 ô = 45. Làm tròn Q5.10 -> (45 + 0)
        send_single_window(16'd1024);
//        #10;
        send_single_window(16'd2048);
        send_single_window(16'd3072);
//        #10; 
//        i_data_valid =0;
        send_single_window(16'd4096);
//        #10;
//        i_data_valid = 0;
        // Đợi một khoảng thời gian để xem o_data_valid bật lên ở nhịp thứ mấy
        #300;

//        // [TEST 4] Pipeline Stall (Test chân CE đóng băng)
//        $display("[%0t] TEST 4: Chay lien tuc roi ngat dot ngot (Stall Pipeline).", $time);
//        @(posedge clk);
//        i_data_valid = 1;
//        i_all_windows = {144{16'd1024}}; // Cửa sổ 1
//        @(posedge clk);
//        i_all_windows = {144{16'd2048}}; // Cửa sổ 2
//        @(posedge clk);
//        i_all_windows = {144{16'd3072}}; // Cửa sổ 3
        
//        // Đóng băng toàn bộ hệ thống ngay lập tức!
//        @(posedge clk);
//        i_data_valid = 0;
//        $display("[%0t] >> DONG BANG PIPELINE TRONG 5 NHIP!", $time);
//        #50; 
        
//        // Mở lại và đẩy cửa sổ 4
//        @(posedge clk);
//        i_data_valid = 1;
//        i_all_windows = {144{16'd4096}}; // Cửa sổ 4
//        @(posedge clk);
//        i_data_valid = 0;
//        i_all_windows = 0;
//        #100;

//        // [TEST 5] Positive Overflow (Test Tràn Dương)
//        $display("[%0t] TEST 5: Test Saturation Tran Duong.", $time);
//        // Nạp Weight cực lớn (VD: 1000)
//        load_all_weights(16'd1024);
//        #20;
//        // Bơm Pixel cực lớn (VD: 1000) -> 1000 * 1000 * 9 = 9,000,000 (Chắc chắn tràn số Q5.10)
//        send_single_window(16'd1024);
//        #100;

        $display("[%0t] ========= KET THUC SIMULATION =========", $time);
        $stop; // Dừng mô phỏng
    end

endmodule