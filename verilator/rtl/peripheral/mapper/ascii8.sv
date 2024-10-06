module mapper_ascii8 (
    cpu_bus cpu_bus,                   // Interface for CPU communication
    block_info block_info,             // Struct containing mapper configuration and parameters
    mapper_out out                     // Interface for mapper output
);
    assign out.sram_cs = '0;
    assign out.ram_cs  = '0;
    assign out.rnw     = '1;
    assign out.addr    = {27{1'b1}};

endmodule
