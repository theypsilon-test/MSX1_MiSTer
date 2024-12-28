   module msx
(
   input                    reset,
   //Clock
   clock_bus_if.base_mp     clock_bus,
   //Video
   video_bus                video_bus,
   //Ext SD card
   ext_sd_card_if.device_mp ext_SD_card_bus,
   spi_if                   ese_spi,
   //Flash acces to SDRAM
   flash_bus_if.device_mp   flash_bus,
   //debug
   output MSX::cpu_regs_t   cpu_regs,
   output  [31:0]           opcode,
   output  [1:0]            opcode_num,
   output                   opcode_out,
   output logic [15:0]      opcode_PC_start,
   //I/O
   output            [15:0] audio,
   input  [           10:0] ps2_key,
   input              [5:0] joy0,
   input              [5:0] joy1,
   //Cassete
   output                   cas_motor,
   input                    cas_audio_in,
   //MSX config
   input             [64:0] rtc_time,
   input MSX::bios_config_t bios_config,
   input MSX::user_config_t msxConfig,
   input                    sram_save,
   input                    sram_load,
   //IOCTL
   input                    ioctl_download,
   input             [15:0] ioctl_index,
   input             [26:0] ioctl_addr,
   //SDRAM/BRAM
   output            [26:0] ram_addr,
   output             [7:0] ram_din,
   output                   ram_rnw,
   output                   sdram_ce,
   output                   bram_ce,
   input              [7:0] ram_dout,
   input              [1:0] sdram_size,
   input MSX::slot_expander_t slot_expander[4],
   input MSX::block_t       slot_layout[64],
   input MSX::lookup_RAM_t  lookup_RAM[16],
   input MSX::lookup_SRAM_t lookup_SRAM[4],
   input MSX::io_device_t   io_device[16][3],
   input MSX::io_device_mem_ref_t io_memory[8],
   //KBD
   input                    kbd_request,
   input              [8:0] kbd_addr,
   input              [7:0] kbd_din,
   input                    kbd_we,
   //SD FDC
   input                    img_mounted,
   input             [31:0] img_size,
   input                    img_readonly,
   output            [31:0] sd_lba,
   output                   sd_rd,
   output                   sd_wr,
   input                    sd_ack,
   input             [13:0] sd_buff_addr,
   input              [7:0] sd_buff_dout,
   output             [7:0] sd_buff_din,
   input                    sd_buff_wr
);

device_bus device_bus();
cpu_bus_if cpu_bus(clock_bus.clk, clock_bus.ce_3m58_n, reset);
sd_bus sd_bus();
sd_bus_control sd_bus_control();

//  -----------------------------------------------------------------------------
//  -- Audio MIX
//  -----------------------------------------------------------------------------
wire [15:0] compr[7:0];
wire  [9:0] audioPSG    = ay_ch_mix + {4'b0, keybeep,5'b00000} + {5'b0, (cas_audio_in & ~cas_motor),4'b0000};
wire [16:0] fm          = {3'b00, audioPSG, 4'b0000};
wire [16:0] audio_mix   = {device_sound[15], device_sound} + fm;
assign compr            = '{ {1'b1, audio_mix[13:0], 1'b0}, 16'h8000, 16'h8000, 16'h8000, 16'h7FFF, 16'h7FFF, 16'h7FFF,  {1'b0, audio_mix[13:0], 1'b0}};
assign audio            = compr[audio_mix[16:14]];

//  -----------------------------------------------------------------------------
//  -- T80 CPU
//  -----------------------------------------------------------------------------
wire [7:0] d_to_cpu;
tv80n Z80
(
   .cpu_bus(cpu_bus.cpu_mp),
   .cpu_regs(cpu_regs),
   .opcode(opcode),
   .opcode_num(opcode_num),
   .opcode_out(opcode_out),
   .opcode_PC_start(opcode_PC_start),
   .wait_n(wait_n),
   .int_n(vdp_int_n),
   .nmi_n(1'b1),
   .busrq_n(1'b1),
   .busak_n(),
   .di(d_to_cpu)
);
//  -----------------------------------------------------------------------------
//  -- WAIT CPU
//  -----------------------------------------------------------------------------
wire exwait_n = 1;

logic wait_n = 1'b0;
always @(posedge clock_bus.clk, negedge exwait_n, negedge u1_2_q) begin
   if (~exwait_n)
      wait_n <= 1'b0;
   else if (~u1_2_q)
      wait_n <= 1'b1;
   else if (clock_bus.ce_3m58_p)
      wait_n <= ~cpu_bus.device_mp.m1;
end

logic u1_2_q = 1'b0;
always @(posedge clock_bus.clk, negedge exwait_n) begin
   if (~exwait_n)
      u1_2_q <= 1'b1;
   else if (clock_bus.ce_3m58_p)
      u1_2_q <= wait_n;
end

logic map_valid = 0;
wire ppi_en = ~ppi_n;
wire [1:0] active_slot;

/*
always @(posedge reset, posedge clock_bus.clk) begin
    if (reset)
        map_valid = 0;
    else if (ppi_en) begin
        map_valid = 1;
   end
end
*/

//wire [1:0] default_slot  = bios_config.MSX_typ == OCM ? 2'b11 : 2'b00;


assign active_slot =    //~map_valid                             ? default_slot   :
                        cpu_bus.device_mp.addr[15:14] == 2'b00 ? ppi_out_a[1:0] :
                        cpu_bus.device_mp.addr[15:14] == 2'b01 ? ppi_out_a[3:2] :
                        cpu_bus.device_mp.addr[15:14] == 2'b10 ? ppi_out_a[5:4] :
                                                       ppi_out_a[7:6] ;

//  -----------------------------------------------------------------------------
//  -- IO Decoder
//  -----------------------------------------------------------------------------
wire psg_n  = ~((cpu_bus.device_mp.addr[7:3] == 5'b10100)   & cpu_bus.device_mp.iorq & ~cpu_bus.device_mp.m1);
wire ppi_n  = ~((cpu_bus.device_mp.addr[7:3] == 5'b10101)   & cpu_bus.device_mp.iorq & ~cpu_bus.device_mp.m1);
wire vdp_en =   (cpu_bus.device_mp.addr[7:3] == 5'b10011)   & cpu_bus.device_mp.iorq & ~cpu_bus.device_mp.m1 ;
wire rtc_en =   (cpu_bus.device_mp.addr[7:1] == 7'b1011010) & cpu_bus.device_mp.iorq & ~cpu_bus.device_mp.m1 & bios_config.MSX_typ != MSX1;

//  -----------------------------------------------------------------------------
//  -- 82C55 PPI
//  -----------------------------------------------------------------------------
wire [7:0] d_from_8255;
wire [7:0] ppi_out_a, ppi_out_c;
wire keybeep = ppi_out_c[7];
assign cas_motor =  ppi_out_c[4];
jt8255 PPI
(
   .rst(reset),
   .clk(clock_bus.clk),
   .addr(cpu_bus.device_mp.addr[1:0]),
   .din(cpu_bus.device_mp.data),
   .dout(d_from_8255),
   .rdn(~cpu_bus.device_mp.rd),
   .wrn(~cpu_bus.device_mp.wr),
   .csn(ppi_n),
   .porta_din(8'h0),
   .portb_din(d_from_kb),
   .portc_din(8'h0),
   .porta_dout(ppi_out_a),
   .portb_dout(),
   .portc_dout(ppi_out_c),
   .porta_reset_default(bios_config.MSX_typ == OCM ? 8'hFF : 8'h00),
   .control_reset_default(bios_config.MSX_typ == OCM ? 7'h0b : 7'h1b)
 );

//  -----------------------------------------------------------------------------
//  -- CPU data multiplex
//  -----------------------------------------------------------------------------
assign d_to_cpu = ~cpu_bus.device_mp.rd   ? 8'hFF           :
                  vdp_en                  ? d_to_cpu_vdp    :
                  rtc_en                  ? d_from_rtc      :
                  ~psg_n                  ? d_from_psg      :
                  ~ppi_n                  ? d_from_8255     :
                  device_oe_rq            ? device_data     :                       // Prioritní data.
                  slot_oe_rq              ? d_from_slots    :                       // Prioritní data.
                                            device_data & ram_dout & d_from_slots;
//  -----------------------------------------------------------------------------
//  -- Keyboard decoder
//  -----------------------------------------------------------------------------
wire [7:0] d_from_kb;
keyboard msx_key
(
   .reset(reset),
   .clk(clock_bus.clk),
   .ps2_key(ps2_key),
   .kb_row(ppi_out_c[3:0]),
   .kb_data(d_from_kb),
   .kbd_addr(kbd_addr),
   .kbd_din(kbd_din),
   .kbd_we(kbd_we),
   .kbd_request(kbd_request)
);
//  -----------------------------------------------------------------------------
//  -- Sound AY-3-8910
//  -----------------------------------------------------------------------------
wire [7:0] d_from_psg, psg_ioa, psg_iob;
wire [5:0] joy_a = psg_iob[4] ? 6'b111111 : {~joy0[5], ~joy0[4], ~joy0[0], ~joy0[1], ~joy0[2], ~joy0[3]};
wire [5:0] joy_b = psg_iob[5] ? 6'b111111 : {~joy1[5], ~joy1[4], ~joy1[0], ~joy1[1], ~joy1[2], ~joy1[3]};
wire [5:0] joyA = joy_a & {psg_iob[0], psg_iob[1], 4'b1111};
wire [5:0] joyB = joy_b & {psg_iob[2], psg_iob[3], 4'b1111};
assign psg_ioa = {cas_audio_in,1'b0, psg_iob[6] ? joyB : joyA};
wire [9:0] ay_ch_mix;

logic u21_1_q = 1'b0;
always @(posedge clock_bus.clk,  posedge psg_n) begin
   if (psg_n)
      u21_1_q <= 1'b0;
   else if (clock_bus.ce_3m58_p)
      u21_1_q <= ~psg_n;
end

logic u21_2_q = 1'b0;
always @(posedge clock_bus.clk, posedge psg_n) begin
   if (psg_n)
      u21_2_q <= 1'b0;
   else if (clock_bus.ce_3m58_p)
      u21_2_q <= u21_1_q;
end

wire psg_e = !(!u21_2_q | clock_bus.ce_3m58_p) | psg_n;
wire psg_bc   = !(cpu_bus.device_mp.addr[0] | psg_e);
wire psg_bdir = !(cpu_bus.device_mp.addr[1] | psg_e);
jt49_bus PSG
(
   .rst_n(~reset),
   .clk(clock_bus.clk),
   .clk_en(clock_bus.ce_3m58_p),
   .bdir(psg_bdir),
   .bc1(psg_bc),
   .din(cpu_bus.device_mp.data),
   .sel(0),
   .dout(d_from_psg),
   .sound(ay_ch_mix),
   .A(),
   .B(),
   .C(),
   .IOA_in(psg_ioa),
   .IOA_out(),
   .IOB_in(8'hFF),
   .IOB_out(psg_iob)
);

//  -----------------------------------------------------------------------------
//  -- RTC
//  -----------------------------------------------------------------------------
wire [7:0] d_from_rtc;
rtc rtc
(
   .clk21m(clock_bus.clk),
   .reset(reset),
   .setup(reset),
   .rt(rtc_time),
   .clkena(clock_bus.ce_10hz),
   .req(cpu_bus.device_mp.req & rtc_en),
   .ack(),
   .wrt(cpu_bus.device_mp.wr),
   .adr(cpu_bus.device_mp.addr),
   .dbi(d_from_rtc),
   .dbo(cpu_bus.device_mp.data)
);
//  -----------------------------------------------------------------------------
//  -- Video
//  -----------------------------------------------------------------------------
wire [7:0] d_to_cpu_vdp;
wire       vdp_int_n;   

vdp_mux vdp
(
   .clock_bus(clock_bus),
   .cpu_bus(cpu_bus.device_mp),
   .video_bus(video_bus),
   .ce(vdp_en),
   .MSX_typ(bios_config.MSX_typ),
   .data(d_to_cpu_vdp),
   .interrupt_n(vdp_int_n),
   .border(msxConfig.border),
   .video_mode(msxConfig.video_mode == AUTO ? bios_config.video_mode : msxConfig.video_mode)
);

wire signed [15:0] device_sound;

assign sd_bus.ack = sd_ack;
assign sd_bus.buff_addr = sd_buff_addr;
assign sd_bus.buff_data = sd_buff_dout;
assign sd_bus.buff_wr = sd_buff_wr;

assign sd_rd  = sd_bus_control.rd;
assign sd_wr  = sd_bus_control.wr;
assign sd_lba = sd_bus_control.sd_lba;
assign sd_buff_din = sd_bus_control.buff_data;

assign ram_addr = slots_ram_addr & device_ram_addr;
assign sdram_ce = slots_ram_ce   | device_ram_ce;

image_info image_info();

assign image_info.mounted = img_mounted;
assign image_info.size = img_size;
assign image_info.readonly = img_readonly;

wire  [7:0] device_data;
wire  [7:0] data_to_mapper;
wire [26:0] device_ram_addr;
wire        device_ram_ce;
wire        device_oe_rq;
devices devices
(
   .clock_bus(clock_bus),
   .cpu_bus(cpu_bus),
   .device_bus(device_bus),
   .sd_bus(sd_bus),
   .sd_bus_control(sd_bus_control),
   .image_info(image_info),
   .io_device(io_device),
   .io_memory(io_memory),
   .sound(device_sound),
   .data(device_data),
   .data_oe_rq(device_oe_rq),
   .data_to_mapper(data_to_mapper),
   .ram_cs(device_ram_ce),
   .ram_addr(device_ram_addr)
);

wire  [7:0] d_from_slots;
wire [26:0] slots_ram_addr;
wire        slots_ram_ce;
wire        slot_oe_rq;
msx_slots msx_slots
(
   .clock_bus(clock_bus),
   .cpu_bus(cpu_bus),
   .device_bus(device_bus),
   .ext_SD_card_bus(ext_SD_card_bus),
   .flash_bus(flash_bus),
   .ese_spi(ese_spi),
   .slot_expander(slot_expander),
   .slot_layout(slot_layout),
   .lookup_RAM(lookup_RAM),
   .lookup_SRAM(lookup_SRAM),
   .data(d_from_slots),
   .data_oe_rq(slot_oe_rq),
   .ram_addr(slots_ram_addr),
   .ram_din(ram_din),
   .ram_rnw(ram_rnw),
   .ram_dout(ram_dout),
   .sdram_ce(slots_ram_ce),
   .bram_ce(bram_ce),
   .sdram_size(sdram_size),
   .active_slot(active_slot),
   .bios_config(bios_config),
   .data_to_mapper(data_to_mapper)
);

endmodule