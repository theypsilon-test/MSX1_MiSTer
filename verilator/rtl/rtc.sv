/*verilator tracing_off*/
module rtc
(
        input clk21m,
        input reset,

        input setup,
        input [64:0] rt,

        input clkena,
        input req,
        output ack,
        input wrt,
        input adr,
        output [7:0] dbi,
        input [7:0] dbo
);

endmodule