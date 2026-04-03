// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
// Date        : Wed Dec 17 19:33:58 2025
// Host        : DESKTOP-CP36ASO running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/LAB/Test_KV260/Test_KV260.gen/sources_1/bd/kria_starter_kit/ip/kria_starter_kit_axi_bram_ctrl_0_bram_0/kria_starter_kit_axi_bram_ctrl_0_bram_0_sim_netlist.v
// Design      : kria_starter_kit_axi_bram_ctrl_0_bram_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xck26-sfvc784-2LV-c
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "kria_starter_kit_axi_bram_ctrl_0_bram_0,blk_mem_gen_v8_4_9,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_9,Vivado 2024.2" *) 
(* NotValidForBitStream *)
module kria_starter_kit_axi_bram_ctrl_0_bram_0
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
  kria_starter_kit_axi_bram_ctrl_0_bram_0_blk_mem_gen_v8_4_9 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 57408)
`pragma protect data_block
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
RgB03c+QKF18
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
