module mapper_zemina90 (
    cpu_bus_if.device_mp    cpu_bus,                // Interface for CPU communication
    block_info              block_info,             // Struct containing mapper configuration and parameters
    device_bus              device_out,             // Interface for device control
    mapper_out              out,                    // Interface for mapper output
    input             [7:0] data_to_mapper
);

    assign out.ram_cs  = '0;
    assign out.addr    = {27{1'b1}};
    assign device_out.typ = DEV_NONE;

endmodule
