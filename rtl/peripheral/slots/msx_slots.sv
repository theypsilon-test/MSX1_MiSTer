module msx_slots (
    cpu_bus                     cpu_bus,          // Interface for CPU communication
    input                 [1:0] active_slot,      // Currently active slot
    output                [7:0] data,             // Data output
    input                       clk_sdram,        // SDRAM clock
    output signed        [15:0] sound,            // Sound output
    output               [26:0] ram_addr,         // RAM address
    output                [7:0] ram_din,          // Data input to RAM
    input                 [7:0] ram_dout,         // Data output from RAM
    output                      ram_rnw,          // RAM read/write control
    output                      sdram_ce,         // SDRAM chip enable
    output                      bram_ce,          // BRAM chip enable
    input                 [1:0] sdram_size,       // SDRAM size
//    output               [26:0] flash_addr,       // Flash memory address
//    output                [7:0] flash_din,        // Flash data input
//    output                      flash_req,        // Flash request
//    input                       flash_ready,      // Flash ready signal
//    input                       flash_done,       // Flash done signal
//    input                       img_mounted,      // Image mounted flag
//    input                [31:0] img_size,         // Image size
//    input                       img_readonly,     // Image read-only flag
//    output               [31:0] sd_lba,           // SD card LBA address
//    output                      sd_rd,            // SD card read control
//    output                      sd_wr,            // SD card write control
//    input                       sd_ack,           // SD card acknowledge
//    input                [13:0] sd_buff_addr,     // SD buffer address
//    input                 [7:0] sd_buff_dout,     // SD buffer data output
//    output                [7:0] sd_buff_din,      // SD buffer data input
//    input                       sd_buff_wr,       // SD buffer write control
    input  MSX::block_t         slot_layout[64],  // Slot layout configuration
    input  MSX::lookup_RAM_t    lookup_RAM[16],   // RAM lookup table
    input  MSX::lookup_SRAM_t   lookup_SRAM[4],   // SRAM lookup table
    input  MSX::bios_config_t   bios_config,      // BIOS configuration
    input  mapper_typ_t         selected_mapper[2], // Selected mapper for slots
    input  dev_typ_t            cart_device[2],   // Cartridge device types
    input  dev_typ_t            msx_device,       // MSX device type
    input                 [3:0] msx_dev_ref_ram[8], // MSX device reference RAM
//    output             [7:0] d_to_sd,             // Data to SD card
//    input              [7:0] d_from_sd,           // Data from SD card
//    output                   sd_tx,               // SD transmit
//    output                   sd_rx,               // SD receive
//    output                   debug_FDC_req,       // Debug FDC request
//    output                   debug_sd_card,       // Debug SD card
//    output                   debug_erase,         // Debug erase
    device_bus               device_bus           // Interface for device control
);
    // Mapper and memory bus configuration
    block_info block_info();
    memory_bus memory_bus();

    // Assign data to SD card from CPU bus
    //assign d_to_sd = cpu_bus.data;

    // Calculate block and layout ID based on CPU address and active slot
    wire [1:0] block = cpu_bus.addr[15:14];
    wire [5:0] layout_id = {active_slot, subslot, block};

    // Retrieve configuration for the current slot
    wire [3:0] ref_ram    = slot_layout[layout_id].ref_ram;
    wire [1:0] ref_sram   = slot_layout[layout_id].ref_sram;
    wire [1:0] offset_ram = slot_layout[layout_id].offset_ram;
    wire       cart_num   = slot_layout[layout_id].cart_num;
    //wire       external   = slot_layout[layout_id].external; // Currently not used, commented out
    
    // Assign device number based on the current layout
    assign device_bus.num = slot_layout[layout_id].device_num;

    // Assign mapper type based on the current slot configuration
    assign block_info.typ = slot_layout[layout_id].mapper;
    assign block_info.device = slot_layout[layout_id].device;
    // Retrieve RAM and SRAM base addresses and sizes
    wire [26:0] base_ram   = lookup_RAM[ref_ram].addr;
    wire [15:0] ram_blocks = lookup_RAM[ref_ram].size;
    wire        ram_ro     = lookup_RAM[ref_ram].ro;
    wire [26:0] base_sram  = lookup_SRAM[ref_sram].addr;
    wire [15:0] sram_size  = lookup_SRAM[ref_sram].size;

    // Data selection between subslot and mapper
    assign data = mapper_subslot_cs ? subslot_data : mapper_data;

    // RAM data input from CPU bus
    assign ram_din = cpu_bus.data;

    // Chip enable signals for BRAM and SDRAM
    assign bram_ce = '0;  // Assuming BRAM is not used in this context, hence inactive
    assign sdram_ce = (memory_bus.ram_cs || memory_bus.sram_cs) && ~mapper_subslot_cs;

    // RAM read/write control signal
    assign ram_rnw = memory_bus.rnw | (memory_bus.ram_cs & ram_ro) | mapper_subslot_cs;

    // RAM address calculation
    assign ram_addr = (memory_bus.sram_cs ? 27'(base_sram) : base_ram) + memory_bus.addr;

    // Assign mapper configuration based on the current slot and layout
    assign block_info.rom_size  = 25'(ram_blocks) << 14;
    assign block_info.sram_size = sram_size;
    assign block_info.id        = cart_num;
    assign block_info.offset_ram = offset_ram;

    // Subslot module instantiation for subslot management
    wire [1:0] subslot;
    wire [7:0] subslot_data;
    wire mapper_subslot_cs;
    
    subslot subslot_inst (
        .cpu_bus(cpu_bus),
        .expander_enable(bios_config.slot_expander_en),
        .data(subslot_data),
        .active_subslot(subslot),
        .cs(mapper_subslot_cs),
        .active_slot(active_slot)
    );

    // Mappers module instantiation for handling different mappers
    wire [7:0] mapper_data;

    mappers mappers_inst (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .memory_bus(memory_bus),
        .block_info(block_info),
        .data(mapper_data)
    );
/*verilator tracing_off*/
endmodule
