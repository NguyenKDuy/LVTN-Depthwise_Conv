module line_buffer (
    input               i_clk,
    input               i_rst_n,
    input  [255:0]      i_linedata,
    input               i_enable,
    input               i_vld,
    input               i_rd_data,
    input  [1:0]        i_config_stride,
    input  [7:0]        i_config_max_line_in,
    input  [7:0]        i_config_max_line_out,
    output [767:0]      o_linedata,
    output              o_almost_done,
    output      [7:0]   rdPntr       
);

    // -------------------------------------------------------------------------
    // 1. Chia nh? b? nh? (Partitioning)
    // Thay v? 1 m?ng 256-bit, ta chia thành 4 m?ng 64-bit
    // -------------------------------------------------------------------------
    (* ram_style = "distributed" *) reg [63:0] line_b0 [129:0]; 
    (* ram_style = "distributed" *) reg [63:0] line_b1 [129:0];
    (* ram_style = "distributed" *) reg [63:0] line_b2 [129:0];
    (* ram_style = "distributed" *) reg [63:0] line_b3 [129:0];

    // -------------------------------------------------------------------------
    // 2. Nhân b?n Write Pointer (Replication)
    // Dùng thu?c tính DONT_TOUCH ð? Vivado không g?p chúng l?i thành 1
    // -------------------------------------------------------------------------
    (*MAX_FANOUT = 50*) (* dont_touch = "yes" *) reg [7:0] wrPntr_rep0;
    (*MAX_FANOUT = 50*) (* dont_touch = "yes" *) reg [7:0] wrPntr_rep1;
    (*MAX_FANOUT = 50*) (* dont_touch = "yes" *) reg [7:0] wrPntr_rep2;
    (*MAX_FANOUT = 50*) (* dont_touch = "yes" *) reg [7:0] wrPntr_rep3;

    reg [7:0] max_line_in_p1;
    reg [7:0] max_line_out_p1;
    reg [7:0] rdPntr_reg; // Internal read pointer
    
    assign rdPntr = rdPntr_reg;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            max_line_in_p1  <= 8'd0;
            max_line_out_p1 <= 8'd0;
        end else begin
            max_line_in_p1  <= i_config_max_line_in  + 8'd1;
            max_line_out_p1 <= i_config_max_line_in - i_config_stride;
        end
    end

    // -------------------------------------------------------------------------
    // 3. C?p nh?t Write Logic ð?ng b? cho các b?n sao
    // -------------------------------------------------------------------------
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            wrPntr_rep0 <= 8'd0; wrPntr_rep1 <= 8'd0;
            wrPntr_rep2 <= 8'd0; wrPntr_rep3 <= 8'd0;
        end else if (i_vld && i_enable) begin
            // Logic wrap-around gi? nguyên
            if (wrPntr_rep0 >= max_line_in_p1) begin
                wrPntr_rep0 <= 8'd0; wrPntr_rep1 <= 8'd0;
                wrPntr_rep2 <= 8'd0; wrPntr_rep3 <= 8'd0;
            end else begin
                wrPntr_rep0 <= wrPntr_rep0 + 8'd1;
                wrPntr_rep1 <= wrPntr_rep1 + 8'd1;
                wrPntr_rep2 <= wrPntr_rep2 + 8'd1;
                wrPntr_rep3 <= wrPntr_rep3 + 8'd1;
            end
            
            // M?i con tr? ch? ði?u khi?n ghi vào "phân khu" c?a nó
            line_b0[wrPntr_rep0] <= i_linedata[63:0];
            line_b1[wrPntr_rep1] <= i_linedata[127:64];
            line_b2[wrPntr_rep2] <= i_linedata[191:128];
            line_b3[wrPntr_rep3] <= i_linedata[255:192];
        end
    end

    // -------------------------------------------------------------------------
    // 4. Read Logic (Týõng t? có th? nhân b?n rdPntr n?u c?n)
    // -------------------------------------------------------------------------
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            rdPntr_reg <= 8'd0;
        end else if (i_rd_data) begin
            if (rdPntr_reg >= max_line_out_p1)
                rdPntr_reg <= 8'd0;
            else
                rdPntr_reg <= rdPntr_reg + {6'd0, i_config_stride};
        end
    end

    // Registered Read Output
    reg [255:0] line_rd0, line_rd1, line_rd2;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            {line_rd0, line_rd1, line_rd2} <= 768'd0;
        end else begin
            // Gom d? li?u t? các sub-blocks khi ð?c
            line_rd0 <= {line_b3[rdPntr_reg], line_b2[rdPntr_reg], line_b1[rdPntr_reg], line_b0[rdPntr_reg]};
            line_rd1 <= {line_b3[rdPntr_reg + 8'd1], line_b2[rdPntr_reg + 8'd1], line_b1[rdPntr_reg + 8'd1], line_b0[rdPntr_reg + 8'd1]};
            line_rd2 <= {line_b3[rdPntr_reg + 8'd2], line_b2[rdPntr_reg + 8'd2], line_b1[rdPntr_reg + 8'd2], line_b0[rdPntr_reg + 8'd2]};
        end
    end

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pack_channels
            assign o_linedata[i*48 +: 48] = {
                line_rd2[i*16 +: 16], 
                line_rd1[i*16 +: 16], 
                line_rd0[i*16 +: 16]
            };
        end
    endgenerate

    assign o_almost_done = (rdPntr_reg >= max_line_out_p1);

endmodule