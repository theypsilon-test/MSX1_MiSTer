// OPM device
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

module dev_opm #(parameter COUNT=3) (
    cpu_bus_if.device_mp   cpu_bus,
    device_bus             device_bus,
    clock_bus_if.base_mp   clock_bus,
    input MSX::io_device_t io_device[3],
    output signed [15:0]   sound_L,
    output signed [15:0]   sound_R,
    output         [7:0]   data,
    output                 irq
);

    assign sound_L = (io_device[0].enable ? sound_OPM_L[0] : '0) +
                     (io_device[1].enable ? sound_OPM_L[1] : '0) +
                     (io_device[2].enable ? sound_OPM_L[2] : '0);

    assign sound_R = (io_device[0].enable ? sound_OPM_R[0] : '0) +
                     (io_device[1].enable ? sound_OPM_R[1] : '0) +
                     (io_device[2].enable ? sound_OPM_R[2] : '0);                   
    
    assign irq = ~((io_device[0].enable ? irq_n[0] : 1'b1) &
                   (io_device[1].enable ? irq_n[1] : 1'b1) &
                   (io_device[2].enable ? irq_n[2] : 1'b1)) ;
    
    wire io_en = cpu_bus.iorq && ~cpu_bus.m1;

    logic signed [15:0] sound_OPM_L[0:2], sound_OPM_R[0:2];
    logic         [7:0] data_OPM[3];
    logic         [2:0] data_OPM_OE;
    logic               irq_n[3];
    
    assign data = (data_OPM_OE[0] ? data_OPM[0] : 8'hFF) &
                  (data_OPM_OE[1] ? data_OPM[1] : 8'hFF) &
                  (data_OPM_OE[2] ? data_OPM[2] : 8'hFF);

    genvar i;
    generate
        for (i = 0; i < COUNT; i++) begin : OPM_INSTANCES
            wire cs_io_active = (cpu_bus.addr[7:0] & io_device[i].mask) == io_device[i].port;
            wire cs_io        = (io_device[i].enable && cs_io_active && io_en);
            wire cs_dev       = (io_device[i].enable && io_device[i].device_ref == device_bus.device_ref && device_bus.en);

            IKAOPM #(.FULLY_SYNCHRONOUS(1), .FAST_RESET(1), .USE_BRAM(0)) OPM_i (
                .i_EMUCLK      (cpu_bus.clk),
                .i_phiM_PCEN_n (~clock_bus.ce_3m58_n),
                .i_IC_n        (~cpu_bus.reset),
                .o_phi1        (),
                .i_CS_n        (~(cs_io || cs_dev)),
                .i_WR_n        (~cpu_bus.wr),
                .i_RD_n        (~cpu_bus.rd),
                .i_A0          (cpu_bus.addr[0]),
                .i_D           (cpu_bus.data),
                .o_D           (data_OPM[i]),
                .o_D_OE        (data_OPM_OE[i]),
                .o_CT1         (), //TODO dořešit
                .o_CT2         (), //TODO dořešit
                .o_IRQ_n       (irq_n[i]),
                .o_SH1         (), //TODO dořešit
                .o_SH2         (), //TODO dořešit
                .o_SO          (), //TODO dořešit
                .o_EMU_R       (sound_OPM_R[i]),
                .o_EMU_L       (sound_OPM_L[i])
				);
        end
    endgenerate

endmodule
