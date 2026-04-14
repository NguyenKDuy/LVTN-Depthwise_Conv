`timescale 1ns / 1ps

module tb_mem_img();

    // --- Parameters ---
    parameter ADDR_W    = 12; // Ð?a ch? hàng v?t l? (4096 hàng)
    parameter ADDR_R    = 14; // Ð?a ch? c?m 16-bit (16384 c?m)
    parameter DATA_W    = 64;
    parameter NUM_BANKS = 6;
    parameter SUB_W     = 16;
    parameter LATENCY   = 3;
    parameter CLK_P     = 10;

    // --- Signals ---
    reg                     clk;
    reg [ADDR_W-1:0]        wr_addr;
    reg [(DATA_W*NUM_BANKS)-1:0] wr_data_all;
    reg [NUM_BANKS-1:0]     wr_en_mask;
    reg [ADDR_R-1:0]        rd_addr;
    reg [NUM_BANKS-1:0]     rd_enb;
    wire [(SUB_W*NUM_BANKS)-1:0] o_data_all;

    // --- Instantiate UUT ---
    mem_img #(
        .ADDR_W(ADDR_W), .ADDR_R(ADDR_R), .DATA_W(DATA_W), 
        .NUM_BANKS(NUM_BANKS), .SUB_W(SUB_W), .LATENCY(LATENCY)
    ) uut (
        .i_clk(clk), 
        .i_wr_addr(wr_addr), 
        .i_wr_data_all(wr_data_all),
        .i_wr_en_mask(wr_en_mask), 
        .i_rd_addr(rd_addr), 
        .i_rd_enb(rd_enb),
        .o_data_all(o_data_all)
    );

    // --- Clock Generation ---
    initial clk = 0;
    always #(CLK_P/2) clk = ~clk;

    integer i, b;

    // --- Main Test Process ---
    initial begin
        // Reset ban ð?u (S? d?ng <= ð? ð?ng b?)
        wr_addr     <= 0;
        wr_data_all <= 0;
        wr_en_mask  <= 0;
        rd_addr     <= 0;
        rd_enb      <= 0;
        #(CLK_P * 5);

        // --- PHASE 1: Ghi d? li?u ð?nh danh (Identify Pattern) ---
        // M?i c?m 16-bit s? lýu: [RowAddr(12-bit)][SubIndex(4-bit)]
        $display("--- STARTING WRITE PHASE (4096 ROWS) ---");
        for (i = 0; i < 4096; i = i + 1) begin
            @(posedge clk);
            wr_en_mask <= 6'b111111;
            wr_addr    <= i;
            
            for (b = 0; b < NUM_BANKS; b = b + 1) begin
                wr_data_all[b*64 +: 64] <= { {i[11:0], 4'h3},  // Sub 3
                                             {i[11:0], 4'h2},  // Sub 2
                                             {i[11:0], 4'h1},  // Sub 1
                                             {i[11:0], 4'h0}   // Sub 0
                                           };
            end
        end

        @(posedge clk);
        wr_en_mask <= 0;
        #(CLK_P * 10);

        // --- PHASE 2: Ð?c liên t?c (Burst Read) ---
        $display("--- STARTING READ PHASE (BURST) ---");
        rd_enb <= 6'b111111;
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk);
            rd_addr <= i; // Ð?a ch? logic ch?y t? 0 ð?n 99
        end

        @(posedge clk);
        rd_enb <= 0;
        #(CLK_P * 20);
        $display("--- TESTBENCH FINISHED ---");
        $finish;
    end

    // --- Monitor & Pipeline Check ---
    // T?o m?ng delay ð? theo d?i ð?a ch? ð? c?p cách ðây LATENCY chu k?
    reg [ADDR_R-1:0] rd_addr_pipe [0:LATENCY];
    
    // --- Khai báo ngoài kh?i always ---
    integer j; // Khai báo j ? ðây
    reg [ADDR_R-1:0] delayed_addr; // Khai báo delayed_addr ? ðây

    always @(posedge clk) begin
        // C?p nh?t Pipeline ð?a ch?
        rd_addr_pipe[0] <= rd_addr;
        for (j = 1; j <= LATENCY; j = j + 1) begin
            rd_addr_pipe[j] <= rd_addr_pipe[j-1];
        end
        
        // Logic ki?m tra d? li?u
        // N?u LATENCY = 3: 
        // RD_ADDR (T0) -> pipe[0](T1) -> pipe[1](T2) -> pipe[2](T3) -> DATA_OUT(T3)
        // V?y t?i th?i ði?m DATA xu?t hi?n, ta l?y pipe[LATENCY-1]
        delayed_addr = rd_addr_pipe[LATENCY-1]; 

        if ($time > (4100 * CLK_P)) begin
            if (o_data_all[15:0] !== 16'bx) begin
                $display("Time:%0t | ReadAddr:%0d | Expected:Row %0d, Sub %0d | Bank0_Data:%h", 
                         $time, delayed_addr, 
                         delayed_addr[ADDR_R-1:2], // Row
                         delayed_addr[1:0],        // Sub
                         o_data_all[SUB_W-1:0]);
            end
        end
    end

endmodule