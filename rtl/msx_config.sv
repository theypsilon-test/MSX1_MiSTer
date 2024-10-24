parameter CONF_STR_SLOT_A = {
    "H2O[19:17],SLOT A,ROM,SCC,SCC+,FM-PAC,MegaFlashROM SCC+ SD,GameMaster2,FDC,Empty;",
    "h2O[19:17],SLOT A,ROM,SCC,SCC+,FM-PAC,MegaFlashROM SCC+ SD,GameMaster2,Empty;"
};
parameter CONF_STR_SLOT_B = {
    "O[31:29],SLOT B,ROM,SCC,SCC+,FM-PAC,Empty;"
};

module msx_config
(
    input                     clk,
    input                     reset,
    input MSX::bios_config_t  bios_config,
    input              [63:0] HPS_status,
    input                     scandoubler,
    input               [1:0] sdram_size,
    output MSX::config_cart_t cart_conf[2],
    output                    ROM_A_load_hide, //3 
    output                    ROM_B_load_hide, //4
    output                    fdc_enabled,
    output MSX::user_config_t msxConfig,
    output                    reload
);
wire [2:0] slot_A_select   = HPS_status[19:17];
wire [2:0] slot_B_select   = HPS_status[31:29];

cart_typ_t typ_A;
assign typ_A = cart_typ_t'(slot_A_select < CART_TYP_FDC  ? slot_A_select   :
                           bios_config.use_FDC           ? CART_TYP_EMPTY  :
                           slot_A_select == CART_TYP_FDC ? CART_TYP_FDC    :
                                                           CART_TYP_EMPTY );

assign cart_conf[0].typ                = typ_A;
assign cart_conf[1].typ                = slot_B_select < CART_TYP_MFRSD ? cart_typ_t'(slot_B_select) : CART_TYP_EMPTY;

assign msxConfig.typ = bios_config.MSX_typ;
assign msxConfig.scandoubler = scandoubler;
assign msxConfig.video_mode = video_mode_t'(bios_config.MSX_typ == MSX1 ? (HPS_status[12] ? 2'd2 : 2'd1) : HPS_status[14:13]);
assign msxConfig.cas_audio_src = cas_audio_src_t'(HPS_status[40]);
assign msxConfig.border = HPS_status[41];

assign ROM_A_load_hide    = cart_conf[0].typ != CART_TYP_ROM;
assign ROM_B_load_hide    = cart_conf[1].typ != CART_TYP_ROM;
assign fdc_enabled = bios_config.MSX_typ != MSX1 || cart_conf[0].typ == CART_TYP_FDC;


logic  [5:0] lastConfig;
wire [5:0] act_config = {cart_conf[1].typ, cart_conf[0].typ};

always @(posedge clk) begin
    if (reload) lastConfig <= act_config;
end

assign reload = ~reset & lastConfig != act_config;

endmodule
