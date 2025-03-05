#include <verilated.h>
#include "Vtop__Syms.h"

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

#include "../imgui/imgui_memory_editor.h"
#include <verilated_vcd_c.h> //VCD Trace
#include "../imgui/ImGuiFileDialog.h"
#include "sim_player.h"

#include <iostream>
#include <fstream>
using namespace std;

// Simulation control
// ------------------
int ResetDuration = 30;
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


// Video
// -----
#define VGA_WIDTH 582 //320
#define VGA_HEIGHT 384 //240
//#define VGA_WIDTH 320
//#define VGA_HEIGHT 240
#define VGA_ROTATE 0
#define VGA_SCALE_X vga_scale
#define VGA_SCALE_Y vga_scale
SimVideo video(VGA_WIDTH, VGA_HEIGHT, VGA_ROTATE);
float vga_scale = 1;

// Verilog module
// --------------
Vtop* top = NULL;
SimPlayer* player = NULL;

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



// Verilog module
// --------------
//Vmodules* top = NULL;

vluint64_t main_time = 0;	// Current simulation time.
double sc_time_stamp() {	// Called by $time in Verilog.
	return main_time;
}


int clk_sys_freq = 21477273;
SimClock clk_sys(1);  // 21.477273 Mhz
SimClock clk_cpu(6);  // 3.5795455 Mhz

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

int ResetCounter = 0;
// Reset simulation variables and clocks
void resetSim() {
	main_time = 0;
	top->rstn = 0;
	clk_sys.Reset();
	clk_cpu.Reset();
	ResetCounter = ResetDuration;
}



int verilate() {
	if (!Verilated::gotFinish()) {

		bool command_execute = player->tick();

		top->eval();
		
		if (Trace) {
			if (!tfp->isOpen()) {
				tfp->open(Trace_File);
			}
			tfp->dump(main_time); //Trace
		}

		main_time++;

		return command_execute;
	}

	// Stop verilating and cleanup
	top->final();
	delete top;
	exit(0);
	return 0;
}

int main(int argc, char** argv, char** env) {

	// Create core and initialise
	top = new Vtop();
	player = new SimPlayer();
	player->addSignal("A0",     &top->A0    , 0x1);
	player->addSignal("RDn",    &top->RDn   , 0x1);
	player->addSignal("WRn",    &top->WRn   , 0x1);
	player->addSignal("CSn",    &top->CSn   , 0x1);
	player->addSignal("WDAT",   &top->WDAT  , 0xFF);
	player->addSignal("RDAT",   &top->RDAT  , 0xFF);
	player->addSignal("DATOE",  &top->DATOE , 0x1);
	player->addSignal("DACKn",  &top->DACKn , 0x1);
	player->addSignal("DRQ",    &top->DRQ   , 0x1);
	player->addSignal("TC",     &top->TC    , 0x1);
	player->addSignal("INTn",   &top->INTn  , 0x1);
	player->addSignal("WAITIN", &top->WAITIN, 0x1);
	player->addSignal("sclk",   &top->sclk  , 0x1);
	player->addSignal("fclk",   &top->fclk  , 0x1);
	player->addSignal("rstn",   &top->rstn  , 0x1);
	player->loadTestFiles();
	//player->test();





	Verilated::commandArgs(argc, argv);

	//Prepare for Dump Signals
	Verilated::traceEverOn(true); //Trace
	top->trace(tfp, 1);// atoi(Trace_Deep) );  // Trace 99 levels of hierarchy
	if (Trace) tfp->open(Trace_File);//"simx.vcd"); //Trace

#ifdef WIN32
	// Attach debug console to the verilated code
	Verilated::setDebug(console);
#endif

		// maxtrack = > 85,
		// maxbwidth = > (BR_300_D * sysclk / 1000000),
		// sysclk = > sysclk / 1000
		// sysclk	:integer	:=21477;		--in kHz

	// fclk clk21m
	// sclk 

	CData* rd_n;
	CData* mreq_n;
	CData* iord_n;
	CData* m1_n;
	CData* refresh_n;

	// Attach bus

	// Setup video output
	if (video.Initialise(windowTitle) == 1) { return 1; }
	
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

		// Debug log window
		console.Draw(windowTitle_DebugLog, &showDebugLog, ImVec2(500, 700));
		ImGui::SetWindowPos(windowTitle_DebugLog, ImVec2(0, 160), ImGuiCond_Once);

		// Trace/VCD window
		ImGui::Begin(windowTitle_Trace);
		ImGui::SetWindowPos(windowTitle_Trace, ImVec2(0, 870), ImGuiCond_Once);
		ImGui::SetWindowSize(windowTitle_Trace, ImVec2(500, 150), ImGuiCond_Once);

		if (ImGui::Button("Start VCD Export")) { 
			Trace = 1; 			
			if (!tfp->isOpen()) {
				tfp->open(Trace_File);
			}
		} 
		ImGui::SameLine();
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
	
	