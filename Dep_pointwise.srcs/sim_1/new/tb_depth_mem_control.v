`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/08/2026 09:33:56 PM
// Design Name: 
// Module Name: tb_depth_mem_control
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


module tb_depth_mem_control;
// 1. Khai báo tín hi?u
    reg i_clk;
    reg i_rst_n;
    reg [3:0] i_stage;
    reg [63:0] i_data;
    reg i_dready;
    
    wire [14:0] o_r_address;
    wire o_r_enable;
    wire [143:0] o_data;
    wire o_valid;

    // Ð?nh ngh?a các Stage (kh?p v?i code c?a b?n)
    localparam IDLE = 'd0, HEAD = 'd1, DOWNS1 = 'd2;

    // 2. Kh?i t?o Unit Under Test (UUT)
    depth_mem_control uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_stage(i_stage),
        .i_data(i_data),
        .i_dready(i_dready),
        .o_r_address(o_r_address),
        .o_r_enable(o_r_enable),
        .o_data(o_data),
        .o_valid(o_valid)
    );

    // 3. T?o Clock (100MHz)
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // 4. Gi? l?p SRAM (Mock RAM)
    // RAM này s? tr? v? d? li?u d?a trên ð?a ch? o_r_address
    // Thêm m?t chút delay ð? mô ph?ng th?c t? (D? li?u v? sau 1 nh?p clock)
    always @(posedge i_clk) begin
        if (o_r_enable)
            // Tr? v? d? li?u có quy lu?t ð? d? ki?m tra: 
            // Ví d?: Ð?a ch? 1 tr? v? 0x1, Ð?a ch? 2 tr? v? 0x2...
            i_data <= {48'h0, 1'b1, o_r_address}; 
        else
            i_data <= 64'hX;
    end

    // 5. K?ch b?n mô ph?ng (Stimulus)
    initial begin
        // --- Bý?c 1: Kh?i t?o ---
        i_rst_n = 0;
        i_stage = IDLE;
        i_dready = 0;
        #25;
        i_rst_n = 1;
        #20;

        // --- Bý?c 2: Ch?y Stage HEAD ---
        $display(">>> Bat dau Stage HEAD...");
        i_stage = HEAD;
        
        // Ch? cho ð?n khi o_valid lên 1 (Buffer ð?y)
        wait(o_valid == 1);
        #15;
        
        // Gi? l?p module phía sau s?n sàng nh?n d? li?u (Handshake)
        i_dready = 1;
        #10;
        i_dready = 0; // Nh?n 1 nh?p r?i ngh? ð? xem buffer tr?ng
        #30;
        i_dready = 1; // Ti?p t?c nh?n

        // --- Bý?c 3: Ch? n?p h?t HEAD và quan sát Reset ð?a ch? ---
        // HEAD_CH là 15, týõng ðýõng n?p 16 channels. 
        // M?i channel m?t kho?ng 4-5 nh?p clock.
        repeat (100) @(posedge i_clk);

        // --- Bý?c 4: Chuy?n sang Stage DOWNS1 ---
        $display(">>> Chuyen sang Stage DOWNS1...");
        i_stage = DOWNS1;
        i_dready = 0;
        
        repeat (50) @(posedge i_clk);
        i_dready = 1;

        // --- Bý?c 5: K?t thúc ---
        #500;
        $display(">>> Mo phong ket thuc.");
        $finish;
    end

    // 6. Theo d?i d? li?u (Monitor)
    initial begin
        $monitor("Time: %0t | Stage: %d | Addr: %d | Valid: %b | Data: %h", 
                 $time, i_stage, o_r_address, o_valid, o_data);
    end

endmodule
