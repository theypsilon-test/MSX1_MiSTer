#include <iostream>
#include <vector>
#include <fstream>
#include "sim_debug_player.h"
#include "sim_console.h"
#include <verilated.h>
#include "Vemu__Syms.h"

SimDebugPlayer::SimDebugPlayer(DebugConsole c, std::string debugFileName) {
	console = c;
	this->debugFileName = debugFileName;
	Reload();
	start = false;
}

SimDebugPlayer::~SimDebugPlayer() {

}

void SimDebugPlayer::Reload(void) {
	std::ifstream ioctl_file(debugFileName, std::ios::binary);

	if (!ioctl_file) {
		console.AddLog("Cannot open file for download %s\n", debugFileName.c_str());
		return;
	}

	DebugDataRecord record;

	while (ioctl_file.read(reinterpret_cast<char*>(&record), sizeof(DebugDataRecord))) {
		records.push_back(record);
	}

	ioctl_file.close();
	index = 0;

}

int SimDebugPlayer::AfterEval(vluint64_t time) {
	DebugDataRecord record;

	if (*reset_n == 1) {
		if (old_reset_n == 0) {
			index = 0;
			errors = 0;
		}

		
		if (old_rd_n == 0 && *rd_n == 1 && old_mreq_n == 0) {			//Konec ctení
			record = records[index];

			while (record.type == 'w' || record.type == 'r' || record.type == 'X') {
				index++;
				record = records[index];
			}

			if (start && (record.address != *addr || record.data != old_data || record.type != 'R')) {
				if (!(index == 939439 || index == 939440)) {				
					console.AddLog("DEBUG %d READ Ocekavam %c index:%d Addr %04X data %02X prislo addr %04X data %02X (PC:%04x)\n", time, record.type, index, record.address, record.data, *addr, old_data, record.PC);
					record = records[index-1];
					console.AddLog("DEBUG predchozi %c Addr %04X data %02X (PC:%04x)\n", record.type, record.address, record.data, record.PC);
					errors++;
				}
			}
			else {
				if (*addr == 0 && old_data == 0xf3)
					start = true;
				//if (record.address == *addr && record.data == *data)
				//	start = true;
			}

			if (start)
				index++;
		}
		if (old_wr_n == 1 && *wr_n == 0 && *mreq_n == 0) {			//Zacatek write
			record = records[index];

			while (record.type == 'w' || record.type == 'r' || record.type == 'X') {
				index++;
				record = records[index];
			}

			if (start && (record.address != *addr || record.type != 'W' || *data_out != record.data)) {
				if (!(index == 938674 || index == 938675)) {
					console.AddLog("DEBUG %d WRITE Ocekavam %c index:%d Addr %04X data %02X prislo addr %04X data %02X (PC:%04x)\n", time, record.type, index, record.address, record.data, *addr, *data_out, record.PC);
					record = records[index - 1];
					console.AddLog("DEBUG predchozi %c Addr %04X data %02X (PC:%04x)\n", record.type, record.address, record.data, record.PC);
					errors++;
				}
			}

			if (start)
				index++;
		}
	}

	old_reset_n = *reset_n;
	old_rd_n = *rd_n;
	old_wr_n = *wr_n;
	old_mreq_n = *mreq_n;
	old_data = *data;
	return errors;
}