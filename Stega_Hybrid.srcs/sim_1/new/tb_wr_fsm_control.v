`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/10/2026 05:42:36 PM
// Design Name: 
// Module Name: tb_wr_fsm_control
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

module tb_wr_fsm_control;

    // --- Parameters ---
    parameter DATA_COMPUTED_W = 512;
    parameter ADDR_URAM_W     = 12;
    parameter ADDR_STEGA_W    = 14;
    parameter STAGE_W         = 4;

    // --- Localparams (Kh?p hoàn toàn v?i Module c?a Duy) ---
    localparam HEAD   = 4'd1,  DOWNS1 = 4'd2,  DOWNS2 = 4'd3,  DOWNS3 = 4'd4, 
               BOTT   = 4'd5,  UPS1   = 4'd6,  UPS2   = 4'd7,  UPS3   = 4'd8, 
               UPS4   = 4'd9,  TAIL   = 4'd10, DONE   = 4'd11;

    // --- Inputs (Reg) ---
    reg                     i_clk;
    reg                     i_rst_n;
    reg [DATA_COMPUTED_W-1:0] i_computed_data;
    reg                     i_vld;
    reg [STAGE_W-1:0]       i_stage;

    // --- Outputs (Wire) ---
    wire [15:0]             o_wr_mem0_ena;
    wire [7:0]              o_wr_mem1_ena, o_wr_mem2_ena, o_wr_mem3_ena, o_wr_mem4_ena, o_wr_mem5_ena;
    wire [2:0]              o_wr_mem_stega_ena;

    wire [ADDR_URAM_W-1:0]  o_wr_mem0_addr, o_wr_mem1_addr, o_wr_mem2_addr, o_wr_mem3_addr, o_wr_mem4_addr, o_wr_mem5_addr;
    wire [ADDR_STEGA_W-1:0] o_wr_mem_stega_addr;
    wire [DATA_COMPUTED_W-1:0] o_computed_data_out;

    // --- Clock Generation (100MHz) ---
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // --- Unit Under Test (UUT) ---
    wr_fsm_control #(
        .DATA_COMPUTED_W(DATA_COMPUTED_W),
        .ADDR_URAM_W(ADDR_URAM_W),
        .ADDR_STEGA_W(ADDR_STEGA_W),
        .STAGE_W(STAGE_W)
    ) uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_computed_data(i_computed_data),
        .i_vld(i_vld),
        .i_stage(i_stage),
        .o_wr_mem0_ena(o_wr_mem0_ena),
        .o_wr_mem1_ena(o_wr_mem1_ena),
        .o_wr_mem2_ena(o_wr_mem2_ena),
        .o_wr_mem3_ena(o_wr_mem3_ena),
        .o_wr_mem4_ena(o_wr_mem4_ena),
        .o_wr_mem5_ena(o_wr_mem5_ena),
        .o_wr_mem_stega_ena(o_wr_mem_stega_ena),
        .o_wr_mem0_addr(o_wr_mem0_addr),
        .o_wr_mem1_addr(o_wr_mem1_addr),
        .o_wr_mem2_addr(o_wr_mem2_addr),
        .o_wr_mem3_addr(o_wr_mem3_addr),
        .o_wr_mem4_addr(o_wr_mem4_addr),
        .o_wr_mem5_addr(o_wr_mem5_addr),
        .o_wr_mem_stega_addr(o_wr_mem_stega_addr),
        .o_computed_data(o_computed_data_out)
    );

    // --- Smart Task for Flexible Simulation ---
    task write_block(
        input [3:0] stage_id,
        input integer loops,      // S? l?n l?p (ví d? 4 d?ng)
        input integer burst_len,  // S? nh?p vld=1 liên t?c (ví d? 8 pixel)
        input integer wait_len    // S? nh?p ngh? vld=0 gi?a các d?ng
    );
        integer l, b, w;
        begin
            i_stage <= stage_id;
            for (l = 0; l < loops; l = l + 1) begin
                // Truy?n d? li?u
                for (b = 0; b < burst_len; b = b + 1) begin
                    @(posedge i_clk);
                    i_vld <= 1;
                    i_computed_data <= i_computed_data + 1;
                end
                // Kho?ng ngh?
                for (w = 0; w < wait_len; w = w + 1) begin
                    @(posedge i_clk);
                    i_vld <= 0;
                end
            end
            i_vld <= 0;
            repeat(2) @(posedge i_clk);
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        // Init
        i_rst_n = 0;
        i_vld   = 0;
        i_stage = 0;
        i_computed_data = 512'h0;

        // Reset
        #50;
        i_rst_n <= 1;
        #20;

        $display("--- Bat dau Test full module ---");

        // 1. Test HEAD: Ghi 4 dot, moi dot 4 word, nghi 2 nhip
        $display("Testing HEAD...");
        write_block(HEAD, 4096, 4, 0);

        // 2. Test DOWNS1
        $display("Testing DOWNS1...");
        write_block(DOWNS1, 4096, 2, 0);
        $display("Testing DOWNS2...");
        write_block(DOWNS2, 1024, 2, 0);
        $display("Testing DOWNS3...");
        write_block(DOWNS3, 256, 4, 0);
        $display("Testing BOTT...");
        write_block(BOTT, 64, 4, 0);

        // 3. Test UPS1 (Kiem tra Swap Bank trong code Duy)
        $display("Testing UPS1...");
        write_block(UPS1, 256, 4, 4);
        $display("Testing UPS2...");
        write_block(UPS2, 1024, 2, 2);
        $display("Testing UPS3...");
        write_block(UPS3, 4096, 2, 2);

        // 4. Test UPS4 (Stage phuc tap ghi nhieu Mem)
        $display("Testing UPS4...");
        write_block(UPS4, 4096, 4, 2);

        // 5. Test TAIL (Kiem tra dich bit l? ena)
        $display("Testing TAIL...");
        write_block(TAIL, 4096, 4, 2);

        // 6. Test DONE
        $display("Testing DONE...");
        write_block(DONE, 16384, 1, 0);

        #500;
        $display("--- Simulation Hoan tat ---");
        $finish;
    end

    // --- Monitor (Optional) ---
    initial begin
        $monitor("Time: %0t | Stage: %d | Addr0: %d | Ena0: %h", 
                 $time, i_stage, o_wr_mem0_addr, o_wr_mem0_ena);
    end

endmodule
