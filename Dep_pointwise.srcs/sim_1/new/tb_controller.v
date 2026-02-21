////`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////
////// Company: 
////// Engineer: 
////// 
////// Create Date: 01/28/2026 09:33:29 PM
////// Design Name: 
////// Module Name: tb_controller
////// Project Name: 
////// Target Devices: 
////// Tool Versions: 
////// Description: 
////// 
////// Dependencies: 
////// 
////// Revision:
////// Revision 0.01 - File Created
////// Additional Comments:
////// 
//////////////////////////////////////////////////////////////////////////////////////



//module tb_accelerator_file;

//    // =========================
//    // DUT signals
//    // =========================
//    reg         clk;
//    reg         i_rst_n;
//    reg  [15:0] data_in;
//    reg         i_data_valid;
//    wire [15:0] data_out;
//    wire [3:0] t_stage;
//    // =========================
//    // DUT
//    // =========================
//    accelerator dut (
//        .clk(clk),
//        .sreset_n(sreset_n),
//        .data_in(data_in),
//        .i_data_valid(i_data_valid),
//        .data_out(data_out),
//        .t_stage(t_stage)
//    );

//    // =========================
//    // Clock
//    // =========================
//    always #5 clk = ~clk;   // 100 MHz

//    // =========================
//    // File I/O
//    // =========================
//    integer fd;
//    integer r;
//    reg [7:0] file_byte;
//    integer idx;

//    // =========================
//    // Stimulus
//    // =========================
//    initial begin
//        $display("=== STREAM TO MEMORY TEST START ===");

//        clk          = 0;
//        i_rst_n     = 0;
//        data_in      = 0;
//        i_data_valid = 0;
//        idx          = 0;

//        #20;
//        i_rst_n = 1;
        
        
//        // Open binary file
//        fd = $fopen("16x16x3.bin", "rb");
//        if (fd == 0) begin
//            $fatal("Cannot open input file");
//        end

//        @(posedge clk);
//        i_data_valid = 1;

//        while (!$feof(fd)) begin
//            r = $fread(file_byte, fd);
            
//            data_in <= {8'd0, file_byte}; // byte -> 16-bit
//            idx = idx + 1;
//            if (idx == 'd769) i_data_valid = 0;
//            @(posedge clk);
//        end
        
        
//        idx          = 0;
        
//        fd = $fopen("16x16x3.bin", "rb");
//        if (fd == 0) begin
//            $fatal("Cannot open input file");
//        end

//        @(posedge clk);
//        i_data_valid = 1;

//        while (!$feof(fd)) begin
//            r = $fread(file_byte, fd);
            
//            data_in <= {8'd0, file_byte}; // byte -> 16-bit
//            idx = idx + 1;
//            if (idx == 'd769) i_data_valid = 0;
//            @(posedge clk);
//        end

//        @(posedge clk);
//        $fclose(fd);

//        #50;
//        $display("Total bytes written = %0d", idx);
//        $display("=== TEST END ===");
//        $finish;
//    end

//    // =========================
//    // Monitor
//    // =========================
////    always @(posedge clk) begin
////        if (i_data_valid) begin
////            $display(
////                "t=%0t | addr=%0d | data_in=%h | mem_data=%h",
////                $time,
////                dut.wr_addr,
////                data_in,
////                data_out
////            );
////        end
////    end

//endmodule

`timescale 1ns / 1ps

module tb_accelerator_file;

    // =========================
    // Parameters & Defines
    // =========================
    parameter PIXEL_WIDTH = 16;
    parameter DATA_WIDTH  = PIXEL_WIDTH * 4; // 64 bits
    parameter NUM_WEIGHTS = 2030;

    // =========================
    // DUT signals
    // =========================
    reg                     clk;
    reg                     i_rst_n;
    reg  [DATA_WIDTH-1 : 0] data_in;
    reg                     i_data_valid;
    reg                     i_ready;      // Fake for depthwise
    
    wire                    o_valid;      // Fake for depthwise
    wire [DATA_WIDTH-1 : 0] data_out1;
    wire [DATA_WIDTH-1 : 0] data_out2;
    wire [DATA_WIDTH-1 : 0] data_out3;
    wire [3:0]              t_stage;

    // =========================
    // DUT Instantiation
    // =========================
    accelerator dut (
        .clk(clk),
        .i_rst_n(i_rst_n),
        .data_in(data_in),
        .i_data_valid(i_data_valid),
        .i_ready(i_ready),
        .o_valid(o_valid),
        .data_out1(data_out1),
        .data_out2(data_out2),
        .data_out3(data_out3),
        .top_stage(top_stage)
    );

    // =========================
    // Clock Generation (100 MHz)
    // =========================
    initial clk = 0;
    always #5 clk = ~clk; 

    // =========================
    // File I/O & Stimulus
    // =========================
    integer fd;
    integer status;
    integer count;
    reg [63:0] weight_val; // Bi?n t?m ð? ð?c hex 64-bit
    
    initial begin
        // --- Kh?i t?o h? th?ng ---
        $display("=== STARTING WEIGHT LOADING TEST ===");
        i_rst_n      = 0;
        data_in      = 0;
        i_data_valid = 0;
        i_ready      = 1; // Gi? l?p bên nh?n luôn s?n sàng
        count        = 0;
        #25;
        i_rst_n = 1;      // Gi?i phóng Reset
        #20;
        force dut.data_control.i_enable = 1'b1; // Ép giá tr? tr?c ti?p

    end
//        // --- M? file weight_ram.hex ---
//        // Lýu ?: File này ph?i ðý?c t?o b?i script Python trý?c ðó
//        fd = $fopen("weight_ram.hex", "r");
//        if (fd == 0) begin
//            $fatal(1, "ERROR: Khong tim thay file weight_ram.hex!");
//        end

//        @(posedge clk);

//        // --- V?ng l?p ð?c và n?p d? li?u ---
//        // S? d?ng $fscanf v?i ð?nh d?ng %h ð? ð?c chu?i Hex 64-bit
//        while (!$feof(fd) && count < NUM_WEIGHTS) begin
//            status = $fscanf(fd, "%h\n", weight_val);
            
//            if (status == 1) begin
//                i_data_valid <= 1;
//                data_in      <= weight_val;
//                count         = count + 1;
                
//                // Monitor m?i 500 d?ng ð? tránh lo?ng console
//                if (count % 500 == 0) 
//                    $display("Time: %0t | Da nap: %0d / 2030", $time, count);
//            end
            
//            @(posedge clk);
//        end

//        // --- K?t thúc n?p d? li?u ---
//        i_data_valid <= 0;
//        data_in      <= 0;
//        $fclose(fd);
        
//        $display("=== LOADING COMPLETED: %0d weights fed ===", count);

//        // Ch? m?t kho?ng th?i gian ð? xem output c?a accelerator x? l?
//        #200;
        
//        $display("=== TEST END ===");
//        $finish;
//    end
    // ========================================================
    // Logic Verification: So kh?p Golden Model
    // ========================================================
    integer fd_golden;
    integer gd_status;
    reg [319:0] golden_data_320;
    
    integer match_count = 0;
    integer error_count = 0;
    integer total_checks = 1920; // 1 Quarter

    // Gi? s? tín hi?u bên trong DUT Duy mu?n check là: 
    // dut.inst_head.line_buffer_concat (320 bit)
    // Ho?c b?t k? dây nào Duy ð? c?t bit týõng ?ng
    wire [319:0] current_dut_data = {dut.data_control.o_data[431:272], dut.data_control.o_data[159:0]}; 
    wire check_en = (top_stage == 4'd1); // Ch? check khi ðang ? stage HEAD

    initial begin
        // Ch? n?p weight xong ho?c ch? tín hi?u b?t ð?u ch?y stage 1
        wait(i_rst_n == 1);
        
        fd_golden = $fopen("head_data_golden_q0.hex", "r");
        if (fd_golden == 0) begin
            $display("ERROR: Khong mo duoc file golden model!");
        end

        // B? qua d?ng Header c?a file CSV (n?u có)
        // status = $fgets(dummy_str, fd_golden); 

        $display("--- Bat dau kiem tra Quarter 0 (1920 dia chi) ---");
    end

    // Clock check logic
    always @(posedge clk) begin
        // Ði?u ki?n ð? check: Stage HEAD ðang ch?y và có data valid bên trong
        if (check_en && o_valid && i_ready) begin 
            
            // Ð?c Golden Model: Format '%h_%h' ð? b? qua d?u g?ch dý?i
            // Lýu ?: Ph?i b? qua các c?t Q,T_Y... n?u Duy ð? chúng trong file
            // ? ðây m?nh gi? s? Duy ð? xu?t file ch? có c?t HEX ho?c dùng $fscanf b? c?t
            gd_status = $fscanf(fd_golden, "%h\n",golden_data_320);
            
//            golden_data_320 = {golden_ch_odd, golden_ch_even};

            if (gd_status > 0) begin
                if (current_dut_data === golden_data_320) begin
                    match_count = match_count + 1;
                    $display("[CORRECT] Time: %0t | %d/ 1920", $time, match_count);
                end else begin
                    error_count = error_count + 1;
                    $display("[ERROR] Time: %0t | Sai tai %0d/1920", $time, match_count + error_count);
                    $display("        DUT: %h", current_dut_data);
                    $display("        GOL: %h", golden_data_320);
                end
            end

            // K?t thúc 1 Quarter
            if ((match_count + error_count) == total_checks) begin
                $display("--------------------------------------------------");
                $display("QUARTER CHECK FINISHED:");
                $display("Result: %0d / %0d Correct", match_count, total_checks);
                $display("Errors: %0d", error_count);
                $display("--------------------------------------------------");
                $fclose(fd_golden);
//                @(posedge clk);
//                @(posedge clk);
//                force dut.data_control.i_pwdone = 1'd1;
//                @(posedge clk);
//                force dut.data_control.i_pwdone = 1'd0;
            end
        end
    end
    
//============================================================
//STAGE: DOWNS1 - quarter = 0
    
//    initial begin
//        // Ch? n?p weight xong ho?c ch? tín hi?u b?t ð?u ch?y stage 1
//        wait(top_stage == 'd2);
        
//        fd_golden = $fopen("downs1_golden.hex", "r");
//        if (fd_golden == 0) begin
//            $display("ERROR: Khong mo duoc file golden model downs1!");
//        end


//        $display("--- Bat dau kiem tra Quarter 0 (4352 dia chi/ qua) ---");
//    end
    
//    always @(posedge clk) begin
        
//    end


endmodule