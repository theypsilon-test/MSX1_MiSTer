module mappers (
    clock_bus_if.base_mp        clock_bus,          // Interface for clock
    cpu_bus_if.device_mp        cpu_bus,            // Interface for CPU communication
    ext_sd_card_if.device_mp    ext_SD_card_bus,    // Interface Ext SD card
    flash_bus_if.device_mp      flash_bus,          // Interface to emulate FLASH
    block_info                  block_info,         // Struct containing block configuration and parameters
    device_bus                  device_bus,         // Interface for device control
    memory_bus                  memory_bus,         // Interface for memory control
    output                [7:0] data,               // Data output from the active mapper; defaults to FF if no mapper is active
    input                 [7:0] data_to_mapper,
    output                      slot_expander_force_en
);

    // Intermediate signals from each mapper
    mapper_out none_out();              // Outputs from LINEAR mapper
    mapper_out ascii8_out();            // Outputs from ASCII8 mapper
    mapper_out ascii16_out();           // Outputs from ASCII16 mapper
    mapper_out offset_out();            // Outputs from OFFSET mapper
    mapper_out fm_pac_out();            // Outputs from FM-PAC mapper
    mapper_out konami_out();            // Outputs from KONAMI mapper
    mapper_out konami_SCC_out();        // Outputs from KONAMI SCC mapper
    mapper_out gm2_out();               // Outputs from Konami GameMaster mapper
    mapper_out msx2_ram_out();          // Outputs from MSX2_RAM mapper
    mapper_out crossBlaim_out();        // Outputs from crossBlaim mapper
    mapper_out generic8k_out();         // Outputs from generic 8k mapper
    mapper_out generic16k_out();        // Outputs from generic 16k mapper
    mapper_out harryFox_out();          // Outputs from Harry Fox mapper
    mapper_out zeimna80_out();          // Outputs from Zemina 80 in 1 mapper
    mapper_out zemina90_out();          // Outputs from Zemina 90 in 1 mapper
    mapper_out mfrsd_out();             // Outputs from MFRSD3 mapper
    device_bus fm_pac_device_out();     // Device bus output for FM-PAC mapper
    device_bus konami_SCC_device_out(); // Device bus output for SCC mapper
    device_bus mfrsd_device_out();      // Device bus output for MFRSD1 mapper
    mapper_out national_out();          // Outputs from NATIONAL mapper
    
    
    //Instantiate the LINEAR mapper
    mapper_none mapper_none (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(none_out)
    );

    // Instantiate the ASCII8 mapper
    mapper_ascii8 ascii8 (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(ascii8_out)
    );

    // Instantiate the ASCII16 mapper
    mapper_ascii16 ascii16 (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(ascii16_out)
    );

    // Instantiate the OFFSET mapper
    mapper_offset offset (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(offset_out)
    );

    // Instantiate the KONAMI mapper
    mapper_konami konami (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(konami_out)
    );

    // Instantiate the KONAMI SCC mapper
    mapper_konami_scc konami_scc (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(konami_SCC_out),
        .device_out(konami_SCC_device_out)
    );

    // Instantiate the FM-PAC mapper
    mapper_fm_pac fm_pac (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(fm_pac_out),
        .device_out(fm_pac_device_out)
    );
    
    // Instantiate the Konami Gamemaster2 mapper
    mapper_gamemaster2 gm2 (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(gm2_out)
    );

    // Instantiate the MSX2 RAM mapper
    mapper_msx2_ram msx2_ram (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(msx2_ram_out),
        .data_to_mapper(data_to_mapper)
    );
   
    // Instantiate the Cross Blaim mapper
    mapper_crossBlaim mapper_crossBlaim (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(crossBlaim_out)
    );

    // Instantiate the Generic 8k mapper
    mapper_generic8k mapper_generic8k (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(generic8k_out)
    );
    
    // Instantiate the Generic 16k mapper
    mapper_generic16k mapper_generic16k (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(generic16k_out)
    );

    // Instantiate the Harry Fox mapper
    mapper_harryFox mapper_harryFox (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(harryFox_out)
    );

    // Instantiate the Zemina80in1 mapper
    mapper_zemina80 mapper_zemina80 (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(zeimna80_out)
    );

    // Instantiate the Zemina90in1 mapper
    mapper_zemina90 mapper_zemina90 (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(zemina90_out),
        .data_to_mapper(data_to_mapper)
    );
      
    mapper_mfrsd  mapper_mfrsd (
        .cpu_bus(cpu_bus),
        .ext_SD_card_bus(ext_SD_card_bus),
        .flash_bus(flash_bus),
        .block_info(block_info),
        .out(mfrsd_out),
        .data_to_mapper(data_to_mapper),
        .device_out(mfrsd_device_out),
        .slot_expander_force_en(slot_expander_force_en)
    );

    // Instantiate the National mapper
    mapper_national national (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(national_out)
    );

    // Assign 
    //assign slot_expander_en = slot_expander_en;

    // Data: Use the FM-PAC mapper's data output, assuming it has priority
    assign data = fm_pac_out.data & mfrsd_out.data & national_out.data;

    // Combine outputs from the mappers
    // Address: Combine addresses from all mappers using a bitwise AND operation
    assign memory_bus.addr  = ascii8_out.addr 
                            & ascii16_out.addr 
                            & offset_out.addr 
                            & fm_pac_out.addr 
                            & konami_out.addr 
                            & gm2_out.addr 
                            & konami_SCC_out.addr 
                            & msx2_ram_out.addr 
                            & crossBlaim_out.addr 
                            & generic8k_out.addr 
                            & generic16k_out.addr
                            & harryFox_out.addr 
                            & zeimna80_out.addr 
                            & zemina90_out.addr 
                            & mfrsd_out.addr
                            & national_out.addr;

    // Read/Write control: Combine read/write signals from all mappers using a bitwise AND operation
    assign memory_bus.rnw   = ascii8_out.rnw 
                            & ascii16_out.rnw 
                            & offset_out.rnw 
                            & fm_pac_out.rnw 
                            & gm2_out.rnw 
                            & msx2_ram_out.rnw 
                            & konami_SCC_out.rnw
                            & mfrsd_out.rnw
                            & national_out.rnw;

    // RAM chip select: Combine RAM chip select signals using a bitwise OR operation
    assign memory_bus.ram_cs    = ascii8_out.ram_cs 
                                | ascii16_out.ram_cs 
                                | offset_out.ram_cs 
                                | fm_pac_out.ram_cs 
                                | konami_out.ram_cs 
                                | gm2_out.ram_cs 
                                | konami_SCC_out.ram_cs 
                                | msx2_ram_out.ram_cs 
                                | crossBlaim_out.ram_cs 
                                | generic8k_out.ram_cs 
                                | generic16k_out.ram_cs
                                | harryFox_out.ram_cs 
                                | zeimna80_out.ram_cs 
                                | zemina90_out.ram_cs 
                                | mfrsd_out.ram_cs
                                | national_out.ram_cs;

    // SRAM chip select: Combine SRAM chip select signals using a bitwise OR operation
    assign memory_bus.sram_cs   = ascii8_out.sram_cs 
                                | ascii16_out.sram_cs 
                                | fm_pac_out.sram_cs 
                                | gm2_out.sram_cs
                                | national_out.sram_cs;

    // Device control signals: Use the FM-PAC mapper's control signals
    assign device_bus.typ   = cpu_bus.mreq ? block_info.device : DEV_NONE;
    
    assign device_bus.we    = fm_pac_device_out.we;
    assign device_bus.en    = fm_pac_device_out.en | konami_SCC_device_out.en | mfrsd_device_out.en;
    assign device_bus.mode  = konami_SCC_device_out.mode & mfrsd_device_out.mode;
    assign device_bus.param = konami_SCC_device_out.param & mfrsd_device_out.param;

endmodule
