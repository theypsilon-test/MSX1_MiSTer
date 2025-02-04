module mapper_msx2_ram (
    cpu_bus_if.device_mp    cpu_bus,         // Interface for CPU communication
    block_info              block_info,      // Struct containing mapper configuration and parameters
    mapper_out              out,             // Interface for mapper output
    input [7:0]             data_to_mapper
);

    wire cs = (block_info.typ == MAPPER_MSX2) && cpu_bus.mreq && (cpu_bus.wr || cpu_bus.rd);

    // Output assignments
    assign out.ram_cs = cs;  // RAM chip select signal

    // Calculate the address by adding the offset to the base address (only if chip select is active)
    assign out.addr = cs ? {5'b0, data_to_mapper, cpu_bus.addr[13:0]} : {27{1'b1}};

    // Generate the Read/Not Write (rnw) signal based on the chip select and write signal
    assign out.rnw = ~(cs & cpu_bus.wr);

endmodule
