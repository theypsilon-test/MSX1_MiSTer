// devices
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

module devices (
    clock_bus_if.base_mp    clock_bus,                              // Clock interface
    cpu_bus_if.device_mp    cpu_bus,                                // CPU bus interface
    device_bus              device_bus,                             // Device control bus interface
    sd_bus                  sd_bus,                                 // SD bus interface
    sd_bus_control          sd_bus_control,                         // SD bus control interface
    video_bus_if.device_mp  video_bus,
    vram_bus_if.device_mp   vram_bus,
    image_info              image_info,                             // Image information
    input MSX::io_device_t  io_device[16][3],                       // Array of IO devices
    input MSX::io_device_mem_ref_t io_memory[8],                    // Array of memory references
    input MSX::kb_memory_t  kb_upload_memory,
    input MSX::user_config_t msxConfig,
    input            [10:0] ps2_key,
    input            [64:0] rtc_time,
    output    signed [15:0] sound,                                  // Combined audio output
    output            [7:0] data,                                   // Combined data output
    output                  data_oe_rq,                             // Priorite data
    output            [7:0] data_to_mapper,                         // Data output to mapper
    output           [26:0] ram_addr,
    output                  ram_cs,
    output                  cpu_interrupt,
    input             [5:0] joy[2],
    input                   tape_in,
    output                  tape_motor_on,
    output            [7:0] slot_config,
    output                  keybeep
);

    video_bus_if            video_bus_tms();
    vram_bus_if             vram_bus_tms();
    video_bus_if            video_bus_v99();
    vram_bus_if             vram_bus_v99();

    // Výstupy kombinující jednotlivé zařízení
    assign sound = opl3_sound + scc_sound + psg_sound;
    assign data = scc_data & wd2793_data & msx2_ram_data & tms_data & v99_data & rtc_data & psg_data & ppi_data;
    assign data_oe_rq = wd2793_data_oe_rq;
    assign data_to_mapper = msx2_ram_data_to_mapper & latch_port_data_to_mapper;

    assign ram_cs = kanji_ram_cs | ocm_ram_cs;
    assign ram_addr = kanji_ram_addr & ocm_ram_addr;

    // VIDEO interfaces
    assign cpu_interrupt     = tms_interrupt | v99_interrupt;

    assign video_bus.R       = video_bus_tms.R              | video_bus_v99.R;          // default black 
    assign video_bus.G       = video_bus_tms.G              | video_bus_v99.G;          // default black
    assign video_bus.B       = video_bus_tms.B              | video_bus_v99.B;          // default black
    assign video_bus.DE      = video_bus_tms.DE             | video_bus_v99.DE;
    assign video_bus.HS      = video_bus_tms.HS             | video_bus_v99.HS;
    assign video_bus.VS      = video_bus_tms.VS             | video_bus_v99.VS;
    assign video_bus.hblank  = video_bus_tms.hblank         | video_bus_v99.hblank;
    assign video_bus.vblank  = video_bus_tms.vblank         | video_bus_v99.vblank;
    assign video_bus.ce_pix  = video_bus_tms.ce_pix         | video_bus_v99.ce_pix;

    assign vram_bus.addr     = vram_bus_tms.device_mp.addr  & vram_bus_v99.device_mp.addr;
    assign vram_bus.data     = vram_bus_tms.device_mp.data  & vram_bus_v99.device_mp.data;
    assign vram_bus.we_lo    = vram_bus_tms.device_mp.we_lo | vram_bus_v99.device_mp.we_lo;
    assign vram_bus.we_hi    = vram_bus_tms.device_mp.we_hi | vram_bus_v99.device_mp.we_hi;
    
    assign vram_bus_tms.q_lo = vram_bus.q_lo;
    assign vram_bus_tms.q_hi = vram_bus.q_hi;
    assign vram_bus_v99.q_lo = vram_bus.q_lo;
    assign vram_bus_v99.q_hi = vram_bus.q_hi;
    
    // Definice instancí zařízení s výstupy pro propojení
    wire signed [15:0] opl3_sound;
    dev_opl3 opl3 (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .io_device(io_device[DEV_OPL3]),
        .sound(opl3_sound)
    );

    wire [7:0] scc_data;
    wire       scc_output_rq;
    wire signed [15:0] scc_sound;
    dev_scc scc (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .io_device(io_device[DEV_SCC]),
        .sound(scc_sound),
        .data(scc_data)
    );

    wire [7:0] msx2_ram_data_to_mapper;
    wire [7:0] msx2_ram_data;
    dev_msx2_ram msx2_ram (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .io_device(io_device[DEV_MSX2_RAM]),
        .data(msx2_ram_data),
        .data_to_mapper(msx2_ram_data_to_mapper)
    );

    wire [7:0] latch_port_data_to_mapper;
    dev_latch_port latch_port (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .io_device(io_device[DEV_LATCH_PORT]),
        .data_to_mapper(latch_port_data_to_mapper)
    );

    wire [7:0] wd2793_data;
    wire wd2793_data_oe_rq;
    dev_WD2793 WD2793 (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .io_device(io_device[DEV_WD2793]),
        .sd_bus(sd_bus),
        .sd_bus_control(sd_bus_control),
        .image_info(image_info),
        .data(wd2793_data),
        .data_oe_rq(wd2793_data_oe_rq)
    );

    wire [26:0] kanji_ram_addr;
    wire        kanji_ram_cs;
    dev_kanji kanji (
        .cpu_bus(cpu_bus),
        .io_device(io_device[DEV_KANJI]),
        .io_memory(io_memory),
        .ram_cs(kanji_ram_cs),
        .ram_addr(kanji_ram_addr)
    );

    wire [26:0] ocm_ram_addr;
    wire        ocm_ram_cs;
    wire        ocm_data_oe_rq;
    dev_ocm ocm (
        .cpu_bus(cpu_bus),
        .io_device(io_device[DEV_OCM_BOOT]),
        .io_memory(io_memory),
        .ram_cs(ocm_ram_cs),
        .ram_addr(ocm_ram_addr)
    );

    wire  [7:0] tms_data;
    wire        tms_interrupt;
    dev_tms tms (
        .cpu_bus(cpu_bus),
        .clock_bus(clock_bus),
        .video_bus(video_bus_tms),
        .vram_bus(vram_bus_tms),
        .io_device(io_device[DEV_VDP_TMS]),
        .data(tms_data),
        .interrupt(tms_interrupt),
        .border(msxConfig.border)
    );
    
    wire  [7:0] v99_data;
    wire        v99_interrupt;
    dev_v99 v99 (
        .cpu_bus(cpu_bus),
        .clock_bus(clock_bus),
        .video_bus(video_bus_v99),
        .vram_bus(vram_bus_v99),
        .io_device(io_device[DEV_VDP_V99xx]),
        .data(v99_data),
        .interrupt(v99_interrupt),
        .border(msxConfig.border)
    );

    wire [7:0] rtc_data;
    dev_rtc dev_rtc
    (
        .cpu_bus(cpu_bus),
        .clock_bus(clock_bus),
        .io_device(io_device[DEV_RTC]),
        .rtc_time(rtc_time),
        .data(rtc_data)
    );

    wire [7:0] psg_data;
    wire signed [15:0] psg_sound;
    dev_psg dev_psg
    (
        .cpu_bus(cpu_bus),
        .clock_bus(clock_bus),
        .io_device(io_device[DEV_PSG]),
        .sound(psg_sound),
        .data(psg_data),
        .joy(joy),
        .tape_in(tape_in)
    );

    wire [7:0] ppi_data;
    dev_ppi dev_ppi
    (
        .cpu_bus(cpu_bus),
        .io_device(io_device[DEV_PPI]),
        .data(ppi_data),
        .kb_upload_memory(kb_upload_memory),
        .ps2_key(ps2_key),
        .slot_config(slot_config),
        .keybeep(keybeep)
    ); 
endmodule
