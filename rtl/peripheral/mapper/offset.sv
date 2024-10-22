module mapper_offset (
    cpu_bus_if.device_mp    cpu_bus,       // Interface for CPU communication
    block_info              block_info,    // Struct containing mapper configuration and parameters
    mapper_out              out,           // Interface for mapper output
    device_bus              device_out     // Interface for device output
);
    // Chip select is valid if the mapper type is OFFSET and memory request (mreq) is active
    wire cs = (block_info.typ == MAPPER_OFFSET) & cpu_bus.mreq;

    // Calculate address mapping
    wire [26:0] ram_addr  = {11'b0, block_info.offset_ram, cpu_bus.addr[13:0]};

    // Check if the calculated RAM address is within the valid range of the ROM size
    wire ram_valid = (ram_addr < {2'b00, block_info.rom_size}) && cs;

    // Output assignments
    assign out.ram_cs = ram_valid;  // RAM chip select signal

    // Calculate the address by adding the offset to the base address (only if chip select is active)
    assign out.addr   = ram_valid ? ram_addr : {27{1'b1}};

    // Generate the Read/Not Write (rnw) signal based on the chip select and write signal
    assign out.rnw    = ~(ram_valid && cpu_bus.wr);

    assign device_out.typ = cs ? block_info.device : DEV_NONE;

endmodule
