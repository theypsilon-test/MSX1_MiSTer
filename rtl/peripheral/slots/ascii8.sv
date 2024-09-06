module cart_ascii8 (
    cpu_bus cpu_bus,                   // Interface for CPU communication
    mapper_out out,                    // Interface for mapper output
    mapper mapper                      // Struct containing mapper configuration and parameters
);

    // Memory mapping control signals
    wire cs, mapped, mode_wizardy, mode_koei, mapper_en;

    // Mapped if address is not in the lower or upper 16KB
    assign mapped       = ^cpu_bus.addr[15:14];  

    // Mapper is enabled if it is ASCII8, KOEI, or WIZARDY
    assign mapper_en    = (mapper.typ == MAPPER_ASCII8) | 
                          (mapper.typ == MAPPER_KOEI) | 
                          (mapper.typ == MAPPER_WIZARDY);

    // Mode is WIZARDY
    assign mode_wizardy = (mapper.typ == MAPPER_WIZARDY);

    // Mode is KOEI
    assign mode_koei    = (mapper.typ == MAPPER_KOEI);

    // Chip select is valid if address is mapped and mapper is enabled
    assign cs           = mapped & mapper_en & cpu_bus.mreq;

    // Bank and SRAM enable logic
    logic [7:0] bank[2][4];
    logic [7:0] sramBank[2][4];
    logic [7:0] sramEnable[2];

    // Define frequently used parameters and masks
    wire        sram_exists   = (mapper.sram_size > 0);
    wire  [7:0] sram_mask     = (mapper.sram_size[10:3] > 0) ? 
                                (mapper.sram_size[10:3] - 8'd1) : 8'd0;

    wire  [7:0] sramEnableBit = mode_wizardy ? 8'h80 : mapper.rom_size[20:13];
    wire  [7:0] sramPages     = mode_koei ? 8'h34 : 8'h30;
    wire  [1:0] region        = cpu_bus.addr[12:11];
    wire  [7:0] bank_base     = bank[mapper.id][{cpu_bus.addr[15], cpu_bus.addr[13]}]; 
    wire  [7:0] sram_bank_base = sramBank[mapper.id][{cpu_bus.addr[15], cpu_bus.addr[13]}];                 

    // Initialize or update bank and SRAM enable signals
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Initialize banks and SRAM enable on reset
            bank       <= '{'{default: '0},'{default: '0}};
            sramBank   <= '{'{default: '0},'{default: '0}};
            sramEnable <= '{default: '0}; 
        end else if (cs & cpu_bus.wr & (cpu_bus.addr[15:13] == 3'b011)) begin
            if (((cpu_bus.data & sramEnableBit) != 0) && sram_exists) begin
                // Enable SRAM
                sramEnable[mapper.id] <= sramEnable[mapper.id] | 
                                        ((8'b00000100 << region) & sramPages);
                $display("Enable SRAM %x sram pages mask %x", 
                          ((8'b00000100 << region) & sramPages), sramPages);
                sramBank[mapper.id][region] <= cpu_bus.data & sram_mask;
                $display("Write SRAM bank region %d bank %x", 
                          region, cpu_bus.data & sram_mask);
            end else begin
                // Disable SRAM
                sramEnable[mapper.id] <= sramEnable[mapper.id] & 
                                        ~(8'b00000100 << region);
                $display("Disable SRAM %x sram pages mask %x", 
                          ((8'b00000100 << region) & sramPages), sramPages);
                bank[mapper.id][region] <= cpu_bus.data;     
            end
        end
    end

    // Calculate bank base and address mapping
    wire        sram_en   = |((8'b00000001 << cpu_bus.addr[15:13]) & sramEnable[mapper.id]);
    wire [26:0] sram_addr = {6'b0, sram_bank_base, cpu_bus.addr[12:0]};
    wire [26:0] ram_addr  = {6'b0, bank_base, cpu_bus.addr[12:0]};
    wire        ram_valid = (out.addr < {2'b00, mapper.rom_size});

    // Output signals
    wire sram_cs   = cs & sram_en;
    wire ram_cs    = cs & ram_valid & ~sram_en & cpu_bus.rd;

    assign out.sram_cs = sram_cs;
    assign out.ram_cs  = ram_cs;
    assign out.rnw     = ~(sram_cs & cpu_bus.wr);
    assign out.addr    = cs ? (sram_en ? sram_addr : ram_addr) : {27{1'b1}};

endmodule
