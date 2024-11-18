#include "sim_clock.h"
#include <string>

SimClock::SimClock() {
	ratio = 1;
	enabler = 0;
	count = 0;
	count_e = 0;
	en = false;
	clk = false;
	old = false;
}

SimClock::SimClock(int r) {
	ratio = r;
	count = 0; 
	count_e = 0;
	enabler = 0;
	en = false;
	clk = false;
	old = false;
}

SimClock::SimClock(int r, int e) {
	ratio = r;
	count = 0;
	count_e = 0;
	enabler = e;
	en = false;
	clk = false;
	old = false;
}


SimClock::~SimClock() {
}

void SimClock::Tick() {
	old = clk;
	count++;
	if (count > ratio) {
		count = 0;
		count_e++;
		en = false;
		if (enabler != 0 && count_e > enabler) {
			count_e = 0;
			en = true;
		}
	}
	clk = (count == 0);
}

void SimClock::Reset() {
	count = 0;
	clk = false;
	old = false;
}

bool SimClock::IsRising() {
	return clk && !old;
}

bool SimClock::IsFalling() {
	return !clk && old;
}