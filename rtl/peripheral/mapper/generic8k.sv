module mapper_generic8k (
    cpu_bus_if.device_mp    cpu_bus,       // Interface for CPU communication
    mapper_out              out,           // Interface for mapper output
    block_info              block_info     // Struct containing mapper configuration and parameters
);
  
    // Control signals for memory mapping
    wire cs, we;

    // Mapped if address is not in the lower or upper 16KB
    wire mapped  = ^cpu_bus.addr[15:14]; //0000-3fff & c000-ffff unmaped

    // Mapper is enabled if type is KONAMI and there is a memory request
    assign cs = block_info.typ == MAPPER_GENERIC8KB & cpu_bus.mreq && mapped;

    // Bank registers for memory banking
    logic [8:0] bank[0:1][4];
    logic [7:0] block, nrBlocks, blockMask;
    logic [8:0] blockCompute;
    
    assign nrBlocks = block_info.rom_size[20:13];
    assign blockMask = nrBlocks  - 1'b1;
    assign block = cpu_bus.data < nrBlocks ? cpu_bus.data : cpu_bus.data & blockMask;
    assign blockCompute = block < nrBlocks ? {1'b0,block} : 9'h100;
    
    
    wire [1:0] sel_bank = {cpu_bus.addr[15],cpu_bus.addr[13]};
    // Bank switching logic
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Initialize bank values on reset
            bank[0] <= '{9'h000, 9'h001, 9'h002, 9'h003};
            bank[1] <= '{9'h000, 9'h001, 9'h002, 9'h003};
        end else begin
            if (cs && cpu_bus.wr && cpu_bus.req) begin
                // Bank switching logic based on address
                bank[block_info.id][sel_bank] <= blockCompute;
            end
        end
    end

    // Calculate bank base and address mapping
    wire  [7:0] bank_base;
    wire        bank_unmaped;
    wire [26:0] ram_addr;
    assign {bank_unmaped, bank_base} = bank[block_info.id][sel_bank];

    assign ram_addr = {6'b0, bank_base, cpu_bus.addr[12:0]};

    // Check if the calculated RAM address is within the valid range of the ROM size
    wire ram_valid = cs && ~bank_unmaped && cpu_bus.rd;

    // Assign the final outputs for the mapper
    assign out.ram_cs  = ram_valid;
    assign out.addr    = ram_valid ? ram_addr : {27{1'b1}};

endmodule
