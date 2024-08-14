module spi_divmmc
(
	input        clk_sys,
	output       ready,

	input        tx,        // Byte ready to be transmitted
	input        rx,        // request to read one byte
	input  [7:0] din,
	output [7:0] dout,

	input        spi_ce,
	output       spi_clk,
	input        spi_di,
	output       spi_do
);

endmodule