module dev_ocm
(
   cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
   clock_bus_if.base_mp    clock_bus,
   input  MSX::io_device_t io_device[3],                          // Array of IO devices with port and mask info
   input  MSX::io_device_mem_ref_t io_memory[8],
   input             [7:0] ff_dip_req,
   input            [10:0] ps2_key,
   output                  cpu_wait,
   output            [1:0] cpu_clock_sel,
   output                  ram_cs,
   output           [26:0] ram_addr,
   output            [7:0] data,
   output                  mapper_limit,
   output                  rst_key_lock,
   output                  swio_reset,
   output                  megaSD_enable,
   output                  Slot1Mode,
   output            [1:0] Slot2Mode,
   output  [7:0]           debug_data[8]
);


assign debug_data[0] = 8'h12;
assign debug_data[1] = 8'h9a;
assign debug_data[2] = 8'hfe;
assign debug_data[3] = 8'ha5;
assign debug_data[4] = 8'h12;
assign debug_data[5] = 8'h34;
assign debug_data[6] = 8'h56;
assign debug_data[7] = 8'h78;
assign ram_cs = 0;
assign ram_addr = '1;
assign mapper_limit = '0;
assign data = '1;
assign rst_key_lock = '0;
assign swio_reset = '0;
assign megaSD_enable = '0;
assign cpu_wait = '0;
assign cpu_clock_sel = 2'b00;

endmodule
