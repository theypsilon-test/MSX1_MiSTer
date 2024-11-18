#include "sim_main.h"
#include "tests.h"

void initComputer() {
	//scc_configure();
	mfrsd_configure();
}

void test(SimCPU &CPU) {
	//scc_test(CPU);
	mfrsd_test(CPU);
}