#include <iostream>
#include <sys/stat.h>
#include <queue>
#include <string>

#include "sim_bus.h"
#include "sim_console.h"
#include "verilated.h"

//#define SIM_SD_CARD

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

//std::queue<SimBus_DownloadChunk> downloadQueue;
//

void SimBus::MountImage(std::string file, int index) {

	FILE *ioctl_file = fopen(file.c_str(), "rb");
	if (!ioctl_file) {
		console.AddLog("Cannot open file for image %s\n", file.c_str());
		return;
	}

	images[index].filename = file;
	images[index].handle = ioctl_file;

	struct stat fileStat;
	stat(file.c_str(), &fileStat);
	images[index].size = fileStat.st_size;

	console.AddLog("Mounted image: %s velikost: %d", images[index].filename.c_str(), images[index].size);

	*img_size = images[index].size;
	*img_readonly = 0;
	*img_mounted = 0x10;
}

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
int active_block = -1;
SData buff_addr;

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
#ifdef SIM_SD_CARD
	if (active_block == -1) {
		if (*sd_rd > 0) {
			// Pozadavek na cteni
			for (int i = 0; i < 7; i++) {
				if (( * sd_rd & (1 << i)) != 0) {
					if (images[i].handle != NULL) {
						active_block = i;
						*sd_ack = *sd_ack | (1 << i);
						uint32_t lba = (*sd_lba)[i];
						fseek(images[i].handle, lba * 512, SEEK_SET);
						*sd_buff_addr = 0;
						*sd_buff_dout = fgetc(images[i].handle);
						*sd_buff_wr = 1;
					}
				}
			}
		}
	}
	else {
		*sd_buff_addr = *sd_buff_addr + 1;
		if (*sd_buff_addr == 512) {
			*sd_buff_wr = 0;
			*sd_ack = 0;
			active_block = -1;
		}
		else {
			*sd_buff_dout = fgetc(images[active_block].handle);
		}
	}
#endif
}

bool SimBus::AfterEval()
{
	bool ret = false;

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
				if (downloadQueue.size() == 0)
				{
					ret = true;
				}
				/*
				if (currentDownload.index == 1) 
				{
					ret = true;
				}*/
			}
		}
	}
	return ret;
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

	img_mounted = NULL;
	img_readonly = NULL;
	img_size = NULL;
	sd_rd = NULL;
	sd_wr = NULL;
	sd_ack = NULL;
	sd_buff_addr = NULL;
	sd_buff_dout = NULL;
	sd_buff_wr = NULL;
	sd_lba = NULL;
	sd_blk_cnt = NULL;
	sd_buff_din = NULL;
	for (int i = 0; i < 6; ++i) {
		images.push_back({ "", 0, NULL });
	}
}

SimBus::~SimBus() {

}
