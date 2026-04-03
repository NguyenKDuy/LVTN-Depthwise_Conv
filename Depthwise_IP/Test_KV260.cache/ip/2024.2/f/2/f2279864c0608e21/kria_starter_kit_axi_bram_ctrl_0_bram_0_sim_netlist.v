// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
// Date        : Wed Dec 17 19:33:56 2025
// Host        : DESKTOP-CP36ASO running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ kria_starter_kit_axi_bram_ctrl_0_bram_0_sim_netlist.v
// Design      : kria_starter_kit_axi_bram_ctrl_0_bram_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xck26-sfvc784-2LV-c
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "kria_starter_kit_axi_bram_ctrl_0_bram_0,blk_mem_gen_v8_4_9,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_9,Vivado 2024.2" *) 
(* NotValidForBitStream *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix
   (clka,
    rsta,
    ena,
    wea,
    addra,
    dina,
    douta,
    rsta_busy);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_mode = "slave BRAM_PORTA" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA RST" *) input rsta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [3:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [31:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [31:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [31:0]douta;
  output rsta_busy;

  wire [31:0]addra;
  wire clka;
  wire [31:0]dina;
  wire [31:0]douta;
  wire ena;
  wire rsta;
  wire rsta_busy;
  wire [3:0]wea;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [31:0]NLW_U0_doutb_UNCONNECTED;
  wire [31:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "32" *) 
  (* C_ADDRB_WIDTH = "32" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "8" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "2" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "1" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "1" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     2.930189 mW" *) 
  (* C_FAMILY = "zynquplus" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "1" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "NONE" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "0" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "2048" *) 
  (* C_READ_DEPTH_B = "2048" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "32" *) 
  (* C_READ_WIDTH_B = "32" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "1" *) 
  (* C_USE_BYTE_WEA = "1" *) 
  (* C_USE_BYTE_WEB = "1" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "4" *) 
  (* C_WEB_WIDTH = "4" *) 
  (* C_WRITE_DEPTH_A = "2048" *) 
  (* C_WRITE_DEPTH_B = "2048" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_blk_mem_gen_v8_4_9 U0
       (.addra({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,addra[12:2],1'b0,1'b0}),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[31:0]),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[31:0]),
        .regcea(1'b1),
        .regceb(1'b1),
        .rsta(rsta),
        .rsta_busy(rsta_busy),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[31:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web({1'b0,1'b0,1'b0,1'b0}));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2024.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
FPXllyX2NFs/RMngGqZy2bLYbZr92CdofeZrJOHklWXExpaPgHNYp2Lzm4MnflbnrfSkCmLwwKT5
zfRgEip7FKQ5Zhb73p0MAIADixBZ/ZRt4hQkJL0T9brm0waLHfanjnov2aCX6jN3LbQc3ujmDga6
Dd73k78u4xjRTDv1/P4=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
kr7VKKvChFoiyRCReag+OvU3jnmG9pN0cv+BxhNmMKLthg/ksgNZyU3L+fQ7cmIQELtlUjwjkBAP
Jjq5RsCnHbJxj+Ys1GNhriiBsxLqxWCP8onhAVvgZN2xZFOih0UWpqlU8NVP8Eww1ohvkDgxTstC
3kDmYehxIUJjqCC/mgRZmuezqugrFdubYmBoz16tUvD17iA5qqCIMS9xSIXYp2LBNekmWEwrVqzu
R4koEo4UlXl/CEw0XY3QvMoHnlXgu6N/6sc+nxZtKSwjiMVvGnZE9UVvJPAC3Hn3zKFGlK53mmGO
Tj0dWzhwX0ahSYzkyJC/HLdbGZmriL2UNvDyFw==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
CaLc9FGt3AdRHfNtGAsGFY/QEvHY1Vv4TvvgCDsdDMqiuDeLizFJDJeskBWjeKDoE2cufK8TxiBq
mySRQNJoeOKnxTiDdf+Rx6m0iR6h/YeswegYwgghpM5KVrl6mSwF3+4yEovPM7a+9ArDQ5vl+WT8
SilNGzyW0KnTwe7+szs=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
cEnudSW1X71p0Xuq6jrXOxHnBku87IA0RA3zKqmeZHZM0r+9rEm5MSzX8RecnQ994yiqeyxbIH2l
fGEzUzr0ZzryS3fkf2LnJuB39f2YARW9eVCSiaeWaraZuY1l89T+h3vgdlurS/1LIraYLS1MyOXa
6F1LAcQp3W4OO4ctc3q1FRMZGldRS1biMsKwJ8Lxj8NEOm67UfgFrJNQAxbVXEfbWRWhKtwNxcTB
JbgC8j4EHkIA46mzoHloeBAL6KieplQUBjKXSSTb66rxglbFhWLy+mirROHcocu9J4ZbvTRYZEww
4lso1lqAllVLAoKYqa3WImZuSRoTbGDngBt9Lg==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
rOyI+x4PlmKcVSFoN3oKgSYpVlmYxc194Ej04il/YmBg10xopy4zmtu5sdCP/uGSNYcNGWeAiw01
mNf98KyNgTUFXruHCA38qjhhEIvl4vfWWn3W3mFRxrIuwmnreT6qTvgMaxIkCdVBDP7Iy7O6WmCf
3Va5X5hnCHhtXgX5UYniBHiLjmupv63B8XMAYDH2n6mQ3H0DF7mtb7psBafd0Z6+IWUbmzwMtKrf
ZrRJBGAhNT0i1KrEjEh/rWjN7Z7N32zQ+Pl1kc5gYCQIX5McfdTdqSaRVXZ/HF90ymS7/8d5LDyj
Er+ORdcjnOn6oAyY4PuUUl4OYUHv5k+RglTe5Q==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2023_11", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
bJa7kPSpDipzoJoQu1APEjc8vFLqBfQZK/grZvWijD7/FgMTerFCWLUY6n8DWeGdvjXvTeyrqCHE
2rP/H57wUqPC8tIJlGm6ZYQGjZ3TgYqLrJshDE5zYMTO//q0vuSraWvZP7A7SLuW6y7tFE/nplpx
L8gbYORx6j70okGUwnamCMS9yhFr7Z2QTJne1k4GNFGvy66URk3k5cBPl5j4/1yc4xGV+aWYl6L8
q8RorRU/CltObHKrji/jdiY1WtdGrkpRyCEFc+XNPazL9xSLLu5bz6XlvKwoks+8a5KYT/VFUovM
JbM0bpAXM8Z7rGaPuXjqXtZBg5praTZLu/WNcA==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
PYKBDinOGc/kIVdFzXrz2wA4/QNFxLDrQfTWfR5TjYE6bm49vrZi0bawcr9HXp4OP1+XxPLB3oCP
oV5e/rYeDln531ebt8yEg27XCoSHEX4FU8oG8aBJ8fqgWayOnAMJt025WodOxuZXbhT1zPo7J3uh
6iO9Mv7RtYE2fZ1W+G8oN//FTOEJYPWlKYnt0cDeZrN3I4rHHptZHuu7l8T+df0PYea3x6U3Mvkl
ojZ+TwQtdu0NuYY5j3QNgx3+W2XYq1M773FAnEz/deW54EjE+jf1jjrBk2pl8SYxeKuutS15oPVF
eHdqXYVcJxoUY5JH8z04lITKEnZ4oq6sYS6dog==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
tl+2vFCWZ583gQGsVC7oopz2NCKBiJ9uOHYBGzJZheOHJMqI/ehNvo25l710eBx00tztXzM30AH6
ZhAJg+kJwE2jO0MV5fmG5dnwXmLqoGEJMBs7xwWxvYK7w/0z9M0AJKD7HnuC+IiLhNU/fIxyuE+I
+vWqp//RcfY0tMMp2I2J1yEW6GUahS1ve/4JchssZ7Xu7VthoSDWXMQWATbvsUsDzeSo2+Ruz8Kq
Dc05HqEU8NgBxDPPEKLCcdKLp4byglwj7iCAtCjsPy8P18qjgb2sycFjNgmaiNMMB51WqeD+hneG
hLOue9bqVdEojkrb3q4WbsGZKz0bAGsryxslOlYHP1b8vey3yI2ixA80wyERe8d3GRIeZiSxGykH
qWxsE6x/iyi8QRb5mXZPMApA+Fln8tYmn7+1rFCm8gF4gJWhr1PsSJqTi658symGrzT0Ghjvf2QL
SvvoaeNdy0pOsWs7jLBFndd4GiFA+9K6Y33sziLToU9EvvFokENIslod

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
oYiCujFRj1F3wKsGZlHR9niEtR9MLXEVAVfy+f/3xrmpW6Ye5a+fBCvm4TH+iRQefGHNdMPnzTNW
K/pEPAS9uMJjOdFiu+APT+LYrSRnEg4W0dX5buSDGM6LBWAuMseoTMjbJJoYDGLRckJgW43E30mX
ej4823nkbfwc+Ecbrup825qLyv8RTQLNHafvJA5lSapdqXwnlOIYRmcHn+sfAh5pGv9kW9aokcdh
ObR2XYxX99rYloyvz3x0pmjxD5ILW4SQMB1IUEuuyqX6eb5IQ+kZ41hjvsHIuQH29vzpCfV9Jqha
WC5yxxK1R+cleZSKD1H1gVzbTei8uFs/91Bgeg==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
urNc+S8AFPj+GVFdqJE5V7P8O6QI6MA3nkwYb8NKbYbVufnXKg6voJIRYYeYr7EOa8mrqirozWbY
Lln9SLWnkaAy2LvL/N6WahoQdCt++4RH+xe768XvSrVUFPrIwZRixqMLurc/tPov4i5P/ukZKl18
ZPZvXRzUNlvCZnMPcF+5QCQihqPbjcZ0YyGgWgX/ipTGG3sNqmylGN7qLa4Rgqu/mB5a2xVyu5Wc
911+/X3VVFx697WVaP5V0SbOzYN8R8+8B8kdznwixMA+f4lSbBXyRysVOSzYjo8bKEMqyKMVBQn9
xDmEuV0DvVWXdO7VPvWA1LuJFwS07OxeI2GCcQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QcP7fsLZxaDrG29e9HQeXfu2TsKsdyW7Yc1vWct6lbmDEfXkWMU1fFWSPIjPzRc9UOnfEu0bRn+B
D+8MWokqes3WF7txljBmgUPiNGZ8arUU6ENa/IY/Wv7iaB/ZKM5PtdnFAkjDIrYyKFCTz/U6Yzwi
hBGGarK/wYQOLzeeKRewiPTiNUL7tztWuMZ1t1msxD951EeKrwjrjcXIIuf/TzrOGUOlWgjHlnrl
4Q/lfMAnRLBNTSWG+5wWewCE8jK2X/gJ5AV4p3x1WP3+JglbxpP39l3pzedXqciZPbuz2XlFnRPV
KByaUaAShzJ56p8+0HjWebibqQdieGNPiPWW0Q==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 57152)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
