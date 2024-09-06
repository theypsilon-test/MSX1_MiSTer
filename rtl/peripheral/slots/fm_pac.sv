/*verilator tracing_off*/
module mapper_fm_pac (
    cpu_bus             cpu_bus,       // Interface for CPU communication
    mapper              mapper,        // Struct containing mapper configuration and parameters
    mapper_out          out,           // Interface for mapper output
    device_bus          device_out     // Interface for device output
);

    // Internal logic variables
    logic [7:0] enable[2];             // Enable registers for mapper
    logic [1:0] bank[2];               // Bank registers for mapper
    logic [7:0] magicLo[2];            // Lower half of magic value for SRAM
    logic [7:0] magicHi[2];            // Upper half of magic value for SRAM
    logic       opll_wr;               // OPLL write signal

    // Initial setup
    initial begin
        opll_wr  = 1'b0;
        enable   = '{default: 8'b0};
        bank     = '{default: 2'b0};
        magicLo  = '{default: 8'b0};
        magicHi  = '{default: 8'b0};
    end

    // Main control logic
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Reset states
            enable  <= '{default: 8'b0};
            bank    <= '{default: 2'b0};
            magicLo <= '{default: 8'b0};
            magicHi <= '{default: 8'b0};
        end else begin
            opll_wr <= 1'b0;
            if (mapper.typ == MAPPER_FMPAC && cpu_bus.wr && cpu_bus.mreq) begin
                case (cpu_bus.addr[13:0]) 
                    14'h1FFE: 
                        if (~enable[mapper.id][4]) 
                            magicLo[mapper.id] <= cpu_bus.data;
                    14'h1FFF: 
                        if (~enable[mapper.id][4]) 
                            magicHi[mapper.id] <= cpu_bus.data;
                    14'h3FF4, 14'h3FF5: 
                        opll_wr <= 1'b1;
                    14'h3FF6: begin
                        enable[mapper.id] <= cpu_bus.data & 8'h11;
                        if (cpu_bus.data[4]) begin
                            magicLo[mapper.id] <= 8'b0;
                            magicHi[mapper.id] <= 8'b0;
                        end
                    end
                    14'h3FF7: 
                        bank[mapper.id] <= cpu_bus.data[1:0];
                    default: ; // No action
                endcase
            end
        end
    end

    // Memory addressing and control
    wire cs            = (mapper.typ == MAPPER_FMPAC) && cpu_bus.mreq;
    wire mapped        = cpu_bus.addr[15:14] == 2'b01;
    wire sramEnable    = {magicHi[mapper.id], magicLo[mapper.id]} == 16'h694D;
    wire sram_en       = sramEnable && cpu_bus.addr[13:0] < 14'h1FFE && cpu_bus.mreq && (cpu_bus.wr || cpu_bus.rd);
    wire [26:0] sram_addr = {14'b0, cpu_bus.addr[12:0]};
    wire [26:0] ram_addr  = {11'b0, bank[mapper.id], cpu_bus.addr[13:0]};

    // Mapper output signals
    assign out.sram_cs  = cs && sram_en;
    assign out.ram_cs   = cs && ~sram_en && cpu_bus.rd && mapped;
    assign out.rnw      = ~(out.sram_cs && cpu_bus.wr);
    assign out.addr     = cs ? (out.sram_cs ? sram_addr : ram_addr) : {27{1'b1}};
    
    assign device_out.typ = cs ? DEV_OPL3 : DEV_NONE;
    assign device_out.we  = cs && opll_wr;
    assign device_out.en  = cs && enable[mapper.id][0];

    // Multiplexing output data
    assign out.data = (mapper.typ == MAPPER_FMPAC) ? 
                      (cpu_bus.addr[13:0] == 14'h3FF6) ? enable[mapper.id] :
                      (cpu_bus.addr[13:0] == 14'h3FF7) ? {6'b000000, bank[mapper.id]} :
                      (cpu_bus.addr[13:0] == 14'h1FFE && sramEnable) ? magicLo[mapper.id] :
                      (cpu_bus.addr[13:0] == 14'h1FFF && sramEnable) ? magicHi[mapper.id] :
                      8'hFF : 8'hFF;

endmodule
