

module accelerator (
    input clk,
    input i_rst_n,
    input [16 * 4 - 1 : 0] data_in,
    input i_data_valid,
    input i_ready, //fake for depthwise
    output o_valid, //fake for depthwise
//    output o_ready,
    output [16 * 4 - 1:0] data_out1,
    output [16 * 4 - 1:0] data_out2,
    output [16 * 4 - 1:0] data_out3,
    output [3:0] top_stage);
//    output o_intrp);
/////////////////////////////////////////////////////////////////////////////
// PAREMETERS

parameter KERNEL_UNROLLING = 9;
parameter DEPTH_UNROLLING = 9; 
parameter POINT_UNROLLING = 32;
parameter ADDRESS = 15;
/////////////////////////////////////////////////////////////////////////////
// DEFINE CONNECTIONS
    wire [1:0] t_stage; // receptor stage only
    wire [ADDRESS - 1:0] t_wr_address1, t_wr_address2, t_wr_address3, o_r_address1, o_r_address2, o_r_address3;
    wire t_data_valid1, t_data_valid2, t_data_valid3;
    // read data from memory
    wire [`PIXEL_WIDTH * 4 - 1 : 0]t_data_out;
/////////////////////////////////////////////////////////////////////////    
    receptor R0(
        .i_data_in(data_in),
        .i_rst (i_rst_n),
        .i_clk (clk),
        .i_data_valid(i_data_valid),
        .o_stage (t_stage),
        //depthwise
        .o_wr_address1(t_wr_address1),
        .o_data_valid1(t_data_valid1),
        //pointwise 
        .o_wr_address2 (t_wr_address2),
        .o_data_valid2(t_data_valid2),
        //image in
        .o_wr_address3 (t_wr_address3),
        .o_data_valid3(t_data_valid3),
        
        .o_data_out (t_data_out)
    ); 
    
/////////////////////////////////////////////////////////////////////////////
// DEFINE CONNECTIONS
    wire [`PIXEL_WIDTH * 4 - 1 : 0] t_rdweight_out;
    wire [`PIXEL_WIDTH * 4 - 1 : 0] t_rpweight_out;
    wire [`PIXEL_WIDTH * 4 - 1 : 0] t_rdata_out;
    wire [9*16 - 1: 0] o_data1;
    wire [544 - 1: 0] o_data3; 
   
/////////////////////////////////////////////////////////////////////////     
    
    wire r_enable_mux = (top_stage == 'd1 || top_stage == 'd0) ? 1 : 0;
     wire [63 : 0] i_data_mux = (top_stage == 'd1 || top_stage == 'd0) ? data_out3 : data_out2;
    
    simple_dual_two_clocks 
    #(.DEPTH(2030)) depth_mem
    (.clka(clk),
    .clkb (clk),
    .ena (1'b1), // always allow
    .enb (o_r_enable1), // TEMP
    .wea (t_data_valid1),
    .addra (t_wr_address1),
    .addrb (o_r_address1), // TEMP
    .dia (t_data_out),
    .dob (data_out1));
    
    wire [3:0] i_stage;
    depth_mem_control dmc (
        .i_clk(clk),
        .i_rst_n(i_rst_n),
        .i_stage(top_stage),
        .i_data(data_out1),
        .i_dready(i_ready),
        .o_r_address(o_r_address1),
        .o_r_enable(o_r_enable1),
        .o_data(o_data1),
        .o_valid(o_valid1)
    );
    
    simple_dual_two_clocks 
    #(.DEPTH(26952)) point_mem
    (.clka(clk),
    .clkb (clk),
    .ena (1'b1), // always allow
    .enb (1'b1), // TEMP
    .wea (t_data_valid2),
    .addra (t_wr_address2),
    .addrb (t_wr_address2), // TEMP
    .dia (t_data_out),
    .dob ());
    
    simple_dual_two_clocks 
    #(.DEPTH(24576), .INIT_FILE("image_64bit_debug.hex")) image_mem
    (.clka(clk),
    .clkb (clk),
    .ena (1'b1), // always allow
    .enb (r_enable_mux), // TEMP
    .wea (t_data_valid3),
    .addra (t_wr_address3),
    .addrb (o_r_address3), // TEMP
    .dia (t_data_out),
    .dob (data_out3));
    
    assign i_enable = (t_wr_address3 >= `ENABLE) ? 1 : 0;
    
    data_controller data_control (
        .i_clk(clk),
        .i_rst_n(i_rst_n),
        .i_enable(i_enable),
        .i_pwdone(i_pwdone),
        .i_data(i_data_mux), // choose from data_3 or data_2
        .i_dready(i_ready),
        .o_stage(top_stage),
        .o_r_address(o_r_address3),
        .o_r_enable(),
        .o_data(o_data3),
        .o_valid(o_valid)
    );
        
       
    
    simple_dual_two_clocks 
    #(.DEPTH(32768), .INIT_FILE("downs1_ram_q0.hex")) imm_data
    (.clka(clk),
    .clkb (clk),
    .ena (1'b1), // always allow
    .enb (!r_enable_mux), // TEMP
    .wea (t_data_valid3),
    .addra (t_wr_address3),
    .addrb (o_r_address3), // TEMP
    .dia (t_data_out),
    .dob (data_out2));
    
      
endmodule