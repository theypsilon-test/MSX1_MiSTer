module cart_ascii8 (
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
wire cs, mapped, mode_wizardy, mode_koei, mapper_en;
assign mapped       =  ^cpu_addr[15:14];  // Adresa je platná, pokud není ve spodních nebo horních 16KB
assign mapper_en    = (mapper == MAPPER_ASCII8) | (mapper == MAPPER_KOEI) | (mapper == MAPPER_WIZARDY);
assign mode_wizardy = (mapper == MAPPER_WIZARDY);
assign mode_koei    = (mapper == MAPPER_KOEI);
assign cs           = mapped & mapper_en & cpu_mreq;

logic [7:0] bank[2][4];
logic [7:0] sramBank[2][4];
logic [7:0] sramEnable[2];

// Definování často používaných parametrů a masek
wire        sram_exists   = (sram_size > 0);
wire  [7:0] sram_mask     = (sram_size[10:3] > 0) ? (sram_size[10:3] - 8'd1) : 8'd0;
wire  [7:0] sramEnableBit = mode_wizardy ? 8'h80 : rom_size[20:13];
wire  [7:0] sramPages     = mode_koei    ? 8'h34 : 8'h30;
wire  [1:0] region        = cpu_addr[12:11];
wire  [7:0] bank_base     = bank[mapper_id][{cpu_addr[15],cpu_addr[13]}]; 
wire  [7:0] sram_bank_base = sramBank[mapper_id][{cpu_addr[15],cpu_addr[13]}];                 

always @(posedge clk) begin
    if (reset) begin
        // Inicializace bank při resetu
        bank       <= '{'{default: '0},'{default: '0}};
        sramBank   <= '{'{default: '0},'{default: '0}};
        sramEnable <= '{default: '0}; 
    end else if (cs & cpu_wr & (cpu_addr[15:13] == 3'b011)) begin
        if ((cpu_data & sramEnableBit) & sram_exists) begin
            // Aktivace SRAM
            sramEnable[mapper_id]       <= sramEnable[mapper_id] | ((8'b00000100 << region) & sramPages);
            $display("Enable SRAM %x sram pages mask %x", ((8'b00000100 << region) & sramPages), sramPages);
            sramBank[mapper_id][region] <= cpu_data & sram_mask;
            $display("Write SRAM bank region %d banka %x", region, cpu_data & sram_mask);
        end else begin
            // Deaktivace SRAM
            sramEnable[mapper_id] <= sramEnable[mapper_id] & ~(8'b00000100 << region);
            $display("Disable SRAM %x sram pages mask %x", ((8'b00000100 << region) & sramPages), sramPages);
            bank[mapper_id][region] <= cpu_data;     
        end
    end
end

// Výpočet základny banky a adres
wire        sram_en   = |((8'b00000001 << cpu_addr[15:13]) & sramEnable[mapper_id]);
wire [26:0] sram_addr = {sram_bank_base, cpu_addr[12:0]};
wire [26:0] ram_addr  = {bank_base, cpu_addr[12:0]};
wire        ram_valid = (mem_addr < {2'b00, rom_size});

assign sram_cs   = cs & sram_en;
assign ram_cs    = cs & ram_valid & ~sram_en & cpu_rd;

assign mem_rnw    = ~(sram_cs & cpu_wr);
assign mem_addr  = cs ? (sram_en ? sram_addr : ram_addr) : {27{1'b1}};

endmodule
