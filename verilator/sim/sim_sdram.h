#include "verilated.h"
#include "sim_console.h"


#ifndef _MSC_VER
#else
#define WIN32
#endif

struct Channel {
	IData addr;
	CData din;
	CData req;
	CData rnw;
	bool rq;
	bool req_last;
};

struct Channel_rtl {
	IData* ch_addr;
	CData* ch_dout;
	CData* ch_din;
	CData* ch_req;
	CData* ch_rnw;
	CData* ch_ready;
	CData* ch_done;
};

struct SimSDRAM {
public:
	Channel_rtl channels_rtl[3];
/*
	CData* size;
*/	
	SimSDRAM(DebugConsole c);
	~SimSDRAM();
	void Initialise(int size);
	void BeforeEval(void);
	void AfterEval(void);
	char* GetMem(void);
	int getHPSsize(void);

private:
	char* mem;
	int mem_size;
	bool mem_ready;
	IData mem_addr;
	int  mem_wait_cnt;
	int  mem_curr_rq;
	DebugConsole console;
	Channel channels[3];
	bool AllocateMemory(int size);
	void FreeMemory(void);
};