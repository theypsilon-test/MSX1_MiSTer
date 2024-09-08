/*verilator tracing_off*/
module mapper_konami
(
    cpu_bus cpu_bus,                   // Interface for CPU communication
    mapper mapper,                     // Struct containing mapper configuration and parameters
    mapper_out out                     // Interface for mapper output
);
    assign out.sram_cs = '0;
    assign out.ram_cs  = '0;
    assign out.rnw     = '1;
    assign out.addr    = {27{1'b1}};

endmodule
