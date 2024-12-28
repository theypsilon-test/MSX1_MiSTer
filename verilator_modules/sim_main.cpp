#include <verilated.h>
#include "Vmodules__Syms.h"

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

#include "sim_main.h"
#include "sim_console.h"
#include "sim_video.h"
#include "sim_clock.h"
#include "sim_cpu.h"
#include "sim_sdram.h"
#include "tests.h"

#include "../imgui/imgui_memory_editor.h"
#include <verilated_vcd_c.h> //VCD Trace
#include "../imgui/ImGuiFileDialog.h"

#include <iostream>
#include <fstream>
using namespace std;

// Simulation control
// ------------------
int initialReset = 30;
bool run_enable = false;
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

// Verilog module
// --------------
Vmodules* top = NULL;

bool showDebugLog = true;
DebugConsole console;
MemoryEditor mem_edit;

struct FileDialogData
{
	uint8_t ioctl_id;
	bool reset;
	uint32_t addr;
};

FileDialogData fileData;
SimCPU CPU;

SimSDRAM SDram(console);

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

// Verilog module
// --------------
//Vmodules* top = NULL;

vluint64_t main_time = 0;	// Current simulation time.
double sc_time_stamp() {	// Called by $time in Verilog.
	return main_time;
}


int clk_sys_freq = 42954545;
SimClock clk_sys(1,5);  // 42.954545mhz

// VCD trace logging
// -----------------
VerilatedVcdC* tfp = new VerilatedVcdC; //Trace
bool Trace = true;
char Trace_Deep[3] = "99";
char Trace_File[30] = "sim.vcd";
char Trace_Deep_tmp[3] = "99";
char Trace_File_tmp[30] = "sim.vcd";
int  iTrace_Deep_tmp = 99;
char SaveModel_File_tmp[20] = "test", SaveModel_File[20] = "test";

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
	top->reset = 1;
	clk_sys.Reset();
	CPU.Reset();
}

int verilate() {
	bool ret = true;
	if (!Verilated::gotFinish()) {

		// Assert reset during startup
		if (main_time < initialReset) {
			top->reset = 1;
		}
		// Deassert reset after startup
		if (main_time == initialReset) { top->reset = 0; }

		// Clock dividers
		clk_sys.Tick();

		// Set clocks in core
		top->clk = clk_sys.clk;
		top->clk_ce = clk_sys.en;

		// Simulate both edges of fastest clock
		if (clk_sys.clk != clk_sys.old) {
			
			if (clk_sys.IsRising()) {
				SDram.BeforeEval();
			}
			
			top->eval();

			if (clk_sys.IsRising()) {
				
				SDram.AfterEval();
			
					if (clk_sys.en) {
						ret = CPU.AfterEval();
					}
			}

			if (CPU.trace) {
				if (!tfp->isOpen()) tfp->open(Trace_File);
				tfp->dump(main_time); //Trace
			}
		}

		main_time++;
//			if (main_time == 13176901) Trace = 1; // 19000000 RESET//60000000 cca zobrazení videa
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
	top = new Vmodules();

	Verilated::commandArgs(argc, argv);

	//Prepare for Dump Signals
	Verilated::traceEverOn(true); //Trace
	top->trace(tfp, 1);// atoi(Trace_Deep) );  // Trace 99 levels of hierarchy
	if (Trace) tfp->open(Trace_File);//"simx.vcd"); //Trace

#ifdef WIN32
	// Attach debug console to the verilated code
	Verilated::setDebug(console);
#endif
	CPU.trace = false;
	test(CPU);	//Nahraj CPU instrukce


	CData* rd_n;
	CData* mreq_n;
	CData* iord_n;
	CData* m1_n;
	CData* refresh_n;

	// Attach bus
	CPU.addr = &top->modules->cpu->A;
	CPU.dout = &top->modules->cpu->dout;
	CPU.wr_n = &top->modules->cpu->wr_n;
	CPU.rd_n = &top->modules->cpu->rd_n;
	CPU.mreq_n = &top->modules->cpu->mreq_n;
	CPU.iorq_n = &top->modules->cpu->iorq_n;
	CPU.m1_n = &top->modules->cpu->m1_n;
	CPU.refresh_n = &top->modules->cpu->rfsh_n;
	CPU.halt_n = &top->modules->cpu->halt_n;
	CPU.slot = &top->modules->slot_mapper;
	CPU.reset = &top->reset;

	SDram.channels_rtl[0].ch_addr = &top->modules->sdram->ch1_addr;
	SDram.channels_rtl[0].ch_din = &top->modules->sdram->ch1_din;
	SDram.channels_rtl[0].ch_dout = &top->modules->sdram->ch1_dout;
	SDram.channels_rtl[0].ch_req = &top->modules->sdram->ch1_req;
	SDram.channels_rtl[0].ch_rnw = &top->modules->sdram->ch1_rnw;
	SDram.channels_rtl[0].ch_ready = &top->modules->sdram->ch1_ready;


	SDram.channels_rtl[1].ch_addr = &top->modules->sdram->ch2_addr;
	SDram.channels_rtl[1].ch_din = &top->modules->sdram->ch2_din;
	SDram.channels_rtl[1].ch_dout = &top->modules->sdram->ch2_dout;
	SDram.channels_rtl[1].ch_req = &top->modules->sdram->ch2_req;
	SDram.channels_rtl[1].ch_rnw = &top->modules->sdram->ch2_rnw;
	SDram.channels_rtl[1].ch_ready = &top->modules->sdram->ch2_ready;
	SDram.channels_rtl[1].ch_done = &top->modules->sdram->ch2_done;

	SDram.channels_rtl[2].ch_addr = &top->modules->sdram->ch3_addr;
	SDram.channels_rtl[2].ch_din = &top->modules->sdram->ch3_din;
	SDram.channels_rtl[2].ch_dout = &top->modules->sdram->ch3_dout;
	SDram.channels_rtl[2].ch_req = &top->modules->sdram->ch3_req;
	SDram.channels_rtl[2].ch_rnw = &top->modules->sdram->ch3_rnw;
	SDram.channels_rtl[2].ch_ready = &top->modules->sdram->ch3_ready;
	SDram.channels_rtl[2].ch_done = &top->modules->sdram->ch3_done;

	SDram.Initialise(0x1000000);
	
	SDram.LoadData("./rom/nms8245_basic-bios2.rom", 0, 32768);	//bios
	SDram.LoadData("./rom/mfrsd.rom", 0x8000, 16384);			//Slot 0 mfrsd
	SDram.LoadData("./rom/mfrsd.rom", 0x488000, 1048576, 7340032);		//Slot 3 mfrsd
	
	// Setup video output
	if (video.Initialise(windowTitle) == 1) { return 1; }
	initComputer();
	resetSim();

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

		ImGui::Begin("SDRAM");
		mem_edit.DrawContents(SDram.GetMem(), 0x1000000, 0);
		ImGui::End();

		// Debug log window
		console.Draw(windowTitle_DebugLog, &showDebugLog, ImVec2(500, 700));
		ImGui::SetWindowPos(windowTitle_DebugLog, ImVec2(0, 160), ImGuiCond_Once);

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

		video.UpdateTexture();

		// Run simulation
		if (run_enable) {
			for (int step = 0; step < batchSize; step++) {
				run_enable = verilate();
				if (!run_enable)
					break;
			}
			if (!run_enable) {
				tfp->flush();
					//break;
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
	
	void setExpander(uint8_t slot, uint8_t en, uint8_t wo)
	{
		top->modules->slot_expander[slot & 3].__PVT__en = en & 1;
		top->modules->slot_expander[slot & 3].__PVT__wo = wo & 1;
	}

	void setBlock(uint8_t slot, uint8_t subslot, uint8_t block, Mapper mapper, Device device, uint8_t device_num, uint8_t cart_num, uint8_t ref_ram, uint8_t offset_ram, uint8_t ref_sram)
	{
		uint8_t _block = (slot & 3) << 4 | (subslot & 3) << 2 | (block & 3);
		setBlock(_block, mapper, device, device_num, cart_num, ref_ram, offset_ram, ref_sram);
	}
	
	void setBlock(uint8_t slot, uint8_t subslot, Mapper mapper, Device device, uint8_t device_num, uint8_t cart_num, uint8_t ref_ram, uint8_t offset_ram, uint8_t ref_sram)
	{
		uint8_t _block = (slot & 3) << 4 | (subslot & 3) << 2;
		setBlock(_block, mapper, device, device_num, cart_num, ref_ram, offset_ram, ref_sram);
		setBlock(_block | 1, mapper, device, device_num, cart_num, ref_ram, offset_ram, ref_sram);
		setBlock(_block | 2, mapper, device, device_num, cart_num, ref_ram, offset_ram, ref_sram);
		setBlock(_block | 3, mapper, device, device_num, cart_num, ref_ram, offset_ram, ref_sram);
	}

	void setBlock(uint8_t block, Mapper mapper, Device device, uint8_t device_num, uint8_t cart_num, uint8_t ref_ram, uint8_t offset_ram, uint8_t ref_sram)
	{
		uint8_t _block = block & 63;

		top->modules->slot_layout[_block].__PVT__cart_num = cart_num & 1;
		top->modules->slot_layout[_block].__PVT__device = device;
		top->modules->slot_layout[_block].__PVT__device_num = device_num & 3;
		top->modules->slot_layout[_block].__PVT__mapper = mapper ;
		top->modules->slot_layout[_block].__PVT__offset_ram = offset_ram & 3;
		top->modules->slot_layout[_block].__PVT__ref_ram = ref_ram & 0xF;
		top->modules->slot_layout[_block].__PVT__ref_sram & 3;
	}

	uint32_t setRam(uint8_t ref, uint32_t addr, uint32_t size, bool ro)
	{
		uint8_t _ref = ref & 0xF;
		uint32_t _size = size / 16384;
		top->modules->lookup_RAM[_ref].__PVT__addr = addr;
		top->modules->lookup_RAM[_ref].__PVT__size = _size;
		top->modules->lookup_RAM[_ref].__PVT__ro = ro;
		return (addr + size);
	}

	void setSram(uint8_t ref, uint32_t addr, uint16_t size)
	{
		uint8_t _ref = ref & 0x3;
		
		top->modules->lookup_SRAM[_ref].__PVT__addr = addr;
		top->modules->lookup_SRAM[_ref].__PVT__size = size;
	}

	void setDevice(uint8_t id, uint8_t mask, uint8_t port, uint8_t num, uint8_t param, Device device)
	{
		uint8_t _id = id & 0xF;
		
		top->modules->io_device[_id].__PVT__id = device;
		top->modules->io_device[_id].__PVT__mask = mask;
		top->modules->io_device[_id].__PVT__port = port;
		top->modules->io_device[_id].__PVT__num = num;
		top->modules->io_device[_id].__PVT__param = param;
	}

	void setBlockDevice(uint8_t num, uint8_t param, Device device)
	{
		top->modules->dev_enable[device] = num & 3;
		top->modules->dev_params[device][num & 3] = param;
	}