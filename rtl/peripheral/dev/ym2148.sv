// YM2148 MIDI UART device
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

module dev_YM2148 #(parameter COUNT=1) (
    cpu_bus_if.device_mp   cpu_bus,
    device_bus             device_bus,
    clock_bus_if.base_mp   clock_bus,
    input MSX::io_device_t io_device[3],
    output         [7:0]   data,
    output                 irq
);

    logic [7:0] irq_vector[2];

    wire irq_vector_to_bus = cpu_bus.m1 && cpu_bus.iorq && cpu_bus.interrupt && io_device[0].enable;

    assign data            = irq_vector_to_bus ? irq_vector[irq] : 8'hFF;
    assign irq             = '0;            //Todo implementace

    always_ff @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            irq_vector <= '{'1,'1};
        end else begin
            if (io_device[0].enable && io_device[0].device_ref == device_bus.device_ref && device_bus.we) begin
                irq_vector[cpu_bus.addr[0]] <= cpu_bus.data;            // 1 - internal (MIDI) IRQ vector, 0 - external IRQ vector
            end
        end
    end

endmodule
