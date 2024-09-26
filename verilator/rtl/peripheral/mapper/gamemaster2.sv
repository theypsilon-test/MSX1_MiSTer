/*verilator tracing_off*/
module mapper_gamemaster2
(
    cpu_bus     cpu_bus,   // Interface for CPU communication
    mapper_out  out,       // Interface for mapper output
    block_info block_info // Struct containing mapper configuration and parameters
);

    assign out.sram_cs = '0;
    assign out.ram_cs  = '0;
    assign out.rnw     = '1;
    assign out.addr    = {27{1'b1}};
    assign out.data    = '{8{1'b1}};

endmodule