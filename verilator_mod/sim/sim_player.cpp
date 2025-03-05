#include "sim_player.h"
#include <iostream>
#include <fstream>
#include <filesystem>
#include <cctype>
#include <sstream>
#include <vector>

namespace fs = std::filesystem;

SimPlayer::SimPlayer() {

}

std::string to_upper(const std::string& str) {
	std::string result;
	for (char c : str) {
		result += std::toupper(c);
	}
	return result;
}

uint32_t parse_number(const std::string& str) {
	uint32_t value = 0;
	std::stringstream ss;

	if (str.find("0x") == 0 || str.find("0X") == 0) {  // Hexadecimální èíslo
		ss << std::hex << str.substr(2);
	}
	else {  // Desítkové èíslo
		ss << std::dec << str;
	}

	ss >> value;
	return value;
}

void SimPlayer::loadTestFiles(void) {
	fs::path folder = fs::current_path() / "test";
	std::vector<commandRecord> commands;
	commandRecord rec;
	for (const auto& entry : fs::directory_iterator(folder)) {
		if (entry.is_regular_file() && entry.path().extension() == ".tst") {
			std::ifstream file(entry.path());  // Otevøení souboru
			if (!file) {
				std::cerr << "Nelze otevøít soubor: " << entry.path() << "\n";
				continue;
			}

			std::cout << "Zpracovávám soubor: " << entry.path().filename() << "\n";

			std::string line;
			commands.clear();
			while (std::getline(file, line)) {
				// Odstranìní prázdných øádkù a komentáøù
				if (line.empty() || line[0] == '#') continue;

				std::istringstream iss(line);
				std::string command, param1, param2;

				if (!(iss >> command)) {
					std::cerr << "Chybný formát øádku: " << line << "\n";
					continue;
				}
				iss >> param1;
				iss >> param2;

				command = to_upper(command);  // Normalizace na UPPERCASE
				
				if (command == "LOOP") {
					rec.type = cmd_LOOP;
					commands.push_back(rec);
				}
				else if (command == "SIGNAL") {
					rec.type = cmd_SET_SIGNAL;
					rec.signal.id = signalMap[param1];
					rec.signal.value = parse_number(param2);
					commands.push_back(rec);
				}
				else if (command == "WAIT") {
					rec.type = cmd_WAIT;
					rec.wait.count = parse_number(param1);
					commands.push_back(rec);
				}
				else if (command == "LOPP_END") {
					rec.type = cmd_END_LOOP;
					commands.push_back(rec);
				}
				else if (command == "STOP") {
					rec.type = cmd_STOP;
					commands.push_back(rec);
				}
				else if (command == "INVERT_SIGNAL") {
					rec.type = cmd_INVERT_SIGNAL;
					rec.signal.id = signalMap[param1];
					commands.push_back(rec);
				}
				
			}
			playList record;
			record.position = 0;
			record.param = 0;
			record.commands = commands;
			playLists.push_back(record);
		}
	}
}

void SimPlayer::addSignal(std::string name, signalReccord record) {
	signals.push_back(record);
	signalMap[name] = signals.size() - 1;
}

void SimPlayer::addSignal(std::string name, CData* ptr, uint32_t mask) {
	signalReccord record;
	record.type = CData_t;
	record.CData_ptr.ptr = ptr;
	record.CData_ptr.mask = mask;
	addSignal(name, record);
}

void SimPlayer::addSignal(std::string name, SData* ptr, uint32_t mask) {
	signalReccord record;
	record.type = SData_t;
	record.SData_ptr.ptr = ptr;
	record.CData_ptr.mask = mask;
	addSignal(name, record);
	
}

void SimPlayer::addSignal(std::string name, IData* ptr, uint32_t mask) {
	signalReccord record;
	record.type = IData_t;
	record.IData_ptr.ptr = ptr;
	record.CData_ptr.mask = mask;
	addSignal(name, record);
}


bool SimPlayer::tick(void) {
	bool command_execute = false;
	bool chunk_end = false;
	bool stop = false;
	uint32_t position;
	CData* cd;
	uint32_t cdv;
	for (size_t i = 0; i < playLists.size(); i++) {

		if (playLists[i].commands.size() == playLists[i].position)
			continue;												// Playlist na konci
		
		command_execute = true;
		do {
			chunk_end = false;
			position = playLists[i].position;
			if (playLists[i].commands.size() == position)
				break;												// Playlist na konci
			
			switch (playLists[i].commands[position].type) {
			case(cmd_STOP):
				stop = true;
				playLists[i].position++;
				break;
			case(cmd_LOOP):
				if (playLists[i].loop != -1 )
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
				if (playLists[i].commands[position].wait.count == playLists[i].param) {
					playLists[i].position++;
					playLists[i].param = 0;
				}
				else {
					playLists[i].param++;
					chunk_end = true;
				}
				break;
			case(cmd_SET_SIGNAL):
				switch (signals[playLists[i].commands[position].signal.id].type) {
				case(CData_t):
					*signals[playLists[i].commands[position].signal.id].CData_ptr.ptr = playLists[i].commands[position].signal.value & signals[playLists[i].commands[position].signal.id].CData_ptr.mask;
					playLists[i].position++;
					break;
				case(SData_t):
					*signals[playLists[i].commands[position].signal.id].SData_ptr.ptr = playLists[i].commands[position].signal.value & signals[playLists[i].commands[position].signal.id].SData_ptr.mask;
					playLists[i].position++;
					break;
				case(IData_t):
					*signals[playLists[i].commands[position].signal.id].IData_ptr.ptr = playLists[i].commands[position].signal.value & signals[playLists[i].commands[position].signal.id].IData_ptr.mask;
					playLists[i].position++;
					break;
				default:
					break;
				}
				break;
			case(cmd_INVERT_SIGNAL):
				switch (signals[playLists[i].commands[position].signal.id].type) {
				case(CData_t):
					*signals[playLists[i].commands[position].signal.id].CData_ptr.ptr = ~*signals[playLists[i].commands[position].signal.id].CData_ptr.ptr & signals[playLists[i].commands[position].signal.id].CData_ptr.mask;
					playLists[i].position++;
					break;
				case(SData_t):
					*signals[playLists[i].commands[position].signal.id].SData_ptr.ptr = ~*signals[playLists[i].commands[position].signal.id].SData_ptr.ptr & signals[playLists[i].commands[position].signal.id].SData_ptr.mask;
					playLists[i].position++;
					break;
				case(IData_t):
					*signals[playLists[i].commands[position].signal.id].IData_ptr.ptr = ~*signals[playLists[i].commands[position].signal.id].IData_ptr.ptr & signals[playLists[i].commands[position].signal.id].IData_ptr.mask;;
					playLists[i].position++;
					break;
				default:
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

