/*verilator tracing_off*/
module cart_fm_pac
(
   input                clk,
   input                reset,
   input         [15:0] cpu_addr,
   input          [7:0] din,
   output         [7:0] mapper_dout,  
   input                cs,
   input                cart_num,
   input                cpu_wr,
   input                cpu_rd,
   input                cpu_mreq,
   output               sram_we,
   output               sram_cs,
   output               mem_unmaped,
   output        [24:0] mem_addr,
   output         [1:0] opll_wr, 
   output         [1:0] opll_io_enable
);
  
    assign mem_addr = '1;
    assign sram_we  = '0;
    assign sram_cs  = '0;            
    assign mem_unmaped     =  cs;
    assign mapper_dout = '1;
    
endmodule

