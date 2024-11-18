module spi_divmmc
(
	input        clk_sys,
	ext_sd_card_if.SD_mp	ext_SD_card_bus,
	output       ready,
	input        spi_ce,
	output       spi_clk,
	input        spi_di,
	output       spi_do
);

endmodule