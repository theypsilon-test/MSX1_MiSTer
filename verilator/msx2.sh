rm obj_dir/*
verilator \
-cc -exe --trace \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
-I../rtl/sound/jtopl/hdl/ \
-I../rtl/sound/jt49/hdl/ \
-I../rtl/video/VDPv/ \
-Wno-PINMISSING \
--converge-limit 6000 \
--timescale-override 1ns/1ps \
--top-module emu \
../rtl/package.sv \
\
./rtl/pll.sv \
../rtl/peripheral/rtc.sv \
./rtl/spram.sv \
./rtl/ddram.sv \
./rtl/hps_io.sv \
./rtl/sdram.sv \
./rtl/video_freak.sv \
./rtl/video_mixer.sv \
./rtl/ltc2308_tape.sv \
\
../MSX1.sv \
../rtl/peripheral/clock.sv \
../rtl/msx_config.sv \
../rtl/msx.sv \
../rtl/cpu/tv80_alu.sv \
../rtl/cpu/tv80.sv \
../rtl/cpu/tv80_mcode.sv \
../rtl/cpu/tv80_reg.sv \
../rtl/cpu/tv80a.sv \
../rtl/peripheral/jt8255.v \
../rtl/peripheral/keyboard.sv \
../rtl/peripheral/slots/memory_upload.sv   \
../rtl/peripheral/slots/crc32.sv           \
../rtl/peripheral/slots/msx_slots.sv       \
../rtl/peripheral/slots/subslot.sv         \
../rtl/peripheral/slots/mappers.sv         \
../rtl/peripheral/slots/devices.sv         \
../rtl/peripheral/mapper/offset.sv         \
../rtl/peripheral/mapper/none.sv           \
\
./rtl/video/vdp18v/vdp18_pack-p.sv        \
./rtl/video/vdp18v/vdp18_col_pack-p.sv    \
./rtl/video/vdp18v/vdp18_core.sv          \
\
../rtl/video/VDPv/vdp_package.sv           \
../rtl/video/VDPv/vdp.sv                   \
../rtl/video/VDPv/vdp_colordec.sv          \
../rtl/video/VDPv/vdp_command.sv           \
../rtl/video/VDPv/vdp_graphic123m.sv       \
../rtl/video/VDPv/vdp_graphic4567.sv       \
../rtl/video/VDPv/vdp_hvcounter.sv         \
../rtl/video/VDPv/vdp_interrupt.sv         \
../rtl/video/VDPv/vdp_ntsc_pal.sv          \
../rtl/video/VDPv/vdp_register.sv          \
../rtl/video/VDPv/vdp_spinforam.sv         \
../rtl/video/VDPv/vdp_sprite.sv            \
../rtl/video/VDPv/vdp_ssg.sv               \
../rtl/video/VDPv/vdp_text12.sv            \
../rtl/video/VDPv/vdp_wait_control.sv      \
../rtl/video/VDPv/vdp_ram.sv               \
\
./rtl/peripheral/mapper/crossBlaim.sv     \
./rtl/peripheral/mapper/generic8k.sv        \
./rtl/peripheral/mapper/generic16k.sv        \
./rtl/peripheral/mapper/harryFox.sv       \
./rtl/peripheral/mapper/zemina80.sv      \
./rtl/peripheral/mapper/zemina90.sv      \
./rtl/peripheral/mapper/fm_pac.sv         \
../rtl/peripheral/mapper/ascii8.sv         \
./rtl/peripheral/mapper/ascii16.sv        \
./rtl/peripheral/mapper/konami.sv         \
./rtl/peripheral/mapper/konami_scc.sv     \
./rtl/peripheral/mapper/gamemaster2.sv    \
../rtl/peripheral/mapper/msx2_ram.sv       \
./rtl/peripheral/mapper/mfrsd.sv          \
./rtl/peripheral/dev/latch_port.sv        \
../rtl/peripheral/dev/reset_status.sv      \
../rtl/peripheral/dev/opl3.sv              \
./rtl/peripheral/dev/scc.sv               \
./rtl/sound/scc_wave.sv                   \
./rtl/peripheral/dev/wd2793.sv            \
./rtl/peripheral/dev/kanji.sv             \
../rtl/peripheral/dev/msx2_ram.sv         \
./rtl/peripheral/mapper/national.sv       \
./rtl/peripheral/mapper/eseRam.sv         \
./rtl/peripheral/mapper/megaram.sv          \
./rtl/peripheral/dev/ocm.sv               \
./rtl/peripheral/dev/tms.sv               \
../rtl/peripheral/dev/v99.sv              \
../rtl/peripheral/dev/rtc.sv              \
../rtl/peripheral/dev/psg.sv              \
../rtl/peripheral/dev/ppi.sv              \
./rtl/wd1793.sv                           \
\
./rtl/sound/jt49/hdl/jt49_bus.sv          \
./rtl/peripheral/spi_divmmc.sv            \
./rtl/peripheral/flash.sv                 \
./sys/sd_card.sv                          \
./rtl/tape.sv                             \
./rtl/nvram_backup.sv                     \
\
../rtl/video/debugOverlay/bram.sv \
../rtl/video/debugOverlay/overlay.sv \