/*verilator tracing_off*/
module kanji
(
   input         clk,
   input         reset,
   input   [7:0] din,
   input   [7:0] addr,
   input         cpu_wr,
   input         cpu_rd,
   input         cpu_iorq,
   input         cs,
   input  [26:0] base_ram,
   input  [15:0] rom_size,
   output [26:0] mem_addr,
   output        ram_ce
);


assign mem_addr = '1;
assign ram_ce   = '0;

endmodule