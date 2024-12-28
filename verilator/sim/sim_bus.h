#pragma once
#include <iostream>
#include <queue>
#include "verilated.h"
#include "sim_console.h"
#include "sim_ddr.h"


#ifndef _MSC_VER
#else
#define WIN32
#endif

struct SimBus_DownloadChunk {
public:
	std::string file;
	int index;
	bool restart;
	int addr;
	SimDDR *DDR;
	
	SimBus_DownloadChunk() {
		file = "";
		index = -1;
		addr = -1;
		DDR = NULL;
	}

	SimBus_DownloadChunk(std::string file, int index) {
		this->restart = false;
		this->file = std::string(file);
		this->index = index;
		this->DDR = NULL;
	}
	SimBus_DownloadChunk(std::string file, int index, bool restart) {
		this->restart = restart;
		this->file = std::string(file);
		this->index = index;
		this->DDR = NULL;
	}
	SimBus_DownloadChunk(std::string file, int index, bool restart, int addr, SimDDR *DDR) {
		this->restart = restart;
		this->file = std::string(file);
		this->index = index;
		this->addr = addr;
		this->DDR = DDR;
	}
};

struct SimBus {
public:

	IData* ioctl_addr;
	SData* ioctl_index;
	CData* ioctl_wait;
	CData* ioctl_download;
	CData* ioctl_upload;
	CData* ioctl_wr;
	CData* ioctl_dout;
	CData* ioctl_din;

	CData* img_mounted;
	CData* img_readonly;
	QData* img_size;

	CData* sd_rd;
	CData* sd_wr;
	CData* sd_ack;
	IData(*sd_lba)[6];
	CData(*sd_blk_cnt)[6]; //pole 6
	
	SData* sd_buff_addr;
	CData* sd_buff_dout;
	CData(*sd_buff_din)[6];			//pole 6
	CData* sd_buff_wr;



	void BeforeEval(void);
	bool AfterEval(void);
	void MountImage(std::string file, int index);
	void QueueDownload(std::string file, int index);
	void QueueDownload(std::string file, int index, bool restart);
	void QueueDownload(std::string file, int index, bool restart, int addr, SimDDR *DDR);
	bool HasQueue();

	SimBus(DebugConsole c);
	~SimBus();

private:
	struct image {
		std::string filename;
		int size;
		FILE* handle;
	};
	
	
	
	std::queue<SimBus_DownloadChunk> downloadQueue;
	SimBus_DownloadChunk currentDownload;
	std::vector<image> images;
	void SetDownload(std::string file, int index);
};
