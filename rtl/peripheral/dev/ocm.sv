module ocm
(
   cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
   input  [2:0]            dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
   input  MSX::io_device_t io_device[16],                          // Array of IO devices with port and mask info
   output                  ram_cs,
   output           [26:0] ram_addr
);

    logic en = 0;

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            en <= dev_en;
            if (dev_en && en == 0) $display("OCM Boot START");       
        end else begin
            if (cpu_bus.addr[7:3] == 5'b10101 && cpu_bus.iorq && ~cpu_bus.m1 &&  cpu_bus.wr) begin      //First write to slot select disable pre boot sekvence
                en <= 0;
                if (en) $display("OCM Boot STOP");       
            end
        end
    end
    


    logic [26:0] memory;
    logic  [7:0] memory_size;  
    logic        dev_en;

    always_comb begin
        // Iterate over each IO device
        dev_en = 0;
        memory = '1;
        memory_size = '0;
        for (int i = 0; i < 16; i++) begin
            if (io_device[i].id == DEV_OCM_BOOT) begin
                dev_en = 1;
                //params = io_device[i].param;
                memory = io_device[i].memory;
                memory_size = io_device[i].memory_size;
            end
        end
    end

    assign ram_cs = cpu_bus.mreq && cpu_bus.rd && en && (cpu_bus.addr[15:14] == 2'b00 || cpu_bus.addr[15:14] == 2'b10);
    assign ram_addr = ram_cs ? memory + {16'b0, cpu_bus.addr[9:0]} : '1;


    logic [7:0] io40_n; // ID Manufacturers/Devices :   $08 (008), $D4 (212=1chipMSX), $FF (255=null)
    logic portF4_mode, WarmMSXlogo, JIS2_ena;
    

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            io40_n <=  '1;  
        end else begin
            if (cpu_bus.req && cpu_bus.addr[7:4] == 4'b0100 && cpu_bus.iorq && ~cpu_bus.m1 && cpu_bus.wr) begin
                case(cpu_bus.addr[3:0])
                    4'h0: begin // Port $40 [ID Manufacturers/Devices]' (read_n/write)
                        io40_n <= cpu_bus.data == 8'h08 ? 8'b11110111 : // ID 008 => $08
                                  cpu_bus.data == 8'hD4 ? 8'b00101011 : // ID 212 => $D4 => 1chipMSX
                                                          8'b11111111 ; // invalid ID
                    end
                    4'hE: begin // Port $4E ID212 [JIS2 enabler] [Reserved to IPL-ROM]' (write_n only)
                    ;
                        //if( req = '1' and wrt = '1' and (adr(3 downto 0) = "1110")  and (io40_n = "00101011") and ff_ldbios_n = '0' )then
                            //JIS2_ena            <=  not dbo(7);                     -- BIT[7]
                    end
                    
                    4'hF: begin // Port $4F ID212 [Port F4 mode] [Reserved to IPL-ROM]' (write_n only)
                    ;
                        //if( req = '1' and wrt = '1' and (adr(3 downto 0) = "1111")  and (io40_n = "00101011") and ff_ldbios_n = '0' )then
                        //    portF4_mode         <=  not dbo(7);                     -- BIT[7]
                        //    WarmMSXlogo         <=  not dbo(7);                     -- MSX logo will be Off after a Warm Reset
                    end

                    default: ;

                endcase

                $display("SWIO Write 0x4%x <= %x", cpu_bus.addr[3:0], cpu_bus.data);
            end
        end
    end

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.req && cpu_bus.addr[7:4] == 4'b0100 && cpu_bus.iorq && ~cpu_bus.m1 && cpu_bus.rd) begin
            $display("SWIO READ 0x4%x", cpu_bus.addr[3:0]);
        end
    end

endmodule