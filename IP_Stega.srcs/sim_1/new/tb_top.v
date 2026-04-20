`timescale 1ns / 1ps

module tb_top;
    parameter DATA_W = 64;
    parameter NUM_SAMPLES = 100; 
    
    reg i_clk, i_rst_n;
    reg s_axis_tvalid;
    reg [DATA_W-1:0] s_axis_tdata;
    wire s_axis_tready;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    wire [DATA_W-1:0] m_axis_tdata;
    reg m_axis_tready;

    // Buffers
    reg [DATA_W-1:0] mem_weights_dw [0:1691];
    reg [DATA_W-1:0] mem_weights_pw [0:12543];
    reg [DATA_W-1:0] mem_bias       [0:2447];
    reg [DATA_W-1:0] mem_image      [0:24575];

    integer f_out;     
    integer img_idx;   
    integer count_so;  
    real progress_val; 
    reg [255:0] file_path_in;  
    reg [255:0] file_path_out; 

    // Instance Design Under Test (DUT)
    top #(.DATA_W(DATA_W)) top_inst (
        .i_clk(i_clk), .i_rst_n(i_rst_n),
        .s_axis_tvalid(s_axis_tvalid), .s_axis_tdata(s_axis_tdata), .s_axis_tready(s_axis_tready),
        .m_axis_tvalid(m_axis_tvalid), .m_axis_tdata(m_axis_tdata), .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Clock Generation (100MHz)
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // =========================================================================
    // MAIN CONTROL PROCESS
    // =========================================================================
    initial begin
        // 1. N?p d? li?u vào RAM mô ph?ng
        $readmemh("input/depthwise_9banks.mem",  mem_weights_dw);
        $readmemh("input/pointwise_16banks.mem", mem_weights_pw);
        $readmemh("input/bias_16banks.mem",      mem_bias);

        // 2. System Reset
        i_rst_n = 0; s_axis_tvalid = 0; m_axis_tready = 1;
        #100; i_rst_n <= 1; #100;

        // 3. G?I WEIGHTS & BIAS (CH? CH?Y 1 L?N)
        $display("[%0t] SETUP: Sending Weights and Bias...", $time);
        send_data(1692, 0);  // DW
        send_data(12544, 1); // PW
        send_data(2448, 2);  // Bias
        $display("[%0t] SETUP: Done. Starting Image Loop.", $time);

        // 4. V?NG L?P 100 ?NH
        for (img_idx = 0; img_idx < NUM_SAMPLES; img_idx = img_idx + 1) begin
            
            progress_val = (img_idx * 100.0) / NUM_SAMPLES;
            $display("\n-------------------------------------------------------");
            $display("PROGRESS: %0.1f%% | Image: %0d/%0d", progress_val, img_idx + 1, NUM_SAMPLES);
            
            $swrite(file_path_in, "image_merge/image_%03d.hex", img_idx);
            $swrite(file_path_out, "output_stega/stega_%03d.hex", img_idx);
            
            $readmemh(file_path_in, mem_image);
            
            f_out = $fopen(file_path_out, "w");
            count_so = 0;
            
            // Ch? g?i ?nh trong v?ng l?p này
            send_data(24576, 3); 

            // Ð?i Design x? l? xong (d?a trên FSM c?a b?n)
            wait(top_inst.u_rd_fsm_control.o_done);
            #1000; // X? s?ch pipeline
            
            $fclose(f_out);
f_out = 0; 
            $display("[%0t] FINISHED: stega_%03d.hex | Pixels: %0d", $time, img_idx, count_so);
        end

        $display("\n*******************************************************");
        $display("   SUCCESS: ALL %0d IMAGES PROCESSED!", NUM_SAMPLES);
        $display("*******************************************************");
        $finish;
    end

    // Ghi d? li?u ð?u ra (Logging)
    always @(posedge i_clk) begin
        if (m_axis_tvalid && f_out != 0) begin
            $fdisplay(f_out, "%h", m_axis_tdata);
            count_so <= count_so + 1;
            // Ð? xóa $fflush ð? ð?t t?c ð? t?i ða
        end
    end

    // Task g?i d? li?u chu?n AXI-Stream
    task send_data(input integer size, input integer type);
        integer k;
        begin
            k = 0;
            while (k < size) begin
                @(posedge i_clk);
                s_axis_tvalid <= 1'b1;
                case(type)
                    0: s_axis_tdata <= mem_weights_dw[k];
                    1: s_axis_tdata <= mem_weights_pw[k];
                    2: s_axis_tdata <= mem_bias[k];
                    3: s_axis_tdata <= mem_image[k];
                endcase
                if (s_axis_tready) k = k + 1;
            end
            @(posedge i_clk);
            s_axis_tvalid <= 1'b0;
        end
    endtask

endmodule
