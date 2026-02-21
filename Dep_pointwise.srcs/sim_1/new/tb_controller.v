`timescale 1ns / 1ps

module tb_accelerator_file;

    // =========================
    // Parameters & Signals
    // =========================
    parameter PIXEL_WIDTH = 16;
    parameter DATA_WIDTH  = PIXEL_WIDTH * 4; 
    reg clk;
    reg i_rst_n;
    reg [DATA_WIDTH-1 : 0] data_in;
    reg i_data_valid;
    reg i_ready;
    
    wire o_valid;
    wire [DATA_WIDTH-1 : 0] data_out1, data_out2, data_out3;
    wire [3:0] top_stage;

    // Event ð? kích ho?t stage ti?p theo
    event start_downs1;

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

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Logic ði?u khi?n Enable/Reset chung
    initial begin
        i_rst_n = 0;
        i_ready = 1;
        #25 i_rst_n = 1;
        #20;
        force dut.data_control.i_enable = 1'b1;
    end

    // ========================================================
    // STAGE 1: VERIFY HEAD (top_stage == 4'd1)
    // ========================================================
    integer fd_head;
    reg [319:0] golden_head;
    integer head_match = 0, head_err = 0;
    wire [319:0] cur_data_head = {dut.data_control.o_data[431:272], dut.data_control.o_data[159:0]};

    initial begin
        wait(i_rst_n);
        fd_head = $fopen("head_data_golden_q0.hex", "r");
        if (fd_head == 0) $fatal("Missing head_data_golden_q0.hex");
        
        $display("--- [START] Checking HEAD Stage ---");
    end

    always @(posedge clk) begin
        if (top_stage == 4'd1 && o_valid && i_ready) begin
            if ($fscanf(fd_head, "%h\n", golden_head) > 0) begin
                if (cur_data_head === golden_head) begin
                    head_match = head_match +1;
                    $display("[CORRECT HEAD] T=%0t | Correct %0d/1920",$time, head_match);
                end
                else begin
                    head_err = head_err + 1;
                    $display("[ERR HEAD] T=%0t | DUT=%h | GOL=%h", $time, cur_data_head, golden_head);
                end
            end

            // Khi check ð? 1920 m?u c?a HEAD
            if ((head_match + head_err) == 1920) begin
                $display("--- [DONE] HEAD: Correct %0d, Error %0d ---", head_match, head_err);
                $fclose(fd_head);
                
                // Kích ho?t stage ti?p theo
                -> start_downs1; 
                
                // G?i tín hi?u hoàn thành stage cho Controller (n?u c?n)
                #10 force dut.data_control.i_pwdone = 1'b1;
                #10 force dut.data_control.i_pwdone = 1'b0;
            end
        end
    end

    // ========================================================
    // STAGE 2: VERIFY DOWNS1 (top_stage == 4'd2)
    // ========================================================
    integer fd_downs1;
    reg [543:0] golden_downs1; // Ð? s?a ð? r?ng bit theo khai báo c?a b?n
    integer downs1_match = 0, downs1_err = 0;
    
    // Lýu ?: data_out cho Downs1 b?n c?n check l?i index c?t bit cho ðúng
    wire [543:0] cur_data_downs1 = {dut.data_control.o_data}; 

    initial begin
        // QUAN TR?NG: Ð?i Stage HEAD xong m?i b?t ð?u
        @(start_downs1); 
        #0 force dut.data_control.i_pwdone = 1;
        #20 force dut.data_control.i_pwdone = 0;
        
        fd_downs1 = $fopen("downs1_golden.hex", "r");
        if (fd_downs1 == 0) $display("ERROR: Missing downs1_golden.hex");
        
        $display("--- [START] Checking DOWNS1 Stage ---");
    end

    always @(posedge clk) begin
        // Ch? check khi ð? qua event start_downs1 và ðúng top_stage
        if (top_stage == 4'd2 && o_valid && i_ready ) begin
            if ($fscanf(fd_downs1, "%h\n", golden_downs1) > 0) begin
                if (cur_data_downs1 === golden_downs1) begin
                    downs1_match= downs1_match+ 1;
                    $display("[CORRECT DOWNS1] T=%0t | Correct %0d/4352",$time, downs1_match);
                end
                else begin
                    downs1_err = downs1_err + 1;
                    $display("[ERR DOWNS1] T=%0t | DUT=%h \n \t\t\t\t\t\t   GOL=%h", $time, cur_data_downs1, golden_downs1);
                end
            end

            if ((downs1_match + downs1_err) == 4352) begin
                $display("--- [DONE] DOWNS1: Correct %0d, Error %0d ---", downs1_match, downs1_err);
                $fclose(fd_downs1);
                $finish; // K?t thúc mô ph?ng
            end
        end
    end

endmodule