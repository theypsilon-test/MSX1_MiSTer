#include "verilated.h"
#include "sim_console.h"


#ifndef _MSC_VER
#else
#define WIN32
#endif

struct SimSDRAM {
public:
	CData* q;
	CData* data;
	IData* addr;
	CData* we;
	CData* rd;
	CData* ready;
	CData* size;
	
	SimSDRAM(DebugConsole c);
	~SimSDRAM();
	void Initialise(int size);
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
	void FreeMemory(void);
};