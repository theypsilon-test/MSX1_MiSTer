#pragma once

#include <vector>
#include <queue>
#include <map>
#include "verilated.h"


// CData
// SData 15:0
// Idata 31:0

enum SignalType : uint8_t
{
	CData_t,
	SData_t,
	IData_t
};

struct type_CData
{
	CData* ptr;
	uint32_t mask;
};
struct type_SData
{
	SData* ptr;
	uint32_t mask;
};
struct type_IData
{
	IData* ptr;
	uint32_t mask;
};

struct signalReccord
{
	SignalType type;
	union
	{
		type_CData CData_ptr;
		type_SData SData_ptr;
		type_IData IData_ptr;
	};
};

enum CommandType : uint8_t
{
	cmd_WAIT,
	cmd_SET_SIGNAL,
	cmd_INVERT_SIGNAL,
	cmd_WHILE,
	cmd_DO,
	cmd_FOR,
	cmd_LOOP,
	cmd_END_LOOP,
	cmd_STOP
};

struct cmd_wait
{
	uint32_t count;
};


struct cmd_signal_set
{
	uint16_t id;
	uint32_t value;
};

struct commandRecord
{
	CommandType type;
	union
	{
		cmd_wait wait;
		cmd_signal_set signal;
		//cmd_set_signal SData_ptr;
		//type_IData IData_ptr;
	};
};

struct playList
{
	uint32_t position;
	uint32_t param;
	int32_t loop = -1;
	std::vector<commandRecord> commands;
};

struct SimPlayer
{

public:
	SimPlayer();

	void addSignal(std::string name, CData* ptr, uint32_t mask);
	void addSignal(std::string name, SData* ptr, uint32_t mask);
	void addSignal(std::string name, IData* ptr, uint32_t mask);
	void addSignal(std::string name, signalReccord record);
	void loadTestFiles(void);
	bool tick(void);
	
private:
	std::map<std::string, uint16_t> signalMap;
	std::vector<signalReccord> signals;
	
	std::vector<playList> playLists;


};