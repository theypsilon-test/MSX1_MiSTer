module mapper_none (
    input               cpu_mreq,
    input               cpu_rd,
    input               cpu_wr,
    input        [15:0] cpu_addr,    
    input  mapper_typ_t mapper,
    input         [1:0] offset_ram,
    output       [26:0] mem_addr,
    output              mem_rnw,
    output              ram_cs
);

wire cs = (mapper == MAPPER_NONE) & cpu_mreq;

assign ram_cs   = cs;
assign mem_addr = cs ? {offset_ram, cpu_addr[13:0]} : {27{1'b1}};
assign mem_rnw  = ~(cs & cpu_wr);

endmodule
