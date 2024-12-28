typedef enum logic [1:0] {AUTO,PAL,NTSC} video_mode_t;
typedef enum logic {CAS_AUDIO_FILE,CAS_AUDIO_ADC} cas_audio_src_t;
typedef enum logic [3:0] {CONFIG_NONE, CONFIG_FDC, CONFIG_SLOT_A, CONFIG_SLOT_B, CONFIG_SLOT_INTERNAL, CONFIG_KBD_LAYOUT, CONFIG_CONFIG, CONFIG_DEVICE} config_typ_t;
typedef enum logic [2:0] {CART_TYP_ROM, CART_TYP_SCC, CART_TYP_SCC2, CART_TYP_FM_PAC, CART_TYP_MFRSD, CART_TYP_GM2, CART_TYP_FDC, CART_TYP_EMPTY } cart_typ_t;
//typedef enum logic [4:0] {MAPPER_UNUSED, MAPPER_RAM, MAPPER_AUTO, MAPPER_NONE, MAPPER_ASCII8, MAPPER_ASCII16, MAPPER_KONAMI, MAPPER_KONAMI_SCC, MAPPER_KOEI, MAPPER_LINEAR, MAPPER_RTYPE, MAPPER_WIZARDY, /*NEXT INTERNAL*/ MAPPER_FMPAC,MAPPER_OFFSET, MAPPER_MFRSD1,MAPPER_MFRSD2, MAPPER_MFRSD3, MAPPER_GM2, MAPPER_HALNOTE} mapper_typ_t;
//typedef enum logic [3:0] {DEVICE_NONE, DEVICE_ROM, DEVICE_RAM, DEVICE_FDC,  DEVICE_MFRSD0} device_typ_t;
typedef enum logic [3:0] {ROM_NONE, ROM_ROM, ROM_RAM, ROM_FDC, ROM_FMPAC, ROM_MFRSD, ROM_GM2 } data_ID_t;

typedef enum logic [1:0] {MSX1,MSX2,MSXx,OCM} MSX_typ_t;


typedef enum logic [3:0] {DEVICE_NONE, DEVICE_ROM } device_typ_t;
typedef enum logic [3:0] {DEV_NONE, DEV_OPL3, DEV_SCC, DEV_WD2793, DEV_MSX2_RAM, DEV_LATCH_PORT, DEV_KANJI, DEV_OCM_BOOT } device_t;
typedef enum logic [4:0] {MAPPER_NONE, MAPPER_OFFSET, MAPPER_ASCII16, MAPPER_RTYPE, MAPPER_ASCII8, MAPPER_KOEI, MAPPER_WIZARDY, MAPPER_KONAMI, MAPPER_FMPAC, MAPPER_GM2, VY0010, MAPPER_KONAMI_SCC, MAPPER_MSX2, MAPPER_GENERIC16KB, MAPPER_CROSS_BLAIM, MAPPER_GENERIC8KB, MAPPER_HARRY_FOX, MAPPER_ZEMINA_80, MAPPER_ZEMINA_90, MAPPER_KONAMI_SCC_PLUS, MAPPER_MFRSD3, MAPPER_MFRSD2, MAPPER_MFRSD1, MAPPER_MFRSD0, MAPPER_NATIONAL, MAPPER_ESE_RAM, MAPPER_UNUSED} mapper_typ_t;
typedef enum logic [3:0] {BLOCK_RAM, BLOCK_ROM, BLOCK_SRAM, BLOCK_DEVICE, BLOCK_MAPPER, BLOCK_CART, BLOCK_REF_MEM, BLOCK_REF_DEV, BLOCK_IO_DEVICE, BLOCK_EXPANDER, BLOCK_REF_SHARED_MEM} block_t;
typedef enum logic [2:0] {CONF_BLOCK, CONF_DEVICE, CONF_LAYOUT, CONF_CARTRIGE, CONF_BLOCK_FW, CONF_UNUSED5, CONF_UNUSED6, CONF_END} conf_t;
typedef enum logic [2:0] {ERR_NONE, ERR_BAD_MSX_CONF, ERR_NOT_SUPPORTED_CONF, ERR_NOT_SUPPORTED_BLOCK, ERR_BAD_MSX_FW_CONF, ERR_NOT_FW_CONF, ERR_DEVICE_MISSING} error_t;


typedef logic [15:0] dev_typ_t;


/*msx*/

parameter DEVs_NONE           = dev_typ_t'(0);
parameter DEVs_KANJI          = dev_typ_t'(1 << 0);
parameter DEVs_OPL3           = dev_typ_t'(1 << 1);
parameter DEVs_RESET_STATUS   = dev_typ_t'(1 << 2);
/*cart*/
parameter DEVs_SCC            = dev_typ_t'(1 << 8);
parameter DEVs_SCC2           = dev_typ_t'(1 << 9);
parameter DEVs_MFRSD2         = dev_typ_t'(1 << 10);
parameter DEVs_FLASH          = dev_typ_t'(1 << 11);
parameter DEVs_PSG            = dev_typ_t'(1 << 12);

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
    input     clk
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
    input       clk_en,
    input       reset
);
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
        input   clk_en,
        input   reset,
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
        input   clk_en,
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

interface video_bus;
    logic  [7:0] R;
    logic  [7:0] G;
    logic  [7:0] B;
    logic        DE;
    logic        HS;
    logic        VS;
    logic        hblank;
    logic        vblank;
    logic        ce_pix;
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

interface spi_if;
    logic        miso;
    logic        mosi;
    logic        clk;
    logic        ss;
    logic        enable;
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
        video_mode_t    video_mode;
        cas_audio_src_t cas_audio_src;
    } user_config_t;    
    
    typedef struct {
        logic     en;
        logic     wo;
    } slot_expander_t;

    typedef struct {
        video_mode_t    video_mode;
        MSX_typ_t       MSX_typ;
        logic     [7:0] ram_size;
        logic           use_FDC;
        logic           fdc_en;
        logic           fdc_internal;
    } bios_config_t;    
    
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
endpackage