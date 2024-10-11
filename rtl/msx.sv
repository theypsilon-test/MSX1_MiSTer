module msx
(
   input                    reset,
   //Clock
   input                    clk21m,
   input                    ce_10m7_p,
   input                    ce_3m58_p,
   input                    ce_3m58_n,
   input                    ce_5m39_n,
   input                    ce_10hz,
   input                    clk_sdram,
   //Video
   video_bus                video_bus,
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
   input  mapper_typ_t      selected_mapper[2],
   input                    sram_save,
   input                    sram_load,
   input              [2:0] dev_enable[0:(1 << $bits(device_t))-1], 
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
   input MSX::block_t       slot_layout[64],
   input MSX::lookup_RAM_t  lookup_RAM[16],
   input MSX::lookup_SRAM_t lookup_SRAM[4],
   input MSX::io_device_t   io_device[16],
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
wire [15:0] a;
wire [7:0] d_to_cpu, d_from_cpu;
wire mreq_n, wr_n, m1_n, iorq_n, rd_n, rfrsh_n;
/*
t80pa #(.Mode(0)) T80
(
   .RESET_n(~reset),
   .CLK(clk21m),
   .CEN_p(ce_3m58_p),
   .CEN_n(ce_3m58_n),
   .WAIT_n(wait_n),
   .INT_n(vdp_int_n),
   .NMI_n(1),
   .BUSRQ_n(1),
   .M1_n(m1_n),
   .MREQ_n(mreq_n),
   .IORQ_n(iorq_n),
   .RD_n(rd_n),
   .WR_n(wr_n),
   .RFSH_n(rfrsh_n),
   .HALT_n(1),
   .BUSAK_n(),
   .A(a),
   .DI(d_to_cpu),
   .DO(d_from_cpu)
);
*/
tv80n Z80
(
   .reset_n(~reset),
   .clk(ce_3m58_n),
   .wait_n(wait_n),
   .int_n(vdp_int_n),
   .nmi_n(1'b1),
   .busrq_n(1'b1),
   .m1_n(m1_n),
   .mreq_n(mreq_n),
   .iorq_n(iorq_n),
   .rd_n(rd_n),
   .wr_n(wr_n),
   .rfsh_n(rfrsh_n),
   .halt_n(),
   .busak_n(),
   .A(a),
   .di(d_to_cpu),
   .dout(d_from_cpu)
);
//  -----------------------------------------------------------------------------
//  -- WAIT CPU
//  -----------------------------------------------------------------------------
wire exwait_n = 1;

logic wait_n = 1'b0;
always @(posedge clk21m, negedge exwait_n, negedge u1_2_q) begin
   if (~exwait_n)
      wait_n <= 1'b0;
   else if (~u1_2_q)
      wait_n <= 1'b1;
   else if (ce_3m58_p)
      wait_n <= m1_n;
end

logic u1_2_q = 1'b0;
always @(posedge clk21m, negedge exwait_n) begin
   if (~exwait_n)
      u1_2_q <= 1'b1;
   else if (ce_3m58_p)
      u1_2_q <= wait_n;
end

logic map_valid = 0;
wire ppi_en = ~ppi_n;
wire [1:0] active_slot;

always @(posedge reset, posedge clk21m) begin
    if (reset)
        map_valid = 0;
    else if (ppi_en)
        map_valid = 1;
end

assign active_slot =    ~map_valid         ? 2'b00         :
                         a[15:14] == 2'b00 ? ppi_out_a[1:0] :
                         a[15:14] == 2'b01 ? ppi_out_a[3:2] :
                         a[15:14] == 2'b10 ? ppi_out_a[5:4] :
                                             ppi_out_a[7:6] ;

//  -----------------------------------------------------------------------------
//  -- IO Decoder
//  -----------------------------------------------------------------------------
wire psg_n  = ~((a[7:3] == 5'b10100)   & ~iorq_n & m1_n);
wire ppi_n  = ~((a[7:3] == 5'b10101)   & ~iorq_n & m1_n);
wire vdp_en =   (a[7:3] == 5'b10011)   & ~iorq_n & m1_n ;
wire rtc_en =   (a[7:1] == 7'b1011010) & ~iorq_n & m1_n & bios_config.MSX_typ == MSX2;

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
   .clk(clk21m),
   .addr(a[1:0]),
   .din(d_from_cpu),
   .dout(d_from_8255),
   .rdn(rd_n),
   .wrn(wr_n),
   .csn(ppi_n),
   .porta_din(8'h0),
   .portb_din(d_from_kb),
   .portc_din(8'h0),
   .porta_dout(ppi_out_a),
   .portb_dout(),
   .portc_dout(ppi_out_c)
 );

//  -----------------------------------------------------------------------------
//  -- CPU data multiplex
//  -----------------------------------------------------------------------------
assign d_to_cpu = rd_n             ? 8'hFF           :
                  vdp_en           ? d_to_cpu_vdp    :
                  rtc_en           ? d_from_rtc      :
                  ~psg_n           ? d_from_psg      :
                  ~ppi_n           ? d_from_8255     :
                  mapper_subslot_rq? mapper_subslot_data :
                  device_output_rq ? device_data     :
                                     ram_dout & d_from_slots;
//  -----------------------------------------------------------------------------
//  -- Keyboard decoder
//  -----------------------------------------------------------------------------
wire [7:0] d_from_kb;
keyboard msx_key
(
   .reset(reset),
   .clk(clk21m),
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
always @(posedge clk21m,  posedge psg_n) begin
   if (psg_n)
      u21_1_q <= 1'b0;
   else if (ce_3m58_p)
      u21_1_q <= ~psg_n;
end

logic u21_2_q = 1'b0;
always @(posedge clk21m, posedge psg_n) begin
   if (psg_n)
      u21_2_q <= 1'b0;
   else if (ce_3m58_p)
      u21_2_q <= u21_1_q;
end

wire psg_e = !(!u21_2_q | ce_3m58_p) | psg_n;
wire psg_bc   = !(a[0] | psg_e);
wire psg_bdir = !(a[1] | psg_e);
jt49_bus PSG
(
   .rst_n(~reset),
   .clk(clk21m),
   .clk_en(ce_3m58_p),
   .bdir(psg_bdir),
   .bc1(psg_bc),
   .din(d_from_cpu),
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

logic iack;
always @(posedge clk21m) begin
   if (reset) iack <= 0;
   else begin
      if (iorq_n  & mreq_n)
         iack <= 0;
      else
         if (req)
            iack <= 1;
   end
end
wire req = ~((iorq_n & mreq_n) | (wr_n & rd_n) | iack);
assign req_dbg = req;
//  -----------------------------------------------------------------------------
//  -- RTC
//  -----------------------------------------------------------------------------
wire [7:0] d_from_rtc;
rtc rtc
(
   .clk21m(clk21m),
   .reset(reset),
   .setup(reset),
   .rt(rtc_time),
   .clkena(ce_10hz),
   .req(req & rtc_en),
   .ack(),
   .wrt(~wr_n),
   .adr(a),
   .dbi(d_from_rtc),
   .dbo(d_from_cpu)
);
//  -----------------------------------------------------------------------------
//  -- Video
//  -----------------------------------------------------------------------------
wire [7:0] d_to_cpu_vdp;
wire       vdp_int_n;   
vdp_mux vdp
(
   .cpu_bus(cpu_bus),
   .video_bus(video_bus),
   .ce(vdp_en),
   .MSX_typ(bios_config.MSX_typ),
   .data(d_to_cpu_vdp),
   .interrupt_n(vdp_int_n),
   .border(msxConfig.border),
   .video_mode(msxConfig.video_mode)
);

wire signed [15:0] device_sound;
device_bus device_bus();
cpu_bus cpu_bus();
assign cpu_bus.clk = clk21m;
assign cpu_bus.clk_en = ce_3m58_p;
assign cpu_bus.clk_en_10_p = ce_10m7_p;
assign cpu_bus.clk_en_5_n = ce_5m39_n;
assign cpu_bus.reset = reset;
assign cpu_bus.mreq = ~mreq_n;
assign cpu_bus.iorq = ~iorq_n;
assign cpu_bus.wr = ~wr_n;
assign cpu_bus.rd = ~rd_n;
assign cpu_bus.m1 = ~m1_n;
assign cpu_bus.data = d_from_cpu;
assign cpu_bus.addr = a;


sd_bus sd_bus();
sd_bus_control sd_bus_control();

assign sd_bus.ack = sd_ack;
assign sd_bus.buff_addr = sd_buff_addr;
assign sd_bus.buff_data = sd_buff_dout;
assign sd_bus.buff_wr = sd_buff_wr;

assign sd_rd  = sd_bus_control.rd;
assign sd_wr  = sd_bus_control.wr;
assign sd_lba = sd_bus_control.sd_lba;
assign sd_buff_din = sd_bus_control.buff_data;

image_info image_info();

assign image_info.mounted = img_mounted;
assign image_info.size = img_size;
assign image_info.readonly = img_readonly;

wire       device_output_rq;
wire [7:0] device_data;
wire [7:0] data_to_mapper;
devices devices
(
   .cpu_bus(cpu_bus),
   .device_bus(device_bus),
   .sd_bus(sd_bus),
   .sd_bus_control(sd_bus_control),
   .image_info(image_info),
   .dev_enable(dev_enable),               //Konfigurace zařízení z load. Povoluje jednotlivé zařízení
   .io_device(io_device),
   .sound(device_sound),
   .data(device_data),
   .output_rq(device_output_rq),
   .data_to_mapper(data_to_mapper)
);

wire         [7:0] d_from_slots;
wire signed [15:0] cart_sound;

wire [1:0] active_subslot;
wire [7:0] mapper_subslot_data;
wire mapper_subslot_rq;
subslot subslot_inst 
(
   .cpu_bus(cpu_bus),
   .expander_enable(bios_config.slot_expander_en),
   .data(mapper_subslot_data),
   .active_subslot(active_subslot),
   .output_rq(mapper_subslot_rq),
   .active_slot(active_slot)
);

wire [5:0] layout_id = {active_slot, active_subslot, cpu_bus.addr[15:14]};
MSX::block_t active_block;
MSX::lookup_RAM_t active_RAM;
MSX::lookup_SRAM_t active_SRAM;

assign active_block = slot_layout[layout_id];
assign active_RAM = lookup_RAM[active_block.ref_ram];
assign active_SRAM = lookup_SRAM[active_block.ref_sram];
msx_slots msx_slots
(
   .cpu_bus(cpu_bus),
   .device_bus(device_bus),
   .data(d_from_slots),  
   .sound(cart_sound),
   .ram_addr(ram_addr),
   .ram_din(ram_din),
   .ram_rnw(ram_rnw),
   .ram_dout(ram_dout),
   .sdram_ce(sdram_ce),
   .bram_ce(bram_ce),
   .sdram_size(sdram_size),
   .active_block(active_block),
   .active_slot(active_slot),
   .active_RAM(active_RAM),
   .active_SRAM(active_SRAM),
   .bios_config(bios_config),
   .data_to_mapper(data_to_mapper)
);
endmodule