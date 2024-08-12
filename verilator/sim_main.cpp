#include <verilated.h>
#include "Vmsx1__Syms.h"

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
const char* windowTitle = "Verilator Sim: Arcade-Centipede";
const char* windowTitle_Control = "Simulation control";
const char* windowTitle_DebugLog = "Debug log";
const char* windowTitle_Video = "VGA output";
const char* windowTitle_Trace = "Trace/VCD control";
const char* windowTitle_Audio = "Audio output";
bool showDebugLog = true;
DebugConsole console;
MemoryEditor mem_edit;

// HPS emulator
// ------------
SimBus bus(console);

// Video
// -----
#define VGA_WIDTH 320
#define VGA_HEIGHT 240
#define VGA_ROTATE -1  // 90 degrees anti-clockwise
#define VGA_SCALE_X vga_scale
#define VGA_SCALE_Y vga_scale
SimVideo video(VGA_WIDTH, VGA_HEIGHT, VGA_ROTATE);
float vga_scale = 2.5;

// Memory

#define systemRAM top->msx1->systemRAM

SimSDRAM SDram(console);
SimDDR DDR(console);
SimMemory Rams(console);

// Verilog module
// --------------
Vmsx1* top = NULL;

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
}

int verilate() {
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
		top->clk21m = clk_sys.clk;

		// Simulate both edges of fastest clock
		if (clk_sys.clk != clk_sys.old) {

			// System clock simulates HPS functions
			if (ce_11.clk) {
//				input.BeforeEval();
			}

			if (clk_sys.IsRising()) {
				if (main_time > initialReset) {
					bus.BeforeEval();
				}

				SDram.BeforeEval();
			}
			Rams.BeforeEval();
			top->eval();
			
			Rams.AfterEval();
			if (clk_sys.IsRising()) {
				SDram.AfterEval();
				DDR.AfterEval();
			}
			
			
			if (Trace) {
				if (!tfp->isOpen()) tfp->open(Trace_File);
				tfp->dump(main_time); //Trace
			}
			if (clk_sys.IsFalling()) {
				bus.AfterEval();
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
			
		return 1;
	}

	// Stop verilating and cleanup
	top->final();
	delete top;
	exit(0);
	return 0;
}

int main(int argc, char** argv, char** env) {

	// Create core and initialise
	top = new Vmsx1();

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

	Rams.AddRAM(
		&systemRAM->address_a,
		&systemRAM->data_a,
		&systemRAM->q_a,
		&systemRAM->wren_a,
		&systemRAM->address_b,
		&systemRAM->data_b,
		&systemRAM->q_b,
		&systemRAM->wren_b,
		1 << systemRAM->addr_width);

	DDR.addr = &top->msx1->buffer->addr;
	DDR.dout = &top->msx1->buffer->dout;
	DDR.rd = &top->msx1->buffer->rd;
	DDR.ready = &top->msx1->buffer->ready;


	SDram.q = &top->sdram_dout;
	SDram.data = &top->sdram_din;
	SDram.addr = &top->sdram_addr;
	SDram.rd = &top->sdram_rd;
	SDram.we = &top->sdram_we;
	SDram.ready = &top->sdram_ready;
	SDram.size = &top->sdram_size;
	SDram.Initialise(0x1000000);

	DDR.Initialise(256*1024*1024); //256Mb
	bus.ioctl_addr = &top->ioctl_addr;
	bus.ioctl_index = &top->ioctl_index;
	bus.ioctl_wait = &top->ioctl_wait;
	bus.ioctl_download = &top->ioctl_download;
	bus.ioctl_wr = &top->ioctl_wr;
	bus.ioctl_dout = &top->ioctl_dout;

	// Setup video output
	if (video.Initialise(windowTitle) == 1) { return 1; }


	//30000000 ROM Pack = Romky MSX			3 MB
	//30300000 FW Pack  = Romky Cartrige	9 MB
	//30C00000 ROM CART 1                   5 MB
	//31100000 ROM CART 2                   5 MB
	//31600000 ROM CRC						1 MB
	//31700000 CAS 
	//40000000 Maximum					

	bus.QueueDownload("./rom/Deep Dungeon 1 - Scaptrust [ASCII8SRAM2] .rom", 3, true, 0x30C00000, &DDR); //27FD8F9A
	bus.QueueDownload("./rom/output_data.bin", 6, true, 0x31600000, &DDR);
	bus.QueueDownload("./rom/Philips_NMS_8245.msx", 1, true, 0x30000000, &DDR);

	//bus.QueueDownload("./rom/Philips_NMS_8245.msx", 1, true);
	//bus.QueueDownload("./rom/Philips_NMS_8245.msx", 1, false);


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
/*
		ImGui::Begin("VRAM Editor");
		mem_edit.DrawContents(VRAM.mem, VRAM.mem_size, 0);
		ImGui::End();

		ImGui::Begin("RAM Editor");
		mem_edit.DrawContents(RAM.mem, RAM.mem_size, 0);
		ImGui::End();
*/
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
			for (int step = 0; step < batchSize; step++) { verilate(); }
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
