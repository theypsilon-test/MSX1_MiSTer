// OCM device
//
// Copyright (c) 2024-2025 Molekula
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Redistributions in synthesized form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
//
// * Neither the name of the author nor the names of other contributors may
//   be used to endorse or promote products derived from this software without
//   specific prior written agreement from the author.
//
// * License is granted for non-commercial use only.  A fee may not be charged
//   for redistributions as source code or in synthesized/hardware form without
//   specific prior written agreement from the author.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

module dev_ocm
(
   cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
   input  MSX::io_device_t io_device[3],                          // Array of IO devices with port and mask info
   input  MSX::io_device_mem_ref_t io_memory[8],
   output                  ram_cs,
   output           [26:0] ram_addr
);

    logic en = 0;

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            en <= io_device[0].enable;
            if (io_device[0].enable && en == 0) $display("OCM Boot START");       
        end else begin
            if (cpu_bus.addr[7:3] == 5'b10101 && cpu_bus.iorq && ~cpu_bus.m1 &&  cpu_bus.wr && cpu_bus.req) begin      //First write to slot select disable pre boot sekvence
                en <= 0;
                if (en) $display("OCM Boot STOP");       
            end
        end
    end

    wire [26:0] memory      = io_memory[io_device[0].mem_ref].memory;
    wire  [7:0] memory_size = io_memory[io_device[0].mem_ref].memory_size;

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