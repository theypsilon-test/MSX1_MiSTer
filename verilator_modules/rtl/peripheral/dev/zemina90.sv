module zemina90 (
    cpu_bus_if.device_mp    cpu_bus,         // Interface for CPU communication
    device_bus              device_bus,      // Interface for device control
    input  MSX::io_device_t io_device[16],   // Array of IO devices with port and mask info
    output            [7:0] data_to_mapper
);

    assign data_to_mapper = 8'hFF;

endmodule