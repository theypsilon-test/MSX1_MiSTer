#include <iostream>
#include <string>

#include "sim_ddr.h"
#include "sim_console.h"
#include "verilated.h"

#ifndef _MSC_VER
#else
#define WIN32
#endif

SimDDR::SimDDR(DebugConsole c)
{
	console = c;
	mem_size = 0;
	mem_wait_cnt = 0;
	mem = NULL;
	addr = NULL;
	din = NULL;
	dout = NULL;
	we = NULL;
	rd = NULL;
	ready = NULL;
	mem_addr = 0xFFFFFFF;
	mem_q = 0xFF;

}

SimDDR::~SimDDR()
{
//	FreeMemory();
}


bool SimDDR::AllocateMemory(int size) {
	mem = (char*)malloc(size);
	if (!mem) {
		console.AddLog("SDRAM memory not allocate: %d", size);
		return false;
	}

	mem_size = size;
	memset(mem, 0, mem_size);
	return true;
}

void SimDDR::Initialise(int size) {
	this->AllocateMemory(size);
}

void SimDDR::writeData(int addr, int value) {
	if (addr >= 0x30000000) {
		int cur_addr = addr - 0x30000000;
		if (mem_size >= cur_addr) {
			mem[cur_addr] = value;
		}
	}
}

char* SimDDR::GetMem(void)
{
	return mem;
}

void SimDDR::BeforeEval(void) {
}

void SimDDR::AfterEval(void) {
	if (ready == NULL) return;

	if (*ready == 1) {
		if (addr != NULL) {
			if (*rd == 1) {
				if (*addr < mem_size) {
					*ready = 0;
					mem_wait_cnt = 1;
					if ((mem_addr >> 3) != (*addr >> 3)) {
						mem_wait_cnt = 8;
					}
					mem_addr = *addr;
					mem_q = mem[mem_addr];
				}
				else {
					mem_q = mem[mem_addr];
					mem_wait_cnt = 1;
				}
			}
		}
	}
	if (mem_size > 0) {		
		if (mem_wait_cnt == 0) {
			*dout = mem_q;
			*ready = 1;
		}
		else {
			mem_wait_cnt--;
		}
	}
}