module msx_slots (
    clock_bus_if.base_mp        clock_bus,        // Interface for clock
    cpu_bus_if.device_mp        cpu_bus,          // Interface for CPU communication
    ext_sd_card_if.device_mp    ext_SD_card_bus,  // Interface Ext SD card
    flash_bus_if.device_mp      flash_bus,        // Interface to emulate FLASH
    input MSX::slot_expander_t  slot_expander[4],
    input MSX::block_t          slot_layout[64],
    input MSX::lookup_RAM_t     lookup_RAM[16],
    input MSX::lookup_SRAM_t    lookup_SRAM[4],
    input                 [1:0] active_slot,      // Currently active slot
    output                [7:0] data,             // Data output
    output                      data_oe_rq,       // Priority output
    output               [26:0] ram_addr,         // RAM address
    output                [7:0] ram_din,          // Data input to RAM
    input                 [7:0] ram_dout,         // Data output from RAM
    output                      ram_rnw,          // RAM read/write control
    output                      sdram_ce,         // SDRAM chip enable
    output                      bram_ce,          // BRAM chip enable
    input                 [1:0] sdram_size,       // SDRAM size
    input MSX::bios_config_t    bios_config,      // BIOS configuration
    device_bus                  device_bus,       // Interface for device control
    input                 [7:0] data_to_mapper
);
    // Mapper and memory bus configuration
    block_info block_info();
    memory_bus memory_bus();

    // Subslot 
    wire       slot_expander_en, slot_expander_wo;
    wire [1:0] active_subslot;
    wire       subslot_output_rq;
    wire [7:0] subslot_data;
    
    
    //TODO zjistit jak zápis a čtení ovlivňuje ostatní. Paměť, atd. dle  MFRSD nedojde k zápisu do RAM a čtení z RAM. (Write není blokováno v MFRSD)
    subslot subslot 
    (
        .cpu_bus(cpu_bus),
        .expander_enable(slot_expander_en),
        .expander_wo(slot_expander_wo),
        .data(subslot_data),
        .active_subslot(active_subslot),
        .output_rq(subslot_output_rq),
        .active_slot(active_slot)
    );

    wire [5:0] layout_id = {active_slot, active_subslot, cpu_bus.addr[15:14]};
    MSX::block_t active_block;
    MSX::lookup_RAM_t active_RAM;
    MSX::lookup_SRAM_t active_SRAM;
    
    assign active_block = slot_layout[layout_id];
    assign active_RAM = lookup_RAM[active_block.ref_ram];
    assign active_SRAM = lookup_SRAM[active_block.ref_sram];
    
    
    assign slot_expander_en = slot_expander[active_slot].en | slot_expander_force_en;
    assign slot_expander_wo = slot_expander[active_slot].wo;
  
    
    // Retrieve configuration for the current slot
    wire [1:0] offset_ram = active_block.offset_ram;
    wire       cart_num   = active_block.cart_num;
        
    // Assign device number based on the current layout
    assign device_bus.num = active_block.device_num;

    // Assign mapper type based on the current slot configuration
    assign block_info.typ      = active_block.mapper;
    assign block_info.device   = active_block.device;
    assign block_info.base_ram = active_RAM.addr;

    // Retrieve RAM and SRAM base addresses and sizes
    wire [26:0] base_ram   = active_RAM.addr;
    wire [15:0] ram_blocks = active_RAM.size;
    wire        ram_ro     = active_RAM.ro;
    wire [26:0] base_sram  = active_SRAM.addr;
    wire [15:0] sram_size  = active_SRAM.size;

    // Data selection between subslot and mapper
    assign data       = subslot_output_rq ? subslot_data : mapper_data;
    assign data_oe_rq = subslot_output_rq;
    
    // RAM data input from CPU bus
    assign ram_din = cpu_bus.data;

    // Chip enable signals for BRAM and SDRAM
    assign bram_ce = '0;  // Assuming BRAM is not used in this context, hence inactive
    assign sdram_ce = ~subslot_output_rq && (memory_bus.ram_cs || memory_bus.sram_cs);

    // RAM read/write control signal
    assign ram_rnw = memory_bus.rnw | (memory_bus.ram_cs & ram_ro);

    // RAM address calculation
    assign ram_addr = (memory_bus.sram_cs ? 27'(base_sram) : base_ram) + memory_bus.addr;

    // Assign mapper configuration based on the current slot and layout
    assign block_info.rom_size  = 25'(ram_blocks) << 14;
    assign block_info.sram_size = sram_size;
    assign block_info.id        = cart_num;
    assign block_info.offset_ram = offset_ram;

    // Mappers module instantiation for handling different mappers
    wire [7:0] mapper_data;
    wire slot_expander_force_en;
    mappers mappers_inst (
        .clock_bus(clock_bus),
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .memory_bus(memory_bus),
        .ext_SD_card_bus(ext_SD_card_bus),
        .flash_bus(flash_bus),
        .block_info(block_info),
        .data(mapper_data),
        .data_to_mapper(data_to_mapper),
        .slot_expander_force_en(slot_expander_force_en)
    );

endmodule
