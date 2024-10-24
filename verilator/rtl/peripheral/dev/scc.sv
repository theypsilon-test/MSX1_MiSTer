module scc (
    cpu_bus_if.device_mp    cpu_bus,            // Interface for CPU communication
    device_bus              device_bus,         // Interface for device control
    input             [2:0] dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input MSX::io_device_t  io_device[16],      // Array of IO devices with port and mask info
    output    signed [15:0] sound,              // Combined sound output from SCC devices
    output           [7:0]  data,               // Data output from SCC device
    output                  output_rq           // Output request signal
);

assign sound = '0;
assign output_rq = '0;
assign data = '1;

endmodule