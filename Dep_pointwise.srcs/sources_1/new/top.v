

module accelerator (
    input clk,
    input i_rst_n,
    input [16 * 4 - 1 : 0] data_in,
    input i_data_valid,
    input i_ready, //fake for depthwise
    output o_valid, //fake for depthwise
//    output o_ready,
    output [16 * 4 - 1:0] dw_out,
    output [16 * 4 - 1:0] pw_out,
    output [543: 0] line_buffer,
    output [3:0] top_stage);
//    output o_intrp);
/////////////////////////////////////////////////////////////////////////////
// PAREMETERS
parameter ADDRESS = 17;
parameter BIT_WIDTH = 16;
///////////////////////////////////////////////////////////////////
// FSM:    
localparam IDLE = 'd0;
localparam HEAD = 'd1;
localparam DOWNS1 = 'd2;
localparam DOWNS2 = 'd3;
localparam BOTT   = 'd4;
localparam UPS1 = 'd5;
localparam UPS2 = 'd6;
localparam UPS3 = 'd7;
localparam TAIL = 'd8;
localparam TANH = 'd9; 
    

/////////////////////////////////////////////////////////////////////////////
// DEFINE CONNECTIONS

wire [ADDRESS - 1:0] top_dw_addr_write, top_pw_addr_write, top_data_addr_write;
wire [ADDRESS - 1:0] top_r_address1, top_r_address2, top_r_address3;
wire [ADDRESS - 1:0] top_dw_addr_read, top_pw_addr_read, top_data_addr_read;
wire t_data_valid1, t_data_valid2, t_data_valid3;
// read data from memory
wire [BIT_WIDTH * 4 - 1 : 0]top_data_out;
wire [16 * 4 - 1:0] data_out1, data_out2, data_out3, data_out4, data_out5, data_out6;
wire [1:0] receptor_stage; // receptor stage only


wire [9*16 - 1: 0] dw_weight; //output depthwise
wire [32*16/ - 1: 0] pw_weight; //output depthwise

/////////////////////////////////////////////////////////////////////////    
    receptor R0(
        .i_data_in(data_in),
        .i_rst (i_rst_n),
        .i_clk (clk),
        .i_data_valid(i_data_valid),
        .o_stage (receptor_stage),
        //depthwise
        .o_wr_address1(top_dw_addr_write[14:0]),
        .o_data_valid1(dw_data_valid),
        //pointwise 
        .o_wr_address2 (top_pw_addr_write[14:0]),
        .o_data_valid2(pw_data_valid),
        //image in
        .o_wr_address3 (top_data_addr_write[14:0]),
        .o_data_valid3(top_data_valid),
        
        .o_data_out (top_data_out)
    ); 
    
/////////////////////////////////////////////////////////////////////////////
// DEFINE CONNECTIONS


 
   
/////////////////////////////////////////////////////////////////////////     
    wire [8:0] top_tile_z;
    wire [63:0] i_data_mux = data_out1;
    wire z_ge_128 = top_tile_z[7];
    wire z_ge_64  = top_tile_z[6] | z_ge_128;
    wire z_ge_32  = top_tile_z[5] | z_ge_64;
    
    //Sheet for double check: https://docs.google.com/spreadsheets/d/1iLmxfv-W6FNoyb50cLoB3PKGHX_CfcvFqyitnjS8ZcA/edit?gid=201810695#gid=201810695
//    always @(*) begin
//        case (top_stage)
//            IDLE, HEAD: i_data_mux = data_out1; 
//            DOWNS1:     i_data_mux = data_out2;  
//            DOWNS2:     i_data_mux = data_out3;  
//            BOTT:       i_data_mux =  data_out4; 
//            UPS1    :   i_data_mux = z_ge_128 ? data_out4 : data_out5; //Output D2
//            UPS2:       i_data_mux = z_ge_64 ? data_out6 : data_out3;
//            UPS3:       i_data_mux = z_ge_32 ? data_out5 : data_out2;
//            default:    i_data_mux = 64'h0;
//        endcase
//    end

/////////////////////////////////////////////////////////////////////////     
//DEPTHWISE MEMORY AND CONTROLLER    
    simple_dual_two_clocks 
    #(.DEPTH(2030)
    ,.ADDRESS (11)
    ,.RAM_STYLE("block")
    ) depth_mem
    (.clka(clk),
    .clkb (clk),
    .ena (1'b1), // always allow
    .enb (1'b1), // TEMP
    .wea (dw_data_valid),
    .addra (top_dw_addr_write[10:0]),
    .addrb (top_dw_addr_read[10:0]), // TEMP
    .dia (top_data_out),
    .dob (dw_out)
    );
    
    wire [3:0] i_stage;
    depth_mem_control dmc (
        .i_clk(clk),
        .i_rst_n(i_rst_n),
        .i_stage(top_stage),
        .i_data(dw_out),
        .i_dready(i_ready),
        .o_r_address(top_dw_addr_read[14:0]),
        .o_r_enable(),                      //don't care;
        .o_data(dw_weight),
        .o_valid(dw_valid)
    );
    
    simple_dual_two_clocks 
    #(.DEPTH(26952)
    ,.ADDRESS(15)
    ,.RAM_STYLE("block") // Chýa chia n?a.
    ) point_mem
    (.clka(clk),
    .clkb (clk),
    .ena (1'b1), // always allow
    .enb (1'b1), // TEMP
    .wea (pw_data_valid),
    .addra (top_pw_addr_write[14:0]),
    .addrb (top_pw_addr_read[14:0]), 
    .dia (top_data_out),
    .dob (pw_out));
    
    simple_dual_one_clocks 
    #(.DEPTH(24576)
    ,.ADDRESS(15)
//    , .INIT_FILE("image_64bit_debug.hex")
    ,. RAM_STYLE("ultra")
    ) image_mem
    (.clk(clk),
    .ena (1'b1), // always allow
    .enb (1'b1), 
    .wea (1'b1),                            //TEMP - wait for routing
    .addra (top_data_addr_write[14:0]),
    .addrb (top_data_addr_read[14:0]), 
    .dia (top_data_out),
    .dob (data_out1));
    
    assign i_enable = (top_data_addr_write >= `ENABLE) ? 1 : 0;
    
    data_controller 
    #(.ADDRESS(17))
    data_control
        (
        .i_clk(clk),
        .i_rst_n(i_rst_n),
        .i_enable(i_enable),                //TEMP - wait for start prepare data
        .i_pwdone(i_ready),                 //TEMP - wait for stage transition
        .i_data(i_data_mux), 
        .i_dready(i_ready),                 //TEMP - wait for export line buffer
        .o_stage(top_stage),
        .o_r_address(top_data_addr_read),
        .o_r_enable(),                      //dont care - X
        .o_data(line_buffer),
        .o_valid(o_valid),                  //TEMP
        .tile_z(top_tile_z)
    );
        
       
    
    
    simple_dual_one_clock 
    #(.DEPTH(32768)
    ,.ADDRESS (15)
//    , .INIT_FILE("downs1_ram_q0.hex")
    ,. RAM_STYLE("ultra")
    ) head_mem
    (.clk(clk),
    .ena (1'b1), // always allow
    .enb (1'b1), // always allow
    .wea (1'b1),                                    //TEMP - wait for routing
    .addra (top_data_addr_read[14:0]),              //TEMP - wait for routing
    .addrb (top_data_addr_read[14:0]), 
    .dia (top_data_out),                            //TEMP - wait for routing
    .dob (data_out2));
    
    simple_dual_one_clock 
    #(.DEPTH(16384)
    ,.ADDRESS (14)
//    , .INIT_FILE("downs2_ram_q0.hex")
    ,. RAM_STYLE("ultra")
    ) downs1_mem
    (.clk(clk),
    .ena (1'b1), // always allow
    .enb (1'b1), 
    .wea (1'b1),                                    //TEMP - wait for routing
    .addra (top_data_addr_read[13:0]),               //TEMP - wait for routing    
    .addrb (top_data_addr_read[13:0]),  
    .dia (top_data_out),                            //TEMP - wait for routing
    .dob (data_out3));
    
    simple_dual_one_clock
    #(.DEPTH(8192)
    ,.ADDRESS (14)
//    , .INIT_FILE("bott_ram_q0.hex")
    ,. RAM_STYLE("ultra")
    ) downs2_mem
    (.clk(clk),
    .ena (1'b1), // always allow
    .enb (1'b1), 
    .wea (1'b1),                                    //TEMP - wait for routing
    .addra (top_data_addr_read[13:0]),               //TEMP - wait for routing    
    .addrb (top_data_addr_read[13:0]),  
    .dia (top_data_out),                            //TEMP - wait for routing
    .dob (data_out4));
    
    simple_dual_one_clock 
    #(.DEPTH(65536)     //share bot and up2
    ,.ADDRESS (17)
//    ,.INIT_FILE("bott_ram_q0.hex")
    ,. RAM_STYLE("ultra")
    ) bott_up2_mem
    (.clk(clk),
    .ena (1'b1), // always allow
    .enb (1'b1), 
    .wea (1'b1),                            //TEMP - wait for routing control
    .addra (top_data_addr_read[16:0]),      //TEMP - wait for routing control
    .addrb (top_data_addr_read[16:0]),  
    .dia (top_data_out),                    //TEMP - wait for routing control
    .dob (data_out5));
    
    simple_dual_one_clock 
    #(.DEPTH(32768)
    ,.ADDRESS(16)
    ,. RAM_STYLE("ultra")
    ) up1_up3_mem
    (.clk(clk),
    .ena (1'b1), // always allow
    .enb (1'b1), 
    .wea (1'b1),                            //routing control
    .addra (top_data_addr_read[15:0]),                 //routing control
    .addrb (top_data_addr_read[15:0]),  
    .dia (top_data_out),                    //routing control
    .dob (data_out6));
      
endmodule