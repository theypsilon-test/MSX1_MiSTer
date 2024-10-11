module vdp_mux (
    cpu_bus                 cpu_bus,
    video_bus               video_bus,
    input                   ce,
    input MSX::MSX_typ_t    MSX_typ,
    output            [7:0] data,
    output                  interrupt_n,
    input                   border,
    input MSX::video_mode_t video_mode 
);

logic vdp18;


assign vdp18 = (MSX_typ == MSX1);

//CPU access
assign data             = vdp18 ? d_from_vdp18 : d_from_vdp;
assign interrupt_n      = vdp18 ? int_n_vdp18  : int_n_vdp;

//Video access
assign video_bus.R      = vdp18 ? R_vdp18            : {R_vdp,R_vdp[5:4]};
assign video_bus.G      = vdp18 ? G_vdp18            : {G_vdp,G_vdp[5:4]};
assign video_bus.B      = vdp18 ? B_vdp18            : {B_vdp,B_vdp[5:4]};
assign video_bus.HS     = vdp18 ? ~HS_n_vdp18        : ~HS_n_vdp;
assign video_bus.VS     = vdp18 ? ~VS_n_vdp18        : ~VS_n_vdp;
assign video_bus.DE     = vdp18 ? DE_vdp18           : DE_vdp;
assign video_bus.hblank = vdp18 ? hblank_vdp18       : hblank_vdp_cor;
assign video_bus.vblank = vdp18 ? vblank_vdp18       : vblank_vdp;
assign video_bus.ce_pix = vdp18 ? cpu_bus.clk_en_5_n : ~DHClk_vdp;


logic hblank_vdp_cor;
always @(posedge cpu_bus.clk) begin
   if (hblank_vdp)
      hblank_vdp_cor <= 1'b1;
   else 
      if (DHClk_vdp & DLClk_vdp)
         hblank_vdp_cor <= 1'b0;
end

//VRAM access
assign VRAM_address   = vdp18 ? {2'b00, VRAM_address_vdp18} : VRAM_address_vdp[15:0];
assign VRAM_we_lo     = vdp18 ? VRAM_we_vdp18               : VRAM_we_lo_vdp;
assign VRAM_we_hi     = vdp18 ? 1'b0                        : VRAM_we_hi_vdp;
assign VRAM_do        = vdp18 ? VRAM_do_vdp18               : VRAM_do_vdp;

assign VRAM_we_lo_vdp = ~VRAM_we_n_vdp & DLClk_vdp & ~VRAM_address_vdp[16];
assign VRAM_we_hi_vdp = ~VRAM_we_n_vdp & DLClk_vdp &  VRAM_address_vdp[16];

logic iack;
always @(posedge cpu_bus.clk) begin
   if (cpu_bus.reset) iack <= 0;
   else begin
      if (~cpu_bus.iorq && ~cpu_bus.mreq)
         iack <= 0;
      else
         if (req)
            iack <= 1;
   end
end
wire req = ~((~cpu_bus.iorq & ~cpu_bus.mreq) | (~cpu_bus.wr & ~cpu_bus.rd) | iack);

wire        int_n_vdp18;
wire  [7:0] d_from_vdp18;
wire        VRAM_we_lo_vdp, VRAM_we_hi_vdp;
wire  [7:0] R_vdp18, G_vdp18, B_vdp18;
wire        HS_n_vdp18, VS_n_vdp18, DE_vdp18, DLClk_vdp18, hblank_vdp18, vblank_vdp18, Blank_vdp18;
wire [13:0] VRAM_address_vdp18;
wire  [7:0] VRAM_do_vdp18;
wire        VRAM_we_vdp18;
vdp18_core #(.compat_rgb_g(0)) vdp_vdp18
(
   .clk_i(cpu_bus.clk),
   .clk_en_10m7_i(cpu_bus.clk_en_10_p),
   .reset_n_i(~cpu_bus.reset),

   .csr_n_i(~(ce & vdp18) | ~cpu_bus.rd),
   .csw_n_i(~(ce & vdp18) | ~cpu_bus.wr),
   .mode_i(cpu_bus.addr[0]),
   .cd_i(cpu_bus.data),
   .cd_o(d_from_vdp18),
   .int_n_o(int_n_vdp18),
   .vram_we_o(VRAM_we_vdp18),
   .vram_a_o(VRAM_address_vdp18),
   .vram_d_o(VRAM_do_vdp18),
   .vram_d_i(VRAM_di_lo),
   .border_i(border),
   .rgb_r_o(R_vdp18),
   .rgb_g_o(G_vdp18),
   .rgb_b_o(B_vdp18),
   .hsync_n_o(HS_n_vdp18),
   .vsync_n_o(VS_n_vdp18),
   .hblank_o(hblank_vdp18),
   .vblank_o(vblank_vdp18),
   .blank_n_o(DE_vdp18),
   .is_pal_i(video_mode == PAL)
);

wire        int_n_vdp;
wire  [7:0] d_from_vdp;
wire  [5:0] R_vdp, G_vdp, B_vdp;
wire        HS_n_vdp, VS_n_vdp, DE_vdp, DLClk_vdp, DHClk_vdp, Blank_vdp, hblank_vdp, vblank_vdp;
wire [16:0] VRAM_address_vdp;
wire  [7:0] VRAM_do_vdp;
wire        VRAM_we_n_vdp;
VDP vdp_vdp 
(
   .CLK21M(cpu_bus.clk),
   .RESET(cpu_bus.reset),

   .REQ(req & ce & ~vdp18),
   .ACK(),
   .WRT(cpu_bus.wr),
   .ADR(cpu_bus.addr),
   .DBI(d_from_vdp),
   .DBO(cpu_bus.data),
   .INT_N(int_n_vdp),
   .PRAMOE_N(),
   .PRAMWE_N(VRAM_we_n_vdp),
   .PRAMADR(VRAM_address_vdp),
   .PRAMDBI({VRAM_di_hi, VRAM_di_lo}),
   .PRAMDBO(VRAM_do_vdp),
   .VDPSPEEDMODE(0),
   .CENTERYJK_R25_N(0),
   .PVIDEOR(R_vdp),
   .PVIDEOG(G_vdp),
   .PVIDEOB(B_vdp),
   .PVIDEODE(DE_vdp),
   .BLANK_O(Blank_vdp),
   .HBLANK(hblank_vdp),
   .VBLANK(vblank_vdp),
   .PVIDEOHS_N(HS_n_vdp),
   .PVIDEOVS_N(VS_n_vdp),
   .PVIDEOCS_N(),
   .PVIDEODHCLK(DHClk_vdp),
   .PVIDEODLCLK(DLClk_vdp),
   .DISPRESO(/*msxConfig.scandoubler*/ 0),
   .LEGACY_VGA(1),
   .RATIOMODE(3'b000),
   .NTSC_PAL_TYPE(video_mode == AUTO),
   .FORCED_V_MODE(video_mode == PAL),
   .BORDER(border)
);

wire [15:0] VRAM_address;
wire  [7:0] VRAM_do, VRAM_di_lo, VRAM_di_hi;
wire        VRAM_we_lo, VRAM_we_hi;
spram #(.addr_width(16),.mem_name("VRA2")) vram_lo
(
   .clock(cpu_bus.clk),
   .address(VRAM_address),
   .wren(VRAM_we_lo),
   .data(VRAM_do),
   .q(VRAM_di_lo)
);
spram #(.addr_width(16),.mem_name("VRA3")) vram_hi
(
   .clock(cpu_bus.clk),
   .address(VRAM_address),
   .wren(VRAM_we_hi),
   .data(VRAM_do),
   .q(VRAM_di_hi)
);

endmodule