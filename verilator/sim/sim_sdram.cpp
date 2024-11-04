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


	for (int i = 0; i <= 2; i++)
	{
		channels[i].rq = false;
		channels[i].req_last = false;
		channels_rtl[i].ch_addr = NULL;
		channels_rtl[i].ch_din = NULL;
		channels_rtl[i].ch_done = NULL;
		channels_rtl[i].ch_dout = NULL;
		channels_rtl[i].ch_ready = NULL;
		channels_rtl[i].ch_req = NULL;
		channels_rtl[i].ch_rnw = NULL;
	}
	mem_addr = 0;
	mem_wait_cnt = 0;
	mem_ready = true;
	mem_curr_rq = 0;
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
	for (int i = 0; i <= 2; i++)
	{
		if (channels_rtl[i].ch_ready) {
			*channels_rtl[i].ch_ready = 1;
		}
	}
}

int SimSDRAM::getHPSsize(void) {
	//0 - none, 1 - 32MB, 2 - 64MB, 3 - 128MB
	
	if (mem_size == 0)
		return 0;
	else if (mem_size <= 0x400000)
		return 0x8001;
	else if (mem_size <= 0x800000)
		return 0x8002;
	else if (mem_size <= 0x1000000)
		return 0x8003;
	
	return 0;
}

void SimSDRAM::BeforeEval(void) {
}

void SimSDRAM::AfterEval(void) {
	for (int i = 0; i <= 2; i++)
	{
		if (channels_rtl[i].ch_req) {
			if (channels_rtl[i].ch_req && *channels_rtl[i].ch_req && !channels[i].req_last)
			{
				channels[i].addr = *channels_rtl[i].ch_addr;
				channels[i].rnw = *channels_rtl[i].ch_rnw; // 1 - read, 0 - write
				channels[i].din = *channels_rtl[i].ch_din;
				channels[i].rq = true;
			}

			channels[i].req_last = *channels_rtl[i].ch_req;
		}
		
		if (channels_rtl[i].ch_req == 0 && channels_rtl[i].ch_done) {
			*channels_rtl[i].ch_done = 0;
		}
	}
	
	if (mem_ready)
	{
		for (int i = 0; i <= 2; i++)
		{
			if (channels[i].rq)
			{
				mem_wait_cnt = 1;
				mem_ready = false;
				mem_curr_rq = i;
				channels[i].rq = false;
				*channels_rtl[i].ch_ready = 0;

				if (channels[i].rnw) {
					//Read
					mem_addr = channels[i].addr;
				}
				else {
					//Write
					if (channels[i].addr < mem_size)
					{
						mem[channels[i].addr] = channels[i].din;
					}
				}
				break;
			}
		}
	}
	else
	{
		//Not ready
		mem_wait_cnt--;
		if (mem_wait_cnt == 0)
		{
			if (channels[mem_curr_rq].rnw) {
				if (channels[mem_curr_rq].addr < mem_size)
				{
					*channels_rtl[mem_curr_rq].ch_dout = mem[channels[mem_curr_rq].addr];
				}
				else {
					*channels_rtl[mem_curr_rq].ch_dout = 0xFF;
				}
			}

			*channels_rtl[mem_curr_rq].ch_ready = 1;
			if (channels_rtl[mem_curr_rq].ch_done) {
				*channels_rtl[mem_curr_rq].ch_done = 1;
			}
			mem_ready = true;
		}
	}
}

char* SimSDRAM::GetMem(void)
{
	return mem;
}