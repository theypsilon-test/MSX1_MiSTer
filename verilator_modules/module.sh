rm obj_dir/*
verilator \
-cc -exe --trace \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
-Wno-PINMISSING \
--converge-limit 6000 \
--timescale-override 1ns/1ps \
--top-module modules \
../rtl/package.sv \
./rtl/modules.sv \
./rtl/cpu.sv \
./rtl/sdram.sv \
../rtl/peripheral/slots/subslot.sv \
../rtl/peripheral/clock.sv \
../rtl/peripheral/slots/msx_slots.sv       \
../rtl/peripheral/slots/mappers.sv        \
../rtl/peripheral/slots/devices.sv         \
../rtl/peripheral/mapper/offset.sv         \
../rtl/peripheral/mapper/none.sv           \
\
../rtl/peripheral/flash.sv  \
./rtl/peripheral/mapper/crossBlaim.sv     \
../rtl/peripheral/mapper/generic8k.sv        \
../rtl/peripheral/mapper/generic16k.sv        \
./rtl/peripheral/mapper/harryFox.sv       \
./rtl/peripheral/mapper/zemina80.sv       \
./rtl/peripheral/mapper/zemina90.sv       \
./rtl/peripheral/mapper/fm_pac.sv         \
./rtl/peripheral/mapper/ascii8.sv         \
./rtl/peripheral/mapper/ascii16.sv        \
./rtl/peripheral/mapper/konami.sv         \
./rtl/peripheral/mapper/konami_scc.sv     \
./rtl/peripheral/mapper/gamemaster2.sv    \
./rtl/peripheral/mapper/msx2_ram.sv       \
./rtl/peripheral/mapper/mfrsd.sv          \
../rtl/peripheral/mapper/national.sv      \
../rtl/peripheral/dev/latch_port.sv          \
./rtl/peripheral/dev/opl3.sv              \
./rtl/peripheral/dev/scc.sv               \
../rtl/peripheral/dev/kanji.sv           \
./rtl/sound/scc_wave.sv                   \
../rtl/peripheral/dev/wd2793.sv           \
./rtl/peripheral/wd1793.sv                           \

#./rtl/peripheral/dev/zemina90.sv          \
#./rtl/peripheral/dev/opl3.sv              \
#./rtl/peripheral/dev/scc.sv               \
#./rtl/sound/scc_wave.sv                   \
#./rtl/peripheral/dev/vy-0010.sv           \
#./rtl/wd1793.sv                           \
