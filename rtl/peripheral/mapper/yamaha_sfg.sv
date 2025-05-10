// Yamaha SFG mapper
//
// Copyright (c) 2025 Molekula
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

module mapper_yamaha_sfg (
    cpu_bus_if.device_mp    cpu_bus,       // Interface for CPU communication
    block_info              block_info,    // Struct containing mapper configuration and parameters
    mapper_out              out,           // Interface for mapper output
    device_bus              device_out     // Interface for device output
);

    // Internal logic variables
    logic       opm_en;                // OPM enable signal

    // Initial setup
    initial begin
        opm_en    = 1'b0;
    end

    wire cs = (block_info.typ == MAPPER_YAMAHA_SFG) && cpu_bus.mreq;

    // Main control logic
    always_ff @(posedge cpu_bus.clk) begin
        opm_en <= 1'b0;
        device_out.we <= 1'b0;
        if (cs) begin
            case (cpu_bus.addr[13:0])
                14'h3FF0:
                    opm_en <= cpu_bus.wr;
                14'h3FF1:
                    opm_en <= 1'b1;
                14'h3FF4,
                14'h3FF5:                   // IRQ_vector addr[0] 0 - internal IRQ vector, 1 - external IRQ vector
                    if (cpu_bus.wr && cpu_bus.req) begin
                        device_out.we <= 1'b1;
                    end
                default: ; // No action
            endcase
            if (cpu_bus.wr && cpu_bus.req && rom_mapped) begin
                $display("Mapper write: %x %x %t", cpu_bus.addr, cpu_bus.data, $time);
            end
        end
    end

    // Mapper output signals
    wire rom_mapped = cpu_bus.addr[13:0] < 14'h3FF0 ||  cpu_bus.addr[13:0] > 14'h3ff8;

    assign device_out.en   = opm_en && ~rom_mapped;
    assign device_out.data = '1;

    // Multiplexing output data
    assign out.ram_cs   = cs && cpu_bus.rd && rom_mapped;
    assign out.rnw      = '1;
    assign out.addr     = cs ? {11'd0, (cpu_bus.addr & (block_info.rom_size[15:0] - 16'd1))} : {27{1'b1}};

endmodule
