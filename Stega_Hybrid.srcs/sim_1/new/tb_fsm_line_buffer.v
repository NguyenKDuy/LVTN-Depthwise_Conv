// =============================================================================
// Testbench: tb_fsm_line_buffer
//
// Flow ðúng cho 128x128, padding=1:
//   max_line_in  = 130  (1 PRE + 128 DATA + 1 POST)
//   max_line_out = 130
//
//   Hàng TOP PAD:  130 pixel, padding_vld=1, config_padding=111
//   Hàng data r:   1 pixel PRE  (padding_vld=1, config=100)
//                  128 pixel DATA (data_vld=1,   config=000)
//                  1 pixel POST (padding_vld=1, config=001)
//   Hàng BOT PAD:  130 pixel, padding_vld=1, config_padding=111
//
// Test cases:
//   Test 1: 128x128, Stride=1, Padding=1
//   Test 2: 128x128, Stride=2, Padding=1
//   Test 3: Multi-layer reset - Layer A stride=1, Layer B stride=2
//
// Data pattern: pixel[row][col] = row*128 + col + 1 (s? tãng d?n, d? check tay)
// =============================================================================
`timescale 1ns/1ps

module tb_fsm_line_buffer;

    // =========================================================================
    // Parameters
    // =========================================================================
    parameter CLK_PERIOD  = 3.3;        // ~300 MHz
    parameter IMG_W       = 128;
    parameter IMG_H       = 128;
    parameter LINE_IN     = IMG_W;  // 130: 1 PRE + 128 DATA + 1 POST
    parameter LINE_OUT    = IMG_W;  // 130
    parameter DATA_W      = 256;        // 16ch x 16bit
    parameter KERNEL_W    = 2304;
    parameter CHANNELS    = 16;

    // =========================================================================
    // DUT Ports
    // =========================================================================
    reg                  clk;
    reg                  rst_n;
    reg                  enable;
    reg                  data_vld;
    reg                  padding_vld;
    reg  [1:0]           config_stride;
    reg  [2:0]           config_padding;
    reg  [7:0]           config_max_line_in;
    reg  [7:0]           config_max_line_out;
    reg  [DATA_W-1:0]    data_in;
    wire [KERNEL_W-1:0]  kernel_data;
    wire                 kernel_vld;

    // =========================================================================
    // DUT
    // =========================================================================
    fsm_line_buffer #(
        .DATA_IN_W (DATA_W),
        .KERNEL_W  (KERNEL_W)
    ) dut (
        .i_clk                (clk),
        .i_rst_n              (rst_n),
        .i_enable             (enable),
        .i_data_vld           (data_vld),
        .i_padding_vld        (padding_vld),
        .i_config_stride      (config_stride),
        .i_config_padding     (config_padding),
        .i_config_max_line_in (config_max_line_in),
        .i_config_max_line_out(config_max_line_out),
        .i_data_in            (data_in),
        .o_kernel_data        (kernel_data),
        .o_kernel_vld         (kernel_vld)
    );

    // =========================================================================
    // Clock
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2.0) clk = ~clk;

    // =========================================================================
    // Counters
    // =========================================================================
    integer kernel_count;
    integer error_count;
    integer bubble_count;
    integer last_vld_cycle;
    integer cur_cycle;

    initial begin
        kernel_count   = 0;
        error_count    = 0;
        bubble_count   = 0;
        last_vld_cycle = 0;
        cur_cycle      = 0;
    end

    always @(posedge clk) cur_cycle = cur_cycle + 1;

    // =========================================================================
    // Helper: T?o pixel word 256-bit - t?t c? channel mang cùng giá tr? 16-bit
    // =========================================================================
    function [DATA_W-1:0] make_pixel;
        input [15:0] val;
        integer ch;
        reg [DATA_W-1:0] w;
        begin
            w = 0;
            for (ch = 0; ch < CHANNELS; ch = ch + 1)
                w[ch*16 +: 16] = val;
            make_pixel = w;
        end
    endfunction

    // Helper: ð?c channel 0 t? 256-bit word
    function [15:0] ch0;
        input [DATA_W-1:0] word;
        begin ch0 = word[15:0]; end
    endfunction

    // =========================================================================
    // Task: Reset
    // =========================================================================
    task apply_reset;
        begin
            rst_n          <= 1'b0;
            enable         <= 1'b0;
            data_vld       <= 1'b0;
            padding_vld    <= 1'b0;
            config_padding <= 3'b000;
            data_in        <= {DATA_W{1'b0}};
            repeat(4) @(posedge clk);
            rst_n  <= 1'b1;
            enable <= 1'b1;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: G?i 1 pixel DATA
    // =========================================================================
    task send_data_pixel;
        input [DATA_W-1:0] pix;
        begin
            
            data_vld       <= 1'b1;
            padding_vld    <= 1'b0;
            config_padding <= 3'b000;
            data_in        <= pix;
//            data_vld       <= 1'b0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: G?i 1 pixel PADDING
    //   pad_type: 3'b111=PAD_ROW, 3'b100=PRE(trái), 3'b001=POST(ph?i)
    // =========================================================================
    task send_pad_pixel;
        input [2:0] pad_type;
        begin
            
            data_vld       <= 1'b0;
            padding_vld    <= 1'b1;
            config_padding <= pad_type;
            data_in        <= {DATA_W{1'b0}};
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: G?i 1 hàng PAD ROW (LINE_IN pixel, t?t c? type=111)
    // =========================================================================
    task send_pad_row;
        integer p;
        begin
            for (p = 0; p < 1; p = p + 1)
                send_pad_pixel(3'b111);
        end
    endtask

    // =========================================================================
    // Task: G?i 1 hàng data v?i PRE + DATA + POST
    //   row: index hàng (0-based) ð? tính giá tr? pixel tãng d?n
    // =========================================================================
    task send_data_row;
        input integer row;
        integer col;
        reg [15:0] val;
        begin
            // PRE pad pixel (trái) - pixel 0 c?a hàng
            send_pad_pixel(3'b100);
            
            // 128 DATA pixels: val = row*IMG_W + col + 1
            for (col = 0; col < IMG_W; col = col + 1) begin
                val = row * IMG_W + col + 1;
                send_data_pixel(make_pixel(val));
                padding_vld    <= 1'b0;
                config_padding <= 3'b000;
            end

            // POST pad pixel (ph?i) - pixel 129 c?a hàng
            send_pad_pixel(3'b001);
        end
    endtask

    // =========================================================================
    // Task: G?i toàn b? ?nh 128x128 v?i padding=1
    //   T?ng pixel g?i: 130 + 128*130 + 130 = 16900 pixel
    // =========================================================================
    task send_full_image;
        integer row;
        begin
            send_pad_row();                                  // TOP PAD
            for (row = 0; row < IMG_H; row = row + 1)
                send_data_row(row);                          // PRE+DATA+POST
            send_pad_row();                                  // BOT PAD
        end
    endtask

    // =========================================================================
    // Monitor: in kernel output và detect bubble
    // =========================================================================
    always @(posedge clk) begin
        if (kernel_vld) begin
            kernel_count = kernel_count + 1;

            // Detect bubble (stride=1 không ðý?c có gap > 1 cycle)
            if (config_stride == 2'd1 && last_vld_cycle != 0 &&
                (cur_cycle - last_vld_cycle) > 1) begin
                bubble_count = bubble_count + 1;
                $display("[WARN] Bubble kernel #%0d, gap=%0d cycles",
                         kernel_count, cur_cycle - last_vld_cycle);
            end
            last_vld_cycle = cur_cycle;

            // In 10 kernel ð?u + m?i 500 kernel
            if (kernel_count <= 128 || (kernel_count % 500 == 0)) begin
                $display("[K%05d] Row0:[%4d,%4d,%4d] Row1:[%4d,%4d,%4d] Row2:[%4d,%4d,%4d]",
                    kernel_count,
                    ch0(kernel_data[KERNEL_W-1         : KERNEL_W-1*DATA_W]),
                    ch0(kernel_data[KERNEL_W-1*DATA_W-1 : KERNEL_W-2*DATA_W]),
                    ch0(kernel_data[KERNEL_W-2*DATA_W-1 : KERNEL_W-3*DATA_W]),
                    ch0(kernel_data[KERNEL_W-3*DATA_W-1 : KERNEL_W-4*DATA_W]),
                    ch0(kernel_data[KERNEL_W-4*DATA_W-1 : KERNEL_W-5*DATA_W]),
                    ch0(kernel_data[KERNEL_W-5*DATA_W-1 : KERNEL_W-6*DATA_W]),
                    ch0(kernel_data[KERNEL_W-6*DATA_W-1 : KERNEL_W-7*DATA_W]),
                    ch0(kernel_data[KERNEL_W-7*DATA_W-1 : KERNEL_W-8*DATA_W]),
                    ch0(kernel_data[KERNEL_W-8*DATA_W-1 : KERNEL_W-9*DATA_W])
                );
            end
        end
    end

    // =========================================================================
    // Task: Ch? kernel outputs + báo cáo
    // =========================================================================
    task wait_and_report;
        input integer         expected_kernels;
        input reg [8*40-1:0]  test_name;
        integer timeout;
        begin
            timeout        = 0;
            kernel_count   = 0;
            bubble_count   = 0;
            last_vld_cycle = 0;

            while (kernel_count < expected_kernels && timeout < 10_000_000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            repeat(20) @(posedge clk);

            $display("----------------------------------------------------");
            $display("[%0s]", test_name);
            $display("  Kernels : %0d / %0d  %0s",
                     kernel_count, expected_kernels,
                     (kernel_count == expected_kernels) ? "PASS" : "FAIL");
            $display("  Bubbles : %0d  %0s",
                     bubble_count,
                     (bubble_count == 0) ? "PASS" : "WARN");
            if (kernel_count != expected_kernels) error_count = error_count + 1;
            $display("----------------------------------------------------");
        end
    endtask

    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    initial begin
        $dumpfile("tb_fsm_line_buffer.vcd");
        $dumpvars(0, tb_fsm_line_buffer);

        // Defaults
        config_stride       = 2'd1;
        config_padding      = 3'b000;
        config_max_line_in  = LINE_IN[7:0];   // 130
        config_max_line_out = LINE_OUT[7:0];  // 130
        error_count         = 0;

        // =================================================================
        // TEST 1: Stride=1, 128x128, padding=1
        // (128+2-3+1) x (128+2-3+1) = 128 x 128 = 16384 kernels
        // =================================================================
        $display("\n===== TEST 1: Stride=1, 128x128, padding=1 =====");
        apply_reset();
        config_stride = 2'd1;
        fork
            send_full_image();
            wait_and_report(16384, "TEST1 Stride=1 128x128 pad=1");
        join

        // =================================================================
        // TEST 2: Stride=2, 128x128, padding=1
        // floor((128+2-3)/2)+1 = 64 kernels/row x 64 rows = 4096 kernels
        // =================================================================
        $display("\n===== TEST 2: Stride=2, 128x128, padding=1 =====");
        apply_reset();
        config_stride = 2'd2;
        fork
            send_full_image();
            wait_and_report(4096, "TEST2 Stride=2 128x128 pad=1");
        join

        // =================================================================
        // TEST 3: Multi-layer (reset gi?a)
        // =================================================================
        $display("\n===== TEST 3: Multi-layer reset =====");

        $display("  [Layer A] Stride=1");
        apply_reset();
        config_stride = 2'd1;
        fork
            send_full_image();
            wait_and_report(16384, "TEST3 LayerA Stride=1");
        join

        $display("  --- Reset giua layer ---");
        apply_reset();

        $display("  [Layer B] Stride=2");
        config_stride = 2'd2;
        fork
            send_full_image();
            wait_and_report(4096, "TEST3 LayerB Stride=2");
        join

        // =================================================================
        // Summary
        // =================================================================
        $display("\n====================================================");
        $display("  TONG KET: %0d loi", error_count);
        if (error_count == 0)
            $display("  >>> TAT CA PASS <<<");
        else
            $display("  >>> CO %0d FAIL <<<", error_count);
        $display("====================================================\n");

        #100;
        $finish;
    end

    // Global timeout
    initial begin
        #1_000_000_000;
        $display("[TIMEOUT] Design bi treo!");
        $finish;
    end

endmodule