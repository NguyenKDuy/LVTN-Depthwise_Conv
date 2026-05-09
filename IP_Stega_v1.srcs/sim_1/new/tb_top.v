`timescale 1ns / 1ps

module tb_top;

    parameter DATA_W = 64;
    reg i_clk, i_rst_n;

    // AXI-Stream Signals
    reg                     s_axis_tvalid;
    reg  [DATA_W-1:0]       s_axis_tdata;
    wire                    s_axis_tready;
    wire                    m_axis_tvalid;
    wire [DATA_W-1:0]       m_axis_tdata;
    reg                     m_axis_tready;

    // Buffers
    reg [DATA_W-1:0] mem_file0 [0:1691];   // Weights DW
    reg [DATA_W-1:0] mem_file1 [0:12543];  // Weights PW
    reg [DATA_W-1:0] mem_file2 [0:2447];   // Bias
    reg [DATA_W-1:0] mem_file3 [0:24575];  // Image 0
    reg [DATA_W-1:0] mem_file4 [0:24575];  // Image 1
    
    // File Handles (M?ng ?? qu?n l? t?p trung)
    integer f1[0:8]; // Cho ?nh 1
    integer f2[0:8]; // Cho ?nh 2

    // Counters
    reg [31:0] cnt[0:8];
    reg processing_img2 = 0; 
    reg [3:0] stage_delayed;
    integer i;

    // Instance Top
    top #(.DATA_W(DATA_W)) top_inst (
        .i_clk(i_clk), .i_rst_n(i_rst_n),
        .s_axis_tvalid(s_axis_tvalid), .s_axis_tdata(s_axis_tdata), .s_axis_tready(s_axis_tready),
        .m_axis_tvalid(m_axis_tvalid), .m_axis_tdata(m_axis_tdata), .m_axis_tready(m_axis_tready)
    );

    // Clock
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // =========================================================================
    // MAIN SIMULATION CONTROL
    // =========================================================================
    initial begin
        // 1. T?o folder (D?ng l?nh shell chu?n)
        $display("--- PREPARING LOG DIRECTORIES ---");
//        $system("mkdir -p img1_logs img2_logs");
        #100;

        // 2. M? to?n b? 18 file c?ng l?c ?? tr?nh l?i descriptor
        f1[0] = $fopen("img1_logs/sel0.txt", "w"); f1[1] = $fopen("img1_logs/sel1.txt", "w");
        f1[2] = $fopen("img1_logs/lb0.txt", "w");   f1[3] = $fopen("img1_logs/lb1.txt", "w");
        f1[4] = $fopen("img1_logs/dw0.txt", "w");   f1[5] = $fopen("img1_logs/dw1.txt", "w");
        f1[6] = $fopen("img1_logs/pw0.txt", "w");   f1[7] = $fopen("img1_logs/pw1.txt", "w");
        f1[8] = $fopen("img1_logs/so.txt", "w");

        f2[0] = $fopen("img2_logs/sel0.txt", "w"); f2[1] = $fopen("img2_logs/sel1.txt", "w");
        f2[2] = $fopen("img2_logs/lb0.txt", "w");   f2[3] = $fopen("img2_logs/lb1.txt", "w");
        f2[4] = $fopen("img2_logs/dw0.txt", "w");   f2[5] = $fopen("img2_logs/dw1.txt", "w");
        f2[6] = $fopen("img2_logs/pw0.txt", "w");   f2[7] = $fopen("img2_logs/pw1.txt", "w");
        f2[8] = $fopen("img2_logs/so.txt", "w");

        // Check if files opened correctly
        for(i=0; i<9; i=i+1) begin
            if (f1[i] == 0 || f2[i] == 0) begin
                $display("ERROR: Could not open file index %0d", i);
                $finish;
            end
        end

        // 3. Load Memories
// Thay "E:/..." b?ng ðý?ng d?n th?c t? ch?a thý m?c 'input' c?a b?n n?u tôi ðoán sai
        $readmemh("E:/vivado/stegano/opti5/LVTN-Depthwise_Conv/IP_Stega_v1.sim/sim_1/behav/xsim/input/depthwise_9banks.mem",  mem_file0);
        $readmemh("E:/vivado/stegano/opti5/LVTN-Depthwise_Conv/IP_Stega_v1.sim/sim_1/behav/xsim/input/pointwise_16banks.mem", mem_file1);
        $readmemh("E:/vivado/stegano/opti5/LVTN-Depthwise_Conv/IP_Stega_v1.sim/sim_1/behav/xsim/input/bias_16banks.mem",      mem_file2);
        $readmemh("E:/vivado/stegano/opti5/LVTN-Depthwise_Conv/IP_Stega_v1.sim/sim_1/behav/xsim/input/image_merge_1.hex",     mem_file3);
        $readmemh("E:/vivado/stegano/opti5/LVTN-Depthwise_Conv/IP_Stega_v1.sim/sim_1/behav/xsim/input/image_merge_1.hex",     mem_file4);
        
        // 4. Reset Design
        i_rst_n = 0; s_axis_tvalid = 0; m_axis_tready = 1;
        #100; i_rst_n <= 1; #100;

        // --- G?I ?NH 1 ---
        processing_img2 = 0;
        $display("[%0t] SENDING IMAGE 1 DATA...", $time);
        send_file_data(1692, 0); 
        send_file_data(12544, 1);
        send_file_data(2448, 2); 
        send_file_data(24576, 3);
        
        wait(top_inst.u_rd_fsm_control.o_done);
        $display("[%0t] IMAGE 1 COMPLETED. COOLING DOWN...", $time);
        #2000; // ??i pipeline x? h?t

        // --- G?I ?NH 2 ---
        processing_img2 = 1; 
        $display("[%0t] SENDING IMAGE 2 DATA...", $time);
        send_file_data(24576, 4); // Ch? g?i image_merge_1
        
        wait(top_inst.u_rd_fsm_control.o_done);
        $display("[%0t] IMAGE 2 COMPLETED. FINALIZING...", $time);
        #2000;
        
        // 5. ??ng to?n b? file khi k?t th?c h?n m? ph?ng
        for(i=0; i<9; i=i+1) begin
            $fclose(f1[i]);
            $fclose(f2[i]);
        end
        
        $display("--- SIMULATION FINISHED SUCCESSFULLY ---");
        $finish;
    end

    // =========================================================================
    // LOGGING LOGIC
    // =========================================================================
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            stage_delayed <= 0;
            for(i=0; i<9; i=i+1) cnt[i] <= 0;
        end else begin
            stage_delayed <= top_inst.u_rd_fsm_control.o_stage;

            // T? ??ng reset counter khi ??i Stage
            if (top_inst.u_rd_fsm_control.o_stage != stage_delayed) begin
                for(i=0; i<9; i=i+1) cnt[i] <= 0;
            end else begin
                
                // Logic ghi log s? d?ng Macro ?? tr?nh sai s?t
                `define LOG_SAFE(vld, data, idx) \
                    if (vld) begin \
                        $fdisplay(processing_img2 ? f2[idx] : f1[idx], \
                            "[%0t] ID:%0d | Stg:%0d | Loc:%0d | Lic:%0d | Data:%h", \
                            $time, cnt[idx], top_inst.u_rd_fsm_control.o_stage, \
                            top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, data); \
                        $fflush(processing_img2 ? f2[idx] : f1[idx]); \
                        cnt[idx] <= cnt[idx] + 1; \
                    end

                `LOG_SAFE(top_inst.u_data_select0.o_valid, top_inst.u_data_select0.o_pixel, 0)
                `LOG_SAFE(top_inst.u_data_select1.o_valid, top_inst.u_data_select1.o_pixel, 1)
                `LOG_SAFE(top_inst.u_fsm_line_buffer0.o_kernel_vld, top_inst.u_fsm_line_buffer0.o_kernel_data, 2)
                `LOG_SAFE(top_inst.u_fsm_line_buffer1.o_kernel_vld, top_inst.u_fsm_line_buffer1.o_kernel_data, 3)
                `LOG_SAFE(top_inst.depthwise_0.o_data_valid, top_inst.depthwise_0.o_data, 4)
                `LOG_SAFE(top_inst.depthwise_1.o_data_valid, top_inst.depthwise_1.o_data, 5)
                `LOG_SAFE(top_inst.u_pw_unit.o_valid_pw0, top_inst.u_pw_unit.o_data_pw0, 6)
                `LOG_SAFE(top_inst.u_pw_unit.o_valid_pw1, top_inst.u_pw_unit.o_data_pw1, 7)

                // ??c th? SO kh?ng c? stage n?n log ri?ng
                if (m_axis_tvalid) begin
                    $fdisplay(processing_img2 ? f2[8] : f1[8], "[%0t] ID:%0d | Data:%h", $time, cnt[8], m_axis_tdata);
                    $fflush(processing_img2 ? f2[8] : f1[8]);
                    cnt[8] <= cnt[8] + 1;
                end
            end
        end
    end

    // Task truy?n d? li?u
    task send_file_data(input integer size, input integer file_id);
        integer k;
        begin
            k = 0;
            while (k < size) begin
                @(posedge i_clk);
                s_axis_tvalid <= 1'b1;
                case(file_id)
                    0: s_axis_tdata <= mem_file0[k];
                    1: s_axis_tdata <= mem_file1[k];
                    2: s_axis_tdata <= mem_file2[k];
                    3: s_axis_tdata <= mem_file3[k];
                    4: s_axis_tdata <= mem_file4[k];
                endcase
                if (s_axis_tready) k = k + 1;
            end
            @(posedge i_clk); s_axis_tvalid <= 1'b0;
        end
    endtask

endmodule