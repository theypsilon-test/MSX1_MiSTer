/*verilator tracing_off*/
module msx_slots
(
   input                       clk,
   input                       clk_sdram,
   input                       clk_en,
   input                       reset,
   //BASE                
   input                [15:0] cpu_addr,
   input                 [7:0] cpu_dout,
   output                [7:0] cpu_din,
   input                       cpu_wr,
   input                       cpu_rd,
   input                       cpu_mreq,
   input                       cpu_iorq,
   input                       cpu_m1,
   input                 [1:0] active_slot,
   output signed        [15:0] sound,
   //RAM
   output               [26:0] ram_addr,
   output                [7:0] ram_din,
   input                 [7:0] ram_dout,
   output                      ram_rnw,
   output                      sdram_ce,
   output                      bram_ce,
   input                 [1:0] sdram_size,
   output               [26:0] flash_addr,
   output                [7:0] flash_din,
   output                      flash_req,
   input                       flash_ready,
   input                       flash_done,
   //Block device
   input                       img_mounted,
   input                [31:0] img_size,
   input                       img_readonly,
   output               [31:0] sd_lba,
   output                      sd_rd,
   output                      sd_wr,
   input                       sd_ack,
   input                [13:0] sd_buff_addr,
   input                 [7:0] sd_buff_dout,
   output                [7:0] sd_buff_din,
   input                       sd_buff_wr,
   //Config
   input  MSX::block_t         slot_layout[64],
   input  MSX::lookup_RAM_t    lookup_RAM[16],
   input  MSX::lookup_SRAM_t   lookup_SRAM[4],
   input  MSX::bios_config_t   bios_config,
   input  mapper_typ_t         selected_mapper[2],
   input  dev_typ_t            cart_device[2],
   input  dev_typ_t            msx_device,
   input                 [3:0] msx_dev_ref_ram[8],
   //SD CARD
   output             [7:0] d_to_sd,
   input              [7:0] d_from_sd,
   output                   sd_tx,
   output                   sd_rx,
   //DEBUG
   output                   debug_FDC_req,
   output                   debug_sd_card,
   output                   debug_erase
);

endmodule
