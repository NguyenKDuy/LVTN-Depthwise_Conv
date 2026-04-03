// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------

`timescale 1 ps / 1 ps

(* BLOCK_STUB = "true" *)
module kria_starter_kit (
  fan_en_b,
  pmod_gpio_tri_i,
  pmod_gpio_tri_o,
  pmod_gpio_tri_t
);

  (* X_INTERFACE_IGNORE = "true" *)
  output [0:0]fan_en_b;
  (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 pmod_gpio TRI_I" *)
  (* X_INTERFACE_MODE = "master pmod_gpio" *)
  input [7:0]pmod_gpio_tri_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 pmod_gpio TRI_O" *)
  output [7:0]pmod_gpio_tri_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:gpio:1.0 pmod_gpio TRI_T" *)
  output [7:0]pmod_gpio_tri_t;

  // stub module has no contents

endmodule
