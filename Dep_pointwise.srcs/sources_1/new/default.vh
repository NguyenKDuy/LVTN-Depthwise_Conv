`ifndef DEFAULT
`define DEFAULT
//----------------------
`define TILE_SIZE       16
`define WEIGHT_WIDTH    16
`define UC  2
//
`define PIXEL_WIDTH     16

`define MULTI_DATA_4    4
/////////////////////////////////////////////////////////////////////////////////
//MODEL SPECIFICATIONS
//`define PARAMETERS      117334
`define POINTWISE_64  26952 
`define DEPTHWISE_64  2030 // 8118 + 2 (dý) / 4
`define COVER           49152
`define SECRET          49152
//`define PARAMETERS      768
//`define COVER           384
//`define SECRET          384
`define ENABLE          128 * 128 * 2 + 291
`endif // GLOBAL_DEFS_VH
