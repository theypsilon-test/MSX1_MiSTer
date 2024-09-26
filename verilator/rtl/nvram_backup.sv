/*verilator tracing_off*/
module nvram_backup
(
   input                      clk,
   input MSX::lookup_SRAM_t   lookup_SRAM[4],
   input                      load_req,
   input                      save_req,
   // SD config
   input                [3:0] img_mounted,
   input                      img_readonly,
   input               [31:0] img_size,
   // SD block level access
   output              [31:0] sd_lba[4],
   output logic         [3:0] sd_rd = 4'd0,
   output logic         [3:0] sd_wr = 4'd0,
   input                [3:0] sd_ack,
   input               [13:0] sd_buff_addr,
   output               [7:0] sd_buff_din[4],
   // RAM access
   output              [26:0] ram_addr,   
   output                     ram_we,
   input                [7:0] ram_dout
);

endmodule