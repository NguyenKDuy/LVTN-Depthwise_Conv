`timescale 1ns / 1ps

module tb_top;

    // =========================================================================
    // 1. PARAMETERS & SIGNALS
    // =========================================================================
    parameter DATA_W = 64;
    
    reg i_clk;
    reg i_rst_n;

    // AXI-Stream Slave Interface
    reg                     s_axis_tvalid;
    reg  [DATA_W-1:0]       s_axis_tdata;
    wire                    s_axis_tready;

    // AXI-Stream Master Interface
    wire                    m_axis_tvalid;
    wire [DATA_W-1:0]       m_axis_tdata;
    reg                     m_axis_tready;

    // Buffers cho d? li?u ð?u vào & Golden
    reg [DATA_W-1:0] mem_file0 [0:1691];
    reg [DATA_W-1:0] mem_file1 [0:12543];
    reg [DATA_W-1:0] mem_file2 [0:543];
    reg [DATA_W-1:0] mem_file3 [0:24575];

//    reg [2303:0] mem_golden  [0:16383]; 
//    reg [2303:0] mem1_golden [0:4095];  
    
    integer golden_ptr  = 0;
    integer stage       = 0; 
    
    // File Handles - Tách riêng t?ng file theo yêu c?u c?a Duy
    integer f_sel0, f_sel1;
    integer f_lb0,  f_lb1;
    integer f_dw0,  f_dw1;
    integer f_pw0,  f_pw1;

    reg [255:0] bank_name;
    integer b;
    reg [31:0] count_sel0 = 0, count_sel1 = 0;
    reg [31:0] count_lb0  = 0, count_lb1  = 0;
    reg [31:0] count_dw0  = 0, count_dw1  = 0;
    reg [31:0] count_pw0  = 0, count_pw1  = 0;
    
    // =========================================================================
    // 2. CLOCK GENERATION (100MHz)
    // =========================================================================
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // =========================================================================
    // 3. INSTANTIATE TOP MODULE
    // =========================================================================
    top #(
        .DATA_W(DATA_W)
    ) top_inst (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tready  (s_axis_tready),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tready  (m_axis_tready)
    );

    // =========================================================================
    // 4. SETUP FOLDER & OPEN INDIVIDUAL FILES
    // =========================================================================
    initial begin
        // T?o folder (Lýu ?: N?u dùng Windows, nên t?o tay folder simulation_logs trý?c)
        $system("mkdir simulation_logs");
        #10;

        // M? 8 file riêng bi?t
        f_sel0 = $fopen("simulation_logs/sel0_data.txt", "w");
        f_sel1 = $fopen("simulation_logs/sel1_data.txt", "w");
        f_lb0  = $fopen("simulation_logs/lb0_kernel.txt", "w");
        f_lb1  = $fopen("simulation_logs/lb1_kernel.txt", "w");
        f_dw0  = $fopen("simulation_logs/dw0_out.txt", "w");
        f_dw1  = $fopen("simulation_logs/dw1_out.txt", "w");
        f_pw0  = $fopen("simulation_logs/pw0_out.txt", "w");
        f_pw1  = $fopen("simulation_logs/pw1_out.txt", "w");

        // N?p d? li?u
        $readmemh("input/depthwise_9banks.mem", mem_file0);
        $readmemh("input/pointwise_16banks.mem", mem_file1);
        $readmemh("input/bias_16banks.mem", mem_file2);
        $readmemh("input/image_merge.hex", mem_file3);
    end

    // =========================================================================
    // 5. MAIN SIMULATION CONTROL
    // =========================================================================
    initial begin
        i_rst_n = 0; s_axis_tvalid = 0; m_axis_tready = 1;
        #100; i_rst_n <= 1; #50;

        send_file_data(1692,  0);
        repeat(50) @(posedge i_clk);
        send_file_data(12544, 1);
        repeat(50) @(posedge i_clk);
        send_file_data(544,   2);
        repeat(50) @(posedge i_clk);
        send_file_data(24576, 3);
        
        // Ði?u ki?n d?ng
        wait( top_inst.u_rd_fsm_control.o_done);
        #100;
        
        // Ðóng toàn b? file
        $fclose(f_sel0); $fclose(f_sel1);
        $fclose(f_lb0);  $fclose(f_lb1);
        $fclose(f_dw0);  $fclose(f_dw1);
        $fclose(f_pw0);  $fclose(f_pw1);
        
        $display("--- SUCCESS: 8 LOG FILES GENERATED IN simulation_logs/ ---");
//        $finish;
    end

    // =========================================================================
    // 6. LOGGING LOGIC (EACH IF TO ONE FILE)
    // =========================================================================
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            // Reset các bi?n ð?m v? 0 khi reset h? th?ng
            count_sel0 <= 0; count_sel1 <= 0;
            count_lb0  <= 0; count_lb1  <= 0;
            count_dw0  <= 0; count_dw1  <= 0;
            count_pw0  <= 0; count_pw1  <= 0;
        end else begin
            
            // --- DATA SELECT ---
            if (top_inst.u_data_select0.o_valid) begin
                $fdisplay(f_sel0, "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
                    $time, count_sel0, top_inst.u_rd_fsm_control.o_stage, 
                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
                    top_inst.u_data_select0.o_pixel);
                $fflush(f_sel0);
                count_sel0 <= count_sel0 + 1;
            end
            
            if (top_inst.u_data_select1.o_valid) begin
                $fdisplay(f_sel1, "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
                    $time, count_sel1, top_inst.u_rd_fsm_control.o_stage, 
                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
                    top_inst.u_data_select1.o_pixel);
                $fflush(f_sel1);
                count_sel1 <= count_sel1 + 1;
            end

            // --- LINE BUFFER (KERNEL) ---
            if (top_inst.u_fsm_line_buffer0.o_kernel_vld) begin
                $fdisplay(f_lb0,  "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
                    $time, count_lb0, top_inst.u_rd_fsm_control.o_stage, 
                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
                    top_inst.u_fsm_line_buffer0.o_kernel_data);
                $fflush(f_lb0);
                count_lb0 <= count_lb0 + 1;
            end
            
            if (top_inst.u_fsm_line_buffer1.o_kernel_vld) begin
                $fdisplay(f_lb1,  "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
                    $time, count_lb1, top_inst.u_rd_fsm_control.o_stage, 
                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
                    top_inst.u_fsm_line_buffer1.o_kernel_data);
                count_lb1 <= count_lb1 + 1;
                $fflush(f_lb1);
            end

            // --- DEPTHWISE ---
            if (top_inst.depthwise_0.o_data_valid) begin
                $fdisplay(f_dw0,  "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
                    $time, count_dw0, top_inst.u_rd_fsm_control.o_stage, 
                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
                    top_inst.depthwise_0.o_data);
                count_dw0 <= count_dw0 + 1;
                $fflush(f_dw0);
            end
            
            if (top_inst.depthwise_1.o_data_valid) begin
                $fdisplay(f_dw1,  "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
                    $time, count_dw1, top_inst.u_rd_fsm_control.o_stage, 
                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
                    top_inst.depthwise_1.o_data);
                count_dw1 <= count_dw1 + 1;
                $fflush(f_dw1);
            end

            // --- POINTWISE ---
            if (top_inst.u_pw_unit.o_valid_pw0) begin
                $fdisplay(f_pw0,  "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
                    $time, count_pw0, top_inst.u_rd_fsm_control.o_stage, 
                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
                    top_inst.u_pw_unit.o_data_pw0);
//                $display(f_pw0,  "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
//                    $time, count_pw0, top_inst.u_rd_fsm_control.o_stage, 
//                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
//                    top_inst.u_pw_unit.o_data_pw0);
                count_pw0 <= count_pw0 + 1;
                $fflush(f_pw0);
            end
            
            if (top_inst.u_pw_unit.o_valid_pw1) begin
                $fdisplay(f_pw1,  "[%0t] ID:%0d | Stage:%0d | Loc:%0d | Lic:%0d | Data:%h", 
                    $time, count_pw1, top_inst.u_rd_fsm_control.o_stage, 
                    top_inst.u_rd_fsm_control.loc_counter, top_inst.u_rd_fsm_control.o_lic_counter, 
                    top_inst.u_pw_unit.o_data_pw1);
                count_pw1 <= count_pw1 + 1;
                $fflush(f_pw1);
            end
        end
    end

    // Task truy?n d? li?u (Gi? nguyên logic c?)
    task send_file_data(input integer size, input integer file_id);
        integer i;
        begin
            i = 0;
            while (i < size) begin
                @(posedge i_clk);
                s_axis_tvalid <= 1'b1;
                case(file_id)
                    0: s_axis_tdata <= mem_file0[i];
                    1: s_axis_tdata <= mem_file1[i];
                    2: s_axis_tdata <= mem_file2[i];
                    3: s_axis_tdata <= mem_file3[i];
                endcase
                if (s_axis_tready) i = i + 1;
            end
            @(posedge i_clk); s_axis_tvalid <= 1'b0;
        end
    endtask

endmodule