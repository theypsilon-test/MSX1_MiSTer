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

// Verilog module
// --------------
Vtop* top = NULL;
SimPlayer<6>* player = NULL;

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
	player = new SimPlayer<6>();										// 6 VNUM zaøízení
	player->addSignal("A0", &top->A0, 1);
	player->addSignal("RDn", &top->RDn, 1);
	player->addSignal("WRn", &top->WRn, 1);
	player->addSignal("CSn", &top->CSn, 1);
	player->addSignal("WDAT", &top->WDAT, 8);
	player->addSignal("RDAT", &top->RDAT, 8);
	player->addSignal("DATOE", &top->DATOE, 1);
	player->addSignal("DACKn", &top->DACKn, 1);
	player->addSignal("DRQ", &top->DRQ, 1);
	player->addSignal("TC", &top->TC, 1);
	player->addSignal("INTn", &top->INTn, 1);
	player->addSignal("WAITIN", &top->WAITIN, 1);
	player->addSignal("sclk", &top->sclk, 1);
	player->addSignal("fclk", &top->fclk, 1);
	player->addSignal("rstn", &top->rstn, 1);

	// Mister IMAGE
	player->addSignal("img_mounted", &top->img_mounted, 6);
	player->addSignal("img_size", &top->img_size, 64);

	//SD block level access
	player->addSignalArrVNUM("sd_lba", &top->sd_lba, 32);
	player->addSignalArrVNUM("sd_blk_cnt",&top->sd_blk_cnt, 6);
	player->addSignal("sd_rd", &top->sd_rd, 6);
	player->addSignal("sd_wr", &top->sd_wr, 6);
	player->addSignal("sd_ack", &top->sd_ack, 6);

	// SD byte level access. Signals for 2-PORT altsyncram.
	player->addSignal("sd_buff_addr", &top->sd_buff_addr, 14);
	player->addSignal("sd_buff_dout", &top->sd_buff_dout, 8);
	player->addSignalArrVNUM("sd_buff_din", &top->sd_buff_din, 8);
	player->addSignal("sd_buff_wr", &top->sd_buff_wr, 1);

	player->loadTestFiles();


	Verilated::commandArgs(argc, argv);

	//Prepare for Dump Signals
	Verilated::traceEverOn(true); //Trace
	top->trace(tfp, 99);
	if (Trace) tfp->open(Trace_File);//"simx.vcd"); //Trace

	// Attach debug console to the verilated code
//	Verilated::setDebug(console);

	MSG msg;
	bool run_enable;
	do
	{
		run_enable = verilate();
	} while (run_enable);

	tfp->flush();
	tfp->close();
	return 0;
}
	
	