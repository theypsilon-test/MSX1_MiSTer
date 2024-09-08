/*verilator tracing_off*/
module devices (
    cpu_bus         cpu_bus,            // Interface for CPU communication
    device_bus      device_bus,         // Interface for device control
    input     [2:0] dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input MSX::io_device_t   io_device[16],  // Array of IO devices with port and mask info
    input     [7:0] dev_dout,           // Data output from device
    input           dev_rd,             // Read request signal
    output signed [15:0] sound          // Combined sound output
);
    // Combine sound outputs from the devices
    assign sound = opl3_sound;

    wire signed [15:0] opl3_sound;
    
    opl3 OPL3
    (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .dev_dout(dev_dout),
        .dev_rd(dev_rd),
        .sound(opl3_sound)
    );

    );

endmodule


