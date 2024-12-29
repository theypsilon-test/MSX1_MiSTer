module kanji
(
   cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
   input  MSX::io_device_t io_device[16],                          // Array of IO devices with port and mask info
   output                  ram_cs,
   output           [26:0] ram_addr
);

ram_cs = 0;
ram_addr = '1;
endmodule