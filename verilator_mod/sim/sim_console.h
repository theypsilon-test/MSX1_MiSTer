#pragma once

struct DebugConsole {
public:
	void AddLog(const char* fmt, ...);
	DebugConsole();
	~DebugConsole();
	void ClearLog();
	//void Draw(const char* title, bool* p_open, ImVec2 size);
	//void    ExecCommand(const char* command_line);
	//int     TextEditCallback(ImGuiInputTextCallbackData* data);
};
