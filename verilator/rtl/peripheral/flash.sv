module flash (
	input                 clk,
	input                 clk_sdram,
	flash_bus_if.flash_mp flash_bus,
	input                 sdram_ready,
	input                 sdram_done,
	output   logic [26:0] sdram_addr,
	output   logic  [7:0] sdram_din,
	output   logic        sdram_req,
	input          [26:0] sdram_offset,
	output                debug_erase
);

assign sdram_req = 1'b0;

endmodule
