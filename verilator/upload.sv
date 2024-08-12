module msx1(

   input clk21m,
   input reset,   
   input        ioctl_download /*verilator public_flat*/,
   input        ioctl_wr,
   input [26:0] ioctl_addr,
   input [7:0]  ioctl_dout,
   input [15:0]  ioctl_index,
   output  reg  ioctl_wait=1'b0,
   
   	//SDRAM
	input   [7:0] sdram_dout,
	output  [7:0] sdram_din,
	output [26:0] sdram_addr,
	output        sdram_we,
	output        sdram_rd,
	input         sdram_ready,
	input   [1:0] sdram_size,

   input [63:0] status,
   input        forced_scandoubler,

   output        DDRAM_CLK,
   input         DDRAM_BUSY,
   output  [7:0] DDRAM_BURSTCNT,
   output [28:0] DDRAM_ADDR,
   input  [63:0] DDRAM_DOUT,
   input         DDRAM_DOUT_READY,
   output        DDRAM_RD,
   output [63:0] DDRAM_DIN,
   output  [7:0] DDRAM_BE,
   output        DDRAM_WE
);


wire upload_ram_ce, upload_sdram_rq, upload_bram_rq, upload_ram_ready, reset_rq;
wire  [7:0] upload_ram_din, config_msx;
wire [26:0] upload_ram_addr;
wire  [7:0] kbd_din;
wire  [8:0] kbd_addr;
wire        kbd_request, kbd_we;
wire        load_sram;
wire  [1:0] rom_loaded;

MSX::user_config_t msxConfig;
MSX::bios_config_t bios_config;
MSX::config_cart_t cart_conf[2];
dev_typ_t    cart_device[2];
dev_typ_t    msx_device;
wire   [3:0] msx_dev_ref_ram[8];

assign sdram_we = upload_ram_ce & upload_sdram_rq;
assign sdram_addr = upload_ram_addr;
assign sdram_din = upload_ram_din;

memory_upload memory_upload(
    .clk(clk21m),
    .reset_rq(reset_rq),
    .ioctl_download(ioctl_download),
    .ioctl_index(ioctl_index),
    .ioctl_addr(ioctl_addr),
    .rom_eject(),
    .reload(),
    .ddr3_addr(ddr3_addr_download),
    .ddr3_rd(ddr3_rd_download),
    .ddr3_wr(),
    .ddr3_dout(ddr3_dout),
    .ddr3_ready(ddr3_ready),
    .ddr3_request(ddr3_request_download),
    .ram_addr(upload_ram_addr),
    .ram_din(upload_ram_din),
    .ram_dout(),
    .ram_ce(upload_ram_ce),
    .sdram_ready(sdram_ready),
    .sdram_rq(upload_sdram_rq),
    .bram_rq(upload_bram_rq),
    .kbd_request(kbd_request),
    .kbd_addr(kbd_addr),
    .kbd_din(kbd_din),
    .kbd_we(kbd_we),
    .sdram_size(sdram_size),
    .slot_layout(),
    .lookup_RAM(),
    .lookup_SRAM(),
    .bios_config(bios_config),
    .cart_conf(cart_conf),
    .rom_loaded(rom_loaded),
    .cart_device(cart_device),
    .msx_device(msx_device),
    .msx_dev_ref_ram(msx_dev_ref_ram),
    .load_sram(load_sram)
);

wire [27:0] ddr3_addr, ddr3_addr_download, ddr3_addr_cas;
wire  [7:0] ddr3_dout, ddr3_din_download;
wire        ddr3_rd, ddr3_rd_download, ddr3_rd_cas, ddr3_wr_download, ddr3_ready, ddr3_request_download;

assign ddr3_addr = ddr3_request_download ? ddr3_addr_download : ddr3_addr_cas ;
assign ddr3_rd   = ddr3_request_download ? ddr3_rd_download   : ddr3_rd_cas   ;

ddram buffer
(
   .DDRAM_CLK(clk21m),
   .addr(ddr3_addr),
   .dout(ddr3_dout),
   .din(),
   .we(),
   .rd(ddr3_rd),
   .ready(ddr3_ready),
   .reset(reset),
   .*
);
/*
wire         sdram_ready, sdram_rnw, dw_sdram_we, dw_sdram_ready, flash_ready, flash_req, flash_done;
wire  [26:0] sdram_addr;
wire  [24:0] dw_sdram_addr;
wire  [26:0] flash_addr;
wire   [7:0] sdram_dout, bram_dout, dw_sdram_din, flash_din;
sdram sdram
(
   .init(~locked_sdram),
   .clk(clk_sdram),
   .doRefresh(1'd0),
   
   .ch1_dout(),
   .ch1_din(upload_ram_din),
   .ch1_addr(upload_ram_addr),
   .ch1_req(upload_ram_ce & upload_sdram_rq),
   .ch1_rnw(1'd0),
   .ch1_ready(upload_ram_ready),   
  
   .ch2_dout(sdram_dout),
   .ch2_din(ram_din),
   .ch2_addr(ram_addr),
   .ch2_req(sdram_ce),
   .ch2_rnw(ram_rnw),
   .ch2_ready(sdram_ready),

   .ch3_addr(flash_addr),
   .ch3_dout(),
   .ch3_din(flash_din),
   .ch3_req(flash_req),
   .ch3_rnw(0),
   .ch3_ready(flash_ready),
   .ch3_done(flash_done),
   .*
);
*/
dpram #(.addr_width(18)) systemRAM
(
   .clock(clk21m),
   .address_a(),
   .wren_a(),
   .data_a(),
   .q_a(),
   .address_b(),
   .wren_b(),
   .data_b(),
   .q_b()
);
/*
dpram #(.addr_width(18)) systemRAM
(
   .clock(clk21m),
   .address_a(18'(upload_bram_rq ? upload_ram_addr : ram_addr)          ),
   .wren_a( upload_bram_rq ? upload_ram_ce         : bram_ce & ~ram_rnw ),
   .data_a( upload_bram_rq ? upload_ram_din        : ram_din            ),
   .q_a(bram_dout),
   .address_b(18'(sram_addr)),
   .wren_b(sram_we),
   .data_b(sd_buff_dout),
   .q_b(sram_dout)
);
*/

wire scandoubler = |status[5:3] || forced_scandoubler;
wire [5:0] mapper_A, mapper_B;
wire       reload, sram_A_select_hide, fdc_enabled, ROM_A_load_hide, ROM_B_load_hide;

msx_config msx_config 
(
   .clk(clk21m),
   .reset(reset),
   .bios_config(bios_config),
   .HPS_status(status),
   .scandoubler(scandoubler),
   .sdram_size(sdram_size),
   .cart_conf(cart_conf),
   .reload(reload),
   .rom_loaded(rom_loaded),
   .sram_A_select_hide(sram_A_select_hide),
   .ROM_A_load_hide(ROM_A_load_hide),
   .ROM_B_load_hide(ROM_B_load_hide),
   .fdc_enabled(fdc_enabled),
   .msxConfig(msxConfig)
);
endmodule