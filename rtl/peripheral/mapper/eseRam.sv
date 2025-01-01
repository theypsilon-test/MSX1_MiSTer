module mapper_eseRam (
    cpu_bus_if.device_mp    cpu_bus,       // Interface for CPU communication
    mapper_out              out,           // Interface for mapper output
    block_info              block_info,
    ext_sd_card_if.device_mp    ext_SD_card_bus  // Interface Ext SD card
);
  
    wire cs;


    assign cs = block_info.typ == MAPPER_ESE_RAM & cpu_bus.mreq;

    logic [7:0] bank[4];

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            bank <= '{8'h00, 8'h00, 8'h00, 8'h00};
        end else begin
            if (cs && cpu_bus.wr && cpu_bus.req && cpu_bus.addr[15:13] == 3'b011) begin
                bank[cpu_bus.addr[12:11]] <= cpu_bus.data;
                $display("BANK: %d  value: %x", cpu_bus.addr[12:11], {cpu_bus.data[6:0],13'b0});
                if (cpu_bus.addr[12:11] == 2'b00) begin
                     $display("mmc: %d  epc %d", cpu_bus.data[7:6] == 2'b01, cpu_bus.data[7:4] == 4'b0110);
                end
            end
        end
    end

    logic  [6:0] bank_base;
    logic        ram_wr;  
    always_comb begin
        ram_wr = 1'b0;
        bank_base = '1;
        case (cpu_bus.addr[14:13])
            2'b00 : begin
                bank_base = bank[2][6:0];
                ram_wr    = bank[2][7] && cpu_bus.wr;
            end
            2'b01 : begin
                bank_base = bank[3][6:0];
                ram_wr    = bank[3][7] && cpu_bus.wr;
            end
            2'b10 : begin
                bank_base = bank[0][6:0];
                ram_wr    = bank[0][7] && cpu_bus.wr;
            end
            2'b11 : begin
                bank_base =  bank[1][6:0];
            end
        endcase
    end
    
    wire mmc_enable, mmc_read;
    wire [26:0] ram_addr;   
    
    assign mmc_enable = bank[0][7:6] == 2'b01 && cpu_bus.addr[15:13] == 3'b010 ;
    assign ram_addr   = {7'b0, bank_base, cpu_bus.addr[12:0]};                   
    
    assign out.ram_cs = cs && (cpu_bus.rd && ~mmc_enable) || ram_wr;
    assign out.addr   = cs ? ram_addr : {27{1'b1}};
    assign out.rnw    = cs ? ~ram_wr : 1'b1;
    assign out.data   = cs && mmc_enable ? ext_SD_card_bus.data_from_SD : '1;

    // SD card function
    logic mmc_cs;

    always @(posedge cpu_bus.clk) begin
        logic mmc_en;
        logic mmc_mod;

        ext_SD_card_bus.rx         <= '0;
        ext_SD_card_bus.tx         <= '0;
        ext_SD_card_bus.data_to_SD <= '1;       
        
        if (cpu_bus.reset) begin
            mmc_mod <= '0;
            mmc_cs  <= '1;
        end else begin
            if (cs && mmc_enable) begin // 4000 - 5FFF
                if (cpu_bus.addr[12:11] == 2'b11) begin // 5800-5FFFh SD/MMC data register
                    if (cpu_bus.wr && cpu_bus.req) begin
                            mmc_mod <= cpu_bus.data[0];
                    end
                end else begin // 4000-57FFh 
                    if (~mmc_mod) begin
                        ext_SD_card_bus.rx <= 1'b1;
                        mmc_cs             <= cpu_bus.addr[12];
                        if (cpu_bus.wr && cpu_bus.req) begin
                            ext_SD_card_bus.tx         <= 1'b1;
                            ext_SD_card_bus.data_to_SD <= cpu_bus.data;
                        end
                    end                    
                end
            end
        end
    /*    
        if (cs && cpu_bus.req && mmc_enable && cpu_bus.addr[12:11] != 2'b11 && ~mmc_mod ) begin
                ext_SD_card_bus.rx <= 1'b1;

                if (cpu_bus.wr) begin
                    ext_SD_card_bus.tx <= 1'b1;
                    ext_SD_card_bus.data_to_SD <= cpu_bus.data;
                end

                if (mmc_en) begin
                    mmc_cs <= cpu_bus.addr[12];
                end
            end 
            
            // 5800-5FFFh SD/MMC data register
            if (cs && cpu_bus.req && cpu_bus.wr && mmc_enable && cpu_bus.addr[12:11] == 2'b11) begin
                mmc_mod = cpu_bus.data[0];
            end
        end*/
    end

endmodule
