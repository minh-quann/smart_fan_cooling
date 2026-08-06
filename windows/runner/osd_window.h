#ifndef RUNNER_OSD_WINDOW_H_
#define RUNNER_OSD_WINDOW_H_

#include <windows.h>
#include <string>
#include <functional>

struct OsdData {
  bool enabled = true;
  bool locked = true;
  double opacity = 0.75;
  std::string style = "horizontal"; // 'horizontal', 'upright', 'compact'
  std::string fontSizeScale = "2K";
  std::string positionPreset = "custom"; // 'top_left', 'top_center', 'top_right', 'bottom_left', 'bottom_center', 'bottom_right', 'custom'

  // Individual Metrics
  bool showFps = true;
  bool showTime = true;
  bool showCpu = true;
  bool showCpuTemp = true;
  bool showCpuUsage = true;
  bool showCpuPower = true;
  bool showCpuClock = true;
  bool showCpuFanRpm = false;
  bool showGpu = true;
  bool showGpuTemp = true;
  bool showGpuUsage = true;
  bool showGpuPower = true;
  bool showGpuClock = false;
  bool showGpuFanRpm = false;
  bool showSmartFanRpm = true;
  bool showSmartFanPwm = true;
  bool showRamUsage = true;

  // Real-time telemetry values
  int fps = 120;
  int cpuTemp = 45;
  int cpuUsage = 18;
  int cpuClockMhz = 3494;
  int cpuPowerW = 42;
  int cpuFanRpm = 3700;
  int gpuTemp = 42;
  int gpuUsage = 12;
  int gpuClockMhz = 1410;
  int gpuPowerW = 33;
  int gpuFanRpm = 3800;
  int fanPwm = 50;
  int fanRpm = 1400;
  int ramUsage = 43;
  int posX = 40;
  int posY = 30;
};

class OsdWindow {
 public:
  static OsdWindow& GetInstance();

  bool CreateOSD();
  void DestroyOSD();
  void ShowOSD(bool show);
  void UpdateData(const OsdData& data);
  void ToggleLock();
  void SetClickThrough(bool clickThrough);
  void SetPositionCallback(std::function<void(int x, int y)> cb) { onPositionChanged_ = cb; }

  HWND GetHandle() const { return hwnd_; }
  bool IsLocked() const { return data_.locked; }

 private:
  OsdWindow() = default;
  ~OsdWindow() = default;

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
  void RenderOSD(HDC hdc);
  void ApplyPresetPosition(const std::string& preset);

  HWND hwnd_ = nullptr;
  OsdData data_;
  bool isCreated_ = false;
  int lastRenderedWidth_ = 650;
  int lastRenderedHeight_ = 26;
  std::function<void(int x, int y)> onPositionChanged_ = nullptr;
};

#endif  // RUNNER_OSD_WINDOW_H_
