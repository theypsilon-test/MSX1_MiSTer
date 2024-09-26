rm obj_dir/*
verilator \
-cc -exe --trace \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
-Wno-PINMISSING \
--converge-limit 6000 \
--top-module emu \
../rtl/package.sv \
../MSX1.sv \
../rtl/peripheral/clock.sv \
../rtl/msx_config.sv \
../rtl/nvram_backup.sv \
../rtl/msx.sv \
../rtl/peripheral/jt8255.v \
../rtl/peripheral/keyboard.sv \
../rtl/peripheral/slots/memory_upload.sv   \
../rtl/peripheral/slots/crc32.sv           \
../rtl/peripheral/slots/msx_slots.sv       \
../rtl/peripheral/slots/reset_status.sv    \
../rtl/peripheral/slots/subslot.sv         \
../rtl/peripheral/slots/offset.sv          \
../rtl/peripheral/slots/mappers.sv         \
../rtl/peripheral/slots/devices.sv         \
../rtl/peripheral/slots/msx2_ram.sv        \
../rtl/peripheral/dev/io_decoder.sv        \
../rtl/peripheral/dev/vy-0010.sv           \
../rtl/peripheral/dev/scc.sv               \
../rtl/peripheral/dev/msx2_ram.sv   \
../rtl/peripheral/slots/konami_scc.sv      \
../rtl/peripheral/rtc.sv      \
../rtl/cpu/tv80_alu.v \
../rtl/cpu/tv80_core.v \
../rtl/cpu/tv80_mcode.v \
../rtl/cpu/tv80_reg.v \
../rtl/cpu/tv80n.v \
../rtl/sound/scc_wave.sv                \
../rtl/video/VDPv/vdp_package.sv       \
../rtl/video/VDPv/vdp.sv     \
../rtl/video/VDPv/vdp_colordec.sv \
../rtl/video/VDPv/vdp_command.sv \
../rtl/video/VDPv/vdp_doublebuf.sv \
../rtl/video/VDPv/vdp_graphic123m.sv \
../rtl/video/VDPv/vdp_graphic4567.sv \
../rtl/video/VDPv/vdp_hvcounter.sv \
../rtl/video/VDPv/vdp_interrupt.sv \
../rtl/video/VDPv/vdp_linebuf.sv \
../rtl/video/VDPv/vdp_ntsc_pal.sv \
../rtl/video/VDPv/vdp_register.sv \
../rtl/video/VDPv/vdp_spinforam.sv \
../rtl/video/VDPv/vdp_sprite.sv \
../rtl/video/VDPv/vdp_ssg.sv     \
../rtl/video/VDPv/vdp_text12.sv \
../rtl/video/VDPv/vdp_vga.sv \
../rtl/video/VDPv/vdp_wait_control.sv \
../rtl/video/VDPv/vdp_ram.sv \
./rtl/vdp18_core.sv \
./rtl/ddram.sv \
./rtl/hps_io.sv \
./rtl/jt2413.sv \
./rtl/jt49_bus.sv \
./rtl/ltc2308_tape.sv \
./rtl/pll.sv \
./rtl/sd_card.sv \
./rtl/sdram.sv \
./rtl/spi_divmmc.sv \
./rtl/spram.sv \
./rtl/tape.sv \
./rtl/video_freak.sv \
./rtl/video_mixer.sv \
./rtl/wd1793.sv \
./rtl/halnote.sv         \
./rtl/flash.sv         \
./rtl/mfrsd.sv         \
./rtl/opll.sv         \
./rtl/opl3.sv         \
./rtl/kanji.sv         \
./rtl/psg.sv         \
./rtl/fdc.sv        \
./rtl/ascii16.sv \
./rtl/fm_pac.sv \
./rtl/konami.sv \
./rtl/ascii8.sv \
./rtl/gamemaster2.sv \


#../rtl/sound/jt49/hdl/jt49_bus.v \
#../rtl/sound/jt49/hdl/jt49.v \
#../rtl/sound/jt49/hdl/jt49_div.v \
#../rtl/sound/jt49/hdl/jt49_eg.v \
#../rtl/sound/jt49/hdl/jt49_exp.v \
#../rtl/sound/jt49/hdl/jt49_noise.v \
#../rtl/sound/jt49/hdl/jt49_cen.v \

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
#../rtl/peripheral/slots/gamemaster2.sv     \
#./rtl/keyboard.sv \
#./rtl/konami.sv  
#./rtl/gamemaster2.sv               \
# --public-flat-rw --public-depth 3
# --public
# --savable
# -Wno-UNOPTFLAT \
#--public-flat-rw \
#--public \

#-Wno-PINMISSING \
#-Wno-WIDTHEXPAND \
#-Wno-WIDTHTRUNC \
#-Wno-WIDTHTRUNC \