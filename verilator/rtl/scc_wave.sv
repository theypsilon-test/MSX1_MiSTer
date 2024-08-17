/*verilator tracing_off*/
module scc_wave
(
   input                clk,
   input                clkena,
   input                reset,
   input                req,
   output               ack,
   input                wrt,
   input          [7:0] adr,
   input          [7:0] dbo,
   output         [7:0] dbi /* verilator public */ ,
   output signed [14:0] wave,
   input                sccPlusChip,
   input                sccPlusMode
);
assign dbi = 8'hFF;
endmodule
