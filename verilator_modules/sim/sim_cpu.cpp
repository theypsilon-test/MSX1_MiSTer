#include "sim_cpu.h"

SimCPU::SimCPU() {

}

void SimCPU::tick(uint32_t count) {
	commandReccord record;
	record.type = TICK;
	record.tick.count = count;
	commandQueue.push(record);
}

void SimCPU::memoryWrite(uint16_t addr, uint8_t value) {
	commandReccord record;
	record.type = MEM_WR;
	record.memory_wr.address = addr;
	record.memory_wr.value = value;
	commandQueue.push(record);
}

void SimCPU::memoryRead(uint16_t addr) {
	commandReccord record;
	record.type = MEM_RD;
	record.memory_rd.address = addr;
	commandQueue.push(record);
}

void SimCPU::ioWrite(uint8_t addr, uint8_t value, uint8_t value2) {
	commandReccord record;
	record.type = IO_WR;
	record.io_wr.address = addr;
	record.io_wr.value = value;
	record.io_wr.value2 = value2;
	commandQueue.push(record);
}

void SimCPU::ioRead(uint8_t addr, uint8_t value2) {
	commandReccord record;
	record.type = IO_RD;
	record.io_rd.address = addr;
	record.io_rd.value2 = value2;
	commandQueue.push(record);
}

void SimCPU::setSubSlot(uint8_t slot, uint8_t value) {
	commandReccord record;
	record.type = SETSUBSLOT;
	record.value.address = slot;
	record.value.value = value;
	commandQueue.push(record);
}

void SimCPU::setSlot(uint8_t block, uint8_t value) {
	commandReccord record;
	record.type = SETSLOT;
	record.value.address = block;
	record.value.value = value;
	commandQueue.push(record);
}

void SimCPU::setTrace(bool value) {
	commandReccord record;
	record.type = SETTRACE;
	record.trace.trace = value;
	commandQueue.push(record);
}

void SimCPU::setReset() {
	commandReccord record;
	record.type = RESET;
	commandQueue.push(record);
}

bool SimCPU::processSetSlot() {
	uint8_t mask  = 3 << ((currentCommand.value.address & 3) * 2);
	uint8_t value = (currentCommand.value.value & 3) << ((currentCommand.value.address & 3) * 2);
	*slot &= ~mask;
	*slot |= value;

	return true;
}

bool SimCPU::processSetSubSlot() {
	(*slot_subslot)[currentCommand.value.address & 03] = currentCommand.value.value;
	return true;
}

inline bool SimCPU::processMemWR() {
	switch (mstate) {

	case 0:
		*m1_n = 0;
		return 0;
	
	case 1:
		*m1_n = 1;
		return 0;
	
	case 2:
		*dout = currentCommand.memory_wr.value;
		return false;	
	
	case 3:
		*addr = currentCommand.memory_wr.address;
		return false;

	case 4:
		*mreq_n = 0;
		*wr_n = 0;
		return false;

	case 5:
		*mreq_n = 1;
		*wr_n = 1;
		return 0;
	
	case 6:
		*dout = 0xFF;
		return 0;
	
	case 7:
		return 1;
	
	}	
}

inline bool SimCPU::processMemRD() {
	switch (mstate) {

	case 0:
		*m1_n = 0;
		return 0;

	case 1:
		*m1_n = 1;
		return 0;

	case 2:
		*addr = currentCommand.memory_rd.address;
		return false;

	case 3:
		*mreq_n = 0;
		*rd_n = 0;
		return false;

	case 4:
		*mreq_n = 1;
		*rd_n = 1;
		return 0;

	case 5:
		return 0;

	case 6:
		return 1;

	}
}

inline bool SimCPU::processIoWR() {
	switch (mstate) {

	case 0:
		*m1_n = 0;
		return 0;

	case 1:
		*m1_n = 1;
		return 0;

	case 2:
		*dout = currentCommand.io_wr.value;
		return false;

	case 3:
		*addr = currentCommand.io_wr.value2 << 8 | currentCommand.io_wr.address;
		return false;

	case 4:
		*iorq_n = 0;
		*wr_n = 0;
		return false;

	case 5:
		*iorq_n = 1;
		*wr_n = 1;
		return 0;

	case 6:
		*dout = 0xFF;
		return 0;

	case 7:
		return 1;

	}
}

inline bool SimCPU::processIoRD() {
	switch (mstate) {

	case 0:
		*m1_n = 0;
		return 0;

	case 1:
		*m1_n = 1;
		return 0;

	case 2:
		*addr = currentCommand.io_rd.value2 << 8 | currentCommand.io_rd.address;
		return false;

	case 3:
		*iorq_n = 0;
		*rd_n = 0;
		return false;

	case 4:
		*iorq_n = 1;
		*rd_n = 1;
		return 0;

	case 5:
		return 0;

	case 6:
		return 1;

	}
}

inline bool SimCPU::processTick() {
	return mstate == currentCommand.tick.count;
}

inline bool SimCPU::processTrace() {
	this->trace = currentCommand.trace.trace;
	return true;
}

inline bool SimCPU::processReset() {
	if (mstate == 0) {
		*reset = 1;
		return false;
	}
	if (mstate == 5) {
		*reset = 0;
		return true;
	}
	return false;
}

bool SimCPU::processCommand() {
	bool ret = true;
	switch (currentCommand.type) {
		case MEM_WR:
			ret = processMemWR();
			break;
		case MEM_RD:
			ret = processMemRD();
			break;
		case IO_WR:
			ret = processIoWR();
			break;
		case IO_RD:
			ret = processIoRD();
			break;
		case TICK:
			ret = processTick();
			break;
		case SETSLOT:
			ret = processSetSlot();
			break;
		case SETSUBSLOT:
			ret = processSetSubSlot();
			break;
		case SETTRACE:
			ret = processTrace();
			break;
		case RESET:
			ret = processReset();
			break;
	}
	return ret;
}
bool SimCPU::BeforeEval() {
	return true;
}

bool SimCPU::AfterEval() {
	bool ret = true;
	switch (state) {
	case IDLE:
		if (commandQueue.size() > 0) {
			currentCommand = commandQueue.front();
			commandQueue.pop();
			mstate = 0;
			state = RUNNING;
		}
		break;
	case RUNNING:
		if (processCommand()) {
			state = NEXT;
		}
		mstate++;
		break;
	case NEXT:
		if (commandQueue.size() > 0) {
			currentCommand = commandQueue.front();
			commandQueue.pop();
			mstate = 0;
			state = RUNNING;
		}
		else {
			ret = false;
		}
		break;
	}
	return ret;
}


void SimCPU::Reset() {
	*mreq_n = 1;
	*iorq_n = 1;
	*wr_n = 1;
	*rd_n = 1;
	*m1_n = 1;
	*refresh_n = 1;
	*dout = 0xFF;
	*addr = 0x0000;
	*halt_n = 1;
	state = IDLE;
}