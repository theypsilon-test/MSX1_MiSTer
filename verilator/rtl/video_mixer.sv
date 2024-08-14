module video_mixer
#(
	parameter LINE_LENGTH  = 768,
	parameter HALF_DEPTH   = 0,
	parameter GAMMA        = 0
)
(
	input            CLK_VIDEO, // should be multiple by (ce_pix*4)
	output reg       CE_PIXEL,  // output pixel clock enable

	input            ce_pix,    // input pixel clock or clock_enable

	input            scandoubler,
	input            hq2x, 	    // high quality 2x scaling

	inout     [21:0] gamma_bus,

	// color
	input [DWIDTH:0] R,
	input [DWIDTH:0] G,
	input [DWIDTH:0] B,

	// Positive pulses.
	input            HSync,
	input            VSync,
	input            HBlank,
	input            VBlank,

	// Freeze engine
	// HDMI: displays last frame 
	// VGA:  black screen with HSync and VSync
	input            HDMI_FREEZE,
	output           freeze_sync,

	// video output signals
	output reg [7:0] VGA_R,
	output reg [7:0] VGA_G,
	output reg [7:0] VGA_B,
	output reg       VGA_VS,
	output reg       VGA_HS,
	output reg       VGA_DE
);

localparam DWIDTH = HALF_DEPTH ? 3 : 7;
localparam DWIDTH_SD = GAMMA ? 7 : DWIDTH;
localparam HALF_DEPTH_SD = GAMMA ? 0 : HALF_DEPTH;

endmodule