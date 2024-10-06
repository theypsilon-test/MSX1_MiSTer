module psg
(
   input clk,
   input clk_en,
   input reset,
   input [7:0] cpu_dout,
   input [7:0] cpu_addr,
   input       cpu_wr,
   input       cpu_iorq,
   input       cpu_m1,
   input [1:0] cs,
   output signed [15:0] sound
);

endmodule