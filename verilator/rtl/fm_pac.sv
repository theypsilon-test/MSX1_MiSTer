/*verilator tracing_off*/
module mapper_fm_pac
(
    cpu_bus cpu_bus,                   // Interface for CPU communication
    block_info block_info,             // Struct containing mapper configuration and parameters
    mapper_out out,                    // Interface for mapper output
    device_bus device_out              // Interface for device output
);
    assign out.sram_cs = '0;
    assign out.ram_cs  = '0;
    assign out.rnw     = '1;
    assign out.addr    = {27{1'b1}};
    assign out.data    = '{8{1'b1}};

    assign device_out.typ = DEV_NONE;
    assign device_out.we  = '0;
    assign device_out.en  = '0;

endmodule

