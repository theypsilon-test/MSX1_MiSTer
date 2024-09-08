module mapper_offset (
    cpu_bus             cpu_bus,       // Interface for CPU communication
    block_info          block_info,    // Struct containing mapper configuration and parameters
    mapper_out          out,           // Interface for mapper output
    device_bus          device_out     // Interface for device output
);

    // Chip select is valid if the mapper type is OFFSET and memory request (mreq) is active
    wire cs = (block_info.typ == MAPPER_OFFSET) & cpu_bus.mreq;

    // Output assignments
    assign out.ram_cs = cs;  // RAM chip select signal
    
    // Calculate the address by adding the offset to the base address (only if chip select is active)
    assign out.addr   = cs ? {11'b0, block_info.offset_ram, cpu_bus.addr[13:0]} : {27{1'b1}};  
    
    // Generate the Read/Not Write (rnw) signal based on the chip select and write signal
    assign out.rnw    = ~(cs & cpu_bus.wr);  

    assign device_out.typ = cs ? block_info.device : DEV_NONE;

endmodule
