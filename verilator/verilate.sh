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
./rtl/spram.sv \
./rtl/ddram.sv \
./rtl/pll.sv \
./rtl/msx.sv \
./rtl/spi_divmmc.sv \
./rtl/sd_card.sv \
./rtl/video_freak.sv \
./rtl/video_mixer.sv \
./rtl/ltc2308_tape.sv \
./rtl/sdram.sv \
./rtl/tape.sv \
./rtl/hps_io.sv \
../rtl/peripheral/clock.sv \
../rtl/peripheral/slots/memory_upload.sv \
../rtl/peripheral/slots/mapper_detect.sv \
../rtl/peripheral/slots/crc32.sv \
../rtl/msx_config.sv \
../rtl/nvram_backup.sv \


# --public-flat-rw --public-depth 3
# --public
# --savable
# -Wno-UNOPTFLAT \
#--public-flat-rw \
#--public \