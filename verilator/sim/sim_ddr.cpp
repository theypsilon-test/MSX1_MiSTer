#include <iostream>
#include <string>
#include <bit>

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
	dout64 = NULL;
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

static int last_rd = 0;
static int last_wr = 0;
static int last_addr = 0;
static int do_ready;

void SimDDR::BeforeEval(void) {
	if (ready == NULL || addr == NULL) return;

	if (*ready == 1) {
		if (last_rd == 0 && *rd == 1) {
			if (*addr < mem_size) {
				do_ready = 0;
				mem_wait_cnt = 0;
				if ((mem_addr >> 3) != (*addr >> 3)) {
					mem_wait_cnt = 8;

					uint32_t tmp_addr = *addr & ~((uint32_t)7);
					*dout64 = *reinterpret_cast<uint64_t*>(mem + tmp_addr);
					//*dout64 = std::byteswap(*reinterpret_cast<uint64_t*>(mem + tmp_addr));
				}
				mem_addr = *addr;
				mem_q = mem[mem_addr];
			}
			else {
				mem_q = mem[mem_addr];
				mem_wait_cnt = 0;
			}
		}
	}

	if (mem_size > 0) {
		if (mem_wait_cnt == 0) {
			*dout = mem_q;
			do_ready = 1;
		}
		else {
			mem_wait_cnt--;
		}
	}

	last_rd = *rd;
}



void SimDDR::AfterEval(void) {
	if (ready == NULL || addr == NULL) return;

	*ready = do_ready;
}