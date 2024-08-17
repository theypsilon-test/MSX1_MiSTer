/*verilator tracing_off*/
module ddram (
  input         reset,
	input         DDRAM_CLK,

	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	input  [27:0] addr  /* verilator public */,        // 256MB at the end of 1GB
	output  [7:0] dout  /* verilator public */,        // data output to cpu
	input   [7:0] din  /* verilator public */,         // data input from cpu
	input         we /* verilator public */,          // cpu requests write
	input         rd /* verilator public */,          // cpu requests read
	output        ready /* verilator public */        // dout is valid. Ready to accept new read/write.
);

endmodule

