/*verilator tracing_off*/
module mapper_gamemaster2 (
    cpu_bus     cpu_bus,       // Interface for CPU communication
    mapper_out  out,           // Interface for mapper output
    mapper      mapper         // Struct containing mapper configuration and parameters
);

    // Memory mapping control signals
    wire cs, mapper_en;

    // Enable mapper if type is GameMaster2
    assign mapper_en = (mapper.typ == MAPPER_GM2);

    // Chip select is active when mapper is enabled and memory request (mreq) is active
    assign cs = mapper_en && cpu_bus.mreq;

    // Bank registers for memory mapping
    logic [5:0] bank1, bank2, bank3;

    // Bank switching logic
    always @(posedge cpu_bus.reset or posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Initialize banks after reset
            bank1 <= 6'h01;   // Default bank 1
            bank2 <= 6'h02;   // Default bank 2
            bank3 <= 6'h03;   // Default bank 3
        end else begin
            if (cs && cpu_bus.wr) begin
                // Bank switching based on address ranges
                case (cpu_bus.addr[15:12])
                    4'h6: bank1 <= cpu_bus.data[5:0];  // Bank 1 (6000-6FFFh)
                    4'h8: bank2 <= cpu_bus.data[5:0];  // Bank 2 (8000-8FFFh)
                    4'hA: bank3 <= cpu_bus.data[5:0];  // Bank 3 (A000-AFFFh)
                    default: ;  // No action for other addresses
                endcase
            end
        end
    end

    // Bank selection logic based on address ranges
    wire [7:0] bank_base = (cpu_bus.addr[15:13] == 3'b010) ? 8'h00 :      // Fixed bank for 4000-5FFFh
                           (cpu_bus.addr[15:13] == 3'b011) ? {2'b00, bank1} :  // Bank 1 (6000-7FFFh)
                           (cpu_bus.addr[15:13] == 3'b100) ? {2'b00, bank2} :  // Bank 2 (8000-9FFFh)
                           {2'b00, bank3};  // Bank 3 (A000-BFFFh)

    // Address generation for RAM and SRAM based on bank selection
    wire [26:0] ram_addr  = {bank_base[5:0], cpu_bus.addr[11:0]};  // RAM address
    wire [26:0] sram_addr = {bank_base[3:0], cpu_bus.addr[12:0]};  // SRAM address

    // SRAM enable signal (based on bank bit 4)
    wire sram_en = bank_base[4];
    
    // RAM enable signal (active if bank bit 4 is not set and CPU is reading)
    wire ram_en = ~bank_base[4] && cpu_bus.rd;

    // Output control signals
    assign out.sram_cs = cs && sram_en;  // SRAM chip select
    assign out.ram_cs  = cs && ram_en;   // RAM chip select
    assign out.rnw     = ~(out.sram_cs && cpu_bus.wr && cpu_bus.addr[15:12] == 4'hB);  // Read/Write control
    assign out.addr    = cs ? (sram_en ? sram_addr : ram_addr) : {27{1'b1}};  // Address output

endmodule
