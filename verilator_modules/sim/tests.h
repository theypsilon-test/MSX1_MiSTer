#pragma once
#include "sim_cpu.h"
void initComputer(void);
void test(SimCPU &CPU);

void scc_test(SimCPU &CPU);
void scc_configure();

void mfrsd_configure();
void mfrsd_test(SimCPU& CPU);