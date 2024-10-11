module mapper_harryFox (
    clock_bus_if    clock_bus,              // Interface for clock
    cpu_bus_if      cpu_bus,                // Interface for CPU communication
    block_info      block_info,             // Struct containing mapper configuration and parameters
    mapper_out      out                     // Interface for mapper output
);

    // Memory mapping control signals
    logic cs, mapper_en;

    // Mapper is enabled if it is 16kb
    assign mapper_en  = (block_info.typ == MAPPER_HARRY_FOX);

    // Chip select is valid if address is mapped and mapper is enabled
    assign cs         = mapper_en & cpu_bus.mreq;

    // Bank enable logic
    logic [2:0] bank[2][4];          // Storage for bank data, two entries for two different mapper IDs
    
    // Initialize or update bank and SRAM enable signals
    always @(posedge clock_bus.clk_sys) begin
        if (clock_bus.reset) begin
            // Initialize banks on reset
            bank[0]    <= '{'b100, 'b000, 'b001, 'b100};
            bank[1]    <= '{'b100, 'b000, 'b001, 'b100};
        end else if (cs & cpu_bus.wr & clock_bus.ce_3m58_p) begin
            case (cpu_bus.addr[15:12])
                4'h6: begin
                    bank[block_info.id][1] = {1'b0, cpu_bus.data[0], 1'b0};
                    $display("Write Hary Fox to  bank 1  %x address %x value %x",  {1'b0, cpu_bus.data[0], 1'b0}, cpu_bus.addr, cpu_bus.data);
                end
                4'h7: begin
                    bank[block_info.id][2] = {1'b0, cpu_bus.data[0], 1'b1};
                    $display("Write Hary Fox to  bank 2  %x address %x value %x",  {1'b0, cpu_bus.data[0], 1'b1}, cpu_bus.addr, cpu_bus.data);
                end
                default: ;
            endcase
        end
    end

    // Calculate bank base and address mapping
    wire [1:0] bank_base;
    wire       bank_unmaped;
    
    assign {bank_unmaped, bank_base} = bank[block_info.id][cpu_bus.addr[15:14]];
    
    wire [26:0] ram_addr  = {11'b0, bank_base, cpu_bus.addr[13:0]};

    // Check if the calculated RAM address is within the valid range of the ROM size
    wire ram_valid = (ram_addr < {2'b00, block_info.rom_size}) && ~bank_unmaped && cs && cpu_bus.rd;

    // Assign the final outputs for the mapper
    assign out.ram_cs  = ram_valid;
    assign out.addr    = ram_valid ? ram_addr : {27{1'b1}};

endmodule
