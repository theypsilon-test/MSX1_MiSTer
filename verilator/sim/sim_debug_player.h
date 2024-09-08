#pragma once
#include <vector>
#include "sim_console.h"
#include <verilated.h>

#pragma pack(push, 1)
struct DebugDataRecord {
	uint8_t type;
	uint16_t address;
	uint8_t data;
	uint16_t PC;
};
#pragma pack(pop)

struct SimDebugPlayer {
public:
	SimDebugPlayer(DebugConsole c, std::string debugFileName);
	~SimDebugPlayer();
	int AfterEval(vluint64_t time);

	CData* data;
	CData* data_out;
	CData* reset_n;
	CData* rd_n;
	CData* wr_n;
	CData* mreq_n;
	SData* addr;

private:
	void Reload(void);
	DebugConsole console;
	std::vector<DebugDataRecord> records;
	std::string debugFileName;

	int index = 0;
	int errors = 0;
	bool start = false;

	CData old_reset_n, old_rd_n, old_wr_n, old_mreq_n;
	CData old_data;


};