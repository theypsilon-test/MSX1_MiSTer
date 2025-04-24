// Block device MUX
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

module blockDevMux #(parameter VDNUM) (
    input                     clk,
    input                     reset,

    input MSX::msx_config_t   msx_config,

    // hps sd interface
    output logic       [31:0] sd_lba[VDNUM],
    output              [5:0] sd_blk_cnt[VDNUM],
    
    output        [VDNUM-1:0] sd_rd,
    output        [VDNUM-1:0] sd_wr,
    input         [VDNUM-1:0] sd_ack,
    input              [13:0] sd_buff_addr,
    input               [7:0] sd_buff_dout,
    output              [7:0] sd_buff_din[VDNUM],
    input                     sd_buff_wr,
    // hps image interface
    input         [VDNUM-1:0] img_mounted,
    input              [63:0] img_size,
    input                     img_readonly,
    
    block_device_if.hps_mp    block_device_FDD[6],
    block_device_if.hps_mp    block_device_SD,
    block_device_if.hps_mp    block_device_nvram[4]
);
    
    genvar i;
    generate
        for (i = 0; i < 6; i++) begin : BLOCK_DEVICE_FDD_MAPS
            assign sd_lba[i+1]                        = block_device_FDD[i].lba;
            assign sd_blk_cnt[i+1]                    = block_device_FDD[i].blk_cnt;
            assign sd_rd[i+1]                         = block_device_FDD[i].rd;
            assign sd_wr[i+1]                         = block_device_FDD[i].wr;
            assign sd_buff_din[i+1]                   = block_device_FDD[i].buff_din;

            assign block_device_FDD[i].ack          = msx_config.fdd[i] ? sd_ack[i+1] : '0;
            assign block_device_FDD[i].buff_addr    = sd_buff_addr;
            assign block_device_FDD[i].buff_dout    = sd_buff_dout;
            assign block_device_FDD[i].buff_wr      = msx_config.fdd[i] ? sd_buff_wr : '0;
            assign block_device_FDD[i].img_mounted  = img_mounted[i+1];
            assign block_device_FDD[i].img_size     = msx_config.fdd[i] ? img_size   : '0; 
            assign block_device_FDD[i].img_readonly = img_readonly;
        end
    endgenerate

endmodule
