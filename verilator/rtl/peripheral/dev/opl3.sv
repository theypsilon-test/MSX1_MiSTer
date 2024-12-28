module opl3 (
    cpu_bus_if.device_mp    cpu_bus,            // Interface for CPU communication
    device_bus              device_bus,         // Interface for device control
    input             [2:0] dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input MSX::io_device_t  io_device[3],      // Array of IO devices with port and mask info
    input             [7:0] dev_dout,           // Data output from device
    input                   dev_rd,             // Read request signal
    output    signed [15:0] sound               // Combined sound output
);

    assign sound = '0;

endmodule
