module nvram_backup
(
   input                      clk,                  // Clock signal
   input MSX::lookup_SRAM_t   lookup_SRAM[4],       // Lookup table for SRAM access
   input                      load_req,             // Request to load data
   input                      save_req,             // Request to save data

   // SD config
   input                [3:0] img_mounted,          // Indicates mounted images
   input                      img_readonly,         // Indicates read-only mode
   input               [31:0] img_size,             // Size of the image

   // SD block level access
   output logic        [31:0] sd_lba[4],            // Logical Block Address for SD
   output logic         [3:0] sd_rd = 4'd0,         // SD read enable
   output logic         [3:0] sd_wr = 4'd0,         // SD write enable
   input                [3:0] sd_ack,               // SD acknowledgement
   input                      sd_buff_wr,           // SD buffer write enable
   input               [13:0] sd_buff_addr,         // SD buffer address
   input                [7:0] sd_buff_dout,         // Data out from SD buffer
   output logic         [7:0] sd_buff_din[4],       // Data into SD buffer

   // RAM access
   output logic        [26:0] ram_addr,             // RAM address
   output logic               ram_req,              // RAM request enable
   output logic               ram_rnw,              // RAM read/not-write enable
   input                      ram_ready,            // RAM ready signal
   input                [7:0] ram_dout,             // Data out from RAM
   output logic         [7:0] ram_din               // Data into RAM
);

endmodule