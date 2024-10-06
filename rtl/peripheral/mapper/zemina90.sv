module mapper_zemina90 (
    cpu_bus         cpu_bus,         // Interface for CPU communication
    block_info      block_info,      // Struct containing mapper configuration and parameters
    mapper_out      out,             // Interface for mapper output
    device_bus      device_out,      // Interface for device control
    input [7:0]     data_to_mapper
);

    wire cs = (block_info.typ == MAPPER_ZEMINA_90) & cpu_bus.mreq;

    // Output assignments
    assign out.ram_cs = cs;  // RAM chip select signal

    // Calculate the address by adding the offset to the base address (only if chip select is active)
    assign out.addr = cs ? {6'b0, data_to_mapper, cpu_bus.addr[12:0]} : {27{1'b1}};

    assign device_out.typ = cs ? block_info.device : DEV_NONE;

endmodule
