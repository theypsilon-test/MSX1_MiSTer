module mapper_megaram (
    cpu_bus_if.device_mp     cpu_bus,        // Interface for CPU communication
    mapper_out               out,            // Interface for mapper output
    block_info               block_info,     // Struct containing mapper configuration and parameters
    device_bus               device_out,      // Interface for device output 
    input                    ocm_slot1_mode,
    input              [1:0] ocm_slot2_mode
);

    logic       cs, DecSccA, DecSccB, Dec1FFE;
    logic       SccBankL, SccBankM;
    logic [7:0] SccBank0, SccBank1, SccBank2, SccBank3, SccModeA, SccModeB;
    logic [1:0] SccSel;

    logic [1:0] mapsel;
    always_comb begin
        case(block_info.typ)
            MAPPER_MEGARAM:     mapsel = block_info.id ? ocm_slot2_mode : {ocm_slot1_mode, 1'b0};
            MAPPER_MEGASCC:     mapsel = 2'b10;
            MAPPER_MEGAASCII8:  mapsel = 2'b01;
            MAPPER_MEGAASCII16: mapsel = 2'b11;
            default: mapsel = 2'b00;
        endcase        
    end

    assign cs = cpu_bus.mreq && mapsel != 2'b00;

    assign DecSccA = cpu_bus.addr[15:11] == 5'b10011 && ~SccModeB[5] && SccBank2[5:0] == 6'b111111;      
    assign DecSccB = cpu_bus.addr[15:11] == 5'b10111 &&  SccModeB[5] && SccBank3[7];                     
    assign Dec1FFE = cpu_bus.addr[12:1] == 12'b111111111111;

    always_comb begin 
        if (~cpu_bus.addr[8] && ~SccModeB[4] && ~mapsel[0] && (DecSccA || DecSccB)) begin
            SccSel = 2'b10; // memory access (scc_wave)
        end else if (
            (cpu_bus.addr[15:14] == 2'b01  &&  mapsel[0]   &&             ~cpu_bus.wr) ||   // 4000-7FFFh(R/-, ASC8K/16K)
            (cpu_bus.addr[15:14] == 2'b10  &&  mapsel[0]   &&             ~cpu_bus.wr) ||   // 8000-BFFFh(R/-, ASC8K/16K)
            (cpu_bus.addr[15:13] == 3'b010 &&  mapsel[0]   &&  SccBank0[7]       ) ||   // 4000-5FFFh(R/W, ASC8K/16K)
            (cpu_bus.addr[15:13] == 3'b100 &&  mapsel[0]   &&  SccBank2[7]       ) ||   // 8000-9FFFh(R/W, ASC8K/16K)
            (cpu_bus.addr[15:13] == 3'b101 &&  mapsel[0]   &&  SccBank3[7]       ) ||   // A000-BFFFh(R/W, ASC8K/16K)
            (cpu_bus.addr[15:13] == 3'b010 && ~SccModeA[6] &&             ~cpu_bus.wr) ||   // 4000-5FFFh(R/-, SCC)
            (cpu_bus.addr[15:13] == 3'b011 &&                             ~cpu_bus.wr) ||   // 6000-7FFFh(R/-, SCC)
            (cpu_bus.addr[15:13] == 3'b100 && ~DecSccA     &&             ~cpu_bus.wr) ||   // 8000-9FFFh(R/-, SCC)
            (cpu_bus.addr[15:13] == 3'b101 && ~SccModeA[6] && ~DecSccB && ~cpu_bus.wr) ||   // A000-BFFFh(R/-, SCC)
            (cpu_bus.addr[15:13] == 3'b010 &&  SccModeA[4]                       ) ||   // 4000-5FFFh(R/W) ESCC-RAM
            (cpu_bus.addr[15:13] == 3'b011 &&  SccModeA[4] && ~Dec1FFE           ) ||   // 6000-7FFDh(R/W) ESCC-RAM
            (cpu_bus.addr[15:14] == 2'b01  &&  SccModeB[4]                       ) ||   // 4000-7FFFh(R/W) SNATCHER
            (cpu_bus.addr[15:13] == 3'b100 &&  SccModeB[4]                       ) ||   // 8000-9FFFh(R/W) SNATCHER
            (cpu_bus.addr[15:13] == 3'b101 &&  SccModeB[4] && ~Dec1FFE           )      // A000-BFFDh(R/W) SNATCHER
         ) begin
            SccSel = 2'b01;
         end else begin
            SccSel = 2'b00;
         end
    end


    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Reset bank registers and disable SCC
            SccBank0    <= 8'h00;
            SccBank1    <= 8'h01;
            SccBank2    <= 8'h02;
            SccBank3    <= 8'h03;
            SccModeA    <= '0;
            SccModeB    <= '0;
            SccBankL    <= '0;
            SccBankM    <= '0;
        end else begin
            if (cs && cpu_bus.wr && cpu_bus.req) begin
                $display("ID: %d mapsel: %d", block_info.id, mapsel);
            end
            if (cs && cpu_bus.wr && cpu_bus.req && SccSel == 2'b00) begin
                if (~mapsel[0]) begin
                    if (~SccModeB[4]) begin
                        case(cpu_bus.addr[15:11])
                            5'b01010: // Mapped I/O port access on 5000-57FFh ... Bank register write
                                if (~SccModeA[6] && ~SccModeA[4]) SccBank0 <= cpu_bus.data;
                            5'b01110: // Mapped I/O port access on 7000-77FFh ... Bank register write
                                if (~SccModeA[6] && ~SccModeA[4]) SccBank1 <= cpu_bus.data;
                            5'b10010: // Mapped I/O port access on 9000-97FFh ... Bank register write
                                SccBank2 <= cpu_bus.data;
                            5'b10110: // Mapped I/O port access on B000-B7FFh ... Bank register write
                                if (~SccModeA[6] && ~SccModeA[4]) SccBank3 <= cpu_bus.data;
                            default: ;
                        endcase
                    end

                    if (Dec1FFE) begin
                        case(cpu_bus.addr[15:13])
                            3'b011: // Mapped I/O port access on 7FFE-7FFFh ... Register write
                                if (SccModeB[5:4] == 2'b00) begin SccModeA <= cpu_bus.data; $display("SET SccModeA %x", cpu_bus.data); end
                            3'b101: // Mapped I/O port access on BFFE-BFFFh ... Register write
                                if (~SccModeA[6] && ~SccModeA[4]) begin SccModeB <= cpu_bus.data;  $display("SET SccModeB %x", cpu_bus.data); end
                            default:;
                        endcase
                    end
                end else begin
                    if (cpu_bus.addr[15:12] == 4'b0110) begin // Mapped I/O port access on 6000-6FFFh ... Bank register write
                        if (mapsel[1]) begin
                            if (~cpu_bus.addr[11]) begin  // ASC16K / 6000-67FFh
                               SccBankL <= cpu_bus.data[6];
                               SccBank0 <= {cpu_bus.data[7], cpu_bus.data[5:0], 1'b0};
                               SccBank1 <= {cpu_bus.data[7], cpu_bus.data[5:0], 1'b1};
                            end
                        end else begin
                            if (cpu_bus.addr[11]) begin 
                                SccBank1 <= cpu_bus.data; // ASC8K / 6800-6FFFh
                            end else begin
                                SccBank0 <= cpu_bus.data; // ASC8K / 6000-67FFh
                            end
                        end
                    end
                    if (cpu_bus.addr[15:12] == 4'b0111) begin // Mapped I/O port access on 7000-7FFFh ... Bank register write
                        if (mapsel[1]) begin
                            if (~cpu_bus.addr[11]) begin //ASC16K / 7000-77FFh
                               SccBankM <= cpu_bus.data[6];
                               SccBank2 <= {cpu_bus.data[7], cpu_bus.data[5:0], 1'b0};
                               SccBank3 <= {cpu_bus.data[7], cpu_bus.data[5:0], 1'b1};
                            end
                        end else begin
                            if (cpu_bus.addr[11]) begin 
                                SccBank3 <= cpu_bus.data; // ASC8K / 7800-7FFFh
                            end else begin
                                SccBank2 <= cpu_bus.data; // ASC8K / 7000-77FFh
                            end
                        end
                    end
                end
            end
            
        end
    end
    
    logic [26:0] ram_addr;

    always_comb begin
        case (cpu_bus.addr[14:13])
            2'b00: begin
                ram_addr[26:0] = {6'd0, SccBank2[7:0], cpu_bus.addr[12:0]};
            end
            2'b01: begin
                ram_addr[26:0] = {6'd0, SccBank3[7:0], cpu_bus.addr[12:0]};
            end
            2'b10: begin
                ram_addr[26:0] = {6'd0, SccBank0[7:0], cpu_bus.addr[12:0]};
            end
            2'b11: begin
                ram_addr[26:0] = {6'd0, SccBank1[7:0], cpu_bus.addr[12:0]};
            end
        endcase
        if (mapsel == 2'b01) begin
            ram_addr[20] = 1'b0;
        end else if (mapsel == 2'b11) begin
            ram_addr[20] = cpu_bus.addr[14] ? SccBankL : SccBankM;
        end
    end


    assign device_out.en    = cs && SccSel[1];
    
    wire oe;
    
    assign oe         = cs && SccSel == 2'b01;

    assign out.addr   = oe ? ram_addr : {27{1'b1}};
    assign out.ram_cs = oe;
    assign out.rnw    = ~(cpu_bus.wr && oe);

    //TODO mapper může být ve dvou slotech

endmodule
