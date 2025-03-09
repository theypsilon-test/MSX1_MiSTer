template <size_t VNUM>
void SimPlayer<VNUM>::addSignal(std::string name, signalReccord<VNUM> record) {
	signals.push_back(record);
	signalMap[name] = signals.size() - 1;
}

template <size_t VNUM>
void SimPlayer<VNUM>::addSignal(std::string name, SignalType type,  void* ptr, uint32_t size) {
	signalReccord<VNUM> record;
	uint64_t mask = size >= 64 ? -1 : (1ULL << size) - 1;
	record.type = type;
	record.signal.ptr = ptr;
	record.signal.mask = mask;
	addSignal(name, record);
	signals.push_back(record);
	signalMap[name] = signals.size() - 1;
}

template <size_t VNUM>
void SimPlayer<VNUM>::addSignalArr(std::string name, SignalType type, void *ptr[VNUM], uint32_t size) {
	signalReccord<VNUM> record;
	uint64_t mask = size >= 64 ? -1 : (1ULL << size) - 1;
	record.type = type;
	record.signals.ptr = ptr;
	record.signals.mask = mask;
	addSignal(name, record);
	signals.push_back(record);
	signalMap[name] = signals.size() - 1;
}

template <size_t VNUM>
void SimPlayer<VNUM>::addSignal(std::string name, CData* ptr, uint32_t size) {
	addSignal(name, CData_t, reinterpret_cast<void*>(ptr), size);
}

template <size_t VNUM>
void SimPlayer<VNUM>::addSignal(std::string name, SData* ptr, uint32_t size) {
	addSignal(name, SData_t, reinterpret_cast<void*>(ptr), size);
}

template <size_t VNUM>
void SimPlayer<VNUM>::addSignal(std::string name, IData* ptr, uint32_t size) {
	addSignal(name, IData_t, reinterpret_cast<void*>(ptr), size);
}

template <size_t VNUM>
void SimPlayer<VNUM>::addSignal(std::string name, QData* ptr, uint64_t size) {
	addSignal(name, QData_t, reinterpret_cast<void*>(ptr), size);
}

template <size_t VNUM>
void SimPlayer<VNUM>::addSignalArrVNUM(std::string name, CData(*ptr)[VNUM], uint32_t size) {
	//addSignalArr(name, CDataArr_t, reinterpret_cast<void* [VNUM]>(ptr), size);
}


template <size_t VNUM>
void SimPlayer<VNUM>::addSignalArrVNUM(std::string name, SData(*ptr)[VNUM], uint32_t size) {
	//addSignalArr(name, SDataArr_t, reinterpret_cast<void* [VNUM]>(ptr), size);
}

template <size_t VNUM>
void SimPlayer<VNUM>::addSignalArrVNUM(std::string name, IData(*ptr)[VNUM], uint32_t size) {
	//addSignalArr(name, IDataArr_t, reinterpret_cast<void*[VNUM]>(ptr), size);
}


template <size_t VNUM>
void SimPlayer<VNUM>::addSignalArrVNUM(std::string name, QData(*ptr)[VNUM], uint32_t size) {
	//addSignalArr(name, QDataArr_t, reinterpret_cast<void* [VNUM]>(ptr), size);
}