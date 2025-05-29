// Dear ImGui: standalone example application for DirectX 11
// If you are new to Dear ImGui, read documentation from the docs/ folder + read the top of imgui.cpp.
// Read online: https://github.com/ocornut/imgui/tree/master/docs

#include "imgui.h"
#include "imgui_impl_win32.h"
#include "imgui_impl_dx11.h"
#include <d3d11.h>
#include <tchar.h>

#include "trace.h"
#include "imgui_memory_editor.h"
#include <z80ex_dasm.h>

// Data
static ID3D11Device*            g_pd3dDevice = NULL;
static ID3D11DeviceContext*     g_pd3dDeviceContext = NULL;
static IDXGISwapChain*          g_pSwapChain = NULL;
static ID3D11RenderTargetView*  g_mainRenderTargetView = NULL;

// Forward declarations of helper functions
bool CreateDeviceD3D(HWND hWnd);
void CleanupDeviceD3D();
void CreateRenderTarget();
void CleanupRenderTarget();
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);


// Static state data
static std::vector<TraceRecord> s_trace;
static int64_t s_trace_position = 0;
static int64_t s_trace_offset = 0;

static int64_t s_trace_scroll_target = -1;



Z80EX_BYTE* data = NULL;
//char buf[80];
int64_t diss_pos;

Z80EX_BYTE readbyte_cb(Z80EX_WORD addr, void* user_data)
{
    uint16_t base_addr = *((int*)user_data);
    return(s_trace[diss_pos].cpu_inst.opcode[addr - base_addr]);
}

char* get_mnemonic(int64_t pos, uint16_t base) {
    char buf[80];
    char buf2[80];
    int t, t2;
    uint16_t base_addr = base, addr = base;
    diss_pos = pos;
    if (pos == 3460115) {
        diss_pos = diss_pos - 1;
        diss_pos = diss_pos + 1;
    }
    z80ex_dasm(buf, 80, 0, &t, &t2, readbyte_cb, addr, &base_addr);
    if (t2) {
        sprintf(buf2, "%-15s  t=%d/%d", buf, t, t2);
    }
    else {
        sprintf(buf2, "%-15s  t=%d", buf, t);
    }
    return buf2;
}


void trace_simulate_to(int64_t new_position)
{
    s_trace_position = new_position;   
}



int64_t trace_find_addr(int64_t start, int direction, int address)
{
    int64_t pos = start + direction;

    while (pos >= 0 && pos < s_trace.size())
    {
        const TraceRecord rec = s_trace[pos];
        switch (rec.type)
        {
                    case CPU_OPCODE:
                        if (rec.cpu_inst.start_PC == address) return pos;
                        break;
        default:
            break;
        }

        pos += direction;
    }

    return -1;
}

void draw_registr_view()
{
    const TraceRecord& rec = s_trace[s_trace_position];

    ImGui::Begin("Regs");
    ImGui::Text("AF: %04X  AF': %04X", rec.cpu_inst.AF, rec.cpu_inst.AF2);
    ImGui::Text("BC: %04X  BC': %04X", rec.cpu_inst.BC, rec.cpu_inst.BC2);
    ImGui::Text("DE: %04X  DE': %04X", rec.cpu_inst.DE, rec.cpu_inst.DE2);
    ImGui::Text("HL: %04X  HL': %04X", rec.cpu_inst.HL, rec.cpu_inst.HL2);
    ImGui::Text("IX: %04X  IY': %04X", rec.cpu_inst.IX, rec.cpu_inst.IY);
    ImGui::Text("PC: %04X  SP': %04X", rec.cpu_inst.PC, rec.cpu_inst.SP);
    ImGui::End();
}

void draw_trace_view()
{
    float text_height = ImGui::GetTextLineHeightWithSpacing();
    int64_t slider_min = 0;
    int64_t slider_max = s_trace.size() > 1000000 ? s_trace.size() - 1000000 : 0;

    static int step_pc_address = 0;

    int64_t scroll_target = s_trace_scroll_target;

    if (scroll_target >= 0)
    {
        s_trace_offset = scroll_target - 500000;
        if (s_trace_offset < 0) s_trace_offset = 0;
    }

    ImGui::SliderScalar("Offset", ImGuiDataType_S64, &s_trace_offset, &slider_min, &slider_max);
    
    ImGui::PushID("pc");

    ImGui::Text("PC");
    ImGui::SetNextItemWidth(120);
    ImGui::SameLine(); ImGui::InputInt("AddrPC", &step_pc_address, 1, 100, ImGuiInputTextFlags_CharsHexadecimal);
        ImGui::SameLine();
    if (ImGui::Button("< Prev"))
    {
        int64_t pos = trace_find_addr(s_trace_position, -1, step_pc_address);
        if (pos >= 0)
        {
            trace_simulate_to(pos);
            s_trace_scroll_target = pos;
        }
    }

    ImGui::SameLine();

    if (ImGui::Button("Next >"))
    {
        int64_t pos = trace_find_addr(s_trace_position, 1, step_pc_address);
        if (pos >= 0)
        {
            trace_simulate_to(pos);
            s_trace_scroll_target = pos;
        }
    }
    ImGui::PopID();

    if (!ImGui::BeginTable("trace", 4, ImGuiTableFlags_ScrollY, ImVec2(0.0f, 0.0f))) return;

    ImGui::TableSetupScrollFreeze(0, 1); // Make top row always visible
    ImGui::TableSetupColumn("Id", ImGuiTableColumnFlags_None);
    ImGui::TableSetupColumn("Addr", ImGuiTableColumnFlags_None);
    ImGui::TableSetupColumn("opcodes", ImGuiTableColumnFlags_None);
    ImGui::TableSetupColumn("Instr", ImGuiTableColumnFlags_None);
    ImGui::TableHeadersRow();

    size_t trace_count = s_trace.size() - s_trace_offset;
    //if (trace_count > 1000000) trace_count = 1000000;

    ImGuiListClipper clipper(trace_count);

    while (clipper.Step())
    {
        if (scroll_target != -1)
        {
            ImGui::SetScrollY(clipper.ItemsHeight * (scroll_target - s_trace_offset));
            s_trace_scroll_target = -1;
        }

        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
        {
            int64_t real_i = i + s_trace_offset;

            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            char index[16];
            sprintf(index, "%zd", real_i);

            
            if (ImGui::Selectable(index, real_i == s_trace_position, ImGuiSelectableFlags_SpanAllColumns))
            {
                trace_simulate_to(real_i);
            }

            ImGui::TableNextColumn();

            const TraceRecord& rec = s_trace[real_i];
            switch (rec.type)
            {
            case CPU_OPCODE:
                ImGui::Text("%04X", rec.cpu_inst.start_PC);
                ImGui::TableNextColumn();
                switch (rec.cpu_inst.opcodes)
                {
                case 1:
                    ImGui::Text("%02X", rec.cpu_inst.opcode[0]);
                    break;
                case 2:
                    ImGui::Text("%02X %02X", rec.cpu_inst.opcode[0], rec.cpu_inst.opcode[1]);
                    break;
                case 3:
                    ImGui::Text("%02X %02X %02X", rec.cpu_inst.opcode[0], rec.cpu_inst.opcode[1], rec.cpu_inst.opcode[2]);
                    break;
                case 4:
                    ImGui::Text("%02X %02X %02X %02X", rec.cpu_inst.opcode[0], rec.cpu_inst.opcode[1], rec.cpu_inst.opcode[2], rec.cpu_inst.opcode[3]);
                    break;
                }
                ImGui::TableNextColumn();
                ImGui::Text(get_mnemonic(real_i, rec.cpu_inst.start_PC));
                break;
            }
        }
    }

    ImGui::EndTable();
}

// Main code
int main(int, char**)
{
    s_trace = read_trace("output.bin");

    // Create application window
    //ImGui_ImplWin32_EnableDpiAwareness();
    WNDCLASSEX wc = { sizeof(WNDCLASSEX), CS_CLASSDC, WndProc, 0L, 0L, GetModuleHandle(NULL), NULL, NULL, NULL, NULL, _T("ImGui Example"), NULL };
    ::RegisterClassEx(&wc);
    HWND hwnd = ::CreateWindow(wc.lpszClassName, _T("Dear ImGui DirectX11 Example"), WS_OVERLAPPEDWINDOW, 100, 100, 1280, 800, NULL, NULL, wc.hInstance, NULL);

    // Initialize Direct3D
    if (!CreateDeviceD3D(hwnd))
    {
        CleanupDeviceD3D();
        ::UnregisterClass(wc.lpszClassName, wc.hInstance);
        return 1;
    }

    // Show the window
    ::ShowWindow(hwnd, SW_SHOWDEFAULT);
    ::UpdateWindow(hwnd);

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    //ImGui::StyleColorsLight();

    // Setup Platform/Renderer backends
    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);

    // Load Fonts
    // - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui::PushFont()/PopFont() to select them.
    // - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
    // - If the file cannot be loaded, the function will return NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    // - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
    // - Read 'docs/FONTS.md' for more instructions and details.
    // - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
    //io.Fonts->AddFontDefault();
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
    //ImFont* font = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, NULL, io.Fonts->GetGlyphRangesJapanese());
    //IM_ASSERT(font != NULL);

    // Our state
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    // Main loop
    bool done = false;
    while (!done)
    {
        // Poll and handle messages (inputs, window resize, etc.)
        // See the WndProc() function below for our to dispatch events to the Win32 backend.
        MSG msg;
        while (::PeekMessage(&msg, NULL, 0U, 0U, PM_REMOVE))
        {
            ::TranslateMessage(&msg);
            ::DispatchMessage(&msg);
            if (msg.message == WM_QUIT)
                done = true;
        }
        if (done)
            break;

        // Start the Dear ImGui frame
        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        ImGui::Begin("Trace");                          // Create a window called "Hello, world!" and append into it.

        draw_trace_view();
        ImGui::End();

        draw_registr_view();


        // Rendering
        ImGui::Render();
        const float clear_color_with_alpha[4] = { clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w };
        g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRenderTargetView, NULL);
        g_pd3dDeviceContext->ClearRenderTargetView(g_mainRenderTargetView, clear_color_with_alpha);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());

        g_pSwapChain->Present(1, 0); // Present with vsync
        //g_pSwapChain->Present(0, 0); // Present without vsync
    }

    // Cleanup
    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();

    CleanupDeviceD3D();
    ::DestroyWindow(hwnd);
    ::UnregisterClass(wc.lpszClassName, wc.hInstance);

    return 0;
}

// Helper functions

bool CreateDeviceD3D(HWND hWnd)
{
    // Setup swap chain
    DXGI_SWAP_CHAIN_DESC sd;
    ZeroMemory(&sd, sizeof(sd));
    sd.BufferCount = 2;
    sd.BufferDesc.Width = 0;
    sd.BufferDesc.Height = 0;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = hWnd;
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    UINT createDeviceFlags = 0;
    //createDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;
    D3D_FEATURE_LEVEL featureLevel;
    const D3D_FEATURE_LEVEL featureLevelArray[2] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0, };
    if (D3D11CreateDeviceAndSwapChain(NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, createDeviceFlags, featureLevelArray, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext) != S_OK)
        return false;

    CreateRenderTarget();
    return true;
}

void CleanupDeviceD3D()
{
    CleanupRenderTarget();
    if (g_pSwapChain) { g_pSwapChain->Release(); g_pSwapChain = NULL; }
    if (g_pd3dDeviceContext) { g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = NULL; }
    if (g_pd3dDevice) { g_pd3dDevice->Release(); g_pd3dDevice = NULL; }
}

void CreateRenderTarget()
{
    ID3D11Texture2D* pBackBuffer;
    g_pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
    g_pd3dDevice->CreateRenderTargetView(pBackBuffer, NULL, &g_mainRenderTargetView);
    pBackBuffer->Release();
}

void CleanupRenderTarget()
{
    if (g_mainRenderTargetView) { g_mainRenderTargetView->Release(); g_mainRenderTargetView = NULL; }
}

// Forward declare message handler from imgui_impl_win32.cpp
extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

// Win32 message handler
// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application, or clear/overwrite your copy of the mouse data.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application, or clear/overwrite your copy of the keyboard data.
// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
        return true;

    switch (msg)
    {
    case WM_SIZE:
        if (g_pd3dDevice != NULL && wParam != SIZE_MINIMIZED)
        {
            CleanupRenderTarget();
            g_pSwapChain->ResizeBuffers(0, (UINT)LOWORD(lParam), (UINT)HIWORD(lParam), DXGI_FORMAT_UNKNOWN, 0);
            CreateRenderTarget();
        }
        return 0;
    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU) // Disable ALT application menu
            return 0;
        break;
    case WM_DESTROY:
        ::PostQuitMessage(0);
        return 0;
    }
    return ::DefWindowProc(hWnd, msg, wParam, lParam);
}
