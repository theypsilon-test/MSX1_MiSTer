#pragma once

#include <vector>
#include <queue>
#include <map>
#include "verilated.h"
#include <fstream>
#include <filesystem>
#include <iostream>
#include <cctype>
#include <sstream>
#include <regex>
#include <tuple>

namespace fs = std::filesystem;

// CData
// SData 15:0
// Idata 31:0
// Qdata 63:0

enum SignalType : uint8_t
{
	CData_t,
	CDataArr_t,
	SData_t,
	SDataArr_t,
	IData_t,
	IDataArr_t,
	QData_t,
	QDataArr_t,
	Image_t
};

struct type_Data
{
	void* ptr;
	uint64_t mask;
};

struct type_DataArr
{
	void *ptr;
	uint64_t mask;
};
struct type_Image
{
	uint32_t img_id;
	uint32_t size;
	char* buffer;
};

template <size_t VNUM>
struct signalReccord
{
	SignalType type;
	union
	{
		type_Data signal;
		type_DataArr signals;
	};
};

enum CommandType : uint8_t
{
	cmd_NONE,
	cmd_WAIT,
	cmd_SET_SIGNAL,
	cmd_INVERT_SIGNAL,
	cmd_WHILE,
	cmd_DO,
	cmd_FOR,
	cmd_LOOP,
	cmd_END_LOOP,
	cmd_STOP,
	cmd_MISTER_LOAD_IMG
};

struct cmd_wait
{
	uint32_t count;
};

struct cmd_signal_set
{
	uint16_t id;
	uint32_t value;
	int16_t min;
	int16_t max;
};

struct commandRecord
{
	CommandType type;
	union
	{
		cmd_wait wait;
		cmd_signal_set signal;
	};
};

struct playList
{
	std::string name;
	uint32_t position;
	uint32_t param;
	int32_t loop = -1;
	std::vector<commandRecord> commands;
};

struct image
{
	uint32_t size;
	uint16_t clock_id;
	uint32_t pos;
	uint32_t lba;

	bool last_clk;
	bool last_rd;
	char* buffer;
};

template <size_t VNUM>
struct SimPlayer
{

public:
	SimPlayer();
	void addSignal(std::string name, SignalType type, void* ptr, uint32_t size);
	void addSignalArr(std::string name, SignalType type, void *ptr, uint32_t size);
	void addSignal(std::string name, CData* ptr, uint32_t size);
	void addSignalArrVNUM(std::string name, CData(*ptr)[VNUM], uint32_t size);
	void addSignal(std::string name, SData* ptr, uint32_t size);
	void addSignalArrVNUM(std::string name, SData(*ptr)[VNUM], uint32_t size);
	void addSignal(std::string name, IData* ptr, uint32_t size);
	void addSignalArrVNUM(std::string name, IData(*ptr)[VNUM], uint32_t size);
	void addSignal(std::string name, QData* ptr, uint64_t size);
	void addSignalArrVNUM(std::string name, QData(*ptr)[VNUM], uint32_t size);
	void addSignal(std::string name, signalReccord<VNUM> record);
	void loadTestFiles(void);
	bool tick(void);
	void HPSpreEvalTick(void);
	void HPSpostEvalTick(void);
	
private:
	void processTestFile(const fs::path& filePath, std::vector<commandRecord>& commands, const std::array<std::string, 10>& input_params);
	void processLine(const std::string& line, std::vector<commandRecord>& commands, const std::array<std::string, 10>& input_params);
	std::map<std::string, uint16_t> signalMap;
	std::vector<signalReccord<VNUM>> signals;
	std::vector<playList> playLists;
	std::vector<image> images;
};


#include "sim_player_add_signal.h"
#include "sim_player_load.h"
#include "sim_player_HPS.h"

namespace fs = std::filesystem;


template <size_t VNUM>
SimPlayer<VNUM>::SimPlayer() {
	images.resize(VNUM);
}


template <size_t VNUM>
bool SimPlayer<VNUM>::tick(void) {
	bool command_execute = false;
	bool chunk_end = false;
	bool stop = false;
	uint32_t position;
	
	int16_t min, max;
	uint64_t data_tmp, mask, value;
	uint16_t numBits;
	uint64_t tmp_mask;
	signalReccord<VNUM> signal;
	for (size_t i = 0; i < playLists.size(); i++) {
		if (playLists[i].commands.size() == playLists[i].position)
			continue;												// Playlist na konci

		command_execute = true;
		do {
			chunk_end = false;
			position = playLists[i].position;
			if (playLists[i].commands.size() == position)
				break;												// Playlist na konci
			auto command = playLists[i].commands[position];
			switch (command.type) {
			case(cmd_STOP):
				stop = true;
				playLists[i].position++;
				std::cout << "STOP reach" << "\n";
				break;
			case(cmd_LOOP):
				if (playLists[i].loop != -1)
					throw std::runtime_error("Chyba: vnoøený loop který není podporovaný!");
				playLists[i].loop = position;
				playLists[i].position++;
				break;
			case(cmd_END_LOOP):
				if (playLists[i].loop == -1)
					throw std::runtime_error("Chyba: nenalezen zaèátek loopu");
				playLists[i].position = playLists[i].loop;
				playLists[i].loop = -1;
				break;
			case(cmd_WAIT):
				if (command.wait.count == playLists[i].param) {
					playLists[i].position++;
					playLists[i].param = 0;
				}
				else {
					playLists[i].param++;
					chunk_end = true;
				}
				break;
			case(cmd_SET_SIGNAL):
				signal = signals[command.signal.id];
				mask = signal.signal.mask;
				value = command.signal.value;
				min = command.signal.min;
				max = command.signal.max;
				if (min == -1) {
					tmp_mask = mask;
					value &= mask;
				}
				else {
					numBits = (max - min) + 1;
					tmp_mask = ((1ULL << numBits) - 1) << min;
					value = (value << min) & tmp_mask;
				}
				switch (signal.type) {
					case(CData_t):
						data_tmp = *reinterpret_cast<CData*>(signal.signal.ptr);
						data_tmp &= ~tmp_mask;
						data_tmp |= value;
						data_tmp &= mask;
						*reinterpret_cast<CData*>(signal.signal.ptr) = data_tmp;
						playLists[i].position++;
						break;
					case(SData_t):
						data_tmp = *reinterpret_cast<SData*>(signal.signal.ptr);
						data_tmp |= ~value;
						data_tmp &= mask;
						*reinterpret_cast<SData*>(signal.signal.ptr) = data_tmp;
						playLists[i].position++;
						break;
					case(IData_t):
						data_tmp = *reinterpret_cast<IData*>(signal.signal.ptr);
						data_tmp &= ~tmp_mask;
						data_tmp |= value;
						data_tmp &= mask;
						*reinterpret_cast<IData*>(signal.signal.ptr) = data_tmp;
						playLists[i].position++;
						break;
					case(QData_t):
						data_tmp = *reinterpret_cast<QData*>(signal.signal.ptr);
						data_tmp &= ~tmp_mask;
						data_tmp |= value;
						data_tmp &= mask;
						*reinterpret_cast<QData*>(signal.signal.ptr) = data_tmp;
						playLists[i].position++;
						break;
					default:
						throw std::runtime_error("Chyba: neznámý typ signálu");
						break;
				}
				break;
			case(cmd_INVERT_SIGNAL):
				signal = signals[command.signal.id];
				mask = signal.signal.mask;
				min = command.signal.min;
				max = command.signal.max;
				if (min == -1) {
					tmp_mask = mask;
					value &= mask;
				}
				else {
					numBits = (max - min) + 1;
					tmp_mask = ((1ULL << numBits) - 1) << min;
					value = (value << min) & tmp_mask;
				}
				switch (signal.type) {
					case(CData_t):
						data_tmp = *reinterpret_cast<CData*>(signal.signal.ptr);
						value = (~data_tmp) & tmp_mask;
						data_tmp &= ~tmp_mask;
						data_tmp |= value;
						data_tmp &= mask;
						*reinterpret_cast<CData*>(signal.signal.ptr) = data_tmp;
						playLists[i].position++;
						break;
					case(SData_t):
						data_tmp = *reinterpret_cast<SData*>(signal.signal.ptr);
						value = (~data_tmp) & tmp_mask;
						data_tmp &= ~tmp_mask;
						data_tmp |= value;
						data_tmp &= mask;
						*reinterpret_cast<SData*>(signal.signal.ptr) = data_tmp;
						playLists[i].position++;
						break;
					case(IData_t):
						data_tmp = *reinterpret_cast<IData*>(signal.signal.ptr);
						value = (~data_tmp) & tmp_mask;
						data_tmp &= ~tmp_mask;
						data_tmp |= value;
						data_tmp &= mask;
						*reinterpret_cast<IData*>(signal.signal.ptr) = data_tmp;
						playLists[i].position++;
						break;
					case(QData_t):
						data_tmp = *reinterpret_cast<QData*>(signal.signal.ptr);
						value = (~data_tmp) & tmp_mask;
						data_tmp &= ~tmp_mask;
						data_tmp |= value;
						data_tmp &= mask;
						*reinterpret_cast<QData*>(signal.signal.ptr) = data_tmp;
						playLists[i].position++;
						break;
					default:
						throw std::runtime_error("Chyba: neznámý typ signálu");
						break;
				}
				break;
			default:
				playLists[i].position++;
				break;
			}
		
		} while (!chunk_end);
	}

	return command_execute && !stop;
}