/*verilator tracing_off*/
module cart_konami_scc
(
   input            clk,
   input            reset,
   input     [24:0] mem_size,
   input     [15:0] cpu_addr,
   input      [7:0] din,
   input            cpu_mreq,
   input            cpu_wr,
   input            cpu_rd,
   input            cs,
   input            cart_num,
   input            sccDevice,     // 0-SCC 1-SCC+
   output           mem_unmaped,
   output    [20:0] mem_addr,
   output           scc_req,
   output    [1:0]  scc_mode
);
   
   assign scc_req  = '0;
   assign mem_unmaped = cs;
   assign mem_addr = '1;

endmodule
       