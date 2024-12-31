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
    input                     disable_menu_FDC,
    input              [63:0] HPS_status,
    input               [1:0] sdram_size,
    output MSX::config_cart_t cart_conf[2],
    output                    ROM_A_load_hide, //3 
    output                    ROM_B_load_hide, //4
    output MSX::user_config_t msxConfig,
    output                    reload
);
wire [2:0] slot_A_select   = HPS_status[19:17];
wire [2:0] slot_B_select   = HPS_status[31:29];

cart_typ_t typ_A;
assign typ_A = cart_typ_t'(slot_A_select < CART_TYP_FDC  ? slot_A_select   :
                           disable_menu_FDC               ? CART_TYP_EMPTY : 
                                                            CART_TYP_FDC ) ;

assign cart_conf[0].typ                = typ_A;
assign cart_conf[1].typ                = slot_B_select < CART_TYP_MFRSD ? cart_typ_t'(slot_B_select) : CART_TYP_EMPTY;

assign msxConfig.cas_audio_src = cas_audio_src_t'(HPS_status[40]);
assign msxConfig.border = HPS_status[41];

assign ROM_A_load_hide    = cart_conf[0].typ != CART_TYP_ROM;
assign ROM_B_load_hide    = cart_conf[1].typ != CART_TYP_ROM;

logic  [5:0] lastConfig;
wire [5:0] act_config = {cart_conf[1].typ, cart_conf[0].typ};

always @(posedge clk) begin
    if (reload) lastConfig <= act_config;
end

assign reload = ~reset & lastConfig != act_config;

endmodule
