module system_memory (
    input                   clk,
    memory_bus_if.ram_mp    memory_bus_msx,
    memory_bus_if.ram_mp    memory_bus_upload,
    //memory_bus_if.ram_mp    memory_bus_flash,
    //memory_bus_if.ram_mp    memory_bus_backup,
    memory_bus_if.device_mp memory_bus_sdram_ch1,
    memory_bus_if.device_mp memory_bus_sdram_ch2,
    memory_bus_if.device_mp memory_bus_sdram_ch3,
    input logic             upload
);

/*
dpram #(.addr_width(16),.mem_name("SYSTEM")) system_ram
(
   .clock(clk),
   .address_a(),
   .wren_a(),
   .data_a(),
   .q_a(),
   .address_b(),
   .wren_b(),
   .data_b(),
   .q_b()
);
*/

    assign memory_bus_sdram_ch1.addr    = upload  ? memory_bus_upload.addr   : memory_bus_msx.addr;
    assign memory_bus_sdram_ch1.data    = upload  ? memory_bus_upload.data   : memory_bus_msx.data;
    assign memory_bus_sdram_ch1.rnw     = upload  ? memory_bus_upload.rnw    : memory_bus_msx.rnw;
    assign memory_bus_sdram_ch1.ram_cs  = upload  ? memory_bus_upload.ram_cs : memory_bus_msx.ram_cs;
    assign memory_bus_sdram_ch1.sram_cs = '0;

    assign memory_bus_upload.q           = memory_bus_upload.ram_cs ? memory_bus_sdram_ch1.q : '1;
    assign memory_bus_upload.sdram_ready = memory_bus_sdram_ch1.sdram_ready;
    assign memory_bus_upload.sdram_done  = memory_bus_sdram_ch1.sdram_done;

    assign memory_bus_msx.q              = memory_bus_msx.ram_cs    ? memory_bus_sdram_ch1.q : '1;
    assign memory_bus_msx.sdram_ready    = memory_bus_sdram_ch1.sdram_ready;
    assign memory_bus_msx.sdram_done     = memory_bus_sdram_ch1.sdram_done;

endmodule
