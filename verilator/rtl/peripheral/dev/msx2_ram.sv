module dev_msx2_ram (
    cpu_bus_if.device_mp    cpu_bus,         // Interface for CPU communication
    device_bus              device_bus,      // Interface for device control
    input  MSX::io_device_t io_device[3], // Array of IO devices with port and mask info
    output                  output_rq,
    output            [7:0] data,
    output            [7:0] data_to_mapper,
    input                   limit_internal_mapper
);

assign data = '1;
assign output_rq = '0;

endmodule