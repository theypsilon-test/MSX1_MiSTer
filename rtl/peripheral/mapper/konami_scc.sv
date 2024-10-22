module mapper_konami_scc (
   cpu_bus_if.device_mp     cpu_bus,        // Interface for CPU communication
   mapper_out               out,            // Interface for mapper output
   block_info               block_info,     // Struct containing mapper configuration and parameters 
   device_bus               device_out      // Interface for device output
);

    // Control signals for memory mapping
    wire cs, mapped, scc_area;

    // Mapper is enabled if type is KONAMI_SCC and there is a memory request (mreq)
    assign cs = (block_info.typ == MAPPER_KONAMI_SCC) & cpu_bus.mreq;

    // Address is mapped if it is between 0x4000 and 0xBFFF and within ROM size
    assign mapped = (cpu_bus.addr >= 16'h4000) && (cpu_bus.addr < 16'hC000) && (ram_addr < {2'b0, block_info.rom_size});

    // SCC area is active if the address is in the range 0x9800 to 0x9FFF and SCC is enabled
    assign scc_area = (cpu_bus.addr >= 16'h9800) && (cpu_bus.addr < 16'hA000) && sccEnable[block_info.id];

    // Bank registers for switching between memory banks
    logic [7:0] bank1[2];   // Bank 1 for address range 0x4000-0x5FFF
    logic [7:0] bank2[2];   // Bank 2 for address range 0x6000-0x7FFF
    logic [7:0] bank3[2];   // Bank 3 for address range 0x8000-0x9FFF
    logic [7:0] bank4[2];   // Bank 4 for address range 0xA000-0xBFFF
    logic [1:0] sccEnable;  // SCC enable flag for each bank

    // Bank switching logic: On reset, set default bank values. On write, update bank values.
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Reset bank registers and disable SCC
            bank1 <= '{'h00, 'h00};  // Default bank 1 values
            bank2 <= '{'h01, 'h01};  // Default bank 2 values
            bank3 <= '{'h02, 'h02};  // Default bank 3 values
            bank4 <= '{'h03, 'h03};  // Default bank 4 values
            sccEnable <= 2'b00;      // Disable SCC initially
        end else if (cs && cpu_bus.wr && cpu_bus.req ) begin
            // Write to the bank registers based on address ranges
            case (cpu_bus.addr[15:11])
                5'b01010: // 5000-57FFh -> Bank 1
                    bank1[block_info.id] <= cpu_bus.data;
                5'b01110: // 7000-77FFh -> Bank 2
                    bank2[block_info.id] <= cpu_bus.data;
                5'b10010: begin // 9000-97FFh -> Bank 3
                    bank3[block_info.id] <= cpu_bus.data;
                    // Enable SCC if the data matches the specific SCC enable value (0x3F)
                    sccEnable[block_info.id] <= (cpu_bus.data[5:0] == 6'h3F);
                end
                5'b10110: // B000-B7FFh -> Bank 4
                    bank4[block_info.id] <= cpu_bus.data;
                default: ;
            endcase
        end
    end

    // Bank selection logic based on the current address range
    wire [7:0] bank_base = (cpu_bus.addr[15:13] == 3'b010) ? bank1[block_info.id] :  // Bank 1 for 4000-5FFFh
                           (cpu_bus.addr[15:13] == 3'b011) ? bank2[block_info.id] :  // Bank 2 for 6000-7FFFh
                           (cpu_bus.addr[15:13] == 3'b100) ? bank3[block_info.id] :  // Bank 3 for 8000-9FFFh
                                                             bank4[block_info.id];    // Bank 4 for A000-BFFFh

    // Generate RAM address based on bank and lower address bits
    wire [26:0] ram_addr = {6'b0, bank_base, cpu_bus.addr[12:0]};

    // Output enable signal: active only if address is mapped and not in SCC area
    wire oe = cs && mapped && ~scc_area;

    // Output assignments to the `out` interface
    assign out.addr   = oe ? ram_addr : {27{1'b1}};   // Output address, or '1 if not enabled
    assign out.ram_cs = oe;                           // RAM chip select signal

    assign device_out.typ = cs ? DEV_SCC : DEV_NONE;
    assign device_out.en  = cs && sccEnable[block_info.id];

endmodule
