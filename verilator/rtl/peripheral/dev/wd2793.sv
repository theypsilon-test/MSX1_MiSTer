module WD2793
(
   cpu_bus_if.device_mp cpu_bus,            // Interface for CPU communication
   device_bus           device_bus,         // Interface for device control
   input  MSX::io_device_t io_device[3],    // Array of IO devices with port and mask info
   sd_bus               sd_bus,             // Data from SD
   sd_bus_control       sd_bus_control,     // Control SD
   image_info           image_info,
   output         [7:0] data,
   output               data_oe_rq,
   input          [7:0] param
);

assign data = '1;
assign data_oe_rq = '0;

endmodule