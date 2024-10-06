module tape
(
	input           clk,
	input           ce_5m3,
	input           play,
	input           rewind,
	output  [27:0]	ram_a,
	input   [7:0]   ram_di,
	output          ram_rd,
	input           buff_mem_ready,
	output          cas_out
);

endmodule