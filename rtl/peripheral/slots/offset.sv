module mapper_offset (
    cpu_bus             cpu_bus,       // Interface for CPU communication
    mapper              mapper,        // Struct containing mapper configuration and parameters
    mapper_out          out            // Interface for mapper output
);

    // Chip select is valid if the mapper type is OFFSET and memory request (mreq) is active
    wire cs = (mapper.typ == MAPPER_OFFSET) & cpu_bus.mreq;

    // Output assignments
    assign out.ram_cs = cs;  // RAM chip select signal
    
    // Calculate the address by adding the offset to the base address (only if chip select is active)
    assign out.addr   = cs ? {11'b0, mapper.offset_ram, cpu_bus.addr[13:0]} : {27{1'b1}};  
    
    // Generate the Read/Not Write (rnw) signal based on the chip select and write signal
    assign out.rnw    = ~(cs & cpu_bus.wr);  

endmodule
