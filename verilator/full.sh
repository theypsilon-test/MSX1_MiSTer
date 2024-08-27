rm obj_dir/*
verilator \
-cc -exe --trace \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
-Wno-PINMISSING \
-Wno-WIDTHEXPAND \
-Wno-WIDTHTRUNC \
--converge-limit 6000 \
--top-module emu \
../rtl/package.sv \
../MSX1.sv \
./rtl/ddram.sv \
./rtl/hps_io.sv \
./rtl/jt2413.sv \
./rtl/jt49_bus.sv \
../rtl/peripheral/keyboard.sv \
./rtl/ltc2308_tape.sv \
./rtl/pll.sv \
./rtl/rtc.sv \
./rtl/scc_wave.sv \
./rtl/sd_card.sv \
./rtl/sdram.sv \
./rtl/spi_divmmc.sv \
./rtl/spram.sv \
./rtl/tape.sv \
./rtl/vdp.sv \
./rtl/video_freak.sv \
./rtl/video_mixer.sv \
./rtl/wd1793.sv \
./rtl/halnote.sv         \
./rtl/flash.sv         \
./rtl/mfrsd.sv         \
./rtl/konami.sv         \
./rtl/konami_scc.sv         \
./rtl/scc_sound.sv         \
./rtl/gamemaster2.sv         \
./rtl/opll.sv         \
./rtl/kanji.sv         \
./rtl/psg.sv         \
./rtl/fdc.sv         \
../rtl/peripheral/clock.sv \
../rtl/msx_config.sv \
../rtl/nvram_backup.sv \
../rtl/msx.sv \
../rtl/peripheral/jt8255.v \
../rtl/peripheral/slots/memory_upload.sv   \
../rtl/peripheral/slots/crc32.sv           \
../rtl/peripheral/slots/mapper_detect.sv   \
../rtl/peripheral/slots/msx_slots.sv       \
../rtl/peripheral/slots/msx2_ram_mapper.sv \
../rtl/peripheral/slots/ascii8.sv          \
../rtl/peripheral/slots/ascii16.sv         \
../rtl/peripheral/slots/reset_status.sv    \
../rtl/peripheral/slots/subslot.sv         \
../rtl/peripheral/slots/offset.sv            \
../rtl/peripheral/slots/mappers.sv         \
../rtl/peripheral/slots/devices.sv         \
../rtl/peripheral/slots/fm_pac.sv          \
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


#../rtl/peripheral/slots/fdc.sv             \
#../rtl/peripheral/slots/konami.sv          \
#../rtl/peripheral/slots/konami_scc.sv      \
#../rtl/peripheral/slots/mfrsd.sv           \
#../rtl/peripheral/slots/opll.sv            \
#../rtl/peripheral/slots/scc_sound.sv       \
#../rtl/peripheral/slots/flash.sv           \
#../rtl/peripheral/slots/gamemaster2.sv     \
#../rtl/peripheral/slots/psg.sv             \
#../rtl/peripheral/slots/kanji.sv           \
#../rtl/peripheral/slots/halnote.sv         \
#./rtl/keyboard.sv \
# --public-flat-rw --public-depth 3
# --public
# --savable
# -Wno-UNOPTFLAT \
#--public-flat-rw \
#--public \