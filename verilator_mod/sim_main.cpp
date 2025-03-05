#include <verilated.h>
#include "Vtop__Syms.h"

#include "sim_main.h"
#include "sim_console.h"
#include "sim_clock.h"

#include <verilated_vcd_c.h> //VCD Trace
#include "sim_player.h"

#include <iostream>
#include <fstream>
using namespace std;

// Simulation control
// ------------------
int batchSize = 150000;
bool run_enable = true;

// Verilog module
// --------------
Vtop* top = NULL;
SimPlayer* player = NULL;

vluint64_t main_time = 0;	// Current simulation time.
double sc_time_stamp() {	// Called by $time in Verilog.
	return main_time;
}

// VCD trace logging
// -----------------
VerilatedVcdC* tfp = new VerilatedVcdC; //Trace
bool Trace = true;
char Trace_Deep[3] = "99";
char Trace_File[30] = "sim.vcd";
char Trace_Deep_tmp[3] = "99";
char Trace_File_tmp[30] = "sim.vcd";
int  iTrace_Deep_tmp = 99;

//Trace Save/Restore
void save_model(const char* filenamep) {
}
void restore_model(const char* filenamep) {
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


	Verilated::commandArgs(argc, argv);

	//Prepare for Dump Signals
	Verilated::traceEverOn(true); //Trace
	top->trace(tfp, 99);
	if (Trace) tfp->open(Trace_File);//"simx.vcd"); //Trace

	// Attach debug console to the verilated code
//	Verilated::setDebug(console);

	MSG msg;
	while (true)
	{
		tfp->flush();
		tfp->close();

		for (int step = 0; step < batchSize; step++) {
			run_enable = verilate();
			if (!run_enable)
				break;
		}
		if (!run_enable) {
			tfp->flush();
			tfp->close();
			return 0;
		}
	}

	return 0;
}
	
	