#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <vector>
#include <string>

enum RecordType : uint8_t
{
	CPU_OPCODE,
};

struct CPUInst
{
	uint16_t AF;
	uint16_t BC;
	uint16_t DE;
	uint16_t HL;
	uint16_t AF2;
	uint16_t BC2;
	uint16_t DE2;
	uint16_t HL2;
	uint16_t IX;
	uint16_t IY;
	uint16_t PC;
	uint16_t SP;
	uint16_t start_PC;
	uint8_t opcodes;
	uint8_t opcode[4];
};

struct CPUMemRead
{
	uint16_t address;
	uint16_t value;
};

struct CPUMemWrite
{
	uint8_t size;
	uint16_t address;
	uint16_t value;
};

struct MCUMem
{
	uint16_t address;
	uint8_t value;
};

struct CPUIP
{
	uint8_t opcode;
	uint32_t address;
};

struct MCUROM
{
	uint16_t address;
};

struct TraceRecord
{
	RecordType type;
	union
	{
		CPUInst cpu_inst;
		//CPUMemRead cpu_read;
		//CPUMemWrite cpu_write;
		//MCUMem mcu_mem;
		//CPUIP cpu_ip;
		//MCUROM mcu_rom;
	};
};

std::vector<TraceRecord> read_trace(const std::string& filename);