	#pragma once
#include <verilated.h>

enum Mapper : uint8_t
{
	MAPPER_NONE, 
	MAPPER_OFFSET,
	MAPPER_ASCII16,
	MAPPER_RTYPE,
	MAPPER_ASCII8,
	MAPPER_KOEI,
	MAPPER_WIZARDY,
	MAPPER_KONAMI,
	MAPPER_FMPAC,
	MAPPER_GM2,
	MAPPER_VY0010,
	MAPPER_KONAMI_SCC,
	MAPPER_MSX2,
	MAPPER_GENERIC16KB,
	MAPPER_CROSS_BLAIM,
	MAPPER_GENERIC8KB,
	MAPPER_HARRY_FOX,
	MAPPER_ZEMINA_80,
	MAPPER_ZEMINA_90,
	MAPPER_KONAMI_SCC_PLUS,
	MAPPER_MFRSD3,
	MAPPER_MFRSD2,
	MAPPER_MFRSD1,
	MAPPER_MFRSD0,
	MAPPER_UNUSED
};

enum Device : uint8_t
{
	DEV_NONE, 
	DEV_OPL3, 
	DEV_SCC, 
	DEV_VY0010, 
	DEV_MSX2_RAM, 
	DEV_ZEMINA90
};

void setBlock(uint8_t block, Mapper mapper, Device device, uint8_t device_num, uint8_t cart_num, uint8_t ref_ram, uint8_t offset_ram, uint8_t ref_sram);
void setBlock(uint8_t slot, uint8_t subslot, Mapper mapper, Device device, uint8_t device_num, uint8_t cart_num, uint8_t ref_ram, uint8_t offset_ram, uint8_t ref_sram);
void setBlock(uint8_t slot, uint8_t subslot, uint8_t block, Mapper mapper, Device device, uint8_t device_num, uint8_t cart_num, uint8_t ref_ram, uint8_t offset_ram, uint8_t ref_sram);
uint32_t setRam(uint8_t ref, uint32_t addr, uint32_t size, bool ro);
void setSram(uint8_t ref, uint32_t addr, uint16_t size);
void setDevice(uint8_t id, uint8_t mask, uint8_t port, uint8_t num, uint8_t param, Device device);
void setExpander(uint8_t slot, uint8_t en, uint8_t wo);

