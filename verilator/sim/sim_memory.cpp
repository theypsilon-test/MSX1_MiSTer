#include <iostream>
#include <string>
#include <list>

#include "sim_memory.h"
#include "sim_console.h"
#include "verilated.h"

#ifndef _MSC_VER
#else
#define WIN32
#endif

SimMemory::SimMemory(DebugConsole c)
{
	console = c;
}

char* SimMemory::AddRAM(SData* addr, CData* data, CData* q, CData* we, int size, std::string filename)
{
	SimMemoryRam ram(console);
	char* ret = NULL;
	if (!ret)
		return NULL;
	ram.LoadFile(filename);
	ram.MapSignals(addr, data, q, we);
	Rams.push_back(ram);
	return ret;
}

char* SimMemory::AddRAM(SData* addr, CData* data, CData* q, CData* we, int size)
{
	SimMemoryRam ram(console);
	char* ret = ram.AllocateMemory(size);
	if (!ram.AllocateMemory(size))
		return NULL;
	ram.MapSignals(addr, data, q, we);
	Rams.push_back(ram);
	return ret;
}

char* SimMemory::AddRAM(IData* addr, CData* data, CData* q, CData* we, int size, std::string filename)
{
	SimMemoryRam ram(console);
	char* ret = ram.AllocateMemory(size);
	if (!ret)
		return NULL;
	ram.LoadFile(filename);
	ram.MapSignals(addr, data, q, we);
	Rams.push_back(ram);
	return ret;
}

char* SimMemory::AddRAM(IData* addr, CData* data, CData* q, CData* we, int size)
{
	SimMemoryRam ram(console);
	char* ret = ram.AllocateMemory(size);
	if (!ret)
		return NULL;
	ram.MapSignals(addr, data, q, we);
	Rams.push_back(ram);
	return ret;
}

char* SimMemory::AddRAM(SData* addr_a, CData* data_a, CData* q_a, CData* we_a, SData* addr_b, CData* data_b, CData* q_b, CData* we_b, int size, std::string filename)
{
	SimMemoryRam ram(console);
	char* ret = ram.AllocateMemory(size);
	if (!ret)
		return NULL;
	ram.LoadFile(filename);
	ram.MapSignals(addr_a, data_a, q_a, we_a, addr_b, data_b, q_b, we_b);
	Rams.push_back(ram);
	return ret;
}

char* SimMemory::AddRAM(SData* addr_a, CData* data_a, CData* q_a, CData* we_a, SData* addr_b, CData* data_b, CData* q_b, CData* we_b, int size)
{
	SimMemoryRam ram(console);
	char* ret = ram.AllocateMemory(size);
	if (!ret)
		return NULL;
	ram.MapSignals(addr_a, data_a, q_a, we_a, addr_b, data_b, q_b, we_b);
	Rams.push_back(ram);
	return ret;
}

char* SimMemory::AddRAM(IData* addr_a, CData* data_a, CData* q_a, CData* we_a, IData* addr_b, CData* data_b, CData* q_b, CData* we_b, int size, std::string filename)
{
	SimMemoryRam ram(console);
	char* ret = ram.AllocateMemory(size);
	if (!ret)
		return NULL;
	ram.LoadFile(filename);
	ram.MapSignals(addr_a, data_a, q_a, we_a, addr_b, data_b, q_b, we_b);
	Rams.push_back(ram);
	return ret;
}

char* SimMemory::AddRAM(IData* addr_a, CData* data_a, CData* q_a, CData* we_a, IData* addr_b, CData* data_b, CData* q_b, CData* we_b, int size)
{
	SimMemoryRam ram(console);
	char* ret = ram.AllocateMemory(size);
	if (!ret)
		return NULL;
	ram.MapSignals(addr_a, data_a, q_a, we_a, addr_b, data_b, q_b, we_b);
	Rams.push_back(ram);
	return ret;
}

SimMemory::~SimMemory()
{

}

void SimMemory::BeforeEval(void)
{
	for (auto it = Rams.begin(); it != Rams.end(); ++it) {
		it->BeforeEval();
	}
}

void SimMemory::AfterEval(void)
{
	for (auto it = Rams.begin(); it != Rams.end(); ++it) {
		it->AfterEval();
	}
}

SimMemoryRam::SimMemoryRam(DebugConsole c)
{
	console = c;
	mem_size = 0;
	mem = NULL;
	addr = NULL;
	addr32 = NULL;
	data = NULL;
	q = NULL;
	we = NULL;
	addr_b = NULL;
	addr32_b = NULL;
	data_b = NULL;
	q_b = NULL;
	we_b = NULL;
}

char * SimMemoryRam::AllocateMemory(int size) {
	mem = (char*)malloc(size);
	if (!mem) {
		console.AddLog("Memory not allocate: %d", size);
		return NULL;
	}
	
	mem_size = size;
	memset(mem, 0, mem_size);
	return mem;
}

void SimMemoryRam::FreeMemory(void)
{
	if (mem == NULL)
		return;

	free(mem);
}

bool SimMemoryRam::LoadFile(std::string filename) {
	if (mem == NULL)
		return false;
	
	FILE* mem_file = fopen(filename.c_str(), "rb");
	if (!mem_file) {
		console.AddLog("Cannot open file for download %s\n", filename.c_str());
		return false;
	}

	fread(mem, 1, mem_size, mem_file);
	fclose(mem_file);
	
	return true;
}

SimMemoryRam::~SimMemoryRam() {
	//FreeMemory();
}

void SimMemoryRam::MapSignals(SData* addr, CData* data, CData* q, CData* we) {
	this->addr = addr;
	this->data = data;
	this->q = q;
	this->we = we;
}

void SimMemoryRam::MapSignals(IData* addr, CData* data, CData* q, CData* we) {
	this->addr32 = addr;
	this->data = data;
	this->q = q;
	this->we = we;
}

void SimMemoryRam::MapSignals(SData* addr_a, CData* data_a, CData* q_a, CData* we_a, SData* addr_b, CData* data_b, CData* q_b, CData* we_b) {
	this->addr = addr_a;
	this->data = data_a;
	this->q = q_a;
	this->we = we_a;
	this->addr_b = addr_b;
	this->data_b = data_b;
	this->q_b = q_b;
	this->we_b = we_b;
}

void SimMemoryRam::MapSignals(IData* addr_a, CData* data_a, CData* q_a, CData* we_a, IData* addr_b, CData* data_b, CData* q_b, CData* we_b) {
	this->addr32 = addr_a;
	this->data = data_a;
	this->q = q_a;
	this->we = we_a;
	this->addr32_b = addr_b;
	this->data_b = data_b;
	this->q_b = q_b;
	this->we_b = we_b;
}

void SimMemoryRam::BeforeEval(void) {
	if (q)
	{
		*q = 0xFF;
		if (addr) {
			if (mem && *addr <= mem_size)
			{
				*q = mem[*addr];
			}
		}
		if (addr32) {
			if (mem && *addr32 <= mem_size)
			{
				*q = mem[*addr32];
			}
		}
	}
	
	if (q_b)
	{
		*q_b = 0xFF;
		if (addr) {
			if (mem && *addr_b <= mem_size)
			{
				*q_b = mem[*addr_b];
			}
		}
		if (addr32_b) {
			if (mem && *addr32_b <= mem_size)
			{
				*q_b = mem[*addr32_b];
			}
		}
	}
}

void SimMemoryRam::AfterEval(void) {
	uint32_t addr = 0;
	if (this->addr != NULL && *this->addr <= mem_size && *we == 1) {
		mem[*this->addr] = *data;
	}
	else if (this->addr32 != NULL && *this->addr32 <= mem_size && *we == 1) {
		mem[*this->addr32] = *data;
	}

	if (this->addr_b != NULL && *this->addr_b <= mem_size && *we_b == 1) {
		mem[*this->addr_b] = *data_b;
	}
	else if (this->addr32_b != NULL && *this->addr32_b <= mem_size && *we_b == 1) {
		mem[*this->addr32_b] = *data_b;
	}
}