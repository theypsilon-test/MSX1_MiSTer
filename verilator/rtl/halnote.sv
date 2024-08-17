/*verilator tracing_off*/
module mapper_halnote
(
   input               clk,
   input               reset,
   input        [15:0] cpu_addr,
   input         [7:0] din,
   input               cpu_mreq,
   input               cpu_wr,
   input               cs,
   output              mem_unmaped,
   output       [24:0] mem_addr,
   output              sram_cs,
   output              sram_we
);

assign mem_addr = '1;
assign mem_unmaped = cs;
assign sram_cs = 1'b0;
assign sram_we = 1'b0;

endmodule