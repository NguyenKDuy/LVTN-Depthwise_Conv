//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 04/11/2026 11:35:50 AM
//// Design Name: 
//// Module Name: tb_top
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//`timescale 1ns / 1ps

//module tb_top;

//    // Parameters
//    parameter DATA_W = 64;
    
//    // Clock & Reset
//    reg i_clk;
//    reg i_rst_n;

//    // AXI-Stream Slave Interface (DMA to Receptor)
//    reg                     s_axis_tvalid;
//    reg  [DATA_W-1:0]       s_axis_tdata;
//    wire                    s_axis_tready;

//    // AXI-Stream Master Interface (Out)
//    wire                    m_axis_tvalid;
//    wire [DATA_W-1:0]       m_axis_tdata;
//    reg                     m_axis_tready;

//    // Output Kernels
//    wire [2303:0]           top_lb_kernel_0, top_lb_kernel_1;
//    wire                    top_lb_kernel_vld_0, top_lb_kernel_vld_1;
//    wire                    intr;

//    // B? nh? ð?m ð? ð?c file hex
//    reg [DATA_W-1:0] mem_file0 [0:1691];  // Max 1692
//    reg [DATA_W-1:0] mem_file1 [0:12479]; // Max 12480
//    reg [DATA_W-1:0] mem_file2 [0:527];   // Max 528
//    reg [DATA_W-1:0] mem_file3 [0:24575]; // Max 24576

//    reg [2303:0] mem_golden [0:16383]; // B? nh? ch?a 16384 kernels chu?n (128x128)
//    integer golden_ptr  = 0;           // Ch? s? kernel ðang so sánh
//    integer error_count = 0;           // T?ng s? kernel b? sai
//    integer pass_count  = 0;           // T?ng s? kernel ðúng
    
//    // --- Clock Gen (100MHz) ---
//    initial begin
//        i_clk = 0;
//        forever #5 i_clk = ~i_clk;
//    end

//    // --- Instantiate TOP Module ---
//    top #(
//        .DATA_W(DATA_W)
//    ) top_inst (
//        .i_clk(i_clk),
//        .i_rst_n(i_rst_n),
//        .s_axis_tvalid(s_axis_tvalid),
//        .s_axis_tdata(s_axis_tdata),
//        .s_axis_tready(s_axis_tready),
//        .m_axis_tvalid(m_axis_tvalid),
//        .m_axis_tdata(m_axis_tdata),
//        .m_axis_tready(m_axis_tready),
//        .intr(intr),
//        .top_lb_kernel_0(top_lb_kernel_0),
//        .top_lb_kernel_1(top_lb_kernel_1),
//        .top_lb_kernel_vld_0(top_lb_kernel_vld_0),
//        .top_lb_kernel_vld_1(top_lb_kernel_vld_1)
//    );

//    // --- Task: Send Stream Data ---
//    // Task này ð?c t? m?t m?ng và ð?y ra chu?n AXI-Stream
//    // --- Task: Send Stream Data (Phiên b?n "Ch?c Cú") ---
//    task send_file_data(
//        input integer size, 
//        input integer file_id  // Dùng s? nguyên ð? ð?nh danh, không dùng string
//    );
//        integer i;
//        begin
//            $display("--- Dang bat dau gui File ID: %0d | Size: %0d words ---", file_id, size);
//            i = 0;
//            while (i < size) begin
//                @(posedge i_clk);
//                s_axis_tvalid <= 1'b1;
                
//                // Case dùng s? nguyên luôn kh?p 100%
//                case(file_id)
//                    0: s_axis_tdata <= mem_file0[i];
//                    1: s_axis_tdata <= mem_file1[i];
//                    2: s_axis_tdata <= mem_file2[i];
//                    3: s_axis_tdata <= mem_file3[i];
//                    default: s_axis_tdata <= 64'hBAAD_F00D;
//                endcase

//                // Ch? ready t? Receptor (Handshake)
//                if (s_axis_tready) begin
//                    i = i + 1;
//                end
//            end
            
//            // K?t thúc truy?n file
//            @(posedge i_clk);
//            s_axis_tvalid <= 1'b0;
//            s_axis_tdata  <= 64'd0;
//            $display("--- Hoan thanh File ID: %0d ---", file_id);
//        end
//    endtask
    
//    integer i;
//    reg [255:0] file_name; // Chu?i lýu tên file

//    initial begin
//        for (i = 0; i < 16; i = i + 1) begin
//            // T?o tên file týõng ?ng: bank_0.hex, bank_1.hex, ...
//            $swrite(file_name, "downs1_s2_hw_banks/bank_%0d.hex", i);
            
//            // S? d?ng $readmemh v?i phân c?p chính xác c?a b?n
//            case(i)
//                0:  $readmemh(file_name, top_inst.mem_0.bank_gen[0].u_mem_bank.ram);
//                1:  $readmemh(file_name, top_inst.mem_0.bank_gen[1].u_mem_bank.ram);
//                2:  $readmemh(file_name, top_inst.mem_0.bank_gen[2].u_mem_bank.ram);
//                3:  $readmemh(file_name, top_inst.mem_0.bank_gen[3].u_mem_bank.ram);
//                4:  $readmemh(file_name, top_inst.mem_0.bank_gen[4].u_mem_bank.ram);
//                5:  $readmemh(file_name, top_inst.mem_0.bank_gen[5].u_mem_bank.ram);
//                6:  $readmemh(file_name, top_inst.mem_0.bank_gen[6].u_mem_bank.ram);
//                7:  $readmemh(file_name, top_inst.mem_0.bank_gen[7].u_mem_bank.ram);
//                8:  $readmemh(file_name, top_inst.mem_0.bank_gen[8].u_mem_bank.ram);
//                9:  $readmemh(file_name, top_inst.mem_0.bank_gen[9].u_mem_bank.ram);
//                10: $readmemh(file_name, top_inst.mem_0.bank_gen[10].u_mem_bank.ram);
//                11: $readmemh(file_name, top_inst.mem_0.bank_gen[11].u_mem_bank.ram);
//                12: $readmemh(file_name, top_inst.mem_0.bank_gen[12].u_mem_bank.ram);
//                13: $readmemh(file_name, top_inst.mem_0.bank_gen[13].u_mem_bank.ram);
//                14: $readmemh(file_name, top_inst.mem_0.bank_gen[14].u_mem_bank.ram);
//                15: $readmemh(file_name, top_inst.mem_0.bank_gen[15].u_mem_bank.ram);
//            endcase
//        end
//    end
    
//    // --- Main Sequence ---
//    initial begin
//        // 1. Reset & Kh?i t?o
//        i_rst_n = 0;
//        s_axis_tvalid = 0;
//        s_axis_tdata = 0;
//        m_axis_tready = 1;

//        // 2. N?p file (Ð?m b?o tên file ðúng trong thý m?c)
//        $readmemh("file0.hex", mem_file0);
//        $readmemh("file1.hex", mem_file1);
//        $readmemh("file2.hex", mem_file2);
//        $readmemh("file3.hex", mem_file3);
//        $readmemh("golden_kernel.hex", mem_golden); // N?p file chu?n t? Python
//        $readmemh("downs1_s2_golden_kernel.hex", mem1_golden); // N?p file chu?n t? Python
        
//        #100;
//        i_rst_n <= 1;
//        #50;

//        // 3. G?i Task b?ng ID cho ch?c ch?n
//        send_file_data(1692,  0); // G?i file0
//        repeat(50) @(posedge i_clk);

//        send_file_data(12480, 1); // G?i file1
//        repeat(50) @(posedge i_clk);

//        send_file_data(528,   2); // G?i file2
//        repeat(50) @(posedge i_clk);

//        send_file_data(24576, 3); // G?i file3
        
//        #1000;
//        $display("Mo phong ket thuc!");
//    end
    

//    always @(posedge i_clk) begin
//        if (!i_rst_n) begin
//            golden_ptr  <= 0;
//            error_count <= 0;
//            pass_count  <= 0;
//        end else begin
//            // Ch? so sánh khi top_lb_kernel_vld_0 lên 1
//            if (top_lb_kernel_vld_0) begin
//                if (top_lb_kernel_0 === mem_golden[golden_ptr]) begin
//                    pass_count = pass_count + 1;
//                    $display("[%0t ns] [PASS] Pass %0d / 16384 !", $time, pass_count);
//                end else begin
//                    error_count = error_count + 1;
//                    $display("================================================================");
//                    $display("[%0t ns] [FAIL] At: %0d", $time, golden_ptr);
//                    $display("(GOLDEN)  : %h", mem_golden[golden_ptr]);
//                    $display("(HARDWARE): %h", top_lb_kernel_0);
//                    $display("================================================================");
//                end
                
//                // Tãng con tr? ð? chu?n b? cho l?n Valid ti?p theo
//                golden_ptr <= golden_ptr + 1;
//            end
//            if (golden_ptr == 16384) begin
//                $display("\n=========================================================");
//                $display("T?NG K?T KI?M TRA (SUMMARY):");
//                $display(" - T?ng s? Kernel ð? ki?m tra: %0d", golden_ptr);
//                $display(" - S? Kernel ÐÚNG:            %0d", pass_count);
//                $display(" - S? Kernel SAI:             %0d", error_count);
                
//                if (error_count == 0 && golden_ptr > 0)
//                    $display(" K?T LU?N: CHÚC M?NG! HARDWARE CH?Y CHU?N GOLDEN MODEL.");
//                else
//                    $display(" K?T LU?N: C?N KI?M TRA L?I LOGIC DESIGN.");
//                $display("=========================================================\n");
                
//                #100;
//                $finish;
//            end
//        end
//    end
    

//endmodule

`timescale 1ns / 1ps

module tb_top;

    // Parameters
    parameter DATA_W = 64;
    
    // Clock & Reset
    reg i_clk;
    reg i_rst_n;

    // AXI-Stream Slave Interface
    reg                 s_axis_tvalid;
    reg  [DATA_W-1:0]   s_axis_tdata;
    wire                s_axis_tready;

    // AXI-Stream Master Interface
    wire                m_axis_tvalid;
    wire [DATA_W-1:0]   m_axis_tdata;
    reg                 m_axis_tready;

    // Output Kernels
//    wire [2303:0]       top_lb_kernel_0, top_lb_kernel_1;
//    wire                top_lb_kernel_vld_0, top_lb_kernel_vld_1;
//    wire                intr;

    // B? nh? ð?m cho d? li?u ð?u vào (C?u trúc c? c?a Duy)
    reg [DATA_W-1:0] mem_file0 [0:1691];
    reg [DATA_W-1:0] mem_file1 [0:12479];
    reg [DATA_W-1:0] mem_file2 [0:527];
    reg [DATA_W-1:0] mem_file3 [0:24575];

    // B? nh? Golden Model ð? so sánh ð?u ra
    reg [2303:0] mem_golden [0:16383];      // Stage S2 (128x128)
    reg [2303:0] mem1_golden [0:4095];     // Stage DOWNS1 (64x64)
    
    integer golden_ptr  = 0;
    integer stage       = 0; // 0: S2, 1: DOWNS1
    integer error_count = 0;
    integer pass_count  = 0;
    
    // Bi?n ph? ð? n?p 16 bank
    integer b;
    reg [255:0] bank_name;

    // --- Clock Gen (100MHz) ---
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // --- Instantiate TOP Module ---
    top #(
        .DATA_W(DATA_W)
    ) top_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tready(s_axis_tready),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tready(m_axis_tready)
//        .intr(intr),
//        .top_lb_kernel_0(top_lb_kernel_0),
//        .top_lb_kernel_1(top_lb_kernel_1),
//        .top_lb_kernel_vld_0(top_lb_kernel_vld_0),
//        .top_lb_kernel_vld_1(top_lb_kernel_vld_1)
    );

    // --- Task: Send Stream Data ---
    task send_file_data(input integer size, input integer file_id);
        integer i;
        begin
            $display("--- Sending File ID: %0d | Size: %0d ---", file_id, size);
            i = 0;
            while (i < size) begin
                @(posedge i_clk);
                s_axis_tvalid <= 1'b1;
                case(file_id)
                    0: s_axis_tdata <= mem_file0[i];
                    1: s_axis_tdata <= mem_file1[i];
                    2: s_axis_tdata <= mem_file2[i];
                    3: s_axis_tdata <= mem_file3[i];
                    default: s_axis_tdata <= 64'hBAAD_F00D;
                endcase

                if (s_axis_tready) i = i + 1;
            end
            @(posedge i_clk);
            s_axis_tvalid <= 1'b0;
            s_axis_tdata  <= 64'd0;
        end
    endtask

    // --- N?p 16 Banks vào Hardware RAM ---
    initial begin
        for (b = 0; b < 16; b = b + 1) begin
            $swrite(bank_name, "downs1_s2_hw_banks/bank_%0d.hex", b);
            case(b)
                0:  $readmemh(bank_name, top_inst.mem_0.bank_gen[0].u_mem_bank.ram);
                1:  $readmemh(bank_name, top_inst.mem_0.bank_gen[1].u_mem_bank.ram);
                2:  $readmemh(bank_name, top_inst.mem_0.bank_gen[2].u_mem_bank.ram);
                3:  $readmemh(bank_name, top_inst.mem_0.bank_gen[3].u_mem_bank.ram);
                4:  $readmemh(bank_name, top_inst.mem_0.bank_gen[4].u_mem_bank.ram);
                5:  $readmemh(bank_name, top_inst.mem_0.bank_gen[5].u_mem_bank.ram);
                6:  $readmemh(bank_name, top_inst.mem_0.bank_gen[6].u_mem_bank.ram);
                7:  $readmemh(bank_name, top_inst.mem_0.bank_gen[7].u_mem_bank.ram);
                8:  $readmemh(bank_name, top_inst.mem_0.bank_gen[8].u_mem_bank.ram);
                9:  $readmemh(bank_name, top_inst.mem_0.bank_gen[9].u_mem_bank.ram);
                10: $readmemh(bank_name, top_inst.mem_0.bank_gen[10].u_mem_bank.ram);
                11: $readmemh(bank_name, top_inst.mem_0.bank_gen[11].u_mem_bank.ram);
                12: $readmemh(bank_name, top_inst.mem_0.bank_gen[12].u_mem_bank.ram);
                13: $readmemh(bank_name, top_inst.mem_0.bank_gen[13].u_mem_bank.ram);
                14: $readmemh(bank_name, top_inst.mem_0.bank_gen[14].u_mem_bank.ram);
                15: $readmemh(bank_name, top_inst.mem_0.bank_gen[15].u_mem_bank.ram);
            endcase
        end
    end

    // --- Main Sequence ---
    initial begin
        // Reset
        i_rst_n = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        m_axis_tready = 1;

        // N?p files cho Stream và Golden
        $readmemh("file0.hex", mem_file0);
        $readmemh("file1.hex", mem_file1);
        $readmemh("file2.hex", mem_file2);
        $readmemh("file3.hex", mem_file3);
        $readmemh("golden_kernel.hex", mem_golden);
        $readmemh("downs1_s2_golden_kernel.hex", mem1_golden);
        
        #100; i_rst_n <= 1; #50;

        // B?t ð?u truy?n d? li?u
        send_file_data(1692,  0);
        repeat(50) @(posedge i_clk);
        send_file_data(12480, 1);
        repeat(50) @(posedge i_clk);
        send_file_data(528,   2);
        repeat(50) @(posedge i_clk);
        send_file_data(24576, 3);
        
        wait(stage == 1 && golden_ptr == 4096);
        #1000;
        $display("Mo phong ket thuc!");
        $finish;
    end

    // --- Logic so sánh 2 Stage (S2 & DOWNS1) ---
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            golden_ptr  <= 0;
            error_count <= 0;
            pass_count  <= 0;
            stage       <= 0;
        end else begin
            if (top_lb_kernel_vld_0) begin
                if (stage == 0) begin
                    // Stage S2: 16384 m?u
                    if (top_lb_kernel_0 === mem_golden[golden_ptr]) begin
                        pass_count <= pass_count + 1;
                        $display("[%0t ns] [STAGE 0-PASS] %0d/16384", $time, pass_count + 1);
                    end else begin
                        error_count <= error_count + 1;
                        $display("[%0t ns] [STAGE 0-FAIL] Ptr: %0d | Exp: %h | Got: %h", $time, golden_ptr, mem_golden[golden_ptr], top_lb_kernel_0);
                    end
                end else begin
                    // Stage DOWNS1: 4096 m?u
                    if (top_lb_kernel_0 === mem1_golden[golden_ptr]) begin
                        pass_count <= pass_count + 1;
                        $display("[%0t ns] [STAGE 1-PASS] %0d/4096", $time, golden_ptr + 1);
                    end else begin
                        error_count <= error_count + 1;
                        $display("================================================================");
                        $display("[%0t ns] [FAIL] At: %0d", $time, golden_ptr);
                        $display("(GOLDEN)  : %h", mem1_golden[golden_ptr]);
                        $display("(HARDWARE): %h", top_lb_kernel_0);
                        $display("================================================================");
    //                
//                        $display("[%0t ns] [STAGE 1-FAIL] Ptr: %0d | Exp: %h | Got: %h", $time, golden_ptr, mem1_golden[golden_ptr], top_lb_kernel_0);
                    end
                end
                
                golden_ptr <= golden_ptr + 1;
            end

            // Ki?m tra chuy?n stage
            if (stage == 0 && golden_ptr == 16384) begin
                $display("\n>>> CHUYEN SANG STAGE 1 (DOWNS1)...");
                stage      <= 1;
                golden_ptr <= 0;
            end 
            
            // T?ng k?t khi k?t thúc stage 1
            if (stage == 1 && golden_ptr == 4096) begin
                $display("\n=========================================================");
                $display("TONG KET: Stage 0 (S2) & Stage 1 (DOWNS1)");
                $display(" - Tong loi: %0d", error_count);
                if (error_count == 0) $display(" KET LUAN: HARDWARE DAT CHUAN GOLDEN.");
                else                  $display(" KET LUAN: LOGIC SAI, CAN KIEM TRA.");
                $display("=========================================================\n");
            end
        end
    end

endmodule