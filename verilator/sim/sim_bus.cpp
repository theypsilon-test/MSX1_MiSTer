#include <iostream>
#include <sys/stat.h>
#include <queue>
#include <string>

#include "sim_bus.h"
#include "sim_console.h"
#include "verilated.h"

#ifndef _MSC_VER
#else
#define WIN32
#endif

#define START_DOWNLOAD_WAIT 50
#define START_INDEX_WAIT 25
#define WR_WAIT 28
#define RECOVERY_WAIT 10

static DebugConsole console;

FILE* ioctl_file = NULL;
int ioctl_next_addr = -1;
int ioctl_last_index = -1;

IData* ioctl_addr = NULL;
CData* ioctl_index = NULL;
CData* ioctl_wait = NULL;
CData* ioctl_download = NULL;
CData* ioctl_upload = NULL;
CData* ioctl_wr = NULL;
CData* ioctl_dout = NULL;
CData* ioctl_din = NULL;

std::queue<SimBus_DownloadChunk> downloadQueue;

void SimBus::QueueDownload(std::string file, int index) {
	SimBus_DownloadChunk chunk = SimBus_DownloadChunk(file, index);
	downloadQueue.push(chunk);
}
void SimBus::QueueDownload(std::string file, int index, bool restart) {
	SimBus_DownloadChunk chunk = SimBus_DownloadChunk(file, index, restart);
	downloadQueue.push(chunk);
}
void SimBus::QueueDownload(std::string file, int index, bool restart, int addr, SimDDR *DDR) {
	SimBus_DownloadChunk chunk = SimBus_DownloadChunk(file, index, restart, addr, DDR);
	downloadQueue.push(chunk);
}
bool SimBus::HasQueue() {
	return downloadQueue.size() > 0;
}

int nextchar = 0;
int file_size = 0;
int start_download_delay_cnt = START_DOWNLOAD_WAIT;
int start_index_delay_cnt = START_INDEX_WAIT;
int recovery_wait = 0;
int wr_delay_cnt = 0;
bool next_wr = false;
bool next_rd = false;

void SimBus::BeforeEval()
{
	// If no file is open and there is a download queued
	if (!ioctl_file && downloadQueue.size() > 0 && recovery_wait == 0) {

		// Get chunk from queue
		currentDownload = downloadQueue.front();
		downloadQueue.pop();

		// Open file
		ioctl_file = fopen(currentDownload.file.c_str(), "rb");

		if (!ioctl_file) {
			console.AddLog("Cannot open file for download %s\n", currentDownload.file.c_str());
			return;
		}

		struct stat fileStat;
		stat(currentDownload.file.c_str(), &fileStat);
		file_size = fileStat.st_size;

		if (file_size == 0)
		{
			console.AddLog("File is empty %s\n", currentDownload.file.c_str());
			fclose(ioctl_file);
			ioctl_file = NULL;
			return;
		}

		console.AddLog("Starting download: %s %d velikost: %d", currentDownload.file.c_str(), ioctl_next_addr, file_size);

		nextchar = fgetc(ioctl_file);
		wr_delay_cnt = 0;
		next_wr = false;

		if (currentDownload.index == *ioctl_index && currentDownload.restart == false) {
			start_download_delay_cnt = 0;
			start_index_delay_cnt = 0;
		}
		else {
			*ioctl_index = currentDownload.index;
			ioctl_next_addr = 0;
			start_download_delay_cnt = START_DOWNLOAD_WAIT;
			start_index_delay_cnt = START_INDEX_WAIT;

			if (currentDownload.DDR) {
				*ioctl_addr = file_size;
			}
		}
	}

	if (recovery_wait)
		recovery_wait--;

	if (ioctl_file) {
		if (start_index_delay_cnt) {
			start_index_delay_cnt--;
		}
		else {
			*ioctl_download = 1;
		}
		
		if (*ioctl_download == 1) {
			if (start_download_delay_cnt) {
				start_download_delay_cnt--;
			}
			else
			{
				*ioctl_wr = next_wr;
				if (wr_delay_cnt) {
					wr_delay_cnt--;
					next_wr = false;
				}
				else {
					*ioctl_wr = 0;
					if (*ioctl_wait == 0) {
						next_rd = true;
						if (currentDownload.DDR == NULL) {
							*ioctl_addr = ioctl_next_addr;
							*ioctl_dout = (unsigned char)nextchar;
							next_wr = true;
							wr_delay_cnt = WR_WAIT;
						}
						else {
							currentDownload.DDR->writeData(ioctl_next_addr + currentDownload.addr, (unsigned char)nextchar);
							wr_delay_cnt = WR_WAIT;
						}
					}
				}
			}
		}
	}
}

void SimBus::AfterEval()
{
	if (*ioctl_download == 1 && ioctl_file)
	{
		if (next_rd && next_wr == false)
		{
			next_rd = false;
			nextchar = fgetc(ioctl_file);
			ioctl_next_addr++;
			
			if (feof(ioctl_file))
			{
				fclose(ioctl_file);
				ioctl_file = NULL;
				*ioctl_download = 0;
				*ioctl_wr = 0;
				recovery_wait = RECOVERY_WAIT;
				console.AddLog("ioctl_download complete %d", ioctl_next_addr);
			}
		}
	}
}


SimBus::SimBus(DebugConsole c) {
	console = c;
	ioctl_addr = NULL;
	ioctl_index = NULL;
	ioctl_wait = NULL;
	ioctl_download = NULL;
	ioctl_upload = NULL;
	ioctl_wr = NULL;
	ioctl_dout = NULL;
	ioctl_din = NULL;
}

SimBus::~SimBus() {

}
