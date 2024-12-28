module kanji
(
   cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
   input  [2:0]            dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
   input  MSX::io_device_t io_device[3],                       // Array of IO devices with port and mask info
   input  MSX::io_device_mem_ref_t io_memory[8],
   output                  ram_cs,
   output           [26:0] ram_addr
);

assign ram_cs = 0;
assign ram_addr = '1;
endmodule