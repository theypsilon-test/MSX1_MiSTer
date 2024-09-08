/*verilator tracing_off*/
module mapper_konami (
    cpu_bus             cpu_bus,       // Interface for CPU communication
    mapper_out          out,           // Interface for mapper output
    block_info          block_info     // Struct containing mapper configuration and parameters  
);

    // Control signals for memory mapping
    wire cs, mapped;

    // Mapper is enabled if type is KONAMI and there is a memory request
    assign cs = (block_info.typ == MAPPER_KONAMI) & cpu_bus.mreq;

    // Address is mapped if it's between 0x4000 and 0xBFFF and within ROM size
    assign mapped = (cpu_bus.addr >= 16'h4000) && (cpu_bus.addr < 16'hC000) && (ram_addr < {2'b0, block_info.rom_size});

    // Bank registers for memory banking
    logic [7:0] bank1[2], bank2[2], bank3[2];

    // Bank switching logic
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Initialize bank values on reset
            bank1 <= '{'h01, 'h01};  // Default bank 1 values
            bank2 <= '{'h02, 'h02};  // Default bank 2 values
            bank3 <= '{'h03, 'h03};  // Default bank 3 values
        end else begin
            if (cs & cpu_bus.wr) begin
                // Bank switching logic based on address
                case (cpu_bus.addr[15:13])
                    3'b011: // 6000-7FFFh: Switch bank 1
                        bank1[block_info.id] <= cpu_bus.data;
                    3'b100: // 8000-9FFFh: Switch bank 2
                        bank2[block_info.id] <= cpu_bus.data;
                    3'b101: // A000-BFFFh: Switch bank 3
                        bank3[block_info.id] <= cpu_bus.data;
                    default: ; // No action for other address ranges
                endcase
            end
        end
    end

    // Bank selection logic based on address ranges
    wire [7:0] bank_base = (cpu_bus.addr[15:13] == 3'b010) ? 8'h00 :  // Fixed bank for 4000-5FFFh
                           (cpu_bus.addr[15:13] == 3'b011) ? bank1[block_info.id] :  // Bank 1 for 6000-7FFFh
                           (cpu_bus.addr[15:13] == 3'b100) ? bank2[block_info.id] :  // Bank 2 for 8000-9FFFh
                           bank3[block_info.id];  // Bank 3 for A000-BFFFh

    // Generate RAM address based on bank and lower address bits
    wire [26:0] ram_addr = {6'b0, bank_base, cpu_bus.addr[12:0]};

    // Output enable signal (only if mapped and chip select is active)
    wire oe = cs && mapped;

    // Output assignments to the `out` interface
    assign out.addr   = oe ? ram_addr : '1;    // Output address, or '1 if not enabled
    assign out.ram_cs = oe;                    // RAM chip select signal

endmodule
