/*verilator tracing_off*/
module mappers (
    cpu_bus             cpu_bus,       // Interface for CPU communication
    block_info          block_info,    // Struct containing block configuration and parameters
    device_bus          device_bus,    // Interface for device control
    memory_bus          memory_bus,    // Interface for memory control
    output       [7:0]  data,          // Data output from the active mapper; defaults to FF if no mapper is active
    input        [7:0]  data_to_mapper
);

/*verilator tracing_off*/
    // Intermediate signals from each mapper
    mapper_out ascii8_out();            // Outputs from ASCII8 mapper
    mapper_out ascii16_out();           // Outputs from ASCII16 mapper
    mapper_out offset_out();            // Outputs from OFFSET mapper
    mapper_out fm_pac_out();            // Outputs from FM-PAC mapper
    mapper_out konami_out();            // Outputs from KONAMI mapper
    mapper_out konami_SCC_out();        // Outputs from KONAMI SCC mapper
    mapper_out gm2_out();               // Outputs from Konami GameMaster mapper
    mapper_out msx2_ram_out();          // Outputs from MSX2_RAM mapper
    mapper_out m_16kb_out();            // Outputs from 16kb mapper
    device_bus fm_pac_device_out();     // Device bus output for FM-PAC mapper
    device_bus konami_SCC_device_out(); // Device bus output for SCC mapper
    device_bus offset_device_out();     // Device bus output for offset mapper (default mapper)
    device_bus msx2_ram_device_out();   // Device bus output for MSX2_RAM mapper

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
        .out(offset_out),
        .device_out(offset_device_out)
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

    /*verilator tracing_off*/
    // Instantiate the MSX2 RAM mapper
    mapper_msx2_ram msx2_ram (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(msx2_ram_out),
        .device_out(msx2_ram_device_out),
        .data_to_mapper(data_to_mapper)
    );
    
    // Instantiate the 16kb mapper
    mapper_16kb mapper_16kb (
        .cpu_bus(cpu_bus),
        .block_info(block_info),
        .out(m_16kb_out)        
    );
    
    // Data: Use the FM-PAC mapper's data output, assuming it has priority
    assign data = fm_pac_out.data;  // FM-PAC mapper has priority for data output

    // Combine outputs from the mappers
    // Address: Combine addresses from all mappers using a bitwise AND operation
    assign memory_bus.addr  = ascii8_out.addr & ascii16_out.addr & offset_out.addr & fm_pac_out.addr & konami_out.addr & gm2_out.addr & konami_SCC_out.addr & msx2_ram_out.addr & m_16kb_out.addr;

    // Read/Write control: Combine read/write signals from all mappers using a bitwise AND operation
    assign memory_bus.rnw   = ascii8_out.rnw & ascii16_out.rnw & offset_out.rnw & fm_pac_out.rnw & gm2_out.rnw & msx2_ram_out.rnw;

    // RAM chip select: Combine RAM chip select signals using a bitwise OR operation
    assign memory_bus.ram_cs    = ascii8_out.ram_cs | ascii16_out.ram_cs | offset_out.ram_cs | fm_pac_out.ram_cs | konami_out.ram_cs | gm2_out.ram_cs | konami_SCC_out.ram_cs | msx2_ram_out.ram_cs | m_16kb_out.ram_cs;

    // SRAM chip select: Combine SRAM chip select signals using a bitwise OR operation
    assign memory_bus.sram_cs   = ascii8_out.sram_cs | ascii16_out.sram_cs | fm_pac_out.sram_cs | gm2_out.sram_cs;

    // Device control signals: Use the FM-PAC mapper's control signals
    assign device_bus.typ = device_t'(fm_pac_device_out.typ | offset_device_out.typ | konami_SCC_device_out.typ | msx2_ram_device_out.typ);
    assign device_bus.we  = fm_pac_device_out.we;
    assign device_bus.en  = fm_pac_device_out.en | konami_SCC_device_out.en;

endmodule
