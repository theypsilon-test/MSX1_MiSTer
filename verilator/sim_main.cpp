#include <verilated.h>
#include "Vemu__Syms.h"

#include "imgui.h"
#include "implot.h"
#ifndef _MSC_VER
#include <stdio.h>
#include <SDL.h>
#include <SDL_opengl.h>
#else
#define WIN32
#include <dinput.h>
#endif

#include "sim_console.h"
#include "sim_bus.h"
#include "sim_video.h"
#include "sim_audio.h"
#include "sim_input.h"
#include "sim_clock.h"
#include "sim_memory.h"
#include "sim_sdram.h"
#include "sim_ddr.h"
#include "sim_debug_player.h"

#include "../imgui/imgui_memory_editor.h"
#include <verilated_vcd_c.h> //VCD Trace
#include "../imgui/ImGuiFileDialog.h"

#include <iostream>
#include <fstream>
using namespace std;

// Simulation control
// ------------------
int initialReset = 3;
bool run_enable = 0;
int batchSize = 150000;
bool single_step = 0;
bool multi_step = 0;
int multi_step_amount = 1024;

// Debug GUI 
// ---------
const char* windowTitle = "Verilator Sim: MSX";
const char* windowTitle_Control = "Simulation control";
const char* windowTitle_DebugLog = "Debug log";
const char* windowTitle_Video = "VGA output";
const char* windowTitle_Trace = "Trace/VCD control";
const char* windowTitle_HPS = "HPS control";
const char* windowTitle_Audio = "Audio output";

bool showDebugLog = true;
DebugConsole console;
MemoryEditor mem_edit;

struct FileDialogData
{
	uint8_t ioctl_id;
	bool reset;
	uint32_t addr;
	SimDDR* mem;
};

FileDialogData fileData;

// HPS emulator
// ------------
VL_OUTW(status, 127, 0, 4);

const char* slotA1[] = { "ROM","SCC","SCC +","FM - PAC","MegaFlashROM SCC + SD","GameMaster2","FDC","Empty"};
const char* slotA2[] = { "ROM","SCC","SCC +","FM - PAC","MegaFlashROM SCC + SD","GameMaster2","Empty" };
const char* slotB[] = { "ROM","SCC","SCC +","FM - PAC","Empty" };
const char* mapperA[] = { "auto","none","ASCII8","ASCII16","Konami","KonamiSCC","KOEI","linear64","R-TYPE","WIZARDRY" };
const char* mapperB[] = { "auto","none","ASCII8","ASCII16","Konami","KonamiSCC","KOEI","linear64","R-TYPE","WIZARDRY" };
const char* sramA[] = { "auto","1kB","2kB","4kB","8kB","16kB","32kB","none" };
int currentSlotA = 0;
//int currentSlotA = 6;
int currentSlotB = 0;
int currentMapperA = 0;
int currentMapperB = 0;
int currentSramA = 0;




//[0]     RESET					0
//[2:1]   Aspect ratio			00
//[4:3]   Scanlines             00
//[6:5]   Scale                 00  
//[7]     Vertical crop         0 
//[8]     Tape input            0
//[9]     Tape rewind           0
//[10]    Reset & Detach        0
//[11]    MSX type              0
//[12]    MSX1 VideoMode        0 
//[14:13] MSX2 VideoMode        00
//[16:15] MSX2 RAM Size         00
//[19:17] SLOT A CART TYPE      000  currentSlotA & 0x7
//[23:20] ROM A TYPE MAPPER     0000 currentMapperA & 0xF
//[25:24] RESERVA               00 
//[28:26] SRAM SIZE             000  currentSramA  & 0x7
//[31:29] SLOT B CART TYPE      000  currentSlotB & 0x7
//[34:32] ROM B TYPE MAPPER     000  currentMapperB & 0x7 
//[37:35] RESERVA               000 
//[38]    BORDER                0


SimInput input(0, console);
SimBus bus(console);

// Video
// -----
//#define VGA_WIDTH 256 //320
//#define VGA_HEIGHT 192 //240
#define VGA_WIDTH 320
#define VGA_HEIGHT 240
#define VGA_ROTATE 0
#define VGA_SCALE_X vga_scale
#define VGA_SCALE_Y vga_scale
SimVideo video(VGA_WIDTH, VGA_HEIGHT, VGA_ROTATE);
float vga_scale = 1.5;

// Memory

#define systemRAM top->emu->systemRAM
#define VRAMhi top->emu->MSX->vram_hi
#define VRAMlo top->emu->MSX->vram_lo
#define kbd top->emu->MSX->msx_key->kbd_ram

//SimMemoryRam* systemRAM_mem;
SimMemoryRam* vdp_mem_hi;
SimMemoryRam* vdp_mem_lo;
SimMemoryRam* kbd_map;

SimSDRAM SDram(console);
SimDDR DDR(console);
SimMemory Rams(console);
SimDebugPlayer debuger(console,"trace.log");

// Verilog module
// --------------
Vemu* top = NULL;

vluint64_t main_time = 0;	// Current simulation time.
double sc_time_stamp() {	// Called by $time in Verilog.
	return main_time;
}


int clk_sys_freq = 42954545;
SimClock clk_sys(1);  // 42.954545mhz
SimClock ce_11(3); // 10.75mhz

// VCD trace logging
// -----------------
VerilatedVcdC* tfp = new VerilatedVcdC; //Trace
bool Trace = 0;
char Trace_Deep[3] = "99";
char Trace_File[30] = "sim.vcd";
char Trace_Deep_tmp[3] = "99";
char Trace_File_tmp[30] = "sim.vcd";
int  iTrace_Deep_tmp = 99;
char SaveModel_File_tmp[20] = "test", SaveModel_File[20] = "test";



void ChangeStatus(void) {
	status[1] = 0;
	status[0] = 0;
	status[0] |= static_cast<uint64_t>(currentSlotA & 0x7) << 17;
	status[0] |= static_cast<uint64_t>(currentMapperA & 0xF) << 20;
	status[0] |= static_cast<uint64_t>(currentSramA & 0x7) << 26;
	status[0] |= static_cast<uint64_t>(currentSlotB & 0x7) << 29;
	status[0] |= static_cast<uint64_t>(currentMapperB & 0x7) << 32;
	console.AddLog("New Status %X", status);
}


//Trace Save/Restore
void save_model(const char* filenamep) {
	/*
	VerilatedSave os;
	os.open(filenamep);
	os << main_time; // user code must save the timestamp, etc
	os << *top;
	*/
}
void restore_model(const char* filenamep) {
	/*
	VerilatedRestore os;
	os.open(filenamep);
	os >> main_time;
	os >> *top;
	*/
}


// Reset simulation variables and clocks
void resetSim() {
	main_time = 0;
	top->RESET = 1;
	clk_sys.Reset();
}

int verilate() {
	int errors = 0;
	if (!Verilated::gotFinish()) {

		// Assert reset during startup
		if (main_time < initialReset) {
			top->RESET = 1;
		}
		// Deassert reset after startup
		if (main_time == initialReset) { top->RESET = 0; }

		// Clock dividers
		clk_sys.Tick();
		ce_11.Tick();

		// Set clocks in core
		top->emu->pll->outclk_1 = clk_sys.clk;
		top->emu->hps_io->status = status;
		// Simulate both edges of fastest clock
		if (clk_sys.clk != clk_sys.old) {

			// System clock simulates HPS functions
			if (ce_11.clk) {
				input.BeforeEval();
			}

			if (clk_sys.IsRising()) {
				if (main_time > initialReset) {
					bus.BeforeEval();
				}
				Rams.BeforeEval();
				SDram.BeforeEval();
			}
			
			top->eval();
			
			
			if (clk_sys.IsRising()) {
				Rams.AfterEval();
				SDram.AfterEval();
				DDR.AfterEval();
				//	errors = debuger.AfterEval(main_time);
				if (top->emu->MSX->ce_pix) {
					uint32_t colour = 0xFF000000 | top->emu->MSX->B << 16 | top->emu->MSX->G << 8 | top->emu->MSX->R;
					video.Clock(top->emu->MSX->hblank, top->emu->MSX->vblank, top->emu->MSX->HS, top->emu->MSX->VS, colour);
				}
/*
				if (top->emu->MSX->vdp_vdp18->ce_pix) {
					uint32_t colour = 0xFF000000 | top->emu->MSX->vdp_vdp18->rgb_b_o << 16 | top->emu->MSX->vdp_vdp18->rgb_g_o << 8 | top->emu->MSX->vdp_vdp18->rgb_r_o;
					video.Clock(top->emu->MSX->vdp_vdp18->hblank_o, top->emu->MSX->vdp_vdp18->vblank_o, top->emu->MSX->vdp_vdp18->hsync_n_o, top->emu->MSX->vdp_vdp18->vsync_n_o, colour);
				}
*/
			}
			
			
			if (Trace) {
				if (!tfp->isOpen()) tfp->open(Trace_File);
				tfp->dump(main_time); //Trace
			}
			
			if (clk_sys.IsFalling()) 
			{
				bus.AfterEval();
				
				// Ladìní load
				//if (bus.AfterEval())
				//{
				//	Trace = 1;
				//}
			}

		}

		// Output pixels on rising edge of pixel clock
		/*
		if (clk_sys.IsRising() && top->ce_pix) {
			uint32_t colour = 0xFF000000 | top->B << 16 | top->G << 8 | top->R;
			video.Clock(top->hblank, top->vblank, top->hsync_n, top->vsync_n, colour);
		}
		*/
		main_time++;
		//if (main_time == 16328900) Trace = 1; // 19000000 RESET//60000000 cca zobrazení videa
		//if (main_time == 60000000) Trace = 1; // 19000000 RESET//60000000 cca zobrazení videa
		//if (main_time == 44000000) Trace = 1; // 19000000 RESET//60000000 cca zobrazení videa
		//if (main_time == 73000000) Trace = 1; // 19000000 RESET//60000000 cca zobrazení videa
		//if (main_time == 83000000) Trace = 1; // 19000000 RESET//60000000 cca zobrazení videa
		
		int ret = 1;
		if (errors > 0) {
			ret = 0;
		}
		//if (main_time == 18000000) ret = 0; //Stop Trace
		return ret;
	}

	// Stop verilating and cleanup
	top->final();
	delete top;
	exit(0);
	return 0;
}

int main(int argc, char** argv, char** env) {

	// Create core and initialise
	top = new Vemu();

	Verilated::commandArgs(argc, argv);

	//Prepare for Dump Signals
	Verilated::traceEverOn(true); //Trace
	top->trace(tfp, 1);// atoi(Trace_Deep) );  // Trace 99 levels of hierarchy
	if (Trace) tfp->open(Trace_File);//"simx.vcd"); //Trace

#ifdef WIN32
	// Attach debug console to the verilated code
	Verilated::setDebug(console);
#endif

	// Attach bus
/*
	systemRAM_mem = Rams.AddRAM(
		1,
		&systemRAM->address_a,
		&systemRAM->data_a,
		&systemRAM->q_a,
		&systemRAM->wren_a,
		&systemRAM->address_b,
		&systemRAM->data_b,
		&systemRAM->q_b,
		&systemRAM->wren_b,
		1 << systemRAM->addr_width);
*/
	vdp_mem_hi = Rams.AddRAM(
		2,
		&VRAMhi->address,
		&VRAMhi->data,
		&VRAMhi->q,
		&VRAMhi->wren,
		1 << VRAMhi->addr_width);

	vdp_mem_lo = Rams.AddRAM(
		3,
		&VRAMlo->address,
		&VRAMlo->data,
		&VRAMlo->q,
		&VRAMlo->wren,
		1 << VRAMlo->addr_width);

	kbd_map = Rams.AddRAM(
		4,
		&kbd->address,
		&kbd->data,
		&kbd->q,
		&kbd->wren,
		1 << kbd->addr_width);
	
	DDR.addr = &top->emu->buffer->addr;
	DDR.dout = &top->emu->buffer->dout;
	DDR.rd = &top->emu->buffer->rd;
	DDR.ready = &top->emu->buffer->ready;

	SDram.channels_rtl[0].ch_addr = &top->emu->sdram->ch1_addr;
	SDram.channels_rtl[0].ch_din = &top->emu->sdram->ch1_din;
	SDram.channels_rtl[0].ch_dout = &top->emu->sdram->ch1_dout;
	SDram.channels_rtl[0].ch_req = &top->emu->sdram->ch1_req;
	SDram.channels_rtl[0].ch_rnw = &top->emu->sdram->ch1_rnw;
	SDram.channels_rtl[0].ch_ready = &top->emu->sdram->ch1_ready;
	
	SDram.channels_rtl[1].ch_addr = &top->emu->sdram->ch2_addr;
	SDram.channels_rtl[1].ch_din = &top->emu->sdram->ch2_din;
	SDram.channels_rtl[1].ch_dout = &top->emu->sdram->ch2_dout;
	SDram.channels_rtl[1].ch_req = &top->emu->sdram->ch2_req;
	SDram.channels_rtl[1].ch_rnw = &top->emu->sdram->ch2_rnw;
	SDram.channels_rtl[1].ch_ready = &top->emu->sdram->ch2_ready;

	SDram.channels_rtl[2].ch_addr = &top->emu->sdram->ch3_addr;
	SDram.channels_rtl[2].ch_din = &top->emu->sdram->ch3_din;
	SDram.channels_rtl[2].ch_dout = &top->emu->sdram->ch3_dout;
	SDram.channels_rtl[2].ch_req = &top->emu->sdram->ch3_req;
	SDram.channels_rtl[2].ch_rnw = &top->emu->sdram->ch3_rnw;
	SDram.channels_rtl[2].ch_ready = &top->emu->sdram->ch3_ready;
	SDram.channels_rtl[2].ch_done = &top->emu->sdram->ch3_done;
	SDram.Initialise(0x1000000);

	DDR.Initialise(256*1024*1024); //256Mb
	
	bus.ioctl_addr = &top->emu->hps_io->ioctl_addr;
	bus.ioctl_index = &top->emu->hps_io->ioctl_index;
	bus.ioctl_wait = &top->emu->hps_io->ioctl_wait;
	bus.ioctl_download = &top->emu->hps_io->ioctl_download;
	bus.ioctl_wr = &top->emu->hps_io->ioctl_wr;
	bus.ioctl_dout = &top->emu->hps_io->ioctl_dout;
	top->emu->hps_io->sdram_sz = SDram.getHPSsize();

	/*
	debuger.data = &top->emu->MSX->Z80->di;
	debuger.reset_n = &top->emu->MSX->Z80->reset_n;
	debuger.rd_n = &top->emu->MSX->Z80->rd_n;
	debuger.wr_n = &top->emu->MSX->Z80->wr_n;
	debuger.mreq_n = &top->emu->MSX->Z80->mreq_n;
	debuger.addr = &top->emu->MSX->Z80->A;
	debuger.data_out = &top->emu->MSX->Z80->dout;
	*/
	input.ps2_key = &top->emu->hps_io->ps2_key;
	input.Initialise();


	// Setup video output
	if (video.Initialise(windowTitle) == 1) { return 1; }


	//30000000 ROM Pack = Romky MSX			3 MB
	//30300000 FW Pack  = Romky Cartrige	9 MB
	//30C00000 ROM CART 1                   5 MB
	//31100000 ROM CART 2                   5 MB
	//31600000 ROM CRC						1 MB
	//31700000 CAS 
	//40000000 Maximum					

	//bus.QueueDownload("./rom/Deep Dungeon 1 - Scaptrust [ASCII8SRAM2] .rom", 3, true, 0x30C00000, &DDR); //27FD8F9A
	bus.QueueDownload("./rom/Mappers/mappers.db", 6, true, 0x31600000, &DDR);
	bus.QueueDownload("./rom/FWpack/CART_FW_EN.msx", 2, true, 0x30300000, &DDR);
	//bus.QueueDownload("./rom/roms/R-Type - IREM [R-Type] .rom", 3, true, 0x30C00000, &DDR);
	//bus.QueueDownload("./rom/roms/1942-Capcom_[ASCII8].rom", 3, true, 0x30C00000, &DDR);
	//bus.QueueDownload("./rom/roms/Konami's Game Master 2 - Konami [GameMaster2] [RC-755] .rom", 3, true, 0x30C00000, &DDR);
	//bus.QueueDownload("./rom/roms/Genghis Khan - MSX1 Version - KOEI [KoeiSRAM32] .rom", 3, true, 0x30C00000, &DDR);
	//bus.QueueDownload("./rom/roms/10th Frame - Access Software [ASCII16].rom", 3, true, 0x30C00000, &DDR);
	//bus.QueueDownload("./rom/roms/Penguin Adventure - Yumetairiku Adventure - Konami [Konami] [RC-743] .rom", 3, true, 0x30C00000, &DDR);
	//bus.QueueDownload("./rom/roms/Gradius_2-Nemesis_2-Konami[KonamiSCC][RC-751].rom", 3, true, 0x30C00000, &DDR);
	bus.QueueDownload("./rom/roms/ASCII16SRAM2/Hydlide 2 - Shine Of Darkness - T&ESOFT [ASCII16SRAM2].rom", 3, true, 0x30C00000, &DDR);
	bus.QueueDownload("./rom/ROMpack/Philips_VG_8020-00.msx", 1, true, 0x30000000, &DDR);
	//bus.QueueDownload("./rom/ROMpack/Philips_NMS_8250.msx", 1, true, 0x30000000, &DDR);
	//bus.QueueDownload("./rom/ROMpack/Philips_NMS_8245.msx", 1, true, 0x30000000, &DDR);
	//bus.QueueDownload("./rom/Philips_NMS_8245.msx", 1, true);
	//bus.QueueDownload("./rom/Philips_NMS_8245.msx", 1, false);

	ChangeStatus();	//Nastav status (defaultní hodnotu)
#ifdef WIN32
	MSG msg;
	ZeroMemory(&msg, sizeof(msg));
	while (msg.message != WM_QUIT)
	{
		if (PeekMessage(&msg, NULL, 0U, 0U, PM_REMOVE))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
			continue;
		}
#else
	bool done = false;
	while (!done)
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			ImGui_ImplSDL2_ProcessEvent(&event);
			if (event.type == SDL_QUIT)
				done = true;
		}
#endif
		video.StartFrame();
		input.Read();

		// Draw GUI
		// --------
		ImGui::NewFrame();

		// Simulation control window
		ImGui::Begin(windowTitle_Control);
		ImGui::SetWindowPos(windowTitle_Control, ImVec2(0, 0), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Control, ImVec2(500, 150), ImGuiCond_Once);
		if (ImGui::Button("Reset simulation")) { resetSim(); } ImGui::SameLine();
		if (ImGui::Button("Start running")) { run_enable = 1; } ImGui::SameLine();
		if (ImGui::Button("Stop running")) { run_enable = 0; } ImGui::SameLine();
		ImGui::Checkbox("RUN", &run_enable);
		//ImGui::PopItemWidth();
		ImGui::SliderInt("Run batch size", &batchSize, 1, 250000);
		if (single_step == 1) { single_step = 0; }
		if (ImGui::Button("Single Step")) { run_enable = 0; single_step = 1; }
		ImGui::SameLine();
		if (multi_step == 1) { multi_step = 0; }
		if (ImGui::Button("Multi Step")) { run_enable = 0; multi_step = 1; }
		//ImGui::SameLine();
		ImGui::SliderInt("Multi step amount", &multi_step_amount, 8, 1024);

		ImGui::End();


		// Debug log window
		console.Draw(windowTitle_DebugLog, &showDebugLog, ImVec2(500, 700));
		ImGui::SetWindowPos(windowTitle_DebugLog, ImVec2(0, 160), ImGuiCond_Once);

		// Memory debug
		ImGui::Begin("DDRAM");
		mem_edit.DrawContents(DDR.GetMem(), 256*1024*1024, 0x30000000);
		ImGui::End();
	
		ImGui::Begin("SDRAM");
		mem_edit.DrawContents(SDram.GetMem(), 0x1000000, 0);
		ImGui::End();


		ImGui::Begin("VRAM Editor HI");
		mem_edit.DrawContents(vdp_mem_hi->GetMem(), 1 << VRAMhi->addr_width, 0);
		ImGui::End();

		ImGui::Begin("VRAM Editor LO");
		mem_edit.DrawContents(vdp_mem_lo->GetMem(), 1 << VRAMlo->addr_width, 0);
		ImGui::End();


		ImGui::Begin("KEYBOARD");
		mem_edit.DrawContents(kbd_map->GetMem(), 1 << kbd->addr_width, 0);
		ImGui::End();
		
/*
		ImGui::Begin("RAM Editor");
		mem_edit.DrawContents(systemRAM_mem->GetMem(), 1 << systemRAM->addr_width, 0);
		ImGui::End();
*/
		
		//HPS emulace
		ImGui::Begin(windowTitle_HPS);
		ImGui::SetWindowPos(windowTitle_Trace, ImVec2(0, 870), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Trace, ImVec2(500, 150), ImGuiCond_Once);
		
		

		if (ImGui::Button("Load ROM PACK")) {
			fileData.addr = 0x30000000;
			fileData.ioctl_id = 1;
			fileData.mem = &DDR;
			fileData.reset = true;
			ImGuiFileDialog::Instance()->OpenDialog("ChooseFileDlgKey", "ROM PACK LOAD", ".msx", "./rom/ROMpack/", 1, &fileData);
		}
		if (ImGui::Button("Load FW PACK")) {
			fileData.addr = 0x30300000;
			fileData.ioctl_id = 2;
			fileData.mem = &DDR;
			fileData.reset = true;
			ImGuiFileDialog::Instance()->OpenDialog("ChooseFileDlgKey", "FW PACK LOAD", ".msx", "./rom/FWpack/", 1, &fileData);
		}

		if (ImGui::Button("Load DB MAPPER")) {
			fileData.addr = 0x31600000;
			fileData.ioctl_id = 6;
			fileData.mem = &DDR;
			fileData.reset = true;
			ImGuiFileDialog::Instance()->OpenDialog("ChooseFileDlgKey", "DB MAPPERS LOAD", ".db", "./rom/Mappers/", 1, &fileData);
		}

		if (ImGui::Button("Load ROM A")) {
			fileData.addr = 0x30C00000;
			fileData.ioctl_id = 3;
			fileData.mem = &DDR;
			fileData.reset = true;
			ImGuiFileDialog::Instance()->OpenDialog("ChooseFileDlgKey", "ROM A", ".rom", "./rom/roms/", 1, &fileData);
		}

		if (ImGui::Button("Load ROM B")) {
			fileData.addr = 0x31100000;
			fileData.ioctl_id = 4;
			fileData.mem = &DDR;
			fileData.reset = true;
			ImGuiFileDialog::Instance()->OpenDialog("ChooseFileDlgKey", "ROM B", ".rom", "./rom/roms/", 1, &fileData);
		}

		ImGui::PushItemWidth(180.0f);
		if (ImGui::Combo("SLOT A", &currentSlotA, slotA1, IM_ARRAYSIZE(slotA1)))
		{
			ChangeStatus();
		}
		if (ImGui::Combo("MAPPER A", &currentMapperA, mapperA, IM_ARRAYSIZE(mapperA)))
		{
			ChangeStatus();
		}
		if (ImGui::Combo("SRAM A", &currentSramA, sramA, IM_ARRAYSIZE(sramA)))
		{
			ChangeStatus();
		}
		if (ImGui::Combo("SLOT B", &currentSlotB, slotB, IM_ARRAYSIZE(slotB)))
		{
			ChangeStatus();
		}
		if (ImGui::Combo("MAPPER B", &currentMapperB, mapperB, IM_ARRAYSIZE(mapperB)))
		{
			ChangeStatus();
		}
		ImGui::PopItemWidth();
		if (ImGuiFileDialog::Instance()->Display("ChooseFileDlgKey")) {
			if (ImGuiFileDialog::Instance()->IsOk()) {
				std::string filePath = ImGuiFileDialog::Instance()->GetFilePathName();
				std::string fileName = ImGuiFileDialog::Instance()->GetCurrentFileName();
				FileDialogData *data = static_cast<FileDialogData*>(ImGuiFileDialog::Instance()->GetUserDatas());
				bus.QueueDownload(ImGuiFileDialog::Instance()->GetFilePathName(), data->ioctl_id, data->reset, data->addr, data->mem);
			}
			ImGuiFileDialog::Instance()->Close();
		}
		ImGui::End();


		// Trace/VCD window
		ImGui::Begin(windowTitle_Trace);
		ImGui::SetWindowPos(windowTitle_Trace, ImVec2(0, 870), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Trace, ImVec2(500, 150), ImGuiCond_Once);

		if (ImGui::Button("Start VCD Export")) { Trace = 1; } ImGui::SameLine();
		if (ImGui::Button("Stop VCD Export")) { Trace = 0; } ImGui::SameLine();
		if (ImGui::Button("Flush VCD Export")) { tfp->flush(); } ImGui::SameLine();
		ImGui::Checkbox("Export VCD", &Trace);

		ImGui::PushItemWidth(120);
		if (ImGui::InputInt("Deep Level", &iTrace_Deep_tmp, 1, 100, ImGuiInputTextFlags_EnterReturnsTrue))
		{
			top->trace(tfp, iTrace_Deep_tmp);
		}

		if (ImGui::InputText("TraceFilename", Trace_File_tmp, IM_ARRAYSIZE(Trace_File), ImGuiInputTextFlags_EnterReturnsTrue))
		{
			strcpy(Trace_File, Trace_File_tmp); //TODO onChange Close and open new trace file
			tfp->close();
			if (Trace) tfp->open(Trace_File);
		};
		ImGui::Separator();
		if (ImGui::Button("Save Model")) { save_model(SaveModel_File); } ImGui::SameLine();
		if (ImGui::Button("Load Model")) {
			restore_model(SaveModel_File);
		} ImGui::SameLine();
		if (ImGui::InputText("SaveFilename", SaveModel_File_tmp, IM_ARRAYSIZE(SaveModel_File), ImGuiInputTextFlags_EnterReturnsTrue))
		{
			strcpy(SaveModel_File, SaveModel_File_tmp); //TODO onChange Close and open new trace file
		}
		ImGui::End();
		int windowX = 550;
		int windowWidth = (VGA_WIDTH * VGA_SCALE_X) + 24;
		int windowHeight = (VGA_HEIGHT * VGA_SCALE_Y) + 90;

		// Video window
		ImGui::Begin(windowTitle_Video);
		ImGui::SetWindowPos(windowTitle_Video, ImVec2(windowX, 0), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Video, ImVec2(windowWidth, windowHeight), ImGuiCond_Once);

		ImGui::SetNextItemWidth(400);
		ImGui::SliderFloat("Zoom", &vga_scale, 1, 8); ImGui::SameLine();
		ImGui::SetNextItemWidth(200);
		ImGui::SliderInt("Rotate", &video.output_rotate, -1, 1); ImGui::SameLine();
		ImGui::Checkbox("Flip V", &video.output_vflip);
		ImGui::Text("main_time: %d frame_count: %d sim FPS: %f", main_time, video.count_frame, video.stats_fps);
		//ImGui::Text("pixel: %06d line: %03d", video.count_pixel, video.count_line);

		// Draw VGA output
		ImGui::Image(video.texture_id, ImVec2(video.output_width * VGA_SCALE_X, video.output_height * VGA_SCALE_Y));
		ImGui::End();


		video.UpdateTexture();

		// Run simulation
		if (run_enable) {
			for (int step = 0; step < batchSize; step++) { 
				run_enable = verilate();
				if (!run_enable)
					break;
			}
		}
		else {
			if (single_step) { verilate(); }
			if (multi_step) {
				for (int step = 0; step < multi_step_amount; step++) { verilate(); }
			}
		}
	}

	// Clean up before exit
	// --------------------

	video.CleanUp();

	return 0;
}
