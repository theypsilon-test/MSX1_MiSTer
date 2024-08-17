/*verilator tracing_off*/
module flash (
	input             clk,
	input             clk_sdram,
	input      [22:0] addr,
	input       [7:0] din,
	output      [7:0] dout,
	output            data_valid,
	input             we,
	input             ce,
	input             sdram_ready,
	input             sdram_done,
	output reg [26:0] sdram_addr,
	output reg  [7:0] sdram_din,
	output reg        sdram_req,
	input      [26:0] sdram_offset,
	output            debug_erase
);

assign sdram_req = 1'b0;
assign dout = '1;

endmodule
