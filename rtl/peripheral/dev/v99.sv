module v99 (
    cpu_bus_if.device_mp    cpu_bus,
    clock_bus_if.base_mp    clock_bus,
    video_bus_if.device_mp  video_bus,
    vram_bus_if.device_mp   vram_bus,
    input  MSX::io_device_t io_device[3],
    output            [7:0] data,
    output                  interrupt,
    input                   border
);

    wire  [7:0] q;
    wire  [5:0] R, G, B;
    wire        interrupt_n, HS_n, VS_n, hblank, vblank, DE;  
    wire        DLClk, DHClk;  
    wire        vram_we;
    wire  [7:0] vram_data;
    wire [16:0] vramm_addr;

    wire io_en       = cpu_bus.iorq && ~cpu_bus.m1;
    wire cs_io_match = (cpu_bus.addr[7:0] & io_device[0].mask) == io_device[0].port;
    wire cs_enable   = io_device[0].enable && cs_io_match && io_en;
    
    assign video_bus.R      = io_device[0].enable ? {R,R[5:4]}                         : '0;
    assign video_bus.G      = io_device[0].enable ? {G,G[5:4]}                         : '0;
    assign video_bus.B      = io_device[0].enable ? {B,B[5:4]}                         : '0;
    assign video_bus.HS     = io_device[0].enable ? ~HS_n                              : '0;
    assign video_bus.VS     = io_device[0].enable ? ~VS_n                              : '0;
    assign video_bus.DE     = io_device[0].enable ? DE                                 : '0;
    assign video_bus.hblank = io_device[0].enable ? hblank_cor                         : '0;
    assign video_bus.vblank = io_device[0].enable ? vblank                             : '0;
    assign video_bus.ce_pix = io_device[0].enable ? ~DHClk                             : '0;

    assign vram_bus.addr    = io_device[0].enable ? vramm_addr[15:0]                   : '1;
    assign vram_bus.data    = io_device[0].enable ? vram_data                          : '1;
    assign vram_bus.we_lo   = io_device[0].enable ? ~vram_we & DLClk & ~vramm_addr[16] : '0;
    assign vram_bus.we_hi   = io_device[0].enable ? ~vram_we & DLClk &  vramm_addr[16] : '0;

    assign interrupt        = io_device[0].enable ? ~interrupt_n                       : '0;

    assign data             = cs_enable           ? q                                  : '1;
    

    logic hblank_cor;
    always @(posedge cpu_bus.clk) begin
        if (hblank)
            hblank_cor <= 1'b1;
        else 
            if (DHClk & DLClk)
                hblank_cor <= 1'b0;
    end

    VDP vdp_vdp 
    (
        .CLK21M(cpu_bus.clk),
        .RESET(cpu_bus.reset),
        .REQ(cs_enable && cpu_bus.req),
        .ACK(),
        .WRT(cpu_bus.wr),
        .ADR(cpu_bus.addr),
        .DBI(q),
        .DBO(cpu_bus.data),
        .INT_N(interrupt_n),
        .PRAMOE_N(),
        .PRAMWE_N(vram_we),
        .PRAMADR(vramm_addr),
        .PRAMDBI({vram_bus.q_hi, vram_bus.q_lo}),
        .PRAMDBO(vram_data),
        .VDPSPEEDMODE(0), //TODO
        .CENTERYJK_R25_N(0), //TODO
        .PVIDEOR(R),
        .PVIDEOG(G),
        .PVIDEOB(B),
        .PVIDEODE(DE),
        .BLANK_O(),
        .HBLANK(hblank),
        .VBLANK(vblank),
        .PVIDEOHS_N(HS_n),
        .PVIDEOVS_N(VS_n),
        .PVIDEOCS_N(),
        .PVIDEODHCLK(DHClk),
        .PVIDEODLCLK(DLClk),
        .DISPRESO(/*msxConfig.scandoubler*/ 0), //TODO
        .LEGACY_VGA(1), //TODO
        .RATIOMODE(3'b000), //TODO
        .NTSC_PAL_TYPE('1),
        .FORCED_V_MODE('0),
        .BORDER(border)
    );

endmodule
