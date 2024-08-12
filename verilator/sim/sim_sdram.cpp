#include <iostream>
#include <string>

#include "sim_sdram.h"
#include "sim_console.h"
#include "verilated.h"

#ifndef _MSC_VER
#else
#define WIN32
#endif

SimSDRAM::SimSDRAM(DebugConsole c)
{
	console = c;
	mem_size = 0;
	mem = NULL;
	addr = NULL;
	data = NULL;
	q = NULL;
	we = NULL;
	rd = NULL;
	ready = NULL;
	size = NULL;
	mem_addr = 0;
	mem_q = 0xff;
	mem_wait_cnt = 0;
}

SimSDRAM::~SimSDRAM()
{
	FreeMemory();
}


bool SimSDRAM::AllocateMemory(int size) {
	mem = (char*)malloc(size);
	if (!mem) {
		console.AddLog("SDRAM memory not allocate: %d", size);
		return false;
	}
	
	mem_size = size;
	memset(mem, 0, mem_size);
	return true;
}

void SimSDRAM::FreeMemory(void)
{
	if (mem == NULL)
		return;

	free(mem);
}

void SimSDRAM::Initialise(int size) {
	
	this->AllocateMemory(size);

	//0 - none, 1 - 32MB, 2 - 64MB, 3 - 128MB
	if (mem_size == 0)
		*this->size = 0;
	else if (mem_size <= 0x400000)
		*this->size = 1;
	else if (mem_size <= 0x800000)
		*this->size = 2;
	else if (mem_size <= 0x1000000)
		*this->size = 3;
	else 
		*this->size = 0;
	*ready = mem_size > 0 ? 1 : 0;
	mem_wait_cnt = 1;
}

void SimSDRAM::BeforeEval(void) {
}

void SimSDRAM::AfterEval(void) {
	if (ready == NULL) return;

	if (*ready == 1) {
		if (addr != NULL) {
			if (*addr < mem_size) {
				if (*we == 1) {
					mem_wait_cnt = 4;
					*ready = 0;
					mem_q = *data;
					mem_addr = *addr;
					mem[mem_addr] = *data;
				}
				else {
					if (*rd == 1 && *addr != mem_addr) {
						mem_wait_cnt = 4;
						*ready = 0;
						mem_addr = *addr;
						mem_q = mem[mem_addr];
					}
				}
			}
			else {
				mem_q = 0xFF;
				mem_addr = *addr;
				mem_wait_cnt = 1;
			}
		}
	}
	else {
		if (mem_size > 0) {
			mem_wait_cnt--;
			if (mem_wait_cnt == 0) {
				*q = mem_q;
				*ready = 1;
			}
		}
	}
}

char* SimSDRAM::GetMem(void)
{
	return mem;
}