module mapper_16kb (
    cpu_bus         cpu_bus,                // Interface for CPU communication
    block_info      block_info,             // Struct containing mapper configuration and parameters
    mapper_out      out                     // Interface for mapper output
);

    // Memory mapping control signals
    logic cs, mapper_en;

    // Mapper is enabled if it is 16kb
    assign mapper_en  = (block_info.typ == MAPPER_16kb);

    // Chip select is valid if address is mapped and mapper is enabled
    assign cs         = mapper_en & cpu_bus.mreq;

    // Bank enable logic
    logic [7:0] bank[2][4];          // Storage for bank data, two entries for two different mapper IDs
    logic [7:0] block, nrBlocks, blockMask, blockCompute;

    assign nrBlocks = block_info.rom_size[21:14];
    assign blockMask = nrBlocks  - 1'b1;
    assign block = cpu_bus.data < nrBlocks ? cpu_bus.data : cpu_bus.data & blockMask;
    assign blockCompute = block < nrBlocks ? block : 8'hFF;

    // Initialize or update bank and SRAM enable signals
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Initialize banks and SRAM enable on reset
            bank[0]    <= '{'hff, 'h00, 'h01, 'hff};
            bank[1]    <= '{'hff, 'h00, 'h01, 'hff};
        end else if (cs & cpu_bus.wr & cpu_bus.clk_en) begin
            bank[block_info.id][cpu_bus.addr[15:14]] <= blockCompute;
        end
    end

    // Calculate bank base and address mapping
    wire [7:0] bank_base = bank[block_info.id][cpu_bus.addr[15:14]];

    wire [26:0] ram_addr  = {5'b0, bank_base, cpu_bus.addr[13:0]};

    // Check if the calculated RAM address is within the valid range of the ROM size
    wire ram_valid = (ram_addr < {2'b00, block_info.rom_size});

    // Assign the final outputs for the mapper
    assign out.ram_cs  = cs & ram_valid & cpu_bus.rd;
    assign out.addr    = cs ? ram_addr : {27{1'b1}};

endmodule
