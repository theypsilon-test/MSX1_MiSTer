verilator \
-cc -exe --trace \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
--converge-limit 6000 \
--top-module msx1 \
../rtl/package.sv \
./upload.sv \
./rtl/spram.sv \
./rtl/ddram.sv \
../rtl/peripheral/slots/memory_upload.sv \
../rtl/peripheral/slots/mapper_detect.sv \
../rtl/peripheral/slots/crc32.sv \
../rtl/msx_config.sv \


# --public-flat-rw --public-depth 3
# --public
# --savable
# -Wno-UNOPTFLAT \
#--public-flat-rw \
#--public \