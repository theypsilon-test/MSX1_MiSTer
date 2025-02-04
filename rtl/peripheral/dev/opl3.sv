// OPL3 device
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

module dev_opl3 (
    cpu_bus_if.device_mp   cpu_bus,
    device_bus             device_bus,
    clock_bus_if.base_mp   clock_bus,
    input MSX::io_device_t io_device[3],
    output signed [15:0]   sound
);

    assign sound = (io_device[0].enable ? sound_OPL3[0] : '0) +
                   (io_device[1].enable ? sound_OPL3[1] : '0) +
                   (io_device[2].enable ? sound_OPL3[2] : '0);

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            opl3_enabled <= 3'b111;
        end else if (device_bus.typ == DEV_OPL3 && device_bus.num < 3) begin
            opl3_enabled[device_bus.num] <= device_bus.en;
        end
    end

    wire io_en = cpu_bus.iorq && ~cpu_bus.m1;

    logic signed [15:0] sound_OPL3[0:2];
    logic [2:0] opl3_enabled;
    genvar i;

    generate
        for (i = 0; i < 3; i++) begin : OPL3_INSTANCES
            wire cs_io_active = (cpu_bus.addr[7:0] & io_device[i].mask) == io_device[i].port;
            wire cs_enable = io_device[i].enable && cs_io_active && io_en && opl3_enabled[i];
            wire cs_dev_bus = (device_bus.typ == DEV_OPL3 && device_bus.we && i == device_bus.num);
            jt2413 OPL3_i (
                .clk(cpu_bus.clk),
                .rst(cpu_bus.reset),
                .cen(clock_bus.ce_3m58_n),
                .din(cpu_bus.data),
                .addr(cpu_bus.addr[0]),
                .cs_n(~(cs_enable || cs_dev_bus)),
                .wr_n(~((cpu_bus.wr && cpu_bus.req) || device_bus.we)),
                .snd(sound_OPL3[i]),
                .sample()
            );
        end
    endgenerate

endmodule
