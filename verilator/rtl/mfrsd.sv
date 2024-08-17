/*verilator tracing_off*/
module mapper_mfrsd0
(
   input               clk,
   input               reset,
   input               cs,
   input               cart_num,
   input        [15:0] cpu_addr,
   input        [26:0] base_ram,
   output logic [26:0] mfrsd_base_ram[2],
   output       [22:0] flash_addr,
   output              flash_rq
);

assign flash_rq   = 1'b0;

endmodule

module mapper_mfrsd1
(
   input               clk,
   input               reset, 
   input               cs,
   input         [1:0] slot, 
   input        [15:0] cpu_addr,
   input         [7:0] din,
   input               cpu_mreq,
   input               cpu_wr,
   input               cpu_rd,
   input        [26:0] mfrsd_base_ram,
   output logic  [7:0] configReg,
   output logic  [3:0] mapper_mask,
   output       [26:0] mem_addr,
   output              mem_unmaped,
   output       [22:0] flash_addr,
   output              flash_rq, 
   output              scc_req,
   output              scc_mode
);

assign mem_unmaped = cs;
assign scc_req  = 1'b0;
assign flash_rq  = 1'b0;

endmodule

module mapper_mfrsd2
(
   input              clk,
   input              reset, 
   input       [15:0] cpu_addr,
   input        [7:0] cpu_dout,
   output       [7:0] mapper_dout,
   input              cpu_wr,
   input              cpu_rd,
   input              cpu_iorq,
   input              cpu_m1,
   input              en,
   output      [21:0] mem_addr
);


assign mapper_dout = '1;


endmodule

module mapper_mfrsd3
(
   input              clk,
   input              reset, 
   input              cs,
   input       [15:0] cpu_addr,
   input        [7:0] din,
   output       [7:0] mapper_dout,
   input              cpu_mreq,
   input              cpu_wr,
   input              cpu_rd,
   input       [26:0] mfrsd_base_ram,
   input        [7:0] configReg,
   output      [26:0] mem_addr,
   output      [22:0] flash_addr,
   output             mem_unmaped,
   output       logic sd_rx,
   output       logic sd_tx,
   input        [7:0] d_from_sd,
   output             flash_rq,
   output             debug_sd_card
);

assign flash_rq  = 1'b0;
assign mapper_dout = '1;

endmodule