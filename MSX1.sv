//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================
/*verilator tracing_off*/
module emu
(
   //Master input clock
   input         CLK_50M,

   //Async reset from top-level module.
   //Can be used as initial reset.
   input         RESET,

   //Must be passed to hps_io module
   inout  [48:0] HPS_BUS,

   //Base video clock. Usually equals to CLK_SYS.
   output        CLK_VIDEO,

   //Multiple resolutions are supported using different CE_PIXEL rates.
   //Must be based on CLK_VIDEO
   output        CE_PIXEL,

   //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
   //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
   output [12:0] VIDEO_ARX,
   output [12:0] VIDEO_ARY,

   output  [7:0] VGA_R,
   output  [7:0] VGA_G,
   output  [7:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,
   output        VGA_DE,    // = ~(VBlank | HBlank)
   output        VGA_F1,
   output [1:0]  VGA_SL,
   output        VGA_SCALER, // Force VGA scaler
   output        VGA_DISABLE, // analog out is off

   input  [11:0] HDMI_WIDTH,
   input  [11:0] HDMI_HEIGHT,
   output        HDMI_FREEZE,
   output        HDMI_BLACKOUT,

`ifdef MISTER_FB
   // Use framebuffer in DDRAM
   // FB_FORMAT:
   //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
   //    [3]   : 0=16bits 565 1=16bits 1555
   //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
   //
   // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
   output        FB_EN,
   output  [4:0] FB_FORMAT,
   output [11:0] FB_WIDTH,
   output [11:0] FB_HEIGHT,
   output [31:0] FB_BASE,
   output [13:0] FB_STRIDE,
   input         FB_VBL,
   input         FB_LL,
   output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
   // Palette control for 8bit modes.
   // Ignored for other video modes.
   output        FB_PAL_CLK,
   output  [7:0] FB_PAL_ADDR,
   output [23:0] FB_PAL_DOUT,
   input  [23:0] FB_PAL_DIN,
   output        FB_PAL_WR,
`endif
`endif

   output        LED_USER,  // 1 - ON, 0 - OFF.

   // b[1]: 0 - LED status is system status OR'd with b[0]
   //       1 - LED status is controled solely by b[0]
   // hint: supply 2'b00 to let the system control the LED.
   output  [1:0] LED_POWER,
   output  [1:0] LED_DISK,

   // I/O board button press simulation (active high)
   // b[1]: user button
   // b[0]: osd button
   output  [1:0] BUTTONS,

   input         CLK_AUDIO, // 24.576 MHz
   output [15:0] AUDIO_L,
   output [15:0] AUDIO_R,
   output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
   output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

   //ADC
   inout   [3:0] ADC_BUS,

   //SD-SPI
   output        SD_SCK,
   output        SD_MOSI,
   input         SD_MISO,
   output        SD_CS,
   input         SD_CD,

   //High latency DDR3 RAM interface
   //Use for non-critical time purposes
   output        DDRAM_CLK,
   input         DDRAM_BUSY,
   output  [7:0] DDRAM_BURSTCNT,
   output [28:0] DDRAM_ADDR,
   input  [63:0] DDRAM_DOUT,
   input         DDRAM_DOUT_READY,
   output        DDRAM_RD,
   output [63:0] DDRAM_DIN,
   output  [7:0] DDRAM_BE,
   output        DDRAM_WE,

   //SDRAM interface with lower latency
   output        SDRAM_CLK,
   output        SDRAM_CKE,
   output [12:0] SDRAM_A,
   output  [1:0] SDRAM_BA,
   inout  [15:0] SDRAM_DQ,
   output        SDRAM_DQML,
   output        SDRAM_DQMH,
   output        SDRAM_nCS,
   output        SDRAM_nCAS,
   output        SDRAM_nRAS,
   output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
   //Secondary SDRAM
   //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
   input         SDRAM2_EN,
   output        SDRAM2_CLK,
   output [12:0] SDRAM2_A,
   output  [1:0] SDRAM2_BA,
   inout  [15:0] SDRAM2_DQ,
   output        SDRAM2_nCS,
   output        SDRAM2_nCAS,
   output        SDRAM2_nRAS,
   output        SDRAM2_nWE,
`endif

   input         UART_CTS,
   output        UART_RTS,
   input         UART_RXD,
   output        UART_TXD,
   output        UART_DTR,
   input         UART_DSR,

   // Open-drain User port.
   // 0 - D+/RX
   // 1 - D-/TX
   // 2..6 - USR2..USR6
   // Set USER_OUT to 1 to read from USER_IN.
   input   [6:0] USER_IN,
   output  [6:0] USER_OUT,

   input         OSD_STATUS
);


///////// Default values for ports not used in this core /////////
assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;

assign AUDIO_S = 1;
assign AUDIO_L = audio;
assign AUDIO_R = audio;
assign AUDIO_MIX = 0;

assign LED_POWER = 0;
assign LED_USER  = vsd_sel & sd_act;
assign LED_DISK  = {1'b1, ~vsd_sel & sd_act};
assign BUTTONS = 0;

localparam VDNUM = 6;
/*verilator tracing_on*/
video_bus_if video_bus();
clock_bus_if clock_bus(clk_core);
ext_sd_card_if ext_SD_card_bus();
flash_bus_if flash_bus();
spi_if ese_spi();
spi_if megasd_spi();
vram_bus_if vram_bus();

/*verilator tracing_off*/
MSX::cpu_regs_t    cpu_regs;
MSX::user_config_t msxConfig;
MSX::bios_config_t bios_config;
MSX::config_cart_t cart_conf[2];
MSX::block_t       slot_layout[64];
MSX::lookup_RAM_t  lookup_RAM[16];
MSX::lookup_SRAM_t lookup_SRAM[4];
MSX::io_device_t   io_device[16][3];
MSX::io_device_mem_ref_t io_memory[8];
MSX::slot_expander_t slot_expander[4];

wire             forced_scandoubler;
wire      [21:0] gamma_bus;
wire       [1:0] buttons;
wire     [127:0] status;
wire      [10:0] ps2_key;
wire      [24:0] ps2_mouse;
wire      [31:0] joy0, joy1;
wire             ioctl_download;
wire      [15:0] ioctl_index;
wire             ioctl_wr;
wire      [26:0] ioctl_addr;
wire       [7:0] ioctl_dout;
wire      [31:0] sd_lba[0:VDNUM-1];
wire [VDNUM-1:0] sd_rd;
wire [VDNUM-1:0] sd_wr;
wire [VDNUM-1:0] sd_ack;
wire      [13:0] sd_buff_addr;
wire       [7:0] sd_buff_dout;
wire       [7:0] sd_buff_din[0:VDNUM-1];
wire             sd_buff_wr;
wire [VDNUM-1:0] img_mounted;
wire      [63:0] img_size;
wire             img_readonly;
wire      [15:0] sdram_sz;
wire      [64:0] rtc;
wire             reset;

//[0]     RESET
//[2:1]   Aspect ratio
//[5:3]   Scandoubler
//[8:6]   Scale
//[9]     Tape rewind
//[10]    Reset & Detach
//[11]    RESERVA
//[12]    RESERVA
//[14:13] VideoMode
//[16:15] RESERVA
//[19:17] SLOT A CART TYPE
//[23:20] RESERVA
//[25:24] RESERVA
//[28:26] RESERVA 
//[31:29] SLOT B CART TYPE
//[34:32] RESERVA
//[37:35] RESERVA
//[38]    SRAM SAVE
//[39]    SRAM LOAD
//[40]    Tape input
//[41]    BORDER
`include "build_id.v" 
localparam CONF_STR = {
   "MSX1;",
   "-;",
   "FC1,MSX,Load ROM PACK,30000000;",
   "FC2,MSX,Load FW  PACK,30300000;",
   "FC6,DB,Load DB MAPPERS,31600000;",
   CONF_STR_SLOT_A,
   "H3FS3,ROM,Load,30C00000;",
   "-;",
   CONF_STR_SLOT_B,
   "H4F4,ROM,Load,31100000;",
   "H6-;",
   "H6R[38],SRAM Save;",
   "H6R[39],SRAM Load;",
   "h1-;",
   "h1S5,DSK,Mount Drive A:;",
   "SC4,VHD,Load SD card;",
   "-;",
   "O[40],Tape Input,File,ADC;",
   "H0F5,CAS,Cas File,31700000;",
   "H0T9,Tape Rewind;",
   "-;",
   "P1,Video settings;",
   "P1O[14:13],Video mode,default,PAL,NTSC;",
   "P1O[2:1],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
   "P1O[5:3],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
   "P1O[8:6],Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer,HV-Integer;",
   "P1O[41],Border,No,Yes;",
   "-;",
   "T[0],Reset;",
   "R[10],Reset & Detach ROM Cartridge;",					
   "R[0],Reset and close OSD;",
   "I,BAD MSX CONF,NOT SUPPORTED CONF,NOT SUPPORTED BLOCK,BAD MSX FW CONF,NOT FW CONF,DEVICE MISSING;",
   "V,v",`BUILD_DATE 
};

assign reset = RESET || status[0] || status[10] || upload_reset;

wire [15:0] status_menumask;
wire [1:0] sdram_size;
wire [7:0] info;
wire info_req;

assign status_menumask[0] = msxConfig.cas_audio_src == CAS_AUDIO_ADC;
assign status_menumask[1] = bios_config.fdc_en;
assign status_menumask[2] = bios_config.fdc_internal;
assign status_menumask[3] = ROM_A_load_hide;
assign status_menumask[4] = ROM_B_load_hide;
assign status_menumask[5] = '0;
assign status_menumask[6] = lookup_SRAM[0].size + lookup_SRAM[1].size + lookup_SRAM[2].size + lookup_SRAM[3].size == 0;
assign status_menumask[15:7] = '0;
assign sdram_size         = sdram_sz[15] ? sdram_sz[1:0] : 2'b00;

assign info_req = error != ERR_NONE;
assign info     = 8'(error);
/*verilator tracing_on*/
hps_io #(.CONF_STR(CONF_STR),.VDNUM(VDNUM)) hps_io
(
   .clk_sys(clock_bus.base_mp.clk),
   .HPS_BUS(HPS_BUS),
   .EXT_BUS(),
   .gamma_bus(gamma_bus),
   .forced_scandoubler(forced_scandoubler),
   .buttons(buttons),
   .status(status),
   .status_menumask(status_menumask),
   .ps2_key(ps2_key),
   .ps2_mouse(ps2_mouse),
   .joystick_0(joy0),
   .joystick_1(joy1),
   .ioctl_download(ioctl_download),
   .ioctl_index(ioctl_index),
   .ioctl_wr(ioctl_wr),
   .ioctl_addr(ioctl_addr),
   .ioctl_dout(ioctl_dout),
   .img_mounted(img_mounted),
   .img_size(img_size),
   .img_readonly(img_readonly),
   .sd_lba(sd_lba),
   .sd_rd(sd_rd),
   .sd_wr(sd_wr),
   .sd_ack(sd_ack),
   .sd_buff_addr(sd_buff_addr),
   .sd_buff_dout(sd_buff_dout),
   .sd_buff_din(sd_buff_din),
   .sd_buff_wr(sd_buff_wr),
   .sdram_sz(sdram_sz),
   .RTC(rtc),
   .info_req(info_req),
   .info(info)
);

/////////////////   CONFIG   /////////////////
wire [5:0] mapper_A, mapper_B;
wire       reload, ROM_A_load_hide, ROM_B_load_hide;
msx_config msx_config 
(
   .clk(clock_bus.base_mp.clk),
   .reset(reset),
   .bios_config(bios_config),
   .HPS_status(status[63:0]),
   .sdram_size(sdram_size),
   .cart_conf(cart_conf),
   .reload(reload),
   .ROM_A_load_hide(ROM_A_load_hide),
   .ROM_B_load_hide(ROM_B_load_hide),
   .msxConfig(msxConfig)
);
/////////////////   CLOCKS   /////////////////
/*verilator tracing_on*/
wire clk_core, clk_sdram, locked_sdram;
pll pll
(
   .refclk(CLK_50M),
   .rst(RESET),
   .outclk_0(clk_sdram),   //85.909090
   .outclk_1(clk_core),    //21.477270
   .locked(locked_sdram)
);

clock clock
(
   .reset(RESET),
   .clock_bus(clock_bus)
);

///////////////// Computer /////////////////
wire  [7:0] R, G, B, cpu_din, cpu_dout;
wire [15:0] cpu_addr, audio;
wire        cpu_wr, cpu_rd, cpu_mreq, cpu_iorq, cpu_m1;
wire [26:0] ram_addr;
wire  [7:0] ram_din, ram_dout;
wire        ram_rnw, sdram_ce, bram_ce;
wire        sd_tx, sd_rx;
wire  [7:0] d_to_sd, d_from_sd;

wire [31:0] opcode;
wire [1:0]  opcode_num;
wire        opcode_out;
wire [15:0] opcode_PC_start;

msx MSX
(
   .reset(reset),
   .clock_bus(clock_bus.base_mp),
   .video_bus(video_bus),
   .vram_bus(vram_bus),
   .ext_SD_card_bus(ext_SD_card_bus),
   .flash_bus(flash_bus),
   .ese_spi(ese_spi),
   .cpu_regs(cpu_regs),
   .opcode(opcode),
   .opcode_num(opcode_num),
   .opcode_out(opcode_out),
   .opcode_PC_start(opcode_PC_start),
   .cas_motor(motor),
   .cas_audio_in(msxConfig.cas_audio_src == CAS_AUDIO_FILE  ? CAS_dout : tape_in),
   .rtc_time(rtc),
   .sram_save(status[38]),
   .sram_load(status[39]),
   .ioctl_addr(ioctl_addr[26:0]),
   .img_mounted(img_mounted[5]),
   .img_size(img_size[31:0]),
   .img_readonly(img_readonly),
   .sd_rd(sd_rd[5]),
   .sd_wr(sd_wr[5]),
   .sd_ack(sd_ack[5]),
   .sd_lba(sd_lba[5]),
   .sd_buff_addr(sd_buff_addr),
   .sd_buff_dout(sd_buff_dout),
   .sd_buff_din(sd_buff_din[5]),
   .sd_buff_wr(sd_buff_wr),
   .slot_expander(slot_expander),
   .slot_layout(slot_layout),
   .lookup_RAM(lookup_RAM),
   .lookup_SRAM(lookup_SRAM),
   .bios_config(bios_config),
   .io_device(io_device),
   .io_memory(io_memory),
   .joy0(joy0[5:0]),
   .joy1(joy1[5:0]),
   .*
);

//////////////////   SD   ///////////////////
wire sdclk;
wire sdmosi;
wire sdss;
wire vsdmiso;
wire sdmiso = vsd_sel ? vsdmiso : SD_MISO;

reg vsd_sel = 0;
always @(posedge clock_bus.base_mp.clk) if(img_mounted[4]) vsd_sel <= |img_size; //TODO je potřeba hlídat náběžnou hranu img mounted

assign SD_CS   = vsd_sel |  sdss;
assign SD_SCK  = sdclk  & ~vsd_sel;
assign SD_MOSI = sdmosi & ~vsd_sel;

reg sd_act;
reg [31:0] timeout = 0;
always @(posedge clock_bus.base_mp.clk) begin
    reg old_mosi, old_miso;

    old_mosi <= sdmosi;
    old_miso <= sdmiso;

    sd_act <= 0;
    if(timeout < 1000000) begin
        timeout <= timeout + 1;
        sd_act <= 1;
    end

    if((old_mosi ^ sdmosi) || (old_miso ^ sdmiso)) timeout <= 0;
end

//////////////////   SPI   ///////////////////
spi_divmmc spi
(
   .clk_sys(clock_bus.base_mp.clk),
   .ext_SD_card_bus(ext_SD_card_bus),
   .ready(),

   .spi_ce(1'b1),
   .spi_clk(megasd_spi.clk),
   .spi_di(megasd_spi.miso),
   .spi_do(megasd_spi.mosi)
);

assign sdclk           = ese_spi.enable ? ese_spi.clk  : megasd_spi.clk;
assign sdmosi          = ese_spi.enable ? ese_spi.mosi : megasd_spi.mosi;
assign sdss            = ese_spi.enable ? ese_spi.ss : '0;
assign ese_spi.miso    = sdmiso;
assign megasd_spi.miso = sdmiso;




sd_card sd_card
(
    .*,
    .reset(reset),
    .clk_sys(clock_bus.base_mp.clk),
    .img_mounted(img_mounted[4]),
    .img_size(img_size),
    .sd_lba(sd_lba[4]),
    .sd_rd(sd_rd[4]),
    .sd_wr(sd_wr[4]),
    .sd_ack(sd_ack[4]),
    .sd_buff_addr(sd_buff_addr[8:0]),
    .sd_buff_dout(sd_buff_dout),
    .sd_buff_din(sd_buff_din[4]),
    .sd_buff_wr(sd_buff_wr),
    
    .clk_spi(clk_sdram),
    .sdhc(1),
    .sck(sdclk),
    .ss(~vsd_sel | sdss),
    .mosi(sdmosi),
    .miso(vsdmiso)
);
/*verilator tracing_off*/
/////////////////  VIDEO  /////////////////
wire       vga_de;
wire [1:0] ar    = status[2:1];
wire [2:0] scale = status[5:3];
wire [2:0] sl    = scale != 0 ? scale - 1'd1 : 3'd0;

assign VGA_SL = sl[1:0];
assign CLK_VIDEO   = clock_bus.base_mp.clk;

reg  en216p;
always @(posedge CLK_VIDEO) begin
	en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && scale != 0);
end

video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
   .VGA_VS(video_bus.display_mp.VS),
	.ARX((ar == 0) ? 12'd4 : {10'b0, (ar - 1'd1)}),
	.ARY((ar == 0) ? 12'd3 : 12'd0),
	.CROP_SIZE(en216p ? 12'd216 : 12'd0),
	.CROP_OFF(0),
	.SCALE(status[8:6])
);

video_mixer #(.GAMMA(1), .LINE_LENGTH(284)) video_mixer
(
   .CLK_VIDEO(CLK_VIDEO),
   .hq2x(scale==1),
   .scandoubler(scale != 0 || forced_scandoubler),
   .gamma_bus(gamma_bus),
   
   .ce_pix(video_bus.display_mp.ce_pix),
   .R(video_bus.display_mp.R),
   .G(video_bus.display_mp.G),
   .B(video_bus.display_mp.B),
   .HSync(video_bus.display_mp.HS),
   .VSync(video_bus.display_mp.VS), 
   .HBlank(video_bus.display_mp.hblank),
   .VBlank(video_bus.display_mp.vblank),

   .HDMI_FREEZE(0),
   .freeze_sync(),

   .CE_PIXEL(CE_PIXEL),
   .VGA_R(VGA_R),
   .VGA_G(VGA_G),
   .VGA_B(VGA_B),
   .VGA_VS(VGA_VS),
   .VGA_HS(VGA_HS),
   .VGA_DE(vga_de)
);

/////////////////  Tape In   /////////////////
wire tape_adc, tape_adc_act, tape_in;

assign tape_in = tape_adc_act & tape_adc;

ltc2308_tape #(.ADC_RATE(120000), .CLK_RATE(21477272)) tape
(
   .clk(clock_bus.base_mp.clk),
   .ADC_BUS(ADC_BUS),
   .dout(tape_adc),
   .active(tape_adc_act)
);

/////////////////  LOAD PACK   /////////////////
wire upload_ram_ce, upload_sdram_rq, upload_bram_rq, upload, upload_reset;
wire  [7:0] upload_ram_din, config_msx;
wire [26:0] upload_ram_addr;
wire  [7:0] kbd_din;
wire  [8:0] kbd_addr;
wire        kbd_request, kbd_we;
wire        load_sram;
error_t     error;
/*verilator tracing_on*/
memory_upload memory_upload(
    .clk(clock_bus.base_mp.clk),
    .upload(upload),
    .ioctl_download(ioctl_download),
    .ioctl_index(ioctl_index),
    .ioctl_addr(ioctl_addr),
    .rom_eject(status[10]),
    .reload(reload),
    .ddr3_addr(ddr3_addr_download),
    .ddr3_rd(ddr3_rd_download),
    .ddr3_dout(ddr3_dout),
    .ddr3_ready(ddr3_ready),
    .ddr3_request(ddr3_request_download),
    .ram_addr(upload_ram_addr),
    .ram_din(upload_ram_din),
    .ram_ce(upload_ram_ce),
    .sdram_ready(sdram_ready),
    .kbd_request(kbd_request),
    .kbd_addr(kbd_addr),
    .kbd_din(kbd_din),
    .kbd_we(kbd_we),
    .slot_expander(slot_expander),
    .slot_layout(slot_layout),
    .lookup_RAM(lookup_RAM),
    .lookup_SRAM(lookup_SRAM),
    .bios_config(bios_config),
    .cart_conf(cart_conf),
    .load_sram(load_sram),
    .io_device(io_device),
    .io_memory(io_memory),
    .error(error),
    .reset(upload_reset)
);
/*verilator tracing_off*/
wire  [26:0] flash_addr;
wire   [7:0] flash_dout;
wire         flash_req, flash_ready, flash_done;
flash flash (
   .clk(clock_bus.base_mp.clk),
   .clk_sdram(clk_sdram),
   .flash_bus(flash_bus),

   .sdram_ready(flash_ready),
   .sdram_done(flash_done),
   .sdram_addr(flash_addr),
   .sdram_din(flash_dout),
   .sdram_req(flash_req)
);

wire [27:0] ddr3_addr, ddr3_addr_download, ddr3_addr_cas;
wire  [7:0] ddr3_dout, ddr3_din_download;
wire        ddr3_rd, ddr3_rd_download, ddr3_rd_cas, ddr3_wr_download, ddr3_ready, ddr3_request_download;

assign ddr3_addr = ddr3_request_download ? ddr3_addr_download : ddr3_addr_cas ;
assign ddr3_rd   = ddr3_request_download ? ddr3_rd_download   : ddr3_rd_cas   ;
assign DDRAM_CLK = clock_bus.base_mp.clk;


logic [255:0] debug_data;
logic [63:0] dout64;

assign debug_data = {4'b0000, opcode_num, 2'b00, 8'b00000000, opcode_PC_start, opcode,
                     cpu_regs.AF,  cpu_regs.BC,  cpu_regs.DE,  cpu_regs.HL,
                     cpu_regs.AF2, cpu_regs.BC2, cpu_regs.DE2, cpu_regs.HL2,
                     cpu_regs.IX, cpu_regs.IY, cpu_regs.SP, cpu_regs.PC};
ddram buffer
(
   .DDRAM_CLK(DDRAM_CLK),
   .addr(ddr3_addr),
   .dout(ddr3_dout),
   .dout64(dout64),
   .din(),
   .we(),
   .rd(ddr3_rd),
   .ready(ddr3_ready),
   .reset(reset),
   .debug_data(debug_data),
   .debug_wr(opcode_out),
   .*
);

assign ram_dout = sdram_ce ? sdram_dout :
                             8'hFF;

wire         sdram_ready, sdram_rnw, dw_sdram_we, dw_sdram_ready;
wire  [26:0] sdram_addr;
wire  [24:0] dw_sdram_addr;
wire   [7:0] sdram_dout, dw_sdram_din;
sdram sdram
(
   .init(~locked_sdram),
   .clk(clk_sdram),
   .doRefresh(1'd0),
   
   .ch1_dout(sdram_dout),
   .ch1_din(upload ? upload_ram_din : ram_din),
   .ch1_addr(upload ? upload_ram_addr : ram_addr),
   .ch1_req(upload ? upload_ram_ce : sdram_ce),
   .ch1_rnw(upload ? 1'd0 : ram_rnw),
   .ch1_ready(sdram_ready),
   
   .ch2_dout(),
   .ch2_din(flash_dout),
   .ch2_addr(flash_addr),
   .ch2_req(flash_req),
   .ch2_rnw(0),
   .ch2_ready(flash_ready),
   .ch2_done(flash_done),

   .ch3_addr(backup_ram_addr),
   .ch3_dout(backup_ram_dout),
   .ch3_din(backup_ram_din),
   .ch3_req(backup_ram_req),
   .ch3_rnw(backup_ram_rnw),
   .ch3_ready(backup_ram_ready),
   .ch3_done(),
   .*
);    

// VDP video RAM
spram #(.addr_width(16),.mem_name("VRA2")) vram_lo
(
   .clock(clock_bus.base_mp.clk),
   .address(vram_bus.vram_mp.addr),
   .wren(vram_bus.vram_mp.we_lo),
   .data(vram_bus.vram_mp.data),
   .q(vram_bus.vram_mp.q_lo)
);
spram #(.addr_width(16),.mem_name("VRA3")) vram_hi
(
   .clock(clock_bus.base_mp.clk),
   .address(vram_bus.vram_mp.addr),
   .wren(vram_bus.vram_mp.we_hi),
   .data(vram_bus.vram_mp.data),
   .q(vram_bus.vram_mp.q_hi)
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
///////////////// NVRAM BACKUP ////////////////
wire [26:0]  backup_ram_addr;
wire [7:0]   backup_ram_din, backup_ram_dout;
wire         backup_ram_req, backup_ram_rnw, backup_ram_ready;
nvram_backup nvram_backup
(
   .clk(clock_bus.base_mp.clk),
   .lookup_SRAM(lookup_SRAM),
   .load_req(status[39] | load_sram),
   .save_req(status[38]),
   .img_mounted(img_mounted[3:0]),
   .img_readonly(img_readonly),
   .img_size(img_size[31:0]),
   .sd_lba(sd_lba[0:3]),
   .sd_rd(sd_rd[3:0]),
   .sd_wr(sd_wr[3:0]),
   .sd_ack(sd_ack[3:0]),
   .sd_buff_wr(sd_buff_wr),
   .sd_buff_addr(sd_buff_addr),
   .sd_buff_din(sd_buff_din[0:3]),
   .sd_buff_dout(sd_buff_dout),
   .ram_addr(backup_ram_addr),
   .ram_dout(backup_ram_dout),
   .ram_din(backup_ram_din),
   .ram_req(backup_ram_req),
   .ram_rnw(backup_ram_rnw),
   .ram_ready(backup_ram_ready)
);

///////////////// CAS EMULATE /////////////////
wire ioctl_isCAS, buff_mem_ready, motor, CAS_dout, play, rewind;
logic cas_load = 0;
always @(posedge clock_bus.base_mp.clk) begin
   logic ioctl_download_last; 
   if (~ioctl_isCAS & ioctl_download_last )  begin
      cas_load <= 1'b1;
   end
   ioctl_download_last <= ioctl_isCAS;         
end

assign play         = ~motor & cas_load;
assign ioctl_isCAS  = ioctl_download & (ioctl_index[5:0] == 6'd5);
assign rewind       = status[9] | ioctl_isCAS | reset;

tape cass 
(
   .clk(clock_bus.base_mp.clk),
   .ce_5m3(clock_bus.base_mp.ce_5m39_p),
   .cas_out(CAS_dout),
   .ram_a(ddr3_addr_cas),
   .ram_di(ddr3_dout),
   .ram_di64(dout64),
   .ram_rd(ddr3_rd_cas),
   .buff_mem_ready(ddr3_ready),
   .play(play),
   .rewind(rewind),
   .enable(cas_load)
);

endmodule
