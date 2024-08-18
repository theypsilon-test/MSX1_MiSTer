module msx_slots
(
   input                       clk,
   input                       reset,
   //CPU
   input                [15:0] cpu_addr,
   input                 [7:0] cpu_data,
   input                       cpu_wr,
   input                       cpu_rd,
   input                       cpu_mreq,
   input                       cpu_iorq,
   input                       cpu_m1,
   //BUS
   input                 [1:0] active_slot,
   output                [7:0] data,
   //Config

   input                       clk_sdram,
   input                       clk_en,
   //BASE                
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


assign d_to_sd = cpu_data;



mapper_typ_t        mapper;
device_typ_t        device;

wire          [1:0] block      = cpu_addr[15:14];
wire          [5:0] layout_id  = {active_slot, subslot, block};
wire          [3:0] ref_ram    = slot_layout[layout_id].ref_ram;
wire          [1:0] ref_sram   = slot_layout[layout_id].ref_sram;
wire          [1:0] offset_ram = slot_layout[layout_id].offset_ram;
wire                cart_num   = slot_layout[layout_id].cart_num;
wire                external   = slot_layout[layout_id].external;
assign              device     = slot_layout[layout_id].device;
assign              mapper     = selected_mapper[cart_num] == MAPPER_UNUSED & device == DEVICE_ROM & external ? MAPPER_UNUSED : slot_layout[layout_id].mapper;                              
                             
wire         [26:0] base_ram   = lookup_RAM[ref_ram].addr;
wire         [15:0] ram_blocks = lookup_RAM[ref_ram].size;
wire                ram_ro     = lookup_RAM[ref_ram].ro;
wire         [17:0] base_sram  = lookup_SRAM[ref_sram].addr;
wire         [15:0] sram_size  = lookup_SRAM[ref_sram].size;


assign data             = mapper_subslot_cs ? subslot_data : ram_dout;
assign ram_din  = cpu_data;

assign bram_ce  = (sdram_size == 2'd0 & ram_cs) | sram_cs;
assign sdram_ce = (sdram_size != 2'd0 & ram_cs);
assign ram_rnw  = mem_rnw | (ram_cs & ram_ro) | mapper_subslot_cs; // Pokud je aktivní zápis do mapperu sublostu neprovádět zápis.
assign ram_addr = (sram_cs ? 27'(base_sram) : base_ram) + mem_addr ;



wire          [1:0] subslot;
wire          [7:0] subslot_data;
wire                mapper_subslot_cs;
subslot subsloot
(
   .expander_enable(bios_config.slot_expander_en),
   .data(subslot_data),
   .active_subslot(subslot),
   .cs(mapper_subslot_cs),
   .*
);

wire sram_cs, ram_cs, mem_rnw;
wire [26:0] mem_addr;
mappers mappers
(
   .clk(clk),
   .reset(reset),
   .cpu_mreq(cpu_mreq),
   .cpu_rd(cpu_rd),
   .cpu_wr(cpu_wr),
   .cpu_data(cpu_data),
   .cpu_addr(cpu_addr),
   .rom_size(25'(ram_blocks) << 14),
   .sram_size(sram_size),
   .offset_ram(offset_ram),
   .mapper(mapper),
   .mapper_id(cart_num),
   .mem_addr(mem_addr),
   .mem_rnw(mem_rnw),
   .ram_cs(ram_cs),
   .sram_cs(sram_cs)
);

endmodule
