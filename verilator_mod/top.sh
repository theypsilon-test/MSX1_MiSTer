rm obj_dir/*
verilator \
-cc -exe --trace \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
-Wno-PINMISSING \
--converge-limit 6000 \
--timescale-override 1ns/1ps \
--top-module top \
./rtl/top.sv \
../rtl/peripheral/FDC/TC8566AF/tc8566af.sv \
../rtl/peripheral/FDC/TC8566AF/signext.sv \
../rtl/peripheral/FDC/TC8566AF/crcgen.sv \
../rtl/peripheral/FDC/TC8566AF/clktx.sv \
../rtl/peripheral/FDC/TC8566AF/digifilter.sv \
../rtl/peripheral/FDC/TC8566AF/nrdet.sv   \
../rtl/peripheral/FDC/TC8566AF/mfmmod.sv  \
../rtl/peripheral/FDC/TC8566AF/mfmdem.sv  \
../rtl/peripheral/FDC/TC8566AF/fmmod.sv  \
../rtl/peripheral/FDC/TC8566AF/fmdem.sv  \
../rtl/peripheral/FDC/TC8566AF/sftgen.sv  \
../rtl/peripheral/FDC/TC8566AF/sftdiv.sv  \
../rtl/peripheral/FDC/TC8566AF/headseek.sv  \
../rtl/peripheral/FDC/TC8566AF/seekcont.sv  \
