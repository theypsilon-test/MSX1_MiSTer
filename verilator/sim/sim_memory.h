#include "verilated.h"
#include "sim_console.h"


#ifndef _MSC_VER
#else
#define WIN32
#endif

struct SimMemoryRam {
public:
	CData* q;
	CData* data;
	SData* addr;
	IData* addr32;
	CData* we;
	CData* q_b;
	CData* data_b;
	SData* addr_b;
	IData* addr32_b;
	CData* we_b;
	char* mem;
	int mem_size;
	
	SimMemoryRam(DebugConsole c);
	~SimMemoryRam();
	char* AllocateMemory(int size);
	void FreeMemory(void);
	bool LoadFile(std::string filename);
	void MapSignals(SData* addr, CData* data, CData* q, CData* we);
	void MapSignals(IData* addr, CData* data, CData* q, CData* we);
	void MapSignals(SData* addr_a, CData* data_a, CData* q_a, CData* we_a, SData* addr_b, CData* data_b, CData* q_b, CData* we_b);
	void MapSignals(IData* addr_a, CData* data_a, CData* q_a, CData* we_a, IData* addr_b, CData* data_b, CData* q_b, CData* we_b);
	void BeforeEval(void);
	void AfterEval(void);

private:
	DebugConsole console;

};

struct SimMemory {
public:
	SimMemory(DebugConsole c);
	~SimMemory();
	char* SimMemory::AddRAM(SData* addr, CData* data, CData* q, CData* we, int size, std::string file);
	char* SimMemory::AddRAM(SData* addr, CData* data, CData* q, CData* we, int size);
	char* SimMemory::AddRAM(IData* addr, CData* data, CData* q, CData* we, int size, std::string file);
	char* SimMemory::AddRAM(IData* addr, CData* data, CData* q, CData* we, int size);
	char* SimMemory::AddRAM(SData* addr_a, CData* data_a, CData* q_a, CData* we_a, SData* addr_b, CData* data_b, CData* q_b, CData* we_b, int size, std::string file);
	char* SimMemory::AddRAM(SData* addr_a, CData* data_a, CData* q_a, CData* we_a, SData* addr_b, CData* data_b, CData* q_b, CData* we_b, int size);
	char* SimMemory::AddRAM(IData* addr_a, CData* data_a, CData* q_a, CData* we_a, IData* addr_b, CData* data_b, CData* q_b, CData* we_b, int size, std::string file);
	char* SimMemory::AddRAM(IData* addr_a, CData* data_a, CData* q_a, CData* we_a, IData* addr_b, CData* data_b, CData* q_b, CData* we_b, int size);
	void BeforeEval(void);
	void AfterEval(void);
private:
	DebugConsole console;
	std::list<SimMemoryRam> Rams;
};