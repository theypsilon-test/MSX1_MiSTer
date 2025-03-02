module mapper_megaram (
    cpu_bus_if.device_mp     cpu_bus,        // Interface for CPU communication
    mapper_out               out,            // Interface for mapper output
    block_info               block_info,     // Struct containing mapper configuration and parameters 
    device_bus               device_out,     // Interface for device output
    input                    ocm_slot1_mode,
    input              [1:0] ocm_slot2_mode
);

    assign out.sram_cs = '0;
    assign out.ram_cs  = '0;
    assign out.rnw     = '1;
    assign out.addr    = {27{1'b1}};
    assign out.data    = '{8{1'b1}};

    assign device_out.en = '0;
    
endmodule