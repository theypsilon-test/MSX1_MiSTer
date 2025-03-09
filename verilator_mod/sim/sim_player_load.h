std::string to_upper(const std::string& str) {
	std::string result;
	for (char c : str) {
		result += std::toupper(c);
	}
	return result;
}

uint32_t parse_number(const std::string& str, const std::array<std::string, 10>& input_params) {
	uint32_t value = 0;
	std::stringstream ss;


	if (str.find("0x") == 0 || str.find("0X") == 0) {  // Hexadecimální èíslo
		ss << std::hex << str.substr(2);
	}
	else if (str.find("$") == 0) {
		ss << std::dec << str.substr(1);
		ss >> value;
		ss.str("");
		ss.clear();
		ss << std::string(input_params[value + 1].c_str());
		return parse_number(ss.str(), input_params);
	}
	else {  // Desítkové èíslo
		ss << std::dec << str;
	}

	ss >> value;
	return value;
}

template <size_t VNUM>
void SimPlayer<VNUM>::loadTestFiles() {
	fs::path folder = fs::current_path() / "test";
	std::array<std::string, 10> params;
	std::vector<commandRecord> commands;
	commandRecord rec;
	for (const auto& entry : fs::directory_iterator(folder)) {
		if (entry.is_regular_file() && entry.path().extension() == ".tst") {
			commands.clear();
			processTestFile(entry.path(), commands, params);
			playList record;
			record.position = 0;
			record.param = 0;
			record.commands = commands;
			record.name = entry.path().filename().string();
			playLists.push_back(record);
		}
	}
	std::cout << "LOAD done" << "\n";
}

template <size_t VNUM>
void SimPlayer<VNUM>::processTestFile(const fs::path& filePath, std::vector<commandRecord>& commands, const std::array<std::string, 10>& input_params) {
	std::ifstream file(filePath);
	if (!file) {
		std::cerr << "Nelze otevøít soubor: " << filePath << "\n";
		return;
	}

	std::cout << "Zpracovávám soubor: " << filePath.filename() << "\n";
	std::string line;
	while (std::getline(file, line)) {
		processLine(line, commands, input_params);
	}
}

std::tuple<std::string, int, int> parseSignalName(const std::string& input) {
	std::regex fullPattern(R"((\w+)\[(\d+):(\d+)\])");   // name[max:min]
	std::regex singlePattern(R"((\w+)\[(\d+)\])");       // name[value]
	std::regex nameOnlyPattern(R"((\w+))");              // name

	std::smatch match;
	std::string name;
	int min = -1, max = -1;

	if (std::regex_match(input, match, fullPattern)) {
		name = match[1];
		max = std::stoi(match[2]);
		min = std::stoi(match[3]);
	}
	else if (std::regex_match(input, match, singlePattern)) {
		name = match[1];
		min = max = std::stoi(match[2]);
	}
	else if (std::regex_match(input, match, nameOnlyPattern)) {
		name = match[1];
	}

	return { name, min, max };
}

template <size_t VNUM>
void SimPlayer<VNUM>::processLine(const std::string& line, std::vector<commandRecord>& commands, const std::array<std::string, 10>& input_params) {
	if (line.empty() || line[0] == '#') return;

	std::istringstream iss(line);
	std::string command;
	std::array<std::string, 10> params;
	size_t paramCount = 0;

	if (!(iss >> command)) {
		std::cerr << "Chybný formát øádku: " << line << "\n";
		return;
	}
	while (paramCount < params.size() && iss >> params[paramCount]) {
		paramCount++;
	}
	command = to_upper(command);

	commandRecord rec;
	image img;

	rec.type = cmd_NONE;
	if (command == "LOOP") {
		rec.type = cmd_LOOP;
		commands.push_back(rec);
	}
	else if (command == "SIGNAL") {
		rec.type = cmd_SET_SIGNAL;
		auto [name, min, max] = parseSignalName(params[0]);
		rec.signal.id = signalMap[name];
		rec.signal.min = min;
		rec.signal.max = max;
		rec.signal.value = parse_number(params[1], input_params);
		commands.push_back(rec);
	}
	else if (command == "WAIT") {
		rec.type = cmd_WAIT;
		rec.wait.count = parse_number(params[0], input_params);
		commands.push_back(rec);
	}
	else if (command == "LOOP_END") {
		rec.type = cmd_END_LOOP;
		commands.push_back(rec);
	}
	else if (command == "STOP") {
		rec.type = cmd_STOP;
		commands.push_back(rec);
	}
	else if (command == "INVERT_SIGNAL") {
		rec.type = cmd_INVERT_SIGNAL;
		auto [name, min, max] = parseSignalName(params[0]);
		rec.signal.id = signalMap[name];
		rec.signal.min = min;
		rec.signal.max = max;
		rec.signal.value = parse_number(params[1], input_params);
		commands.push_back(rec);
	}
	else if (command == "CALL") {
		fs::path folder = fs::current_path() / "test" / (params[0] + ".inc");
		processTestFile(folder, commands, params);
	}
	else if (command == "MISTER") {
		if (params[0] == "LOADIMG") {
			
			std::ifstream file(params[1], std::ios::binary | std::ios::ate);
			if (!file) {
				std::cerr << "Chyba: Nelze otevøít soubor!" << std::endl;
				exit(0);
			}

			std::streamsize size = file.tellg();
			file.seekg(0, std::ios::beg);

			char* buffer = new char[size];

			if (!file.read(buffer, size)) {
				std::cerr << "Chyba: Nepodaøilo se pøeèíst soubor!" << std::endl;
				delete[] buffer;
				exit(0);
			}

			file.close();
			uint32_t vnum = parse_number(params[2], input_params);
			image rec;
			rec.size = size;
			rec.clock_id = signalMap[params[3]];
			rec.pos = 0;
			rec.buffer = buffer;
			rec.last_clk = false;
			rec.last_rd = false;
			images[vnum] = rec;
			processLine("SIGNAL img_size " + std::to_string(size), commands, params);
			processLine("SIGNAL img_mounted[" + std::to_string(vnum) + "] 1", commands, params);
			processLine("WAIT 4", commands, params);
		}
		else {
			std::cerr << "Neznámý pøíkaz pro MISTER: " << command << "\n";
			exit(0);
		}
	}
	else {
		std::cerr << "Neznámý pøíkaz: " << command << "\n";
		exit(0);
	}
}


