module cart_ascii16 (
    input               clk,
    input               reset,
    input               cpu_mreq,
    input               cpu_rd,
    input               cpu_wr,
    input         [7:0] cpu_data,
    input        [15:0] cpu_addr,
    input        [24:0] rom_size,
    input        [15:0] sram_size,
    input  mapper_typ_t mapper,
    input               mapper_id,
    output       [26:0] mem_addr,
    output              mem_rnw,
    output              ram_cs,
    output              sram_cs
);

// Signály a logika pro mapování paměti
wire cs, mapped, mode_rtype, mapper_en;
assign mapped     =  ^cpu_addr[15:14];  // Adresa je platná, pokud není ve spodních nebo horních 16KB
assign mapper_en  = (mapper == MAPPER_ASCII16) | (mapper == MAPPER_RTYPE);
assign mode_rtype = (mapper == MAPPER_RTYPE);
assign cs         = mapped & mapper_en & cpu_mreq;

// Deklarace logiky bank a povolení SRAM
logic [7:0] bank0[2];
logic [7:0] bank1[2];
logic [1:0] sramEnable[2];

wire sram_exists = (sram_size > 0);

always @(posedge clk) begin
    if (reset) begin
        // Inicializace bank a sramEnable při resetu
        bank0      <= '{'h00, 'h00};
        bank1      <= '{'h00, 'h00};
        sramEnable <= '{2'd0, 2'd0};
    end else if (cs & cpu_wr) begin
        if (mode_rtype) begin
            // Zápis do bank1 v režimu R-Type
            if (cpu_addr[15:12] == 4'b0111) begin
                bank1[mapper_id] <= cpu_data & (cpu_data[4] ? 8'h17 : 8'h1F);
            end
        end else begin
            // Standardní režim zápisu
            case (cpu_addr[15:11])
                5'b01100: // 6000-67FF
                    if (cpu_data == 8'h10 && sram_exists) 
                        sramEnable[mapper_id][0] <= 1'b1;
                    else begin
                        sramEnable[mapper_id][0] <= 1'b0;
                        bank0[mapper_id] <= cpu_data;
                    end
                5'b01110: // 7000-77FF
                    if (cpu_data == 8'h10 && sram_exists) 
                        sramEnable[mapper_id][1] <= 1'b1;
                    else begin
                        sramEnable[mapper_id][1] <= 1'b0;
                        bank1[mapper_id] <= cpu_data;
                    end
                default: ;
            endcase
        end
    end
end

// Výpočet základny banky a adres
wire [7:0]  bank_base = cpu_addr[15] ? bank1[mapper_id] : (mode_rtype ? 8'h0F : bank0[mapper_id]);
wire        sram_en   = sramEnable[mapper_id][cpu_addr[15]];
wire [26:0] sram_addr = {sram_size > 16'd2 ? {25'd0, cpu_addr[12:0]} : {25'd0, cpu_addr[10:0]}};
wire [26:0] ram_addr  = {bank_base, cpu_addr[13:0]};
wire        ram_valid = (ram_addr < {2'b00, rom_size});

// Výstupy modulu
assign sram_cs       = cs & sram_en;
assign ram_cs        = cs & ram_valid & ~sram_en & cpu_rd;
assign mem_rnw       = ~(sram_cs & cpu_wr & cpu_addr[15]);
assign mem_addr      = cs ? (sram_en ? sram_addr : ram_addr) : {27{1'b1}};

endmodule
