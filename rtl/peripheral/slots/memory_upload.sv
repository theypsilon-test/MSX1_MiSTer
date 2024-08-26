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

    // Parametry
    localparam DDR3_BASE_ADDR = 28'h300000;
    localparam DDR3_CRC32_TABLE_ADDR = 28'h1600000;

    // Stavový signál, který indikuje, zda je modul resetován
    assign reset_rq = state != STATE_IDLE;

    // Řízení načítání dat
    logic [26:0] ioctl_size[5] = '{default: 27'd0};
    logic        load = 1'b0;

    always @(posedge clk) begin
        logic ioctl_download_last;
        load <= 1'b0;
        if (~ioctl_download & ioctl_download_last) begin
            case (ioctl_index[5:0])
                6'd1: begin ioctl_size[0] <= ioctl_addr; load <= 1'b1; end  // MSX PACK
                6'd2: begin ioctl_size[1] <= ioctl_addr; load <= 1'b1; end  // FW PACK
                6'd3: begin ioctl_size[2] <= ioctl_addr; load <= 1'b1; end  // ROM A
                6'd4: begin ioctl_size[3] <= ioctl_addr; load <= 1'b1; end  // ROM B
                6'd6: begin ioctl_size[4] <= ioctl_addr; end                // Další případy
                default: ;
            endcase
        end

        // Vynulování velikostí ROM při vysunutí
        if (rom_eject) begin
            ioctl_size[2] <= 27'd0;
            ioctl_size[3] <= 27'd0;
        end

        // Obnovovací signál pro načtení
        if (reload) load <= 1'b1;
        ioctl_download_last <= ioctl_download;
    end

    // Správa zařízení
    initial begin
        for (int i = 0; i < (1 << $bits(device_t)); i++) begin
            dev_enable[i] = 3'b000;
        end
    end    

    // Pomocník pro vyplňování RAM
    typedef enum logic [2:0] {
        PATTERN_DDR,
        PATTERN_FF,
        PATTERN_ZERO,
        PATTERN_03,
        PATTERN_04,
        PATTERN_05
    } pattern_t;
    
    wire [8:0] fill_poss = 9'(ram_addr - lookup_RAM[ref_ram].addr);

    // Vstupní data RAM jsou vybírána podle vzoru
    assign ram_din = (pattern == PATTERN_DDR)  ? ddr3_dout :
                     (pattern == PATTERN_FF)   ? 8'hFF     :
                     (pattern == PATTERN_ZERO) ? 8'h00     :
                     (pattern == PATTERN_03)   ? ((fill_poss[8]) ? ((fill_poss[1]) ? 8'hff : 8'h00) : ((fill_poss[1]) ? 8'h00 : 8'hff)) :
                     (pattern == PATTERN_04)   ? ((fill_poss[8]) ? ((fill_poss[0]) ? 8'h00 : 8'hff) : ((fill_poss[0]) ? 8'hff : 8'h00)) :
                     (pattern == PATTERN_05)   ? ((fill_poss[7]) ? 8'hff : 8'h00) : 8'hFF;

    // Stavový automat pro načítání dat
    typedef enum logic [3:0] {
        STATE_IDLE,
        STATE_CLEAN,
        STATE_READ_FW_CONF,
        STATE_READ_CONF,
        STATE_CHECK_FW_CONF,
        STATE_CHECK_CONF,
        STATE_LOAD_CONF,
        STATE_PROCESS_BLOCK,
        STATE_FILL_RAM,
        STATE_SET_LAYOUT,
        STATE_SEARCH_CRC32_INIT,
        STATE_SEARCH_CRC32,
        STATE_GET_FW_ADDR,
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

    // Alias pro typy bloků a konfigurací
    block_t block_typ = block_t'(conf[2]);
    conf_t  config_typ = conf_t'(conf[0]);

    always @(posedge clk) begin      
        logic [24:0] data_size;
        logic [7:0]  temp[8];
        logic [5:0]  block_num;
        logic [2:0]  head_addr, read_cnt;
        logic [27:0] save_addr;    
        logic        ref_add, ref_sram_add, fw_space;
        logic [1:0]  slot, subslot, block, size, offset, ref_sram;
        logic [15:0] rom_fw_table;
        mapper_typ_t mapper;       
        
        if (load) begin
            state <= STATE_CLEAN;
        end
        
        // Automatické inkrementace pro DDR3, RAM a klávesnici
        if (ddr3_ready && ddr3_rd) begin
            ddr3_addr <= ddr3_addr + 1'b1;
            ddr3_rd   <= '0;
        end

        ram_ce <= '0;
        if (ram_ce) begin
            ram_addr <= ram_addr + 1'd1;
        end

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
                    fw_space     <= '0;
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
                        read_cnt <= 5;
                        if (ioctl_size[1] > 0) begin
                            state <= STATE_READ_CONF;
                            next_state <= STATE_CHECK_FW_CONF;
                            ddr3_addr <= DDR3_BASE_ADDR;
                            fw_space     <= '1;                         // Čtení firmware oblasti
                        end
                    end
                end
                STATE_READ_CONF: begin                                  // Přečte požadovaný počet bytů do konfigurace
                    if (fw_space ? ioctl_size[1] > (ddr3_addr - DDR3_BASE_ADDR) : ioctl_size[0] > (ddr3_addr)) begin  // Kontrola konce dat
                        conf[head_addr] <= ddr3_dout;
                        ddr3_rd <= '1;
                        if (head_addr == read_cnt) begin
                            state <= next_state;
                            head_addr <= '0;
                        end else begin
                            head_addr <= head_addr + 1'b1;
                        end
                    end else begin
                        state <= STATE_IDLE;
                    end
                    kbd_request <= '1;
                end
                STATE_CHECK_FW_CONF: begin
                    if ({conf[0], conf[1], conf[2]} == {"M", "s", "X"}) begin
                        fw_space     <= '0;
                        state <= STATE_READ_CONF;
                        next_state <= STATE_CHECK_CONF;
                        rom_fw_table <= {conf[5], conf[4]};
                        ddr3_addr <= '0;
                        ddr3_rd <= '1;
                    end else begin
                        error <= ERR_BAD_MSX_FW_CONF;
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
                            $display("  BLOCK FW state %d", fw_space);
                            if (~fw_space) begin                                // Pokud čteme konfiguraci, tak se slot načítá výhradně z konfigurace
                                slot <= '0;
                            end
                            state <= STATE_PROCESS_BLOCK;
                        end
                        CONF_LAYOUT:  begin
                            $display("  LOAD KBD LAYOUT");
                            kbd_addr <= '0;
                            kbd_request <= '1;                                  
                            state <= STATE_LOAD_KBD_LAYOUT;
                        end
                        CONF_END: begin
                            ddr3_addr <= save_addr;
                            ddr3_rd <= '1;
                            fw_space <= '0;
                            state <= STATE_READ_CONF;
                            next_state <= STATE_LOAD_CONF;
                        end
                    default: begin
                        error <= ERR_NOT_SUPPORTED_CONF;
                        state <= STATE_IDLE;
                    end
                    endcase
                end
                STATE_PROCESS_BLOCK: begin
                    slot <= slot | conf[1][7:6];
                    subslot <= conf[1][5:4];
                    block <= conf[1][3:2];
                    size <= conf[1][1:0];
                    mapper <= MAPPER_NONE;
                    next_state <= STATE_READ_CONF;
                    case(block_t'(conf[2]))
                        BLOCK_RAM: begin
                            $display("BLOCK RAM ref_RAM:%x addr:%x size %d %x ", ref_ram, ram_addr, {conf[3],14'd0}, conf[2]);
                            lookup_RAM[ref_ram].addr <= ram_addr;                  // Uložíme adresu RAM
                            lookup_RAM[ref_ram].size <= {conf[3],14'd0};           // Uložíme velikost RAM
                            lookup_RAM[ref_ram].ro <= '0;                          // Vypneme ochranu paměti RAM
                            mapper <= MAPPER_OFFSET;
                            offset <= '0;                                          // Offset posunu RAM
                            ref_add <= '1;                                         // Bude potřeba zvednout referenci
                            data_size <= {conf[3],14'd0};                          // Velikost nahrávaných dat
                            pattern <= pattern_t'(conf[4]);
                            state <= STATE_FILL_RAM;
                        end
                        BLOCK_ROM: begin
                            $display("BLOCK ROM ref_RAM:%x addr:%x size %d ", ref_ram, ram_addr, {conf[3],14'd0});
                            lookup_RAM[ref_ram].addr <= ram_addr;                  // Uložíme adresu ROM
                            lookup_RAM[ref_ram].size <= {conf[3],14'd0};           // Uložíme velikost ROM
                            lookup_RAM[ref_ram].ro <= '1;                          // Uložíme ochranu paměti ROM
                            mapper <= MAPPER_OFFSET;
                            offset <= '0;                                          // Offset posunu RAM
                            ref_add <= '1;                                         // Bude potřeba zvednout referenci
                            data_size <= {conf[3],14'd0};                          // Velikost nahrávaných dat
                            pattern <= PATTERN_DDR;
                            state <= STATE_FILL_RAM;
                        end
                        BLOCK_CART: begin
                            next_state <= STATE_LOAD_CONF;                          // Defaultně neděláme nic
                            state <= STATE_READ_CONF;
                            $display("BLOCK CART %d", conf[3][0]);
                            if (ioctl_size[conf[3][0] ? 3 : 2] > '0) begin
                                $display("BLOCK CART %d LOAD START ref: %d addr:%x size:%x - %x", conf[3][0], ref_ram, ram_addr, ioctl_size[conf[3][0] ? 3 : 2], ioctl_size[conf[3][0] ? 3 : 2][26:14]);
                                lookup_RAM[ref_ram].addr <= ram_addr;               // Uložíme adresu ROM
                                lookup_RAM[ref_ram].size <= ioctl_size[conf[3][0] ? 3 : 2][26:14];        // Uložíme velikost ROM
                                lookup_RAM[ref_ram].ro <= '1;                       // Uložíme ochranu paměti ROM
                                state <= STATE_FILL_RAM;                            // Načítáme ROM
                                next_state <= STATE_SEARCH_CRC32_INIT;              // Po nahrání budeme hledat CRC
                                save_addr <= ddr3_addr - 1'b1;                      // Uchováme adresu -1 kvůli již načtenému prefetch bajtu
                                ddr3_addr <= conf[3][0] ? 28'h1100000 : 28'hC00000; // Adresa ROM v DDR
                                data_size <= ioctl_size[conf[3][0] ? 3 : 2][24:0];  // Velikost ROM
                                ddr3_rd <= '1;                                      // Prefetch
                                ref_add <= '1;                                      // Ukládáme referenci
                                crc_en <= '1;                                       // Počítáme CRC
                                pattern <= PATTERN_DDR;                             // Ukládáme z ROM
                            end
                        end
                        BLOCK_MAPPER: begin
                            $display("BLOCK MAPPER %d", conf[3]);
                            mapper <= mapper_typ_t'(conf[3]);
                            state <= STATE_SET_LAYOUT;
                        end
                        default: begin
                            $display("BLOCK UNKNOWN");
                            error <= ERR_NOT_SUPPORTED_BLOCK;
                            state <= STATE_IDLE;
                        end
                    endcase
                end
                STATE_FILL_RAM: begin
                    if (sdram_ready) begin                           // RAM je připravená
                        data_size <= data_size - 25'd1;              // Snížíme velikost dat
                        ram_ce <= 1'b1;
                        if (pattern == PATTERN_DDR) ddr3_rd <= 1'b1; // Připrav další byte z DDR, pokud je vzor DDR
                        if (data_size == 25'd1) begin                // Poslední byte
                            state <= STATE_SET_LAYOUT;
                        end 
                    end
                end
                STATE_SET_LAYOUT: begin
                    if (size == 2'b00) begin                      // Kontrola, zda jsme na konci
                        if (ref_add) begin
                            ref_ram <= ref_ram + 1'd1;                        // Zvýšíme referenci o 1              
                        end
                        ref_add <= '0;
                        ref_sram_add <= '0;
                        state <= next_state;
                        next_state <= STATE_LOAD_CONF;
                    end
                    
                    block <= block + 2'b01;                 // Další blok
                    size  <= size - 2'b01;                  // Snížíme počet
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

                    // slot_layout[{slotSubslot, i[1:0]}].device
                    // slot_layout[{slotSubslot, i[1:0]}].external
                    if (subslot != 2'b00) begin                        
                        bios_config.slot_expander_en[slot] <= 1'b1;
                        $display("BLOCK expander enable slot:%x", slot);
                    end
                end
                STATE_SEARCH_CRC32_INIT: begin
                    // TODO: Pokud není k dispozici CRC32 DB, nastav mapper offset a pokračuj. Nezapomeň na obnovení ddr3_addr.
                    state <= STATE_SEARCH_CRC32; 
                    ddr3_addr <= DDR3_CRC32_TABLE_ADDR;                               // Adresa CRC32 tabulky
                    ddr3_rd <= 1'b1;                                        // Prefetch
                    crc_en  <= 1'b0;                                        // Zastavení počítání CRC
                end
                STATE_SEARCH_CRC32: begin
                    temp[ddr3_addr[2:0]] = ddr3_dout;
                    if (ddr3_addr[2:0] == 3'd0 && rom_crc32 == {temp[4], temp[3], temp[2], temp[1]}) begin
                        $display("FIND CRC32: %x mapper:%x sram:%x", rom_crc32, temp[5], temp[6]);       // CRC32 nalezeno
                        if (ioctl_size[1] > '0) begin                                                    // Máme FW?
                            ddr3_addr <= 'h300010 + {temp[5],2'b00};
                            ddr3_rd <= '1;
                            read_cnt <= 4;
                            fw_space <= '1;
                            state <= STATE_READ_CONF;
                            next_state <= STATE_GET_FW_ADDR;
                        end else begin
                            error <= ERR_NOT_FW_CONF;
                            state <= STATE_IDLE;
                        end
                    end else begin
                        if ((ddr3_addr - DDR3_CRC32_TABLE_ADDR) == {1'b0, ioctl_size[4]}) begin
                            $display("NOT FIND CRC32: %x", rom_crc32);
                            // TODO: Nastav linear mapper a pokračuj.
                            ddr3_addr <= save_addr;
                            ddr3_rd <= '1;
                            state <= STATE_STOP;
                        end else begin
                            ddr3_rd <= 1'b1;    
                        end                                                                                                // Další data z DDR
                    end
                end
                STATE_GET_FW_ADDR: begin
                    ddr3_addr <= {4'h3, conf[2][3:0], conf[1], conf[0]};
                    ddr3_rd <= '1;
                    read_cnt <= 5;
                    state <= STATE_READ_CONF;
                    next_state <= STATE_LOAD_CONF;
                    $display("CART_CONFIG DDR ADDR %x", {conf[2][3:0], conf[1], conf[0]});
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

endmodule
