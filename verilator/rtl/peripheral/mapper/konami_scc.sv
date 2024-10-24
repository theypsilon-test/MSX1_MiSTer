module mapper_konami_scc (
   cpu_bus_if.device_mp    cpu_bus,        // Interface for CPU communication
   mapper_out              out,            // Interface for mapper output
   block_info              block_info,     // Struct containing mapper configuration and parameters 
   device_bus              device_out      // Interface for device output
);

   assign out.sram_cs = '0;
   assign out.ram_cs  = '0;
   assign out.rnw     = '1;
   assign out.addr    = {27{1'b1}};
   
   assign device_out.en = '0;
   assign device_out.typ = DEV_NONE;

endmodule
       