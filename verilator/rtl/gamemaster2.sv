/*verilator tracing_off*/
module cart_gamemaster2
(
   input            clk,
   input            reset,
   input     [15:0] cpu_addr,
   input      [7:0] din,
   input            cpu_mreq,
   input            cpu_wr,
   input            cs,
   output    [24:0] mem_addr,
   output           sram_we,
   output           sram_cs
);

assign sram_cs   = '0;
assign mem_addr  = '1;
assign sram_we   = '0;

endmodule