module mapper_crossBlaim (
    cpu_bus_if.device_mp    cpu_bus,                // Interface for CPU communication
    block_info              block_info,             // Struct containing mapper configuration and parameters
    mapper_out              out                     // Interface for mapper output
);

    assign out.ram_cs  = '0;
    assign out.addr    = {27{1'b1}};

endmodule
