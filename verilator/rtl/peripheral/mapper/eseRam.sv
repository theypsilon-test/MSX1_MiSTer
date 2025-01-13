module mapper_eseRam (
    cpu_bus_if.device_mp    cpu_bus,                // Interface for CPU communication
    block_info              block_info,             // Struct containing mapper configuration and parameters
    mapper_out              out,
    ext_sd_card_if.device_mp    ext_SD_card_bus
);

    assign out.ram_cs  = '0;
    assign out.addr    = {27{1'b1}};
    assign out.rnw = '1;
    assign out.data    = '{8{1'b1}};
    
    assign ext_SD_card_bus.data_to_SD = '1;
    assign ext_SD_card_bus.rx = '0;
    assign ext_SD_card_bus.tx = '0;

endmodule
