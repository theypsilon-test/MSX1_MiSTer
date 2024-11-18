#pragma once

#include <vector>
#include <queue>
#include "verilated.h"

enum CommandType : uint8_t
{
	MEM_WR,
	MEM_RD,
	IO_WR,
	IO_RD,
	TICK,
	SETSLOT,
	SETSUBSLOT,
	SETTRACE,
	RESET
};


struct Mem_WR
{
	uint16_t address;
	uint8_t value;
};

struct Io_WR
{
	uint8_t address;
	uint8_t value;
	uint8_t value2;
};

struct Mem_RD
{
	uint16_t address;
};

struct Io_RD
{
	uint8_t address;
	uint8_t value2;
};

struct Tick
{
	uint32_t count;
};

struct Value
{
	uint8_t address;
	uint8_t value;
};

struct CPU_trace
{
	bool trace;
};

struct commandReccord
{
	CommandType type;
	union
	{
		Mem_WR memory_wr;
		Mem_RD memory_rd;
		Io_WR io_wr;
		Io_RD io_rd;
		Tick tick;
		Value value;
		CPU_trace trace;
	};
};

struct SimCPU
{

public:
	CData* dout;
	SData* addr;
	CData* wr_n;
	CData* rd_n;
	CData* mreq_n;
	CData* iorq_n;
	CData* m1_n;
	CData* refresh_n;
	CData* halt_n;
	CData* reset;
	VlUnpacked<CData/*7:0*/, 4> * slot_subslot;
	CData* slot;
	bool trace;

	SimCPU();

	void setSubSlot(uint8_t slot, uint8_t value);
	void setSlot(uint8_t block, uint8_t value);
	void memoryWrite(uint16_t addr, uint8_t value);
	void memoryRead(uint16_t addr);
	void ioWrite(uint8_t addr, uint8_t value, uint8_t value2);
	void ioRead(uint8_t addr, uint8_t value2);
	void tick(uint32_t count);
	void setTrace(bool state);
	void setReset();

	bool BeforeEval();
	bool AfterEval();
	void Reset();

private:
	enum CPU_state : uint8_t
	{
		IDLE,
		RUNNING,
		NEXT
	};

	CPU_state state = IDLE;
	uint32_t mstate;
	commandReccord currentCommand;
	std::queue<commandReccord>	commandQueue;	

	bool processCommand();
	inline bool processMemWR();
	inline bool processMemRD();
	inline bool processIoWR();
	inline bool processIoRD();
	inline bool processTick();
	inline bool processTrace();
	inline bool processReset();

	bool processSetSlot();
	bool processSetSubSlot();
};