module mapper_zemina80 (
    clock_bus_if    clock_bus,     // Interface for clock
    cpu_bus_if      cpu_bus,       // Interface for CPU communication
    mapper_out      out,           // Interface for mapper output
    block_info      block_info     // Struct containing mapper configuration and parameters
);
  
    // Control signals for memory mapping
    wire cs, we;

    // Mapper is enabled if type is KONAMI and there is a memory request
    assign cs = (block_info.typ == MAPPER_ZEMINA_80) & cpu_bus.mreq;

    assign we = cs && (cpu_bus.addr >= 16'h4000) && (cpu_bus.addr < 16'h4004) && cpu_bus.wr;

    // Bank registers for memory banking
    logic [8:0] bank[0:1][0:7];
    logic [7:0] block, nrBlocks, blockMask;
    logic [8:0] blockCompute;
    
    assign nrBlocks = block_info.rom_size[20:13];
    assign blockMask = nrBlocks  - 1'b1;
    assign block = cpu_bus.data < nrBlocks ? cpu_bus.data : cpu_bus.data & blockMask;
    assign blockCompute = block < nrBlocks ? {1'b0,block} : 9'h100;

    // Bank switching logic
    always @(posedge clock_bus.clk_sys) begin
        if (clock_bus.reset) begin
            // Initialize bank values on reset
            bank[0] <= '{9'h100, 9'h100, 9'h000, 9'h001, 9'h002, 9'h003, 9'h100,  9'h100};
            bank[1] <= '{9'h100, 9'h100, 9'h000, 9'h001, 9'h002, 9'h003, 9'h100,  9'h100};
        end else begin
            if (we && clock_bus.ce_3m58_p) begin
                // Bank switching logic based on address
                    bank[block_info.id][3'd2 +  {1'b0,cpu_bus.addr[1:0]}] <= blockCompute;    
                    $display("Write Zemina 80 [%d] < %x  addr %x value %x ", 3'd2 +  {1'b0,cpu_bus.addr[1:0]}, blockCompute, cpu_bus.addr, cpu_bus.data);
            end
        end
    end

    
    wire  [7:0] bank_base;
    wire        bank_unmaped, ram_valid;
    wire [26:0] ram_addr;
    
    // Calculate bank base and address mapping
    assign {bank_unmaped, bank_base} = bank[block_info.id][cpu_bus.addr[15:13]];
    assign ram_addr = {6'b0, bank_base, cpu_bus.addr[12:0]};

    // Check if the calculated RAM address is within the valid range of the ROM size
    assign ram_valid = (ram_addr < {2'b00, block_info.rom_size}) && ~bank_unmaped && cs && cpu_bus.rd;

    // Assign the final outputs for the mapper
    assign out.ram_cs  = ram_valid;
    assign out.addr    = ram_valid ? ram_addr : {27{1'b1}};

endmodule
