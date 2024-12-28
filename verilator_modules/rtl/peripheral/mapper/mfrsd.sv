module mapper_mfrsd (
    cpu_bus_if.device_mp        cpu_bus,          // Interface for CPU communication
    block_info                  block_info,       // Struct containing mapper configuration and parameters
    ext_sd_card_if.device_mp    ext_SD_card_bus,  // Interface Ext SD card
    flash_bus_if.device_mp      flash_bus,        // Interface to emulate FLASH
    mapper_out                  out,              // Interface for mapper output
    device_bus                  device_out,
    input                 [7:0] data_to_mapper, 
    output                      slot_expander_force_en
);

    assign out.ram_cs  = '0;
    assign out.addr    = {27{1'b1}};
    assign out.data    = '1;

endmodule
