rm obj_dir/*
verilator \
-cc -exe --trace \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
-Wno-PINMISSING \
--trace \
--timescale-override 1ns/1ps \
--converge-limit 6000 \
--timescale-override 1ns/1ps \
--top-module top \
./rtl/top.sv \
../rtl/lib/sftgen.sv  \
../rtl/peripheral/FDD/fdd.sv \
../rtl/peripheral/FDD/motor.sv \
../rtl/peripheral/FDD/ready.sv \
../rtl/peripheral/FDD/track.sv \
../rtl/peripheral/FDD/transmit.sv \
../rtl/peripheral/FDD/track_buffer.sv \
../rtl/peripheral/wd1793.sv

#../rtl/peripheral/FDD/FDDtimming.sv
#../rtl/peripheral/FDC/TC8566AF/tc8566af.sv \
#../rtl/peripheral/FDC/TC8566AF/signext.sv \
#../rtl/peripheral/FDC/TC8566AF/crcgen.sv \
#../rtl/peripheral/FDC/TC8566AF/clktx.sv \
#../rtl/peripheral/FDC/TC8566AF/digifilter.sv \
#../rtl/peripheral/FDC/TC8566AF/nrdet.sv   \
#../rtl/peripheral/FDC/TC8566AF/mfmmod.sv  \
#../rtl/peripheral/FDC/TC8566AF/mfmdem.sv  \
#../rtl/peripheral/FDC/TC8566AF/fmmod.sv  \
#../rtl/peripheral/FDC/TC8566AF/fmdem.sv  \
#../rtl/peripheral/FDC/TC8566AF/sftdiv.sv  \
#../rtl/peripheral/FDC/TC8566AF/headseek.sv  \
#../rtl/peripheral/FDC/TC8566AF/seekcont.sv  \
