#include "flutter_window.h"

#include <optional>
#include <variant>
#include "flutter/generated_plugin_registrant.h"
#include "osd_window.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::SetClickThrough(bool clickThrough) {
  is_click_through_ = clickThrough;
  if (OsdWindow::GetInstance().GetHandle()) {
    LONG_PTR exStyle = GetWindowLongPtr(OsdWindow::GetInstance().GetHandle(), GWL_EXSTYLE);
    if (clickThrough) {
      SetWindowLongPtr(OsdWindow::GetInstance().GetHandle(), GWL_EXSTYLE, exStyle | WS_EX_TRANSPARENT | WS_EX_NOACTIVATE);
    } else {
      SetWindowLongPtr(OsdWindow::GetInstance().GetHandle(), GWL_EXSTYLE, exStyle & ~WS_EX_TRANSPARENT & ~WS_EX_NOACTIVATE);
    }
  }
}

void FlutterWindow::RegisterOverlayHotKey(UINT modifiers, UINT vkKey) {
  HWND hwnd = GetHandle();
  if (!hwnd) return;
  UnregisterHotKey(hwnd, HOTKEY_OVERLAY_TOGGLE);
  RegisterHotKey(hwnd, HOTKEY_OVERLAY_TOGGLE, modifiers, vkKey);
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  HWND hwnd = GetHandle();
  if (hwnd) {
    RegisterOverlayHotKey(MOD_CONTROL | MOD_SHIFT, 'O');
    OsdWindow::GetInstance().CreateOSD();
  }

  method_channel_ = std::make_unique<flutter::MethodChannel<>>(
      flutter_controller_->engine()->messenger(), "smart_fan_cooling/window",
      &flutter::StandardMethodCodec::GetInstance());

  OsdWindow::GetInstance().SetPositionCallback([this](int x, int y) {
    if (method_channel_) {
      flutter::EncodableMap map;
      map[flutter::EncodableValue("posX")] = x;
      map[flutter::EncodableValue("posY")] = y;
      method_channel_->InvokeMethod("onPositionChanged", std::make_unique<flutter::EncodableValue>(map));
    }
  });

  method_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<>& call,
             std::unique_ptr<flutter::MethodResult<>> result) {
        if (call.method_name() == "setAlwaysOnTop") {
          bool enable = true;
          if (const auto* args = std::get_if<bool>(call.arguments())) {
            enable = *args;
          }
          this->is_always_on_top_ = enable;
          OsdWindow::GetInstance().ShowOSD(enable);
          result->Success(true);
        } else if (call.method_name() == "setClickThrough") {
          bool enable = true;
          if (const auto* args = std::get_if<bool>(call.arguments())) {
            enable = *args;
          }
          OsdWindow::GetInstance().SetClickThrough(enable);
          result->Success(true);
        } else if (call.method_name() == "updateOsdData") {
          if (const auto* map = std::get_if<flutter::EncodableMap>(call.arguments())) {
            OsdData data;
            auto getBool = [&](const char* key, bool defVal) -> bool {
              auto it = map->find(flutter::EncodableValue(key));
              if (it != map->end()) {
                if (const auto* v = std::get_if<bool>(&it->second)) return *v;
              }
              return defVal;
            };
            auto getInt = [&](const char* key, int defVal) -> int {
              auto it = map->find(flutter::EncodableValue(key));
              if (it != map->end()) {
                if (const auto* v = std::get_if<int>(&it->second)) return *v;
                if (const auto* v = std::get_if<double>(&it->second)) return static_cast<int>(*v);
              }
              return defVal;
            };
            auto getDouble = [&](const char* key, double defVal) -> double {
              auto it = map->find(flutter::EncodableValue(key));
              if (it != map->end()) {
                if (const auto* v = std::get_if<double>(&it->second)) return *v;
                if (const auto* v = std::get_if<int>(&it->second)) return static_cast<double>(*v);
              }
              return defVal;
            };
            auto getString = [&](const char* key, const std::string& defVal) -> std::string {
              auto it = map->find(flutter::EncodableValue(key));
              if (it != map->end()) {
                if (const auto* v = std::get_if<std::string>(&it->second)) return *v;
              }
              return defVal;
            };

            data.enabled = getBool("enabled", true);
            data.locked = getBool("locked", true);
            data.opacity = getDouble("opacity", 0.75);
            data.style = getString("style", "horizontal");
            data.fontSizeScale = getString("fontSizeScale", "2K");
            data.positionPreset = getString("positionPreset", "custom");

            data.showFps = getBool("showFps", true);
            data.showTime = getBool("showTime", true);
            data.showCpuTemp = getBool("showCpuTemp", true);
            data.showCpuUsage = getBool("showCpuUsage", true);
            data.showCpuPower = getBool("showCpuPower", true);
            data.showCpuClock = getBool("showCpuClock", true);
            data.showCpuFanRpm = getBool("showCpuFanRpm", false);
            data.showGpuTemp = getBool("showGpuTemp", true);
            data.showGpuUsage = getBool("showGpuUsage", true);
            data.showGpuPower = getBool("showGpuPower", true);
            data.showGpuClock = getBool("showGpuClock", false);
            data.showGpuFanRpm = getBool("showGpuFanRpm", false);
            data.showSmartFanRpm = getBool("showSmartFanRpm", true);
            data.showSmartFanPwm = getBool("showSmartFanPwm", true);
            data.showRamUsage = getBool("showRamUsage", true);

            data.fps = getInt("fps", 120);
            data.cpuTemp = getInt("cpuTemp", 45);
            data.cpuUsage = getInt("cpuUsage", 18);
            data.cpuClockMhz = getInt("cpuClockMhz", 3494);
            data.cpuPowerW = getInt("cpuPowerW", 42);
            data.cpuFanRpm = getInt("cpuFanRpm", 3700);
            data.gpuTemp = getInt("gpuTemp", 42);
            data.gpuUsage = getInt("gpuUsage", 12);
            data.gpuClockMhz = getInt("gpuClockMhz", 1410);
            data.gpuPowerW = getInt("gpuPowerW", 33);
            data.gpuFanRpm = getInt("gpuFanRpm", 3800);
            data.fanPwm = getInt("fanPwm", 50);
            data.fanRpm = getInt("fanRpm", 1400);
            data.ramUsage = getInt("ramUsage", 43);
            data.posX = getInt("posX", 40);
            data.posY = getInt("posY", 30);

            OsdWindow::GetInstance().UpdateData(data);
            OsdWindow::GetInstance().ShowOSD(data.enabled);
          }
          result->Success(true);
        } else if (call.method_name() == "setHotKey") {
          if (const auto* map = std::get_if<flutter::EncodableMap>(call.arguments())) {
            auto modIt = map->find(flutter::EncodableValue("modifiers"));
            auto keyIt = map->find(flutter::EncodableValue("key"));
            if (modIt != map->end() && keyIt != map->end()) {
              int mods = std::get<int>(modIt->second);
              int vk = std::get<int>(keyIt->second);
              RegisterOverlayHotKey(static_cast<UINT>(mods), static_cast<UINT>(vk));
            }
          }
          result->Success(true);
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  OsdWindow::GetInstance().DestroyOSD();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_HOTKEY:
      if (wparam == HOTKEY_OVERLAY_TOGGLE) {
        OsdWindow::GetInstance().ToggleLock();

        if (method_channel_) {
          bool isUnlocked = !OsdWindow::GetInstance().IsLocked();
          method_channel_->InvokeMethod(
              "onHotkeyPressed",
              std::make_unique<flutter::EncodableValue>(isUnlocked));
        }
      }
      break;

    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
