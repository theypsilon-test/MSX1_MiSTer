module mapper_ascii16 (
    cpu_bus_if.device_mp    cpu_bus,                // Interface for CPU communication
    block_info              block_info,             // Struct containing mapper configuration and parameters
    mapper_out              out                     // Interface for mapper output
);

    // Memory mapping control signals
    wire cs, mapped, mode_rtype, mapper_en;

    // Mapped if address is not in the lower or upper 16KB
    assign mapped     = ^cpu_bus.addr[15:14];

    // Mapper is enabled if it is ASCII16 or R-TYPE
    assign mapper_en  = (block_info.typ == MAPPER_ASCII16) | (block_info.typ == MAPPER_RTYPE);

    // Mode is R-TYPE
    assign mode_rtype = (block_info.typ == MAPPER_RTYPE);

    // Chip select is valid if address is mapped and mapper is enabled
    assign cs         = mapped & mapper_en & cpu_bus.mreq;

    // Bank and SRAM enable logic
    logic [7:0] bank0[2];            // Storage for bank0 data, two entries for two different mapper IDs
    logic [7:0] bank1[2];            // Storage for bank1 data
    logic [1:0] sramEnable[2];       // SRAM enable signals for two different mapper IDs

    // SRAM exists if its size is greater than 0
    wire sram_exists = (block_info.sram_size > 0);

    // Initialize or update bank and SRAM enable signals
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Initialize banks and SRAM enable on reset
            bank0      <= '{'h00, 'h00};
            bank1      <= '{'h00, 'h00};
            sramEnable <= '{2'd0, 2'd0};
        end else if (cs & cpu_bus.wr && cpu_bus.req) begin
            if (mode_rtype) begin
                // Write to bank1 in R-TYPE mode (0x7000-0x7FFF)
                if (cpu_bus.addr[15:12] == 4'b0111) begin
                    bank1[block_info.id] <= cpu_bus.data & (cpu_bus.data[4] ? 8'h17 : 8'h1F);
                end
            end else begin
                // Standard mode write operations (0x6000-0x67FF and 0x7000-0x77FF)
                case (cpu_bus.addr[15:11])
                    5'b01100: // 0x6000-0x67FF
                        if (cpu_bus.data == 8'h10 && sram_exists)
                            sramEnable[block_info.id][0] <= 1'b1;
                        else begin
                            sramEnable[block_info.id][0] <= 1'b0;
                            bank0[block_info.id] <= cpu_bus.data;
                        end
                    5'b01110: // 0x7000-0x77FF
                        if (cpu_bus.data == 8'h10 && sram_exists)
                            sramEnable[block_info.id][1] <= 1'b1;
                        else begin
                            sramEnable[block_info.id][1] <= 1'b0;
                            bank1[block_info.id] <= cpu_bus.data;
                        end
                    default: ;
                endcase
            end
        end
    end

    // Calculate bank base and address mapping
    wire [7:0] bank_base = cpu_bus.addr[15] ? bank1[block_info.id] :
                          (mode_rtype ? 8'h0F : bank0[block_info.id]);

    wire sram_en   = sramEnable[block_info.id][cpu_bus.addr[15]];

    // Determine the SRAM and RAM addresses based on the mapper configuration
    wire [26:0] sram_addr = {block_info.sram_size > 16'd2 ?
                            {14'd0, cpu_bus.addr[12:0]} :
                            {16'd0, cpu_bus.addr[10:0]}};

    wire [26:0] ram_addr  = {5'b0, bank_base, cpu_bus.addr[13:0]};

    // Check if the calculated RAM address is within the valid range of the ROM size
    wire ram_valid = (ram_addr < {2'b00, block_info.rom_size});

    // Output signals based on calculated conditions
    wire sram_cs = cs & sram_en;
    wire ram_cs  = cs & ram_valid & ~sram_en & cpu_bus.rd;

    // Assign the final outputs for the mapper
    assign out.sram_cs = sram_cs;
    assign out.ram_cs  = ram_cs;
    assign out.rnw     = ~(sram_cs & cpu_bus.wr & cpu_bus.addr[15]);
    assign out.addr    = cs ? (sram_en ? sram_addr : ram_addr) : {27{1'b1}};

endmodule
