module WD2793
(
   cpu_bus_if.device_mp cpu_bus,            // Interface for CPU communication
   device_bus           device_bus,         // Interface for device control
   sd_bus               sd_bus,             // Data from SD
   sd_bus_control       sd_bus_control,     // Control SD
   image_info           image_info,
   output         [7:0] data,
   output               output_rq,
   input          [7:0] param
);

assign data = '1;
assign output_rq = '0;

endmodule