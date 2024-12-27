module mapper_eseRam (
    cpu_bus_if.device_mp    cpu_bus,       // Interface for CPU communication
    mapper_out              out,           // Interface for mapper output
    block_info              block_info,
    spi_if                  spi            // Struct containing mapper configuration and parameters
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
    
    wire mmc_enable;
    wire [26:0] ram_addr;   
    
    assign mmc_enable = bank[0][7:6] == 2'b01 && cpu_bus.addr[15:13] == 3'b010 ;
    assign ram_addr   = {7'b0, bank_base, cpu_bus.addr[12:0]};
    
    
                        
    
    assign out.ram_cs = cs && (cpu_bus.rd && ~mmc_enable) || ram_wr;
    assign out.addr   = cs ? ram_addr : {27{1'b1}};
    assign out.rnw    = cs ? ~ram_wr : 1'b1;
    assign out.data   = cs && mmc_enable ? mmc_dbi : '1;

    // SD card function
    
    //V budoucnu výstupy
    logic mmc_cs, epc_cs;
    logic mmc_di, epc_di;
    logic mmc_ck, epc_ck;
    logic mmc_act;
    logic epc_do;
    logic [7:0] mmc_dbi;
    
    wire mmc_do;
    assign mmc_do   = spi.miso;
    assign spi.mosi = mmc_di;
    assign spi.clk  = mmc_ck;
    assign spi.ss   = mmc_cs;

    always @(posedge cpu_bus.clk) begin
        logic mmc_en, epc_en;
        logic [4:0] mmc_seq;
        logic [1:0] mmc_mod;
        logic [7:0] mmc_dbo, mmc_tmp;
        
        if (cpu_bus.reset) begin
            mmc_en  = '0;
            epc_en  = '0;
            mmc_seq = '0;
            mmc_mod = '0;
            mmc_tmp = '1;
            mmc_dbo = '1;

            mmc_cs  <= '1;
            epc_cs  <= '1;           
            mmc_dbi <= '1;
            mmc_ck  <= '0;
            epc_ck  <= '1;
            mmc_di  <= '0;
            epc_di  <= '1;
            spi.enable <= '0;
        end else begin
            mmc_en = bank[0][7:6] == 2'b01;
            epc_en = bank[0][7:4] == 4'b0110;

            if (mmc_seq[0]) begin
                if (epc_en) begin
                    case (mmc_seq[4:1])
                        4'b1001: mmc_tmp[7] = epc_do;
                        4'b1000: mmc_tmp[6] = epc_do;    
                        4'b0111: mmc_tmp[5] = epc_do;
                        4'b0110: mmc_tmp[4] = epc_do;
                        4'b0101: mmc_tmp[3] = epc_do;
                        4'b0100: mmc_tmp[2] = epc_do;
                        4'b0011: mmc_tmp[1] = epc_do;
                        4'b0010: mmc_tmp[0] = epc_do;
                        4'b0001: mmc_dbi <= mmc_tmp;
                        default: ;
                    endcase
                end else begin
                    case (mmc_seq[4:1])
                        4'b1001: mmc_tmp[7] = mmc_do;
                        4'b1000: mmc_tmp[6] = mmc_do;    
                        4'b0111: mmc_tmp[5] = mmc_do;
                        4'b0110: mmc_tmp[4] = mmc_do;
                        4'b0101: mmc_tmp[3] = mmc_do;
                        4'b0100: mmc_tmp[2] = mmc_do;
                        4'b0011: mmc_tmp[1] = mmc_do;
                        4'b0010: mmc_tmp[0] = mmc_do;
                        4'b0001: mmc_dbi <= mmc_tmp;
                        default: ;
                    endcase
                end
            end else begin
                case (mmc_seq[4:1])
                    4'b1001: begin mmc_di <= mmc_dbo[6]; epc_di <= mmc_dbo[6]; end //9
                    4'b1000: begin mmc_di <= mmc_dbo[5]; epc_di <= mmc_dbo[5]; end //8
                    4'b0111: begin mmc_di <= mmc_dbo[4]; epc_di <= mmc_dbo[4]; end //7
                    4'b0110: begin mmc_di <= mmc_dbo[3]; epc_di <= mmc_dbo[3]; end //6
                    4'b0101: begin mmc_di <= mmc_dbo[2]; epc_di <= mmc_dbo[2]; end //5
                    4'b0100: begin mmc_di <= mmc_dbo[1]; epc_di <= mmc_dbo[1]; end //4
                    4'b0011: begin mmc_di <= mmc_dbo[0]; epc_di <= mmc_dbo[0]; end //3
                    4'b0010: begin mmc_di <= 1'b0; epc_di <= 1'b1; end             //2
                    default: ;
                endcase
            end
                                 // 11                       // 1
            if (mmc_seq[4:1] < 4'b1011 && mmc_seq[4:1] > 4'b0001) begin
                if (epc_en) begin
                    mmc_ck <= 1'b0;
                    epc_ck <= mmc_seq[0];
                end else begin
                    mmc_ck <= mmc_seq[0];
                    epc_ck <= 1'b1;
                end
            end else begin
                mmc_ck <= 1'b0;
                epc_ck <= 1'b1;
            end

            if (cs && cpu_bus.req && cpu_bus.addr[15:13] == 3'b010 && cpu_bus.addr[12:11] != 2'b11 && mmc_en && mmc_seq == 5'd0 && mmc_mod[0] == 0 ) begin
                
                spi.enable <= '1;

                if (cpu_bus.wr) begin
                    mmc_dbo = cpu_bus.data;
                end else begin
                    mmc_dbo = '1;
                end

                if (epc_en) begin
                    mmc_cs <= 1;
                    epc_cs <= cpu_bus.addr[12];
                end else begin
                    mmc_cs <= cpu_bus.addr[12];
                    epc_cs <= 1;
                end
                
                mmc_seq  = 5'b10011; //9 
                mmc_di  <= mmc_dbo[7];
                epc_di  <= mmc_dbo[7];
            end else begin
                if (mmc_seq != 5'd0) begin
                    mmc_seq = mmc_seq - 1;
                end
            end

            if (cs && cpu_bus.req && cpu_bus.wr && cpu_bus.addr[15:13] == 3'b010 && cpu_bus.addr[12:11] == 2'b11 && mmc_en ) begin
                mmc_mod = cpu_bus.data[1:0];
            end

            mmc_act = !(mmc_seq == 5'd0);

        end
    end

endmodule
