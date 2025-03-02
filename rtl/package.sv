typedef enum logic [3:0] {DEVICE_NONE, DEVICE_ROM } device_typ_t;
typedef enum logic {CAS_AUDIO_FILE,CAS_AUDIO_ADC} cas_audio_src_t;
typedef enum logic [1:0] {Z80, R800, UNKN1, UNKN2} cpu_t;

typedef enum logic [3:0] {CART_TYP_SCC, CART_TYP_SCC2, CART_TYP_FM_PAC, CART_TYP_MFRSD, CART_TYP_GM2, CART_TYP_FDC, CART_MEGASCC1, CART_MEGASCC2, CART_MEGA_ASCII_8, CART_MEGA_ASCII_16, MEGARAM, CART_TYP_ROM, CART_TYP_EMPTY } cart_typ_t;
typedef enum logic [3:0] {DEV_NONE, DEV_OPL3, DEV_SCC, DEV_WD2793, DEV_MSX2_RAM, DEV_LATCH_PORT, DEV_KANJI, DEV_OCM_BOOT, DEV_VDP_TMS, DEV_VDP_V99xx, DEV_RTC, DEV_PSG, DEV_PPI, DEV_RESET_STATUS } device_t;
typedef enum logic [4:0] {MAPPER_NONE, MAPPER_OFFSET, MAPPER_ASCII16, MAPPER_RTYPE, MAPPER_ASCII8, MAPPER_KOEI, MAPPER_WIZARDY, MAPPER_KONAMI, 
                          MAPPER_FMPAC, MAPPER_GM2, VY0010, MAPPER_KONAMI_SCC, MAPPER_MSX2, MAPPER_GENERIC16KB, MAPPER_CROSS_BLAIM, MAPPER_GENERIC8KB, 
                          MAPPER_HARRY_FOX, MAPPER_ZEMINA_80, MAPPER_ZEMINA_90, MAPPER_KONAMI_SCC_PLUS, 
                          MAPPER_MFRSD3, MAPPER_MFRSD2, MAPPER_MFRSD1, MAPPER_MFRSD0, 
                          MAPPER_NATIONAL, MAPPER_ESE_RAM, 
                          MAPPER_MEGARAM, MAPPER_MEGASCC, MAPPER_MEGAASCII8, MAPPER_MEGAASCII16,
                          MAPPER_UNUSED} mapper_typ_t;
typedef enum logic [3:0] {BLOCK_RAM, BLOCK_ROM, BLOCK_SRAM, BLOCK_DEVICE, BLOCK_MAPPER, BLOCK_CART, BLOCK_REF_MEM, BLOCK_REF_DEV, BLOCK_IO_DEVICE, BLOCK_EXPANDER, BLOCK_REF_SHARED_MEM} block_t;
typedef enum logic [2:0] {CONF_BLOCK, CONF_DEVICE, CONF_LAYOUT, CONF_CARTRIGE, CONF_BLOCK_FW, CONF_UNUSED5, CONF_UNUSED6, CONF_END} conf_t;
typedef enum logic [2:0] {ERR_NONE, ERR_BAD_MSX_CONF, ERR_NOT_SUPPORTED_CONF, ERR_NOT_SUPPORTED_BLOCK, ERR_BAD_MSX_FW_CONF, ERR_NOT_FW_CONF, ERR_DEVICE_MISSING, ERR_MISSING_SOURCE} error_t;

interface cpu_regs_if();
    wire [15:0] AF;
    wire [15:0] BC;
    wire [15:0] DE;
    wire [15:0] HL;
    wire [15:0] AF2;
    wire [15:0] BC2;
    wire [15:0] DE2;
    wire [15:0] HL2;
    wire [15:0] IX;
    wire [15:0] IY;
    wire [15:0] PC;
    wire [15:0] SP;
    wire change;
endinterface

interface clock_bus_if(
    input     clk,
    input     clk_mem
);
    wire     ce_10m7_p;
    wire     ce_10m7_n;
    wire     ce_5m39_p;
    wire     ce_5m39_n;   
    wire     ce_3m58_p;
    wire     ce_3m58_n;
    wire     ce_10hz;

    modport generator_mp (
        input   clk,
        input   clk_mem,
        output  ce_10m7_p,
        output  ce_10m7_n,
        output  ce_5m39_p,
        output  ce_5m39_n,   
        output  ce_3m58_p,
        output  ce_3m58_n,
        output  ce_10hz
    );

    modport base_mp (
        input   clk,
        input   clk_mem,
        input   ce_10m7_p,
        input   ce_10m7_n,
        input   ce_5m39_p,
        input   ce_5m39_n,   
        input   ce_3m58_p,
        input   ce_3m58_n,
        input   ce_10hz
    );

endinterface

interface cpu_bus_if(
    input       clk,
    input       reset
);
    wire        cpu_clk;
    wire        mreq;
    wire        iorq;
    wire        rd;
    wire        wr;
    wire        m1;
    wire        halt;
    wire        rfsh;
    wire [15:0] addr;
    wire  [7:0] data;
    wire        req;

    modport cpu_mp (
        input   clk,
        input   reset,
        output  cpu_clk,
        output  mreq,
        output  iorq,
        output  rd,
        output  wr,
        output  m1,
        output  halt,
        output  rfsh,
        output  addr,
        output  data,
        output  req
    );
    
    modport device_mp (
        input   clk,
        input   cpu_clk,
        input   reset,
        input   mreq,
        input   iorq,
        input   rd,
        input   wr,
        input   m1,
        input   halt,
        input   rfsh,
        input   addr,
        input   data,
        input   req
    );

endinterface

interface ext_sd_card_if;
    logic        rx;
    logic        tx;
    logic  [7:0] data_to_SD;
    logic  [7:0] data_from_SD;
    
    modport SD_mp (
        output  data_from_SD,
        input   data_to_SD,
        input   rx,
        input   tx
    );

    modport device_mp (
        input    data_from_SD,
        output   data_to_SD,
        output   rx,
        output   tx
    );
endinterface

interface flash_bus_if;
    logic [22:0] base_addr;
    logic [22:0] addr;
    logic  [7:0] data_to_flash;
    logic  [7:0] data_from_flash;
    logic        data_valid;
    logic        we;
    logic        ce;

    modport flash_mp (
        input  base_addr,
        input  addr,
        input  data_to_flash,
        output data_from_flash,
        output data_valid,
        input  we,
        input  ce
    );

    modport device_mp (
        output base_addr,
        output addr,
        output data_to_flash,
        input  data_from_flash,
        input  data_valid,
        output we,
        output ce
    );
endinterface

interface video_bus_if;
    logic  [7:0] R;
    logic  [7:0] G;
    logic  [7:0] B;
    logic        DE;
    logic        HS;
    logic        VS;
    logic        hblank;
    logic        vblank;
    logic        ce_pix;

    modport device_mp (
        output R, G, B, DE, HS, VS, hblank, vblank, ce_pix
    );
    modport display_mp (
        input R, G, B, DE, HS, VS, hblank, vblank, ce_pix
    );
endinterface

interface vram_bus_if;
    logic   [7:0] q_lo;
    logic   [7:0] q_hi;
    logic  [15:0] addr;
    logic   [7:0] data;
    logic         we_lo;
    logic         we_hi;

    modport device_mp (
        output addr, data, we_lo, we_hi,
        input  q_lo, q_hi
    );
    modport vram_mp (
        input  addr, data, we_lo, we_hi,
        output q_lo, q_hi
    );

endinterface

interface device_bus;
    device_t    typ;
    logic       we;
    logic       en;
    logic       mode;
    logic       param;
    logic [1:0] num;
endinterface

interface memory_bus;
    logic [26:0] addr;
    logic        rnw;
    logic        sram_cs;
    logic        ram_cs;
endinterface

interface mapper_out;
    logic [26:0] addr;
    logic        rnw;
    logic        ram_cs;
    logic        sram_cs;
    logic  [7:0] data;
endinterface

interface block_info;
    logic [24:0] rom_size;
    logic [15:0] sram_size;
    logic  [1:0] offset_ram;
    logic [26:0] base_ram;
    mapper_typ_t typ;
    device_t     device;
    logic        id;
endinterface

interface sd_bus;
   logic          ack;
   logic   [13:0] buff_addr;
   logic    [7:0] buff_data;
   logic          buff_wr;
endinterface

interface sd_bus_control;
   logic         rd;
   logic         wr;
   logic  [31:0] sd_lba;
   logic   [7:0] buff_data;
endinterface

interface image_info;
    logic        mounted;
    logic [31:0] size;
    logic        readonly;
endinterface

package MSX;
    
    typedef struct {
        logic [15:0] AF;
        logic [15:0] BC;
        logic [15:0] DE;
        logic [15:0] HL;
        logic [15:0] AF2;
        logic [15:0] BC2;
        logic [15:0] DE2;
        logic [15:0] HL2;
        logic [15:0] IX;
        logic [15:0] IY;
        logic [15:0] PC;
        logic [15:0] SP;
    } cpu_regs_t; 

    typedef struct {
        logic           border;
        cas_audio_src_t cas_audio_src;
        logic     [7:0] ocm_dip;
    } user_config_t;    
    
    typedef struct {
        logic       en;
        logic       wo;
        logic [7:0] init;
    } slot_expander_t; 
    
    typedef struct {
        logic  [3:0] ref_ram;
        logic  [1:0] ref_sram;
        logic  [1:0] offset_ram;
        logic  [1:0] device_num;
        mapper_typ_t mapper;
        device_t     device;
        logic        cart_num;
        logic        external;
    } block_t;    
    
    typedef struct {
        logic [26:0] addr;
        logic [15:0] size;
        logic        ro;
    } lookup_RAM_t;
    
    typedef struct {
        logic [26:0] addr;
        logic [15:0] size;
    } lookup_SRAM_t;

    typedef struct {
        cart_typ_t   typ;
    } config_cart_t;

    typedef struct {
        logic [7:0] mask; 
        logic [7:0] port;
        logic [7:0] param;
        logic [2:0] mem_ref;
        logic       enable;
    } io_device_t;

    typedef struct {
        logic [26:0] memory;
        logic  [7:0] memory_size;
    } io_device_mem_ref_t;

    typedef struct {
        logic isConfigRegDisabled;
        logic isMemoryMapperEnabled;
        logic isDSKmodeEnabled;
        logic isPSGalsoMappedToNormalPorts;
        logic isSlotExpanderEnabled;
        logic isFlashRomBlockProtectEnabled;
        logic isFlashRomWriteEnabled;
    } mfrsd_config_t;

    typedef struct {
       logic [8:0] addr;
       logic [7:0] data;
       logic       we;
       logic       rq;
    } kb_memory_t;

    typedef struct {
        cpu_t cpu;
        logic [2:0] wait_count;
        logic [2:0] cpu_clock_sel;
    } msx_config_t;

endpackage
