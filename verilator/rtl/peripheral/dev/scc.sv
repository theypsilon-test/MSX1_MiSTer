module dev_scc (
    cpu_bus_if.device_mp    cpu_bus,            // Interface for CPU communication
    device_bus              device_bus,         // Interface for device control
    clock_bus_if.base_mp    clock_bus,
    input MSX::io_device_t  io_device[3],      // Array of IO devices with port and mask info
    output    signed [15:0] sound,              // Combined sound output from SCC devices
    output           [7:0]  data,               // Data output from SCC device
    output                  output_rq           // Output request signal
);

assign sound = '0;
assign output_rq = '0;
assign data = '1;

endmodule