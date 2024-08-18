module mappers(
    input               clk,
    input               reset,
    input               cpu_mreq,
    input               cpu_wr,
    input               cpu_rd,
    input         [7:0] cpu_data,
    input        [15:0] cpu_addr,  
    input        [24:0] rom_size,
    input        [15:0] sram_size,
    input         [1:0] offset_ram,     
    input  mapper_typ_t mapper,
    input               mapper_id,
    output      [24:0]  mem_addr,      //Adresa požadované paměti (obecná)
    output              mem_rnw,       //Požadavek RD/WR (obecný)
    output              ram_cs,        //Požadovaná RAM/ROM
    output              sram_cs        //Požadovaná SRAM
);

assign mem_addr = ascii8_addr  & ascii16_addr & offset_addr;
assign mem_rnw  = ascii8_rnw & ascii16_rnw & offset_rnw;
assign ram_cs   = ascii8_ram_cs | ascii16_ram_cs | offset_ram_cs;
assign sram_cs  = ascii8_sram_cs | ascii16_sram_cs;


wire [24:0] ascii8_addr;
wire        ascii8_sram_cs, ascii8_ram_cs, ascii8_rnw;
cart_ascii8 ascii8
(
   .mem_addr(ascii8_addr),
   .mem_rnw(ascii8_rnw),
   .ram_cs(ascii8_ram_cs),
   .sram_cs(ascii8_sram_cs),
   .*
);

wire [24:0] ascii16_addr;
wire        ascii16_sram_cs, ascii16_ram_cs, ascii16_rnw;
cart_ascii16 ascii16
(
   .mem_addr(ascii16_addr),
   .mem_rnw(ascii16_rnw),
   .ram_cs(ascii16_ram_cs),
   .sram_cs(ascii16_sram_cs),
   .*
);

/* verilator lint_off IMPLICIT */
wire [26:0] offset_addr;
wire offset_ram_cs, offset_rnw;
mapper_offset offset
(
   .mem_addr(offset_addr),
   .mem_rnw(offset_rnw),
   .ram_cs(offset_ram_cs),
   .*
);

endmodule