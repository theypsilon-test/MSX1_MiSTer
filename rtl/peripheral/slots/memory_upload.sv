module memory_upload
(
    input                       clk,
    output                      reset_rq,
    input                       ioctl_download,
    input                [15:0] ioctl_index,
    input                [26:0] ioctl_addr,
    input                       rom_eject,
    input                       reload,
    output logic         [27:0] ddr3_addr,
    output logic                ddr3_rd,
    output logic                ddr3_wr,
    input                 [7:0] ddr3_dout,
    input                       ddr3_ready,
    output                      ddr3_request,

    output logic         [26:0] ram_addr,
    output                [7:0] ram_din,
    input                 [7:0] ram_dout,
    output logic                ram_ce,
    input                       sdram_ready,
//    output logic                sdram_rq,
//    output logic                bram_rq,
    output logic                kbd_request,
    output logic          [8:0] kbd_addr,
    output logic          [7:0] kbd_din,
    output logic                kbd_we,
    input                 [1:0] sdram_size,
    output logic                load_sram,
    output MSX::block_t         slot_layout[64],
    output MSX::lookup_RAM_t    lookup_RAM[16],
    output MSX::lookup_SRAM_t   lookup_SRAM[4],
    output MSX::bios_config_t   bios_config,
    input  MSX::config_cart_t   cart_conf[2],
    output logic          [1:0] rom_loaded,
    output dev_typ_t            cart_device[2],
    output dev_typ_t            msx_device,
    output logic          [3:0] msx_dev_ref_ram[8],
    output logic          [2:0] dev_enable[0:(1 << $bits(device_t))-1],
    output logic          [1:0] led_out
);

    
    assign reset_rq = state != STATE_IDLE;
    
    // Load management
    logic [26:0] ioctl_size[5] = '{default: 27'd0};
    logic        load = 1'b0;

    always @(posedge clk) begin
        logic ioctl_download_last;
        load <= 1'b0;
        if (~ioctl_download & ioctl_download_last) begin
            case (ioctl_index[5:0])
                6'd1: begin ioctl_size[0] <= ioctl_addr; load <= 1'b1; end          //MSX PACK
                6'd2: begin ioctl_size[1] <= ioctl_addr; load <= 1'b1; end          //FW PACK
                6'd3: begin ioctl_size[2] <= ioctl_addr; load <= 1'b1; end          //ROM A
                6'd4: begin ioctl_size[3] <= ioctl_addr; load <= 1'b1; end          //ROM B
                6'd6: begin ioctl_size[4] <= ioctl_addr; end
                default: ;
            endcase
        end

        if (rom_eject) begin
            ioctl_size[2] <= 27'd0;
            ioctl_size[3] <= 27'd0;
        end

        if (reload) load <= 1'b1;
        ioctl_download_last <= ioctl_download;
    end 
    
    
    //Device management
    initial begin
        for (int i = 0; i < (1 << $bits(device_t)); i++) begin
            dev_enable[i] = 3'b000;
        end
    end    
    
    //Fill RAM Hellper
    typedef enum logic [2:0] {
        PATTERN_DDR,
        PATTERN_FF,
        PATTERN_ZERO,
        PATTERN_03,
        PATTERN_04,
        PATTERN_05
    } pattern_t;
    
    wire [8:0] fill_poss = 9'(ram_addr - lookup_RAM[ref_ram].addr);
    assign ram_din =(pattern == PATTERN_DDR)  ? ddr3_dout :
                    (pattern == PATTERN_FF)   ? 8'hFF     :
                    (pattern == PATTERN_ZERO) ? 8'h00     :
                    (pattern == PATTERN_03)   ? ((fill_poss[8]) ? ((fill_poss[1]) ? 8'hff : 8'h00) : ((fill_poss[1]) ? 8'h00 : 8'hff)) :
                    (pattern == PATTERN_04)   ? ((fill_poss[8]) ? ((fill_poss[0]) ? 8'h00 : 8'hff) : ((fill_poss[0]) ? 8'hff : 8'h00)) :
                    (pattern == PATTERN_05)   ? ((fill_poss[7]) ? 8'hff : 8'h00) : 8'hFF;

    //Load machine  
    typedef enum logic [3:0] {
        STATE_IDLE,
        STATE_CLEAN,
        STATE_READ_CONF,
        STATE_CHECK_CONF,
        STATE_LOAD_CONF,
        STATE_PROCESS_BLOCK,
        STATE_FILL_RAM,
        STATE_SET_LAYOUT,
        STATE_SEARCH_CRC32_INIT,
        STATE_SEARCH_CRC32,
        STATE_LOAD_KBD_LAYOUT,
        STATE_STOP
    } state_t;

    

    state_t state = STATE_IDLE;
    state_t next_state = STATE_IDLE;
    error_t error = ERR_NONE;
    pattern_t pattern;
    logic [7:0] conf[6];
    logic [4:0] ref_ram;
    logic       crc_en;
    //alias       
    block_t block_typ = block_t'(conf[2]);
    conf_t  config_typ = conf_t'(conf[0]);
    
    always @(posedge clk) begin      
        logic [24:0] data_size;
        logic [7:0]  temp[8];
        logic  [5:0] block_num;
        logic  [2:0] head_addr;
        logic [27:0] save_addr;    
        logic        ref_add, ref_sram_add;
        logic  [1:0] slot, subslot, block, size, offset, ref_sram;
        mapper_typ_t mapper;       
        
        if (load) begin
            state <= STATE_CLEAN;
        end
        
        //Auto increment DDR3
        if (ddr3_ready && ddr3_rd) begin
            ddr3_addr <= ddr3_addr + 1'b1;
            ddr3_rd   <= '0;
        end

        //Auto increment RAM
        ram_ce    <= '0;
        if (ram_ce) begin
            ram_addr  <= ram_addr + 1'd1;
        end

        //Keyboard auto increment
        kbd_we <= '0;
        if (kbd_we) begin
            kbd_addr <= kbd_addr + 1'd1;
        end

        if (ddr3_ready && ~ddr3_rd) begin
            case(state)
                STATE_IDLE: begin
                    block_num <= '0;
                    ddr3_request <= '0;
                    ref_add       <= '0;
                    ref_sram_add <= '0;
                    ref_ram      <= '0;
                    ram_addr     <= '0;
                    crc_en       <= '0;
                end
                STATE_CLEAN: begin
                    error_t error = ERR_NONE;
                    ddr3_request <= '1;
                    slot_layout[block_num].mapper     <= MAPPER_NONE;
                    slot_layout[block_num].device     <= DEVICE_NONE;
                    slot_layout[block_num].ref_ram    <= '0;
                    slot_layout[block_num].offset_ram <= block_num[1:0];
                    slot_layout[block_num].cart_num   <= '0;
                    slot_layout[block_num].ref_sram   <= '0;
                    slot_layout[block_num].external   <= '0;
                    lookup_SRAM[block_num[1:0]].size  <= '0;
                    bios_config.slot_expander_en      <= '0;

                    block_num <= block_num + 1'd1;
                    if (block_num == 63) begin
                        state <= STATE_READ_CONF;
                        next_state <= STATE_CHECK_CONF;
                        block_num <= '0;
                        ddr3_addr <= '0;
                        ddr3_rd   <= '1;
                        head_addr <= '0;
                    end
                end
                STATE_READ_CONF: begin
                    kbd_request <= 1'b0;
                    if (ioctl_size[0] > ddr3_addr) begin
                        conf[head_addr] <= ddr3_dout;
                        ddr3_rd <= '1;
                        head_addr <= head_addr + 1'b1;
                        if (head_addr == 5) begin
                            state <= next_state;
                            head_addr <= '0;
                        end
                    end else begin
                        state <= STATE_IDLE;
                    end
                end
                STATE_CHECK_CONF: begin
                    if ({conf[0], conf[1], conf[2]} == {"M", "S", "x"}) begin
                        state <= STATE_READ_CONF;
                        next_state <= STATE_LOAD_CONF;
                        ddr3_request <= '1;
                        bios_config.MSX_typ <= conf[3][0] ? MSX2 : MSX1 ;
                    end else begin
                        error <= ERR_BAD_MSX_CONF;
                        state <= STATE_IDLE;
                    end
                end
                STATE_LOAD_CONF: begin
                    case(conf_t'(conf[0]))
                        CONF_BLOCK:  begin
                            state <= STATE_PROCESS_BLOCK;
                        end
                        CONF_LAYOUT:  begin
                            $display("  LOAD KBD LAYOUT");
                            kbd_addr <= '0;
                            kbd_request <= '1;
                            state <= STATE_LOAD_KBD_LAYOUT;
                        end
                    default: begin
                        error <= ERR_NOT_SUPPORTED_CONF;
                        state <= STATE_IDLE;
                    end
                    endcase
                end
                STATE_PROCESS_BLOCK: begin
                    slot <= conf[1][7:6];
                    subslot <= conf[1][5:4];
                    block <= conf[1][3:2];
                    size <= conf[1][1:0];
                    mapper <= MAPPER_NONE;
                    case(block_t'(conf[2]))
                        BLOCK_RAM: begin
                            $display("BLOCK RAM ref_RAM:%x addr:%x size %d %x ", ref_ram, ram_addr, {conf[3],14'd0}, conf[2]);
                            lookup_RAM[ref_ram].addr <= ram_addr;                  // Uložíme adresu   ROM
                            lookup_RAM[ref_ram].size <= {conf[3],14'd0};           // Uložíme velikost ROM
                            lookup_RAM[ref_ram].ro <= '0;                          // Vypneme ochranu pameti RAM
                            mapper <= MAPPER_OFFSET;
                            offset <= '0;                                          // Offset posunu RAM
                            ref_add <= '1;                                          // Bude potřeba zvednout referenci
                            data_size <= {conf[3],14'd0};                          // Kolik dat nahráváme
                            pattern <= pattern_t'(conf[4]);
                            state <= STATE_FILL_RAM;
                            next_state <= STATE_SET_LAYOUT;
                        end
                        BLOCK_ROM: begin
                            $display("BLOCK ROM ref_RAM:%x addr:%x size %d ", ref_ram, ram_addr, {conf[3],14'd0});
                            lookup_RAM[ref_ram].addr <= ram_addr;                  // Uložíme adresu   ROM
                            lookup_RAM[ref_ram].size <= {conf[3],14'd0};           // Uložíme velikost ROM
                            lookup_RAM[ref_ram].ro <= '1;                          // Uložíme ochranu pameti ROM
                            mapper <= MAPPER_OFFSET;
                            offset <= '0;                                          // Offset posunu RAM
                            ref_add <= '1;                                          // Bude potřeba zvednout referenci
                            data_size <= {conf[3],14'd0};                          // Kolik dat nahráváme
                            pattern <= PATTERN_DDR;
                            state <= STATE_FILL_RAM;
                            next_state <= STATE_SET_LAYOUT;
                        end
                        BLOCK_CART: begin
                            state <= STATE_READ_CONF;                                 // Default neděláme nic
                            $display("BLOCK CART %d", conf[3][0]);
                            if (ioctl_size[conf[3][0] ? 3 : 2] > '0) begin
                                $display("BLOCK CART %d LOAD START", conf[3][0]);
                                state <= STATE_FILL_RAM;                            // Máme ROM nahrajeme
                                next_state <= STATE_SEARCH_CRC32_INIT;              // Po nahrání budeme hledat CRC
                                save_addr <= ddr3_addr - 1'b1;                      // Uchováme adresu -1 kvůli již načtenému prefetch bajtu
                                ddr3_addr <= conf[3][0] ? 28'h1100000 : 28'hC00000; // Adresa ROM v DDR
                                data_size <= ioctl_size[conf[3][0] ? 3 : 2][24:0];  // Velikost ROM
                                ddr3_rd <= '1;                                      // Prefetch
                                ref_add <= '1;                                       // Ukládáme referenci
                                crc_en <= '1;                                       // Pocitame CRC
                                pattern <= PATTERN_DDR;                             // Ukládáme z ROM
                            end
                        end
                        default: begin
                            $display("BLOCK UNKNOWN");
                            error <= ERR_NOT_SUPPORTED_BLOCK;
                            state <= STATE_IDLE;
                        end
                    endcase
                end
                STATE_FILL_RAM: begin
                    if (sdram_ready /* && ~ram_ce*/) begin                           // RAM ready
                        data_size <= data_size - 25'd1;                         // Increment dec
                        ram_ce <= 1'b1;
                        if (pattern == PATTERN_DDR) ddr3_rd <= 1'b1;            // Připrav další byte z DDR pokud je copy
                        if (data_size == 25'd1) begin                           // Ukládáme poslední byt
                            state <= next_state;                                // Pokračujem dle určení
                        end 
                    end
                end
                STATE_SET_LAYOUT: begin
                    next_state <= STATE_LOAD_CONF;                  
                    if (size == 2'b00) begin                      // Jsme na konci ? Pocet je v konfiguraci dopredu snizen o 1.
                        if (ref_add) begin
                            ref_ram <= ref_ram + 1'd1;                        // Refence o 1              
                        end
                        ref_add <= '0;
                        ref_sram_add <= '0;
                        state <= STATE_READ_CONF;
                    end
                    
                    block <= block + 2'b01;                 // Dalsi blok
                    size  <= size - 2'b01;                  // Snizime pocet
                    offset <= offset + 2'b01;
                    
                    if (ref_add) begin                       
                        slot_layout[{slot, subslot, block}].ref_ram <= ref_ram;
                        slot_layout[{slot, subslot, block}].offset_ram <= offset;
                        $display("BLOCK slot:%x subslot:%x block:%x < reference:%x offset:%x ", slot, subslot, block, ref_ram, offset );
                    end

                    if (mapper != MAPPER_NONE) begin
                        slot_layout[{slot, subslot, block}].mapper <= mapper;
                        $display("BLOCK slot:%x subslot:%x block:%x < mapper:%x", slot, subslot, block, mapper );
                    end
                    
                    if (block_t'(conf[2]) == BLOCK_CART)  begin
                        $display("BLOCK slot:%x subslot:%x block:%x < cart_num:%x", slot, subslot, block, conf[3][0] );
                        slot_layout[{slot, subslot, block}].cart_num <= conf[3][0];
                    end
                    
                    if (ref_sram_add)  begin
                        $display("BLOCK slot:%x subslot:%x block:%x < ref_sram:%x", slot, subslot, block, conf[3][0] );
                        slot_layout[{slot, subslot, block}].ref_sram <= ref_sram;
                    end

                    //slot_layout[{slotSubslot, i[1:0]}].device
                    //slot_layout[{slotSubslot, i[1:0]}].external
                    if (subslot != 2'b00) begin                        
                        bios_config.slot_expander_en[slot] <= 1'b1;
                        $display("BLOCK expander enable slot:%x", slot);
                    end
                end
                STATE_SEARCH_CRC32_INIT: begin
                    //TODO pokud není k dispozici CRC32 DB tak nastav mapper offset a jdi od toho. Nezapomeň na recovery rrd3_addr
                    state <= STATE_SEARCH_CRC32; 
                    ddr3_addr <= 28'h1600000;                               // CRC32 table
                    ddr3_rd <= 1'b1;                                        // Prefetch
                    crc_en  <= 1'b0;                                        // CRC stop.
                end
                STATE_SEARCH_CRC32: begin
                    temp[ddr3_addr[2:0]] = ddr3_dout;
                    if (ddr3_addr[2:0] == 3'd0 && rom_crc32 == {temp[4], temp[3], temp[2], temp[1]}) begin
                        $display("FIND CRC32: %x mapper:%x sram:%x", rom_crc32, temp[5], temp[6]);       // CRC32 nalezeno
                        mapper <= mapper_typ_t'(temp[5]);
                        ddr3_addr <= save_addr;
                        ddr3_rd <= '1;
                        state <= STATE_SET_LAYOUT;
                        if (temp[6] > '0) begin
                            lookup_SRAM[conf[3][0] ? 2'd1 : 2'd0].addr <= ram_addr;                // Uložíme parametry SRAM bloku
                            lookup_SRAM[conf[3][0] ? 2'd1 : 2'd0].size <= 16'(temp[6]);            // TODO sram je 8bit, ale ukládám do 16bit (jsou to 2kb bloky)
                            data_size <= {temp[6], 10'd0};                                         // Požadavek na SRAM, alokuj SRAM
                            ref_sram_add <= '1;
                            ref_sram <= conf[3][0] ? 2'd1 : 2'd0;
                            pattern <= PATTERN_FF;
                            state <= STATE_FILL_RAM;
                            next_state <= STATE_SET_LAYOUT;
                        end
                    end else begin
                        if ((ddr3_addr - 28'h1600000) == {1'b0, ioctl_size[4]}) begin
                            $display("NOT FIND CRC32: %x", rom_crc32);
                            //TODO Nastav linear mapper a jdi od toho.
                            ddr3_addr <= save_addr;
                            ddr3_rd <= '1;
                            state <= STATE_STOP;
                        end else begin
                            ddr3_rd <= 1'b1;    
                        end                                                                                                // Next data z DDR
                    end
                end
                STATE_LOAD_KBD_LAYOUT: begin
                    if (~kbd_we) begin
                        ddr3_rd <= 1'b1;
                        kbd_we <= 1'b1;
                        kbd_din <= ddr3_dout;
                        if (kbd_addr == 9'h1FF) begin
                            state <= STATE_READ_CONF;
                        end
                    end
                end
                default: ;
            endcase
        end
    end

    wire [31:0] rom_crc32;
    CRC_32 CRC_32
    (
        .clk(clk),
        .en(crc_en),
        .we(ram_ce),
        .crc_in(ddr3_dout),
        .crc_out(rom_crc32)
    );


/*

    logic        load;
    logic [27:0] save_addr;
    logic [7:0]  conf[16];
    logic [7:0]  temp[8];
    logic [2:0]  pattern;
    logic [1:0]  subslot;   
    logic [3:0]  ref_ram;
    logic        crc_en;

    typedef enum logic [3:0] {
        STATE_IDLE,
        STATE_CLEAN,
        STATE_READ_CONF,
        STATE_READ_CONF2,
        STATE_CHECK_CONFIG,
        STATE_FILL_RAM,
        STATE_FILL_RAM2,
        STATE_STORE_SLOT_CONFIG,
        STATE_FIND_ROM,
        STATE_FILL_KBD,
        STATE_ERROR,
        STATE_SEARCH_CRC32_1,
        STATE_SEARCH_CRC32_2,
        STATE_FILL_SRAM,
        STATE_FILL_RAM_OLD
    } state_t;
    state_t state, state_next;

    assign reset_rq = !(state == STATE_IDLE || state == STATE_ERROR);
    assign ram_din = (pattern == 3'd0) ? ddr3_dout :
                     (pattern == 3'd1) ? 8'hFF     :
                     (pattern == 3'd2) ? 8'h00     :
                     (pattern == 3'd3) ? ((fill_poss[8]) ? ((fill_poss[1]) ? 8'hff : 8'h00) : ((fill_poss[1]) ? 8'h00 : 8'hff)) :
                     (pattern == 3'd4) ? ((fill_poss[8]) ? ((fill_poss[0]) ? 8'h00 : 8'hff) : ((fill_poss[0]) ? 8'hff : 8'h00)) :
                     (pattern == 3'd5) ? ((fill_poss[7]) ? 8'hff : 8'h00) :
                                         8'hFF;
    assign rom_loaded = {|ioctl_size[3], |ioctl_size[2]};

    wire [8:0] fill_poss = 9'(ram_addr - lookup_RAM[ref_ram].addr);
    wire [3:0] curr_conf = config_typ_t'(conf[3][7:4]);
    wire [3:0] cart_id   = curr_conf == CONFIG_SLOT_B;

    always @(posedge clk) begin
        logic [5:0] block_num;
        logic [3:0] config_head_addr;
        logic [24:0] data_size;
        logic [24:0] sram_size;
        logic [1:0] ref_sram;
        mapper_typ_t mapper;
        device_typ_t mem_device;
        data_ID_t data_id;
        logic [7:0] mode, param, sram;
        logic [3:0] slotSubslot;
        logic ref_add;
        logic [3:0] cart_slot_expander_en;
        logic external;
        
        // Resetting outputs by default at the beginning of the clock cycle
        ddr3_wr   <= 1'b0;
        load_sram <= 1'b0;
        ram_ce    <= 1'b0;

        if (ram_ce) begin
            ram_addr  <= ram_addr + 1'd1;
        end

        if (ddr3_ready & ddr3_rd) begin
            ddr3_rd <= 1'b0;
            ddr3_addr <= ddr3_addr + 1'd1;
        end

        if (load) begin
            state <= STATE_CLEAN;
            ddr3_addr             <= 28'd0;
            ram_addr              <= 27'd0;
            block_num             <= 6'd0;
            config_head_addr      <= 4'd0;
            ref_ram               <= 4'd0;
            ddr3_rd               <= 1'b0;        
            save_addr             <= 28'd0;
            ref_add                <= 1'b0;
            subslot               <= 2'd0; 
            cart_slot_expander_en <= 4'd0;
            cart_device           <= '{default: 0};
            bios_config.ram_size  <= 8'h00;
            bios_config.use_FDC   <= 1'b0;
            lookup_SRAM[0].size   <= 16'd0;
            lookup_SRAM[1].size   <= 16'd0;
            lookup_SRAM[2].size   <= 16'd0;
            lookup_SRAM[3].size   <= 16'd0;
        end

        if (ddr3_ready & ~ddr3_rd) begin
            case (state)
                STATE_IDLE,
                STATE_ERROR: begin
                    ddr3_request <= 1'b0;
                end

                STATE_CLEAN: begin
                    ddr3_request <= 1'b1;
                    slot_layout[block_num].mapper   <= MAPPER_UNUSED;
                    slot_layout[block_num].device   <= DEVICE_NONE;
                    slot_layout[block_num].external <= 1'b0;

                    block_num <= block_num + 1'd1;
                    if (block_num == 63) begin
                        state <= STATE_READ_CONF;
                        block_num <= 6'd0;
                    end
                end

                STATE_READ_CONF: begin
                    subslot <= 2'd0; 
                    state   <= STATE_READ_CONF2;
                    if (ddr3_addr >= 28'(ioctl_size[0])) begin
                        state     <= STATE_IDLE;
                        load_sram <= 1'b1;
                    end else begin
                        ddr3_rd <= 1'b1;
                    end
                end

                STATE_READ_CONF2: begin
                    config_head_addr <= config_head_addr + 4'd1;
                    ddr3_rd          <= 1'b1;
                    conf[config_head_addr] <= ddr3_dout;         
                    if (config_head_addr == 4'b1111) begin
                        state <= STATE_CHECK_CONFIG;
                        ddr3_rd          <= 1'b0;
                        config_head_addr <= 4'd0;
                    end
                end

                STATE_CHECK_CONFIG: begin
                    //state <= STATE_IDLE;
                    //data_size <= 25'd0;
                    //sram_size <= 25'd0;
                    //external  <= 1'b0;
                    if ({conf[0], conf[1], conf[2]} == {"M", "S", "X"}) begin
                        //state <= STATE_FILL_RAM;
                        slotSubslot <= conf[3][3:0];
                        $display("CONF slot: %d subslot: %d (expand subslot: %d) mem_dev:%02X ram_size:%04X device:%02X mapper:%02X mode:%0x-%x-%x-%x param:%x-%x-%x-%x pattern:%02X", 
                                 conf[3][3:2], conf[3][1:0], subslot, conf[4], {conf[6], conf[5]}, conf[7], conf[8], conf[9][7:6], conf[9][5:4], conf[9][3:2], conf[9][1:0], 
                                 conf[10][7:6], conf[10][5:4], conf[10][3:2], conf[10][1:0], conf[11]);

                        case (curr_conf)
                            CONFIG_SLOT_A,
                            CONFIG_SLOT_B: begin
                                $display("  CONFIG CART %d", cart_id);
                                state <= STATE_READ_CONF;
                                // Pokud bude  vybrán ROM - nahrát
                                // Pokud bude  vybrán Multifunkční CART vyhledat ve FW PACK kde bude i konkrétní definice.
                                case (cart_conf[cart_id].typ)
                                    CART_TYP_ROM: begin
                                        if (ioctl_size[cart_id ? 3 : 2] > 27'd0) begin                       // Máme co nahrát ?
                                            save_addr <= ddr3_addr;                                          // Uložíme aktuální pozici zpracování konfigurace
                                            ddr3_addr <= cart_id ? 28'h1100000 : 28'hC00000 ;                // Adresa ROM v DDR
                                            data_size <= ioctl_size[cart_id ? 3 : 2][24:0];                  // Velikost ROM
                                            ddr3_rd   <= 1'b1;                                               // Prefetch
                                            pattern   <= 3'd0;                                               // Kopírujeme z DDR
                                            crc_en    <= 1'b1;                                               // Počítáme CRC
                                            state     <= STATE_FILL_RAM;
                                            state_next <= STATE_SEARCH_CRC32_1;                              // Po nahrání ROM najít CRC32
                                            data_id    <= ROM_ROM;
                                            ref_add                   <= 1'b1;                                // Budeme chtít inkrementovat čítač referencí
                                            lookup_RAM[ref_ram].addr <= ram_addr;                            // Uložíme parametry RAM bloku
                                            lookup_RAM[ref_ram].size <= ioctl_size[cart_id ? 3 : 2][24:14]; // Velikost ROM
                                            lookup_RAM[ref_ram].ro   <= 1'b1;
                                            ref_sram                 <= cart_id ? 2'd1 : 2'd0 ;              // Sram ID pokud bude nalezeno
                                            $display("           FILL ROM RAM_ID:%d addr:%x size:%d kB", ref_ram, ram_addr, ioctl_size[cart_id ? 3 : 2][24:14]*16);
                                        end
                                    end
                                    CART_TYP_EMPTY: begin
                                    end
                                    default: begin
                                    end
                                endcase
                            end
 
                            CONFIG_KBD_LAYOUT: begin
                                $display("  LOAD KBD LAYOUT");
                                kbd_addr <= 9'h0;
                                kbd_request <= 1'b1;
                                ddr3_rd <= 1'b1;
                                state <= STATE_FILL_KBD;
                            end

                            CONFIG_CONFIG: begin
                                bios_config.slot_expander_en <= conf[4][3:0] | cart_slot_expander_en;
                                bios_config.MSX_typ          <= MSX_typ_t'(conf[4][5:4]);
                                state <= STATE_READ_CONF;
                                $display("  STORE CONFIG  MSX:%d SLOT_EXPANDER:%x (%x %x)", MSX_typ_t'(conf[4][5:4]), conf[4][3:0] | cart_slot_expander_en, conf[4][3:0], cart_slot_expander_en);
                            end

                            CONFIG_DEVICE: begin
                                $display("  ADD DEVICE ID: %d", conf[7]);
                                msx_device <= msx_device | (1 << conf[7]);
                                msx_dev_ref_ram[conf[7][2:0]] <= ref_ram;
                                data_size <= {conf[5][2:0], conf[6], 14'h0};
                                sram_size <= 25'd0;
                                data_id <= ROM_ROM;
                                mode <= 8'h0;
                            end

                            CONFIG_SLOT_INTERNAL: begin
                                $display("  SLOT INTERNAL");
                                mapper <= MAPPER_UNUSED;
                                mode <= conf[9];
                                param <= conf[10];
                                state <= STATE_STORE_SLOT_CONFIG;
                                state_next <=  STATE_STORE_SLOT_CONFIG;
                                data_id <= data_ID_t'(conf[4]);

                                if ({conf[5][2:0], conf[6]} > 0) begin          
                                    mapper <= mapper_typ_t'(conf[8]);
                                    data_size <= {conf[5][2:0], conf[6], 14'h0};            // Požadavek na ROM / RAM
                                    pattern <= conf[11][2:0];

                                    ref_add                   <= 1'b1;                                // Budeme chtít inkrementovat čítač referencí
                                    lookup_RAM[ref_ram].addr <= ram_addr;                            // Uložíme parametry RAM bloku
                                    lookup_RAM[ref_ram].size <= {conf[5][2:0], conf[6]};
                                    lookup_RAM[ref_ram].ro   <= 1'b0;                                // ROM provede overide

                                    if (data_ID_t'(conf[4]) == ROM_ROM) begin
                                        pattern <= 3'd0;                                    // Jedná se o ROM. 
                                        ddr3_rd   <= 1'b1;                                  // Prefetch
                                        lookup_RAM[ref_ram].ro   <= 1'b1;
                                        $display("           FILL ROM RAM_ID:%d addr:%x size:%d kB", ref_ram, ram_addr, {conf[5][2:0], conf[6]}*16);
                                    end else begin
                                        $display("           FILL RAM RAM_ID:%d addr:%x size:%d kB", ref_ram, ram_addr, {conf[5][2:0], conf[6]}*16);
                                    end
                                    state      <= STATE_FILL_RAM;
                                    
                                    if (conf[12] > 0) begin
                                        sram_size <= 25'({conf[12], 10'd0});                // Požadavek na SRAM, Po nahrání alokuj SRAM
                                        ref_sram <= 3;
                                        state_next <= STATE_FILL_SRAM;
                                        $display("           FILL (next) SRAM SRAM_ID:%d addr:%x size:%d kB", 3, ram_addr, 16'(conf[12])*16);                      
                                    end
                                end else begin
                                    if (conf[12] > 0) begin
                                        sram_size <= 25'({conf[12], 10'd0});                // Požadavek na SRAM, Po nahrání alokuj SRAM
                                        ref_sram <= 3;
                                        state <= STATE_FILL_SRAM;                      
                                         $display("           FILL SRAM SRAM_ID:%d addr:%x size:%d kB", 3, ram_addr, 16'(conf[12])*16);                      
                                    end
                                end

                                if (conf[7] != 8'hFF) begin
                                    $display("     ADD DEVICE ID: %d", conf[7]);
                                    msx_device <= msx_device | (1 << conf[7]);
                                    msx_dev_ref_ram[conf[7][2:0]] <= ref_ram;
                                end

                                if (device_typ_t'(conf[4]) == DEVICE_FDC) bios_config.use_FDC <= 1'b1;                      // Nastav interní FDC
                                if (data_ID_t'(conf[4]) == ROM_RAM && bios_config.ram_size < conf[6]) begin                 // nastav velikost RAM podle největší RAM
                                    bios_config.ram_size <= conf[6];
                                end
                            end
                                                

                            default;
                        endcase
                    end
                end

                STATE_FILL_KBD: begin
                    if (kbd_we) begin
                        kbd_we <= 1'b0;
                        kbd_addr <= kbd_addr + 9'd1;
                        if (kbd_addr == 9'h1FF) begin
                            kbd_request <= 1'b0;
                            state <= STATE_READ_CONF;
                        end
                    end else begin
                        kbd_din <= ddr3_dout;
                        kbd_we <= 1'b1;
                        if (kbd_addr != 9'h1FF) begin
                            ddr3_rd <= 1'b1;
                        end
                    end
                end

                STATE_FIND_ROM: begin
                    config_head_addr <= config_head_addr + 4'd1;
                    ddr3_rd <= 1'b1;
                    temp[config_head_addr[2:0]] <= ddr3_dout;
                    if (config_head_addr == 4'd7) begin
                        config_head_addr <= 4'd0;
                        if ({temp[0], temp[1], temp[2]} == {"M", "S", "X"}) begin
                            if (data_ID_t'(temp[4]) == data_id) begin
                                data_size <= {temp[5][2:0], temp[6], 14'h0};
                                ddr3_addr <= ddr3_addr + 28'd7;
                                state <= STATE_FILL_RAM;
                                $display("        FILL FW ROM size:%X", {temp[5][2:0], temp[6], 14'h0});
                            end else if ((ddr3_addr - 28'h100000 + (28'({temp[5], temp[6]}) << 14) + 28'd8) >= 28'(ioctl_size[1])) begin
                                ddr3_addr <= save_addr;
                                state <= STATE_READ_CONF; // Not found, skip load
                            end else begin
                                ddr3_addr <= ddr3_addr + (28'({temp[5], temp[6]}) << 14) + 28'd8; // Not usable, next header
                            end
                        end else begin
                            ddr3_addr <= save_addr;
                            state <= STATE_READ_CONF; // Error, reset address
                        end
                    end
                end
                STATE_FILL_RAM: begin
                    if (sdram_ready && ~ram_ce) begin                           // RAM ready
                        data_size <= data_size - 25'd1;                         // Increment dec
                        ram_ce <= 1'b1;
                        if (pattern == 3'd0) ddr3_rd <= 1'b1;                   // Připrav další byte z DDR pokud je copy
                        if (data_size == 25'd1) begin                           // Ukládáme poslední byt
                            state <= state_next;                                // Pokračujem dle určení
                            ddr3_rd <= 1'b0;                                    // Data již nejsou potřeba
                            if (save_addr > 28'd0) begin
                                ddr3_addr <= save_addr;                         // Restore DDR pro pokračování
                                save_addr <= 28'd0;
                            end
                        end 
                    end
                end


                STATE_FILL_RAM_OLD: begin
                    if (~ram_ce) begin                                          // Paměť volno ?
                        state <= STATE_FILL_RAM2;                               // Pokračujeme dalším stavem
                        if (data_size != 25'd0) begin                           // Pokud je co plnit do RAM
                            ref_add                   <= 1'b1;                   // Budeme chtít inkrementovat čítač referencí
                            lookup_RAM[ref_ram].addr <= ram_addr;               // Uložíme parametry RAM bloku
                            lookup_RAM[ref_ram].size <= 16'(data_size[24:14]);
                            lookup_RAM[ref_ram].ro <= (data_id == ROM_RAM) ? 1'b0 : 1'b1;   // Nastavit ochranu paměti před přepsáním podle typu
                            pattern <= (data_id == ROM_RAM) ? 3'd1 : 3'd0;                  // Pokud je to RAM tak FF jinak přebíráme z DDR

                            if (data_id != ROM_RAM) ddr3_rd <= 1'b1;                        // Prefetch DDR pokud čteme z DDR
                       end else if (sram_size != 25'd0) begin                              // Chceme plnit SRAM ?
                            lookup_SRAM[ref_sram].size <= 16'(sram_size[24:10]);
                            pattern <= 3'd1;                                                // Vyplnit FF (inicializace SRAM proběhne z backupu)
                            data_size <= sram_size;                                         // 
                            sram_size <= 25'd0;
                            data_id <= ROM_RAM;
                        end else begin
                            state <= STATE_STORE_SLOT_CONFIG;
                            if (cart_conf[curr_conf == CONFIG_SLOT_B].selected_mapper == MAPPER_AUTO && ioctl_size[4] != 27'd0) begin
                                if (curr_conf == CONFIG_SLOT_A || curr_conf == CONFIG_SLOT_B) begin
                                    if (cart_conf[curr_conf == CONFIG_SLOT_B].typ == CART_TYP_ROM) begin
                                        state <= STATE_SEARCH_CRC32_1;
                                        save_addr <= ddr3_addr;
                                        ddr3_addr <= 28'h1600000; // CRC32 table
                                        ddr3_rd <= 1'b1;
                                    end
                                end
                            end
                        end
                    end
                end

                STATE_FILL_RAM2: begin
                    if (sdram_ready && ~ram_ce) begin
                        data_size <= data_size - 25'd1;
                        ram_ce <= 1'b1;

                        if (data_size == 25'd1) begin
                            state <= STATE_FILL_RAM;
                            if (save_addr > 28'd0) begin
                                ddr3_addr <= save_addr; // Restore
                                save_addr <= 28'd0;
                                if (curr_conf == CONFIG_SLOT_A || curr_conf == CONFIG_SLOT_B) begin
                                    if (cart_conf[curr_conf == CONFIG_SLOT_B].typ == CART_TYP_ROM) begin
                                        mapper <= cart_mapper;
                                        if (cart_mapper == MAPPER_NONE) begin
                                            param <= detect_param;
                                            mode <= detect_mode;
                                        end
                                    end
                                end
                            end
                        end else if (data_id != ROM_RAM) begin
                            ddr3_rd <= 1'b1;
                        end
                    end
                end
                STATE_SEARCH_CRC32_1: begin
                    state <= STATE_SEARCH_CRC32_2;
                    save_addr <= ddr3_addr;
                    ddr3_addr <= 28'h1600000;                           // CRC32 table
                    ddr3_rd <= 1'b1;                                    // Prefetch
                    crc_en  <= 1'b0;                                    // CRC stop.
                end
                STATE_SEARCH_CRC32_2: begin
                    temp[ddr3_addr[2:0]] = ddr3_dout;
                    if (ddr3_addr[2:0] == 3'd0 && rom_crc32 == {temp[4], temp[3], temp[2], temp[1]}) begin                      
                        $display("FIND CRC32: %x mapper:%x sram:%x param:%x mode:%x", rom_crc32, temp[5], temp[6], temp[7], temp[0]);       // CRC32 nalezeno
                        led_out <= 2'b10;                                                                                                   // Debug Mister
                        mapper <= mapper_typ_t'(temp[5]);                                                                                   // Mapper z konfigurace
                        param <= temp[7];                                                                                                   // Param a mode pro další využití
                        mode <= temp[0];
                        sram <= temp[5];

                        ddr3_addr <= save_addr;                                                                                             // Obnovení DDR 
                        save_addr <= 28'd0;
                        state <= STATE_FILL_SRAM;                                                                                            
                    end else if ((ddr3_addr - 28'h1600000) == {1'b0, ioctl_size[4]}) begin                                                  
                        $display("NOT FIND CRC32: %x", rom_crc32);                                                                          // CRC32 nalezeno
                        led_out               <= 2'b11;                                                                                     // Debug Mister
                        mapper                <= MAPPER_NONE;                                                                               // Mapper NONE
                        mode                  <= {2'd2,2'd2,2'd2,2'd2};                                                                     // RAM
                        param                 <= {2'd3,2'd2,2'd1,2'd0};                                                                     // Ofsety 
                        sram                  <= '0;                                                                                        // SRAM neni                                                         
                        ddr3_addr <= save_addr;                                                                                             // Konec DB
                        save_addr <= 28'd0;
                        state <= STATE_STORE_SLOT_CONFIG;
                    end else begin
                        ddr3_rd <= 1'b1;                                                                                                    // Next data z DDR
                    end
                end
                STATE_FILL_SRAM: begin
                    if (sram > 0) begin
                        lookup_SRAM[ref_sram].addr <= 18'(ram_addr);                   // Uložíme parametry SRAM bloku
                        lookup_SRAM[ref_sram].size <= 16'(sram);
                        pattern <= 3'd1;                                                // Vyplníme 0
                        data_size <= 25'({sram, 10'd0});                                // Velikost SRAM
                        state_next <= STATE_STORE_SLOT_CONFIG;
                        state <= STATE_FILL_RAM;
                        $display("           FILL RAM SRAM_ID: %d addr:%x size:%d kB", ref_sram, ram_addr, sram);
                    end else begin
                        state <= STATE_STORE_SLOT_CONFIG;
                    end
                end

                STATE_STORE_SLOT_CONFIG: begin
//                    if (curr_conf == CONFIG_SLOT_A || curr_conf == CONFIG_SLOT_B) begin
//                        cart_device[curr_conf == CONFIG_SLOT_B] <= cart_device[curr_conf == CONFIG_SLOT_B] | conf_device;
//                    end
                    $display("              FINAL mapper:%x mode:%x(%x-%x-%x-%x) param:%x(%x-%x-%x-%x) mem_dev:%x ", mapper, 
                                                                                                                     mode,  mode[7:6] , mode[5:4] , mode[3:2] , mode[1:0],
                                                                                                                     param, param[7:6], param[5:4], param[3:2], param[1:0],
                                                                                                                     mem_device);
                    for (int i = 0; i < 4; i++) begin
                        if (mode[i*2 +: 2] != 2'd0) begin
                            $display("              STORE block %d mapper:%d mode:%d param:%d mem_device:%d", i, mapper, mode[i*2 +: 2], param[i*2 +: 2], mem_device);

                            slot_layout[{slotSubslot, i[1:0]}].mapper     <= (mode[i*2 +: 2] == 2'd1) ? slot_layout[{slotSubslot, param[i*2 +: 2]}].mapper  :
                                                                              (mode[i*2 +: 2] == 2'd2) ? mapper                                             :
                                                                                                         MAPPER_UNUSED;

                            slot_layout[{slotSubslot, i[1:0]}].device     <= (mode[i*2 +: 2] == 2'd2) ? mem_device                                          :
                                                                              (mode[i*2 +: 2] == 2'd3) ? mem_device                                         :
                                                                                                         DEVICE_NONE;

                            slot_layout[{slotSubslot, i[1:0]}].ref_ram    <= (mode[i*2 +: 2] == 2'd1) ? slot_layout[{slotSubslot, param[i*2 +: 2]}].ref_ram :
                                                                                                         ref_ram;

                            slot_layout[{slotSubslot, i[1:0]}].offset_ram <= (mode[i*2 +: 2] == 2'd1) ? slot_layout[{slotSubslot, param[i*2 +: 2]}].offset_ram :
                                                                                                         param[i*2 +: 2];

                            slot_layout[{slotSubslot, i[1:0]}].cart_num   <= (curr_conf == CONFIG_SLOT_B);
                            slot_layout[{slotSubslot, i[1:0]}].ref_sram   <= ref_sram;
                            slot_layout[{slotSubslot, i[1:0]}].external   <= external;
                        end
                    end

                    state <= STATE_READ_CONF;
                    ref_ram <= ref_ram + 4'(ref_add);
                    ref_add  <= 1'b0;
                 
                end

                default: ;
            endcase
        end
    end

    mapper_typ_t detect_mapper;
    wire [3:0] detect_offset;
    wire [7:0] detect_mode, detect_param;
    mapper_detect mapper_detect 
    (
        .clk(clk),
        .rst(state == STATE_READ_CONF),
        .data(ddr3_dout),
        .wr(ram_ce),
        .rom_size(ioctl_size[curr_conf == CONFIG_SLOT_A ? 3'd2 : 3'd3]),
        .mapper(detect_mapper),
        .offset(detect_offset),
        .mode(detect_mode),
        .param(detect_param)
    );

    wire [31:0] rom_crc32;
    CRC_32 CRC_32
    (
        .clk(clk),
        .en(crc_en),
        .we(ram_ce),
        .crc_in(ddr3_dout),
        .crc_out(rom_crc32)
    );

    mapper_typ_t cart_mapper;
    device_typ_t cart_mem_device;
    dev_typ_t    conf_device;
    data_ID_t    cart_rom_id;
    logic  [7:0] cart_sram_size, cart_mode, cart_param, cart_ram_size;

    cart_confDecoder cart_decoder
    (
        .typ(cart_conf[curr_conf == CONFIG_SLOT_B].typ),
        .selected_mapper(cart_conf[curr_conf == CONFIG_SLOT_B].selected_mapper),
        .detected_mapper(detect_mapper),
        .selected_sram_size(cart_conf[curr_conf == CONFIG_SLOT_B].selected_sram_size),
        .subslot(subslot),
        .mapper(cart_mapper), 
        .mem_device(cart_mem_device),
        .rom_id(cart_rom_id),
        .sram_size(cart_sram_size),
        .ram_size(cart_ram_size),
        .mode(cart_mode),
        .param(cart_param),
        .device(conf_device)
    );

endmodule

module cart_confDecoder
(
    input  cart_typ_t   typ,
    input  mapper_typ_t selected_mapper,
    input  mapper_typ_t detected_mapper,
    input  logic  [7:0] selected_sram_size,
    input         [1:0] subslot,
    output mapper_typ_t mapper, 
    output device_typ_t mem_device,
    output data_ID_t    rom_id,
    output logic  [7:0] sram_size,
    output logic  [7:0] ram_size,
    output logic  [7:0] mode,
    output logic  [7:0] param,
    output dev_typ_t device
);
    mapper_typ_t rom_mapper;
    dev_typ_t rom_device;

    assign rom_mapper = (selected_mapper == MAPPER_AUTO) ? detected_mapper : selected_mapper;

    assign rom_device = (rom_mapper == MAPPER_KONAMI_SCC) ? DEVs_SCC : DEVs_NONE;

    assign {                                           mapper,            mem_device,  rom_id,     mode, param, sram_size,          ram_size, device} = 
        (typ == CART_TYP_ROM    && subslot == 2'd0) ? {rom_mapper,        DEVICE_NONE, ROM_ROM,   8'hAA, 8'hE4, selected_sram_size, 8'd0,   rom_device} :
        (typ == CART_TYP_SCC    && subslot == 2'd0) ? {MAPPER_KONAMI_SCC, DEVICE_NONE, ROM_ROM,   8'hAA, 8'h00, 8'd0,               8'd0,   DEVs_SCC} :
        (typ == CART_TYP_SCC2   && subslot == 2'd0) ? {MAPPER_KONAMI_SCC, DEVICE_NONE, ROM_RAM,   8'hAA, 8'h00, 8'd0,               8'd8,   DEVs_SCC2} :
        (typ == CART_TYP_FM_PAC && subslot == 2'd0) ? {MAPPER_FMPAC,      DEVICE_NONE, ROM_FMPAC, 8'h08, 8'h00, 8'd8,               8'd0,   DEVs_OPL3} :
        (typ == CART_TYP_MFRSD  && subslot == 2'd0) ? {MAPPER_NONE,       DEVICE_MFRSD0, ROM_MFRSD, 8'hAA, 8'h00, 8'd0,             8'd0,   DEVs_FLASH} :
        (typ == CART_TYP_MFRSD  && subslot == 2'd1) ? {MAPPER_MFRSD1,     DEVICE_NONE, ROM_NONE,  8'hAA, 8'h00, 8'd0,               8'd0,   DEVs_SCC2 | DEVs_FLASH} :
        (typ == CART_TYP_MFRSD  && subslot == 2'd2) ? {MAPPER_MFRSD2,     DEVICE_NONE, ROM_RAM,   8'hAA, 8'h00, 8'd0,               8'd32,  DEVs_MFRSD2 | DEVs_PSG} :
        (typ == CART_TYP_MFRSD  && subslot == 2'd3) ? {MAPPER_MFRSD3,     DEVICE_NONE, ROM_NONE,  8'hAA, 8'h00, 8'd0,               8'd0,   DEVs_FLASH} :
        (typ == CART_TYP_GM2    && subslot == 2'd0) ? {MAPPER_GM2,        DEVICE_NONE, ROM_GM2,   8'hAA, 8'h00, 8'd8,               8'd0,   DEVs_NONE} :
        (typ == CART_TYP_FDC    && subslot == 2'd0) ? {MAPPER_NONE,       DEVICE_FDC,  ROM_FDC,   8'h08, 8'h00, 8'd0,               8'd0,   DEVs_NONE} :
                                                      {MAPPER_UNUSED,     DEVICE_NONE, ROM_NONE,  8'h00, 8'h00, 8'd0,               8'd0,   DEVs_NONE};

*/
endmodule
