// ASCII16 mapper
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

module mapper_ascii16 (
    cpu_bus_if.device_mp    cpu_bus,
    block_info              block_info,
    mapper_out              out
);

    wire cs, mapped, mode_rtype, mapper_en;

    assign mapped     = ^cpu_bus.addr[15:14];

    assign mapper_en  = (block_info.typ == MAPPER_ASCII16) | (block_info.typ == MAPPER_RTYPE);

    assign mode_rtype = (block_info.typ == MAPPER_RTYPE);

    assign cs         = mapped & mapper_en & cpu_bus.mreq;

    logic [7:0] bank0[2];
    logic [7:0] bank1[2];
    logic [1:0] sramEnable[2];

    wire sram_exists = (block_info.sram_size > 0);

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            bank0      <= '{'h00, 'h00};
            bank1      <= '{'h00, 'h00};
            sramEnable <= '{2'd0, 2'd0};
        end else if (cs & cpu_bus.wr && cpu_bus.req) begin
            if (mode_rtype) begin
                if (cpu_bus.addr[15:12] == 4'b0111) begin
                    bank1[block_info.id] <= cpu_bus.data & (cpu_bus.data[4] ? 8'h17 : 8'h1F);
                end
            end else begin
                case (cpu_bus.addr[15:11])
                    5'b01100: // 0x6000-0x67FF
                        if (cpu_bus.data == 8'h10 && sram_exists)
                            sramEnable[block_info.id][0] <= 1'b1;
                        else begin
                            sramEnable[block_info.id][0] <= 1'b0;
                            bank0[block_info.id] <= cpu_bus.data;
                        end
                    5'b01110: // 0x7000-0x77FF
                        if (cpu_bus.data == 8'h10 && sram_exists)
                            sramEnable[block_info.id][1] <= 1'b1;
                        else begin
                            sramEnable[block_info.id][1] <= 1'b0;
                            bank1[block_info.id] <= cpu_bus.data;
                        end
                    default: ;
                endcase
            end
        end
    end

    wire [7:0] bank_base = cpu_bus.addr[15] ? bank1[block_info.id] :
                          (mode_rtype ? 8'h0F : bank0[block_info.id]);

    wire sram_en   = sramEnable[block_info.id][cpu_bus.addr[15]];

    wire [26:0] sram_addr = {block_info.sram_size > 16'd2 ?
                            {14'd0, cpu_bus.addr[12:0]} :
                            {16'd0, cpu_bus.addr[10:0]}};

    wire [26:0] ram_addr  = {5'b0, bank_base, cpu_bus.addr[13:0]};

    wire ram_valid = (ram_addr < {2'b00, block_info.rom_size});

    wire sram_cs = cs & sram_en & (cpu_bus.rd || cpu_bus.wr);
    wire ram_cs  = cs & ram_valid & ~sram_en & cpu_bus.rd;

    assign out.sram_cs = sram_cs;
    assign out.ram_cs  = ram_cs;
    assign out.rnw     = ~(sram_cs & cpu_bus.wr & cpu_bus.addr[15]);
    assign out.addr    = cs ? (sram_en ? sram_addr : ram_addr) : {27{1'b1}};

endmodule
