module modules
(
    input clk               /* verilator public */,
    input clk_ce            /* verilator public */,
    input reset             /* verilator public */
);

logic [7:0] slot_mapper /* verilator public */;          
logic [2:0] dev_enable[0:(1 << $bits(device_t))-1]  /* verilator public */ ;
MSX::block_t       slot_layout[64] /* verilator public */ ;
MSX::lookup_RAM_t  lookup_RAM[16] /* verilator public */ ;
MSX::lookup_SRAM_t lookup_SRAM[4] /* verilator public */ ;
MSX::io_device_t   io_device[16] /* verilator public */ ;
MSX::slot_expander_t slot_expander[4] /* verilator public */ ;

wire [1:0] active_slot = slot_mapper[(cpu_bus.device_mp.addr[15:14] * 2) +: 2];

cpu_bus_if          cpu_bus(clk, clk_ce, reset);
clock_bus_if        clock_bus(clk);
flash_bus_if        flash_bus();
ext_sd_card_if      ext_SD_card_bus();
device_bus          device_bus();
sd_bus              sd_bus();
sd_bus_control      sd_bus_control();
image_info          image_info();

clock clock
(
   .reset(reset),
   .clock_bus(clock_bus)
);

wire [7:0] d_to_cpu;
cpu cpu(
    .cpu_bus(cpu_bus),
    .di(d_to_cpu)
);
/*
wire [1:0] active_subslot;

subslot subslot (
   .cpu_bus(cpu_bus),
   .active_slot(active_slot),
   .active_subslot(active_subslot),
   .expander_enable(),
   .data(),
   .output_rq()
);

/*
wire [5:0] layout_id = {active_slot, active_subslot, cpu_bus.device_mp.addr[15:14]};
MSX::block_t active_block;
MSX::lookup_RAM_t active_RAM;
MSX::lookup_SRAM_t active_SRAM;

assign active_block = slot_layout[layout_id];
assign active_RAM = lookup_RAM[active_block.ref_ram];
assign active_SRAM = lookup_SRAM[active_block.ref_sram];
*/
msx_slots msx_slots(
    .clock_bus(clock_bus),
    .cpu_bus(cpu_bus),
    .ext_SD_card_bus(ext_SD_card_bus),
    .flash_bus(flash_bus),
    .active_slot(active_slot),       //<
    .slot_expander(slot_expander),
    .slot_layout(slot_layout),
    .lookup_RAM(lookup_RAM),
    .lookup_SRAM(lookup_SRAM),
    .data(d_to_cpu),                 //>
    .ram_addr(sdram_addr),                     //>
    .ram_din(sdram_din),                      //>
    .ram_dout(sdram_dout),                     //<
    .ram_rnw(sdram_rnw),                      //>
    .sdram_ce(sdram_req),                     //>
    .bram_ce(),                      //>
    .sdram_size(),                   //<
    .bios_config(),                  //<
    .device_bus(device_bus),         //
    .data_to_mapper(data_to_mapper)                //<
);

wire [7:0] data_to_mapper;
devices devices
(
   .clock_bus(clock_bus),
   .cpu_bus(cpu_bus),
   .device_bus(device_bus),
   .sd_bus(sd_bus),
   .sd_bus_control(sd_bus_control),
   .image_info(image_info),
   .dev_enable(dev_enable),               //Konfigurace zařízení z load. Povoluje jednotlivé zařízení
   .io_device(io_device),
   .sound(),
   .data(),
   .output_rq(),
   .data_to_mapper(data_to_mapper)
);

wire  [26:0] flash_addr, sdram_addr;
wire   [7:0] flash_dout, sdram_din, sdram_dout;
wire         flash_req, flash_ready, flash_done, sdram_rnw, sdram_req;
flash flash (
   .clk(cpu_bus.clk),
   .clk_sdram(cpu_bus.clk),
   .flash_bus(flash_bus),
   .sdram_ready(flash_ready),
   .sdram_done(flash_done),
   .sdram_addr(flash_addr),
   .sdram_din(flash_dout),
   .sdram_req(flash_req)
);

sdram sdram
(
   .init(),
   .clk(),
   .doRefresh(1'd0),
   
   .ch1_dout(sdram_dout),
   .ch1_din(sdram_din),
   .ch1_addr(sdram_addr),
   .ch1_req(sdram_req),
   .ch1_rnw(sdram_rnw),
   .ch1_ready(),
   
   .ch2_dout(),
   .ch2_din(flash_dout),
   .ch2_addr(flash_addr),
   .ch2_req(flash_req),
   .ch2_rnw(0),
   .ch2_ready(flash_ready),
   .ch2_done(flash_done),

   .ch3_addr(),
   .ch3_dout(),
   .ch3_din(),
   .ch3_req(),
   .ch3_rnw(),
   .ch3_ready(),
   .ch3_done()
);    

endmodule