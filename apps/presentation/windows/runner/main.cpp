#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <iostream>

#include "flutter_window.h"
#include "flutter_window.h"
#include "utils.h"

#include "flutter/generated_plugin_registrant.h"
#include <desktop_multi_window/desktop_multi_window_plugin.h>
#include <app_links/app_links_plugin_c_api.h>
#include <audioplayers_windows/audioplayers_windows_plugin.h>
#include <file_selector_windows/file_selector_windows.h>
#include <screen_retriever_windows/screen_retriever_windows_plugin_c_api.h>
#include <url_launcher_windows/url_launcher_windows.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  DesktopMultiWindowSetWindowCreatedCallback([](void *controller) {
    auto *flutter_controller = reinterpret_cast<flutter::FlutterViewController *>(controller);
    // auto *registry = flutter_controller->engine();

    // Register plugins manually for secondary window to avoid singletons/conflicts
    // Only register plugins strictly needed for secondary windows.
    // Most plugins (AppLinks, Audioplayers) are singletons or resource-heavy 
    // and may crash if initialized twice in the same process group.
    
    // AppLinksPluginCApiRegisterWithRegistrar(registry->GetRegistrarForPlugin("AppLinksPluginCApi"));
    // AudioplayersWindowsPluginRegisterWithRegistrar(registry->GetRegistrarForPlugin("AudioplayersWindowsPlugin"));
    // FileSelectorWindowsRegisterWithRegistrar(registry->GetRegistrarForPlugin("FileSelectorWindows"));
    // ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar(registry->GetRegistrarForPlugin("ScreenRetrieverWindowsPluginCApi"));
    // UrlLauncherWindowsRegisterWithRegistrar(registry->GetRegistrarForPlugin("UrlLauncherWindows"));
    
    // Register desktop_multi_window to enable MethodChannel communication
    // Note: This may print "Error: main window already exists" to console, which is expected and safe.
    // DesktopMultiWindowPluginRegisterWithRegistrar(registry->GetRegistrarForPlugin("DesktopMultiWindowPlugin"));

    std::cout << "[Secondary Window] Created. Applying Fullscreen Logic..." << std::endl;

    // Manual Fullscreen/Frameless logic (replacing window_manager)
    HWND hwnd = flutter_controller->view()->GetNativeWindow();
    
    // Position: Fullscreen on current monitor (or nearest)
    HMONITOR hMonitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    MONITORINFO mi = { sizeof(mi) };
    GetMonitorInfo(hMonitor, &mi);
    
    int target_x = mi.rcMonitor.left;
    int target_y = mi.rcMonitor.top;
    int target_w = mi.rcMonitor.right - mi.rcMonitor.left;
    int target_h = mi.rcMonitor.bottom - mi.rcMonitor.top;

    std::cout << "[Secondary Window] Target Monitor: " << target_w << "x" << target_h << " @ " << target_x << "," << target_y << std::endl;

    // Style: Force POPUP (removes all decorations)
    // We remove OVERLAPPEDWINDOW (Caption, ThickFrame, SysMenu, Min/Max)
    // And add POPUP + VISIBLE
    LONG_PTR lStyle = GetWindowLongPtr(hwnd, GWL_STYLE);
    lStyle &= ~WS_OVERLAPPEDWINDOW;
    lStyle |= WS_POPUP | WS_VISIBLE;
    SetWindowLongPtr(hwnd, GWL_STYLE, lStyle);

    // FIX: Set native window background to BLACK to prevent white flash
    HBRUSH hBrush = CreateSolidBrush(RGB(0, 0, 0));
    SetClassLongPtr(hwnd, GCLP_HBRBACKGROUND, (LONG_PTR)hBrush);
    
    // Apply changes
    SetWindowPos(hwnd, HWND_TOP,
                 target_x, target_y,
                 target_w, target_h,
                 SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
                 
    std::cout << "[Secondary Window] Fullscreen Applied." << std::endl;
  });

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"presentation", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
