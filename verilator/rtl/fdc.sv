module fdc
(
   input          clk,
   input          reset,
   input          clk_en,
   input          cs,
   input   [13:0] addr,
   input    [7:0] d_from_cpu,
   output   [7:0] d_to_cpu,
   output         output_en,
   input          rd,
   input          wr,
   input          img_mounted,
   input   [31:0] img_size,
   input          img_readonly,
   output  [31:0] sd_lba,
   output         sd_rd,
   output         sd_wr,
   input          sd_ack,
   input    [8:0] sd_buff_addr,
   input    [7:0] sd_buff_dout,
   output   [7:0] sd_buff_din,
   input          sd_buff_wr
);

assign d_to_cpu = '1;

endmodule
