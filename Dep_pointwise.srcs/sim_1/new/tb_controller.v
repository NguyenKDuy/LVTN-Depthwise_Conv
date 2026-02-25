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
    wire [544- 1: 0] line_buffer;
    // Event ð? kích ho?t stage ti?p theo
    event start_downs1, start_downs2, start_bott,
          start_ups1, start_ups2, start_ups3, start_tail;

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
        .top_stage(top_stage),
        .dw_out(),
        .pw_out(),
        .line_buffer(line_buffer)
    );
    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Logic ði?u khi?n Enable/Reset chung
    initial begin
        $readmemh ("image_64bit_debug.hex",dut.image_mem.ram);
        $readmemh ("downs1_ram_q0.hex",dut.image_mem.ram);
        $readmemh ("downs2_ram_q0.hex",dut.image_mem.ram);
        $readmemh ("bott_ram_q0.hex",dut.image_mem.ram);
        
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
    wire [319:0] cur_data_head = {line_buffer[431:272], line_buffer[159:0]};

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
//                $fclose(fd_head);
                
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
    wire [543:0] cur_data_downs1 = {line_buffer}; 

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
                -> start_downs2; 
                
                // G?i tín hi?u hoàn thành stage cho Controller (n?u c?n)
                #10 force dut.data_control.i_pwdone = 1'b1;
                #10 force dut.data_control.i_pwdone = 1'b0;
            end
        end
    end
    
        // ========================================================
    // STAGE 3: VERIFY DOWNS2 (top_stage == 4'd3)
    // ========================================================
    integer fd_downs2;
    reg [543:0] golden_downs2; // Ð? s?a ð? r?ng bit theo khai báo c?a b?n
    integer downs2_match = 0, downs2_err = 0;
    
    // Lýu ?: data_out cho Downs1 b?n c?n check l?i index c?t bit cho ðúng
    wire [543:0] cur_data_downs2 = {line_buffer}; 

    initial begin
        // QUAN TR?NG: Ð?i Stage HEAD xong m?i b?t ð?u
        @(start_downs2); 
        #0 force dut.data_control.i_pwdone = 1;
        #20 force dut.data_control.i_pwdone = 0;
        
        fd_downs2 = $fopen("downs2_golden.hex", "r");
        if (fd_downs2 == 0) $display("ERROR: Missing downs2_golden.hex");
        
        $display("--- [START] Checking DOWNS2 Stage ---");
    end

    always @(posedge clk) begin
        // Ch? check khi ð? qua event start_downs1 và ðúng top_stage
        if (top_stage == 4'd3 && o_valid && i_ready ) begin
            if ($fscanf(fd_downs2, "%h\n", golden_downs2) > 0) begin
                if (cur_data_downs2 === golden_downs2) begin
                    downs2_match= downs2_match+ 1;
                    $display("[CORRECT DOWNS2] T=%0t | Correct %0d/2176",$time, downs2_match);
                end
                else begin
                    downs2_err = downs2_err + 1;
                    $display("[ERR DOWNS2] T=%0t | DUT=%h \n \t\t\t\t\t\t    GOL=%h", $time, cur_data_downs2, golden_downs2);
                end
            end

            if ((downs2_match + downs2_err) == 2176) begin
                $display("--- [DONE] DOWNS2: Correct %0d, Error %0d ---", downs2_match, downs2_err);
                $fclose(fd_downs2);
                -> start_bott; 
                
//                // G?i tín hi?u hoàn thành stage cho Controller (n?u c?n)
                #10 force dut.data_control.i_pwdone = 1'b1;
                #10 force dut.data_control.i_pwdone = 1'b0;
            end
        end
    end
    
        // ========================================================
    // STAGE 4: VERIFY BOTT (top_stage == 4'd4)
    // ========================================================
    integer fd_bott;
    reg [543:0] golden_bott; // Ð? s?a ð? r?ng bit theo khai báo c?a b?n
    integer bott_match = 0, bott_err = 0;
    
    // Lýu ?: data_out cho Downs1 b?n c?n check l?i index c?t bit cho ðúng
    wire [543:0] cur_data_bott = {line_buffer}; 

    initial begin
        // QUAN TR?NG: Ð?i Stage HEAD xong m?i b?t ð?u
        @(start_bott); 
        #0 force dut.data_control.i_pwdone = 1;
        #20 force dut.data_control.i_pwdone = 0;
        
        fd_bott = $fopen("bott_golden.hex", "r");
        if (fd_bott == 0) $display("ERROR: Missing bott_golden.hex");
        
        $display("--- [START] Checking BOTT Stage ---");
    end

    always @(posedge clk) begin
        // Ch? check khi ð? qua event start_downs1 và ðúng top_stage
        if (top_stage == 4'd4 && o_valid && i_ready ) begin
            if ($fscanf(fd_bott, "%h\n", golden_bott) > 0) begin
                if (cur_data_bott === golden_bott) begin
                    bott_match= bott_match+ 1;
                    $display("[CORRECT BOTT] T=%0t | Correct %0d/1088",$time, bott_match);
                end
                else begin
                    bott_err = bott_err + 1;
                    $display("[ERR BOTT] T=%0t | DUT=%h \n \t\t\t\t\t\t    GOL=%h", $time, cur_data_bott, golden_bott);
                end
            end

            if ((bott_match + bott_err) == 1088) begin
                $display("--- [DONE] BOTT: Correct %0d, Error %0d ---", bott_match, bott_err);
                $fclose(fd_bott);
//                -> start_ups1; 
                
            end
        end
    end
    
//    // STAGE 5: VERIFY UPS1 (top_stage == 4'd5)
//    // ========================================================
//    integer fd_ups1;
//    reg [320:0] golden_ups1; // Ð? s?a ð? r?ng bit theo khai báo c?a b?n
//    integer ups1_match = 0, ups1_err = 0;
    
//    // Lýu ?: data_out cho Downs1 b?n c?n check l?i index c?t bit cho ðúng
//    wire [320:0] cur_data_ups1 = {line_buffer[431:272], line_buffer[159:0]};

//    initial begin
//        // QUAN TR?NG: Ð?i Stage HEAD xong m?i b?t ð?u
//        @(start_ups1); 
//        #0 force dut.data_control.i_pwdone = 1;
//        #20 force dut.data_control.i_pwdone = 0;
//        $readmemh("ups1_ram_0_q0.hex",dut.imm_mem.ram[16383:0]);
//        $readmemh("ups1_ram_1_q0.hex",dut.bott_mem.ram);
//        fd_ups1 = $fopen("ups1_golden.hex", "r"); //merging and for quarter 10
//        if (fd_ups1 == 0) $display("ERROR: Missing ups1_golden.hex");
        
//        $display("--- [START] Checking UPS1 Stage ---");
//    end

//    always @(posedge clk) begin
//        // Ch? check khi ð? qua event start_downs1 và ðúng top_stage
//        if (top_stage == 4'd5 && o_valid && i_ready ) begin
//            if ($fscanf(fd_ups1, "%h\n", golden_ups1) > 0) begin
//                if (cur_data_ups1 === golden_ups1) begin
//                    ups1_match= ups1_match+ 1;
//                    $display("[CORRECT UPS1] T=%0t | Correct %0d/1088",$time, ups1_match);
//                end
//                else begin
//                    ups1_err = ups1_err + 1;
//                    $display("[ERR UPS1] T=%0t | DUT=%h \n \t\t\t\t\t\t    GOL=%h", $time, cur_data_ups1, golden_ups1);
//                end
//            end

//            if ((ups1_match + ups1_err) == 1088) begin
//                $display("--- [DONE] UPS1: Correct %0d, Error %0d ---", ups1_match, ups1_err);
//                $fclose(fd_ups1);
//                -> start_ups2; 
                
//////                // G?i tín hi?u hoàn thành stage cho Controller (n?u c?n)
//////                #10 force dut.data_control.i_pwdone = 1'b1;
//////                #10 force dut.data_control.i_pwdone = 1'b0;
//            end
//        end
//    end

endmodule