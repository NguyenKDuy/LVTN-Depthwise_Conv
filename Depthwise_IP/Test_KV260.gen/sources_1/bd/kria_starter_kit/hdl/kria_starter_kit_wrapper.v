//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Wed Dec 17 19:23:24 2025
//Host        : DESKTOP-CP36ASO running 64-bit major release  (build 9200)
//Command     : generate_target kria_starter_kit_wrapper.bd
//Design      : kria_starter_kit_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module kria_starter_kit_wrapper
   (fan_en_b,
    pmod_gpio_tri_io);
  output [0:0]fan_en_b;
  inout [7:0]pmod_gpio_tri_io;

  wire [0:0]fan_en_b;
  wire [0:0]pmod_gpio_tri_i_0;
  wire [1:1]pmod_gpio_tri_i_1;
  wire [2:2]pmod_gpio_tri_i_2;
  wire [3:3]pmod_gpio_tri_i_3;
  wire [4:4]pmod_gpio_tri_i_4;
  wire [5:5]pmod_gpio_tri_i_5;
  wire [6:6]pmod_gpio_tri_i_6;
  wire [7:7]pmod_gpio_tri_i_7;
  wire [0:0]pmod_gpio_tri_io_0;
  wire [1:1]pmod_gpio_tri_io_1;
  wire [2:2]pmod_gpio_tri_io_2;
  wire [3:3]pmod_gpio_tri_io_3;
  wire [4:4]pmod_gpio_tri_io_4;
  wire [5:5]pmod_gpio_tri_io_5;
  wire [6:6]pmod_gpio_tri_io_6;
  wire [7:7]pmod_gpio_tri_io_7;
  wire [0:0]pmod_gpio_tri_o_0;
  wire [1:1]pmod_gpio_tri_o_1;
  wire [2:2]pmod_gpio_tri_o_2;
  wire [3:3]pmod_gpio_tri_o_3;
  wire [4:4]pmod_gpio_tri_o_4;
  wire [5:5]pmod_gpio_tri_o_5;
  wire [6:6]pmod_gpio_tri_o_6;
  wire [7:7]pmod_gpio_tri_o_7;
  wire [0:0]pmod_gpio_tri_t_0;
  wire [1:1]pmod_gpio_tri_t_1;
  wire [2:2]pmod_gpio_tri_t_2;
  wire [3:3]pmod_gpio_tri_t_3;
  wire [4:4]pmod_gpio_tri_t_4;
  wire [5:5]pmod_gpio_tri_t_5;
  wire [6:6]pmod_gpio_tri_t_6;
  wire [7:7]pmod_gpio_tri_t_7;

  kria_starter_kit kria_starter_kit_i
       (.fan_en_b(fan_en_b),
        .pmod_gpio_tri_i({pmod_gpio_tri_i_7,pmod_gpio_tri_i_6,pmod_gpio_tri_i_5,pmod_gpio_tri_i_4,pmod_gpio_tri_i_3,pmod_gpio_tri_i_2,pmod_gpio_tri_i_1,pmod_gpio_tri_i_0}),
        .pmod_gpio_tri_o({pmod_gpio_tri_o_7,pmod_gpio_tri_o_6,pmod_gpio_tri_o_5,pmod_gpio_tri_o_4,pmod_gpio_tri_o_3,pmod_gpio_tri_o_2,pmod_gpio_tri_o_1,pmod_gpio_tri_o_0}),
        .pmod_gpio_tri_t({pmod_gpio_tri_t_7,pmod_gpio_tri_t_6,pmod_gpio_tri_t_5,pmod_gpio_tri_t_4,pmod_gpio_tri_t_3,pmod_gpio_tri_t_2,pmod_gpio_tri_t_1,pmod_gpio_tri_t_0}));
  IOBUF pmod_gpio_tri_iobuf_0
       (.I(pmod_gpio_tri_o_0),
        .IO(pmod_gpio_tri_io[0]),
        .O(pmod_gpio_tri_i_0),
        .T(pmod_gpio_tri_t_0));
  IOBUF pmod_gpio_tri_iobuf_1
       (.I(pmod_gpio_tri_o_1),
        .IO(pmod_gpio_tri_io[1]),
        .O(pmod_gpio_tri_i_1),
        .T(pmod_gpio_tri_t_1));
  IOBUF pmod_gpio_tri_iobuf_2
       (.I(pmod_gpio_tri_o_2),
        .IO(pmod_gpio_tri_io[2]),
        .O(pmod_gpio_tri_i_2),
        .T(pmod_gpio_tri_t_2));
  IOBUF pmod_gpio_tri_iobuf_3
       (.I(pmod_gpio_tri_o_3),
        .IO(pmod_gpio_tri_io[3]),
        .O(pmod_gpio_tri_i_3),
        .T(pmod_gpio_tri_t_3));
  IOBUF pmod_gpio_tri_iobuf_4
       (.I(pmod_gpio_tri_o_4),
        .IO(pmod_gpio_tri_io[4]),
        .O(pmod_gpio_tri_i_4),
        .T(pmod_gpio_tri_t_4));
  IOBUF pmod_gpio_tri_iobuf_5
       (.I(pmod_gpio_tri_o_5),
        .IO(pmod_gpio_tri_io[5]),
        .O(pmod_gpio_tri_i_5),
        .T(pmod_gpio_tri_t_5));
  IOBUF pmod_gpio_tri_iobuf_6
       (.I(pmod_gpio_tri_o_6),
        .IO(pmod_gpio_tri_io[6]),
        .O(pmod_gpio_tri_i_6),
        .T(pmod_gpio_tri_t_6));
  IOBUF pmod_gpio_tri_iobuf_7
       (.I(pmod_gpio_tri_o_7),
        .IO(pmod_gpio_tri_io[7]),
        .O(pmod_gpio_tri_i_7),
        .T(pmod_gpio_tri_t_7));
endmodule
