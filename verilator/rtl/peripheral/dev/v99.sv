module dev_v99 (
    cpu_bus_if.device_mp    cpu_bus,
    clock_bus_if.base_mp    clock_bus,
    video_bus_if.device_mp  video_bus,
    vram_bus_if.device_mp   vram_bus,
    input  MSX::io_device_t io_device[3],
    output            [7:0] data,
    output                  interrupt,
    input                   border
);

    assign video_bus.R      = '0;
    assign video_bus.G      = '0;
    assign video_bus.B      = '0;
    assign video_bus.HS     = '0;
    assign video_bus.VS     = '0;
    assign video_bus.DE     = '0;
    assign video_bus.hblank = '0;
    assign video_bus.vblank = '0;
    assign video_bus.ce_pix = '0;
  
    assign vram_bus.addr    = '1;
    assign vram_bus.data    = '1;
    assign vram_bus.we_lo   = '0;
    assign vram_bus.we_hi   = '0;

    assign data             = '1;
    assign interrupt        = '0;


endmodule
