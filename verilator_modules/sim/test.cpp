#include "sim_main.h"
#include "tests.h"

void initComputer() {
	//scc_configure();
	//mfrsd_configure();
	setBlock(3, 0, MAPPER_NATIONAL, DEV_NONE, 0, 0, 1, 0, 0);
	setRam(0, 0, 16384, true);
}

void test(SimCPU &CPU) {
	//scc_test(CPU);
	// mfrsd_test(CPU);
	CPU.setTrace(false);
	CPU.tick(500);		//Reset stability
	CPU.setSlot(0, 3);
	CPU.setSlot(1, 3);
	CPU.setSlot(2, 3);
	CPU.setSlot(3, 3);
	CPU.setTrace(true);

	CPU.memoryRead(0x0000);
	CPU.memoryRead(0x4000);
	CPU.memoryRead(0x8000);
	CPU.memoryRead(0xE000);

	CPU.memoryWrite(0x6400, 0x1);
	CPU.memoryRead(0x0000);
	CPU.memoryRead(0x4000);
	
	CPU.memoryWrite(0x7ff9, 0x2);	//SRAM ENABLE

	CPU.memoryWrite(0x3FFD, 0x01);
	CPU.memoryWrite(0x3FFD, 0x02);

	/*CPU.memoryWrite(0x4000 | 0x3FF9, 0x10);
	CPU.memoryWrite(0x4000 | 0x3FFA, 0x11);
	CPU.memoryWrite(0x4000 | 0x3FFB, 0x12);
	CPU.memoryWrite(0x4000 | 0x3FFC, 0x01);
	CPU.memoryWrite(0x4000 | 0x3FFD, 0x02); */
}