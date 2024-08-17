/*verilator tracing_off*/
module ltc2308_tape #(parameter HIST_LOW = 16, HIST_HIGH = 64, ADC_RATE = 48000, CLK_RATE = 50000000)
(
	input        reset,
	input        clk,

	inout  [3:0] ADC_BUS,
	output reg   dout,
	output       active
);

endmodule