/*verilator tracing_off*/
module vdp
(
input        CLK21M,
input        RESET,
input        REQ,
output        ACK,
input        WRT,
input  [15:0]      ADR,
output [7:0]       DBI,
input  [7:0]      DBO,

output        INT_N,

output        PRAMOE_N,
output        PRAMWE_N,
output [16:0]       PRAMADR,
input  [15:0]      PRAMDBI,
output [7:0]       PRAMDBO,

input        VDPSPEEDMODE,
input  [2:0]      RATIOMODE,
input        CENTERYJK_R25_N,

output [5:0]       PVIDEOR,
output [5:0]       PVIDEOG,
output [5:0]       PVIDEOB,
output        PVIDEODE,

output        PVIDEOHS_N,
output        PVIDEOVS_N,
output        PVIDEOCS_N,

output        PVIDEODHCLK,
output        PVIDEODLCLK,

output        BLANK_O,
output        HBLANK,
output        VBLANK,

input        DISPRESO,

input        NTSC_PAL_TYPE,
input        FORCED_V_MODE,
input        LEGACY_VGA,
input        BORDER,

input [4:0]        VDP_ID,
input [6:0]       OFFSET_Y
);

endmodule