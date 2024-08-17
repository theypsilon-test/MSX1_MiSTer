/*verilator tracing_off*/
module sd_card #(parameter WIDE = 0, OCTAL=0)
(
	input             clk_sys,
	input             reset,

	input             sdhc,
	input             img_mounted,
	input      [63:0] img_size,

	output reg [31:0] sd_lba,
	output reg        sd_rd,
	output reg        sd_wr,
	input             sd_ack,

	input      [AW:0] sd_buff_addr,
	input      [DW:0] sd_buff_dout,
	output     [DW:0] sd_buff_din,
	input             sd_buff_wr,

	// SPI interface
	input             clk_spi,

	input             ss,
	input             sck,
	input      [SW:0] mosi,
	output reg [SW:0] miso
);

localparam AW = WIDE  ?  7 : 8;
localparam DW = WIDE  ? 15 : 7;
localparam SZ = OCTAL ?  8 : 1;
localparam SW = SZ-1;

endmodule