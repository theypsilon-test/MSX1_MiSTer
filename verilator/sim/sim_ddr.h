#pragma once
#include "verilated.h"
#include "sim_console.h"


#ifndef _MSC_VER
#else
#define WIN32
#endif

struct SimDDR {
public:

	CData* dout;
	CData* din;
	IData* addr;
	CData* we;
	CData* rd;
	CData* ready;
	
	SimDDR(DebugConsole c);
	~SimDDR();

	void Initialise(int size);
	void writeData(int addr, int value);
	void BeforeEval(void);
	void AfterEval(void);
	char* GetMem(void);

private:
	char* mem;
	int mem_size;
	uint32_t mem_addr;
	CData mem_q;
	int  mem_wait_cnt;
	DebugConsole console;
	bool AllocateMemory(int size);
//	void FreeMemory(void);
};