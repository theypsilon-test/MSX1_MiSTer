   module msx
(
   input                    reset,
   //Clock
   clock_bus_if.base_mp     clock_bus,
   //Video
   video_bus_if.device_mp   video_bus,
   vram_bus_if.device_mp    vram_bus,
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
   input             [10:0] ps2_key,
   input              [5:0] joy[2],
   //Cassete
   output                   tape_motor_on,
   input                    tape_in,
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
   input MSX::kb_memory_t   kb_upload_memory,
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
wire  [9:0] sysAudio    = {4'b0, keybeep,5'b00000} + {5'b0, (tape_in & ~tape_motor_on),4'b0000};
wire [16:0] fm          = {3'b00, sysAudio, 4'b0000};
wire [16:0] audio_mix   = {device_sound[15], device_sound} + fm;
assign compr            = '{ {1'b1, audio_mix[13:0], 1'b0}, 16'h8000, 16'h8000, 16'h8000, 16'h7FFF, 16'h7FFF, 16'h7FFF,  {1'b0, audio_mix[13:0], 1'b0}};
assign audio            = compr[audio_mix[16:14]];

//  -----------------------------------------------------------------------------
//  -- T80 CPU
//  -----------------------------------------------------------------------------
wire [7:0] d_to_cpu;
wire cpu_interrupt;
tv80n Z80
(
   .cpu_bus(cpu_bus.cpu_mp),
   .cpu_regs(cpu_regs),
   .opcode(opcode),
   .opcode_num(opcode_num),
   .opcode_out(opcode_out),
   .opcode_PC_start(opcode_PC_start),
   .wait_n(wait_n),
   .int_n(~cpu_interrupt),
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

wire [1:0] active_slot;

assign active_slot =    //~map_valid                             ? default_slot   :
                        cpu_bus.device_mp.addr[15:14] == 2'b00 ? slot_config[1:0] :
                        cpu_bus.device_mp.addr[15:14] == 2'b01 ? slot_config[3:2] :
                        cpu_bus.device_mp.addr[15:14] == 2'b10 ? slot_config[5:4] :
                                                                 slot_config[7:6] ;

//  -----------------------------------------------------------------------------
//  -- CPU data multiplex
//  -----------------------------------------------------------------------------
assign d_to_cpu = ~cpu_bus.device_mp.rd   ? 8'hFF           :
                  device_oe_rq            ? device_data     :                       // Prioritní data.
                  slot_oe_rq              ? d_from_slots    :                       // Prioritní data.
                                            device_data & ram_dout & d_from_slots;

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
wire  [7:0] slot_config;
wire [26:0] device_ram_addr;
wire        device_ram_ce;
wire        device_oe_rq;
wire        keybeep;

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
   .ram_addr(device_ram_addr),
   .vram_bus(vram_bus),
   .video_bus(video_bus),
   .cpu_interrupt(cpu_interrupt),
   .kb_upload_memory(kb_upload_memory),
   .ps2_key(ps2_key),
   .rtc_time(rtc_time),
   .joy(joy),
   .tape_in(tape_in),
   .tape_motor_on(tape_motor_on),
   .slot_config(slot_config),
   .keybeep(keybeep),
   .msxConfig(msxConfig)
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