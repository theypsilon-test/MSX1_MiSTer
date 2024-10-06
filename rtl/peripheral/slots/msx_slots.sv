module msx_slots (
    cpu_bus                     cpu_bus,          // Interface for CPU communication
    input                 [1:0] active_slot,      // Currently active slot
    output                [7:0] data,             // Data output
    output signed        [15:0] sound,            // Sound output
    output               [26:0] ram_addr,         // RAM address
    output                [7:0] ram_din,          // Data input to RAM
    input                 [7:0] ram_dout,         // Data output from RAM
    output                      ram_rnw,          // RAM read/write control
    output                      sdram_ce,         // SDRAM chip enable
    output                      bram_ce,          // BRAM chip enable
    input                 [1:0] sdram_size,       // SDRAM size
    input  MSX::block_t         active_block,     // Slot layout configuration
    input  MSX::lookup_RAM_t    active_RAM,       // RAM lookup table
    input  MSX::lookup_SRAM_t   active_SRAM,      // SRAM lookup table
    input  MSX::bios_config_t   bios_config,      // BIOS configuration
    device_bus               device_bus,          // Interface for device control
    input                 [7:0] data_to_mapper
);
    // Mapper and memory bus configuration
    block_info block_info();
    memory_bus memory_bus();

    // Retrieve configuration for the current slot
    wire [3:0] ref_ram    = active_block.ref_ram;
    wire [1:0] ref_sram   = active_block.ref_sram;
    wire [1:0] offset_ram = active_block.offset_ram;
    wire       cart_num   = active_block.cart_num;
        
    // Assign device number based on the current layout
    assign device_bus.num = active_block.device_num;

    // Assign mapper type based on the current slot configuration
    assign block_info.typ = active_block.mapper;
    assign block_info.device = active_block.device;
    
    // Retrieve RAM and SRAM base addresses and sizes
    wire [26:0] base_ram   = active_RAM.addr;
    wire [15:0] ram_blocks = active_RAM.size;
    wire        ram_ro     = active_RAM.ro;
    wire [26:0] base_sram  = active_SRAM.addr;
    wire [15:0] sram_size  = active_SRAM.size;

    // Data selection between subslot and mapper
    assign data = mapper_data;

    // RAM data input from CPU bus
    assign ram_din = cpu_bus.data;

    // Chip enable signals for BRAM and SDRAM
    assign bram_ce = '0;  // Assuming BRAM is not used in this context, hence inactive
    assign sdram_ce = memory_bus.ram_cs || memory_bus.sram_cs;

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

    mappers mappers_inst (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .memory_bus(memory_bus),
        .block_info(block_info),
        .data(mapper_data),
        .data_to_mapper(data_to_mapper)
    );

endmodule
