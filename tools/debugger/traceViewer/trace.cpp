#include "trace.h"
#include <algorithm>

std::vector<TraceRecord> read_trace(const std::string& filename)
{
	FILE* fp = fopen(filename.c_str(), "rb");

	fseek(fp, 0, SEEK_END);
	uint64_t size = _ftelli64(fp);
	fseek(fp, 0, SEEK_SET);

	uint16_t cs = 0;

	uint8_t work[32];

	std::vector<TraceRecord> out;
	out.reserve(size / 32);
	
	while (true)
	{
		int r = fread(work, 1, 32, fp);
		if (r != 32) break;

		uint8_t type = work[31] & 3;
		TraceRecord record;

		switch (type)
		{

		case CPU_OPCODE:
			record.type = CPU_OPCODE;
			record.cpu_inst.opcodes = (work[31] >> 2) & 3;
			std::reverse_copy(work + 24, work + 28, record.cpu_inst.opcode);
			record.cpu_inst.start_PC = *reinterpret_cast<uint16_t*>(work + 28);
			record.cpu_inst.AF       = *reinterpret_cast<uint16_t*>(work + 22);
			record.cpu_inst.BC       = *reinterpret_cast<uint16_t*>(work + 20);
			record.cpu_inst.DE       = *reinterpret_cast<uint16_t*>(work + 18);
			record.cpu_inst.HL       = *reinterpret_cast<uint16_t*>(work + 16);
			record.cpu_inst.AF2      = *reinterpret_cast<uint16_t*>(work + 14);
			record.cpu_inst.BC2      = *reinterpret_cast<uint16_t*>(work + 12);
			record.cpu_inst.DE2      = *reinterpret_cast<uint16_t*>(work + 10);
			record.cpu_inst.HL2      = *reinterpret_cast<uint16_t*>(work + 8);
			record.cpu_inst.IX       = *reinterpret_cast<uint16_t*>(work + 6);
			record.cpu_inst.IY       = *reinterpret_cast<uint16_t*>(work + 4);
			record.cpu_inst.PC       = *reinterpret_cast<uint16_t*>(work + 0);
			record.cpu_inst.SP       = *reinterpret_cast<uint16_t*>(work + 2);
			out.push_back(record);
			break;
		}
	}

	fclose(fp);

	return out;
}