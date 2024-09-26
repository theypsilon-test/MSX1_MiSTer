rm obj_dir/*
verilator \
-cc -exe --trace \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
-I../rtl/sound/jtopl/hdl/ \
-I../rtl/sound/jt49/hdl/ \
-Wno-PINMISSING \
--converge-limit 6000 \
--top-module emu \
../rtl/package.sv \
../MSX1.sv \
./rtl/pll.sv \
./rtl/rtc.sv \
./rtl/spram.sv \
./rtl/vdp.sv \
./rtl/ddram.sv \
./rtl/hps_io.sv \
./rtl/sdram.sv \
./rtl/video_freak.sv \
./rtl/video_mixer.sv \
./rtl/ltc2308_tape.sv \
../rtl/peripheral/clock.sv \
../rtl/msx_config.sv \
../rtl/msx.sv \
../rtl/cpu/tv80_alu.v \
../rtl/cpu/tv80_core.v \
../rtl/cpu/tv80_mcode.v \
../rtl/cpu/tv80_reg.v \
../rtl/cpu/tv80n.v \
../rtl/video/vdp18v/vdp18_pack-p.sv     \
../rtl/video/vdp18v/vdp18_col_pack-p.sv \
../rtl/video/vdp18v/vdp18_addr_mux.sv   \
../rtl/video/vdp18v/vdp18_clk_gen.sv    \
../rtl/video/vdp18v/vdp18_col_mux.sv    \
../rtl/video/vdp18v/vdp18_core.sv       \
../rtl/video/vdp18v/vdp18_cpuio.sv      \
../rtl/video/vdp18v/vdp18_ctrl.sv       \
../rtl/video/vdp18v/vdp18_hor_vert.sv   \
../rtl/video/vdp18v/vdp18_pattern.sv    \
../rtl/video/vdp18v/vdp18_sprite.sv     \
../rtl/peripheral/jt8255.v \
../rtl/peripheral/keyboard.sv \
../rtl/peripheral/dev/io_decoder.sv        \
../rtl/peripheral/slots/memory_upload.sv   \
../rtl/peripheral/slots/crc32.sv           \
../rtl/peripheral/slots/msx_slots.sv       \
../rtl/peripheral/slots/subslot.sv         \
../rtl/peripheral/slots/offset.sv          \
../rtl/peripheral/slots/mappers.sv         \
../rtl/peripheral/slots/devices.sv         \
./rtl/ascii8.sv \
./rtl/ascii16.sv \
./rtl/konami.sv \
./rtl/konami_scc.sv \
./rtl/gamemaster2.sv \
../rtl/peripheral/slots/fm_pac.sv          \
./rtl/msx2_ram.sv \
./rtl/opl3.sv \
./rtl/scc.sv \
./rtl/vy-0010.sv     \
./rtl/jt49_bus.sv \
./rtl/spi_divmmc.sv \
./rtl/sd_card.sv \
./rtl/tape.sv \
./rtl/nvram_backup.sv \


#../rtl/sound/jt49/hdl/jt49_bus.v \
#./rtl/jt49_bus.sv \

#../rtl/peripheral/dev/scc.sv               \
#./rtl/ascii8.sv \
#../rtl/peripheral/slots/ascii8.sv          \

#../rtl/peripheral/slots/ascii16.sv         \
#./rtl/ascii16.sv \

#../rtl/peripheral/slots/konami.sv          \
#./rtl/konami.sv \

#../rtl/peripheral/slots/konami_scc.sv      \
#./rtl/konami_scc.sv \

#../rtl/peripheral/slots/gamemaster2.sv     \
#./rtl/gamemaster2.sv \

#../rtl/peripheral/slots/fm_pac.sv          \
#./rtl/fm_pac.sv \

#../rtl/peripheral/slots/msx2_ram.sv        \
#../rtl/peripheral/dev/msx2_ram.sv   \
#./rtl/msx2_ram.sv

#../rtl/peripheral/dev/opl3.sv     \
#./rtl/opl3.sv \

#../rtl/peripheral/dev/scc.sv               \
#../rtl/sound/scc_wave.sv \
#./rtl/scc.sv \

#../rtl/peripheral/dev/vy-0010.sv     \
#../rtl/peripheral/wd1793.sv \
#./rtl/vy-0010.sv     \

#../rtl/peripheral/spi_divmmc.sv \
#../sys/sd_card.sv \
#./rtl/spi_divmmc.sv \
#./rtl/sd_card.sv \

#../rtl/tape.sv \
#./rtl/tape.sv \

#../rtl/nvram_backup.sv \
#./rtl/nvram_backup.sv \
