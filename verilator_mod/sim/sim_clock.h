#pragma once

class SimClock
{

public:
	bool clk, old, en;

	SimClock();
	SimClock(int r);
	SimClock(int r, int e);
	~SimClock();
	void Tick();
	void Reset();
	bool IsRising();
	bool IsFalling();

private:
	int ratio, count, count_e, enabler;
};