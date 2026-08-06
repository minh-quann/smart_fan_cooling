#include "osd_window.h"
#include <dwmapi.h>
#include <gdiplus.h>
#include <vector>
#include <algorithm>

#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "dwmapi.lib")

using namespace Gdiplus;

static ULONG_PTR gdiplusToken = 0;

OsdWindow& OsdWindow::GetInstance() {
  static OsdWindow instance;
  return instance;
}

bool OsdWindow::CreateOSD() {
  if (isCreated_ && hwnd_) return true;

  GdiplusStartupInput gdiplusStartupInput;
  GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

  WNDCLASSEXW wc = {0};
  wc.cbSize = sizeof(WNDCLASSEXW);
  wc.lpfnWndProc = WndProc;
  wc.hInstance = GetModuleHandle(NULL);
  wc.lpszClassName = L"SMART_FAN_OSD_WINDOW_CLASS";
  wc.hCursor = LoadCursor(NULL, IDC_ARROW);
  wc.hbrBackground = NULL;
  RegisterClassExW(&wc);

  int w = 850;
  int h = 26;

  hwnd_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED | (data_.locked ? WS_EX_NOACTIVATE | WS_EX_TRANSPARENT : 0),
      L"SMART_FAN_OSD_WINDOW_CLASS",
      L"SmartFanOSD",
      WS_POPUP,
      data_.posX, data_.posY, w, h,
      NULL, NULL, GetModuleHandle(NULL), this);

  if (!hwnd_) return false;

  // Use RGB(1, 1, 1) as ColorKey instead of RGB(0,0,0) so dark background boxes (RGB 10,14,20) remain 100% mouse-clickable!
  SetLayeredWindowAttributes(hwnd_, RGB(1, 1, 1), 255, LWA_ALPHA);

  MARGINS margins = {-1, -1, -1, -1};
  ::DwmExtendFrameIntoClientArea(hwnd_, &margins);

  ::SetWindowPos(hwnd_, HWND_TOPMOST, data_.posX, data_.posY, w, h,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);

  SetTimer(hwnd_, 1001, 300, NULL);

  isCreated_ = true;
  return true;
}

void OsdWindow::DestroyOSD() {
  if (hwnd_) {
    KillTimer(hwnd_, 1001);
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
  isCreated_ = false;
  if (gdiplusToken) {
    GdiplusShutdown(gdiplusToken);
    gdiplusToken = 0;
  }
}

void OsdWindow::ShowOSD(bool show) {
  data_.enabled = show;
  if (!isCreated_) {
    if (show) CreateOSD();
    return;
  }
  if (show) {
    ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
    SetWindowPos(hwnd_, HWND_TOPMOST, data_.posX, data_.posY, lastRenderedWidth_, lastRenderedHeight_, SWP_NOACTIVATE | SWP_SHOWWINDOW);
  } else {
    ShowWindow(hwnd_, SW_HIDE);
  }
}

void OsdWindow::SetClickThrough(bool clickThrough) {
  data_.locked = clickThrough;
  if (hwnd_) {
    LONG_PTR exStyle = GetWindowLongPtr(hwnd_, GWL_EXSTYLE);
    if (clickThrough) {
      SetWindowLongPtr(hwnd_, GWL_EXSTYLE, exStyle | WS_EX_TRANSPARENT | WS_EX_NOACTIVATE);
    } else {
      SetWindowLongPtr(hwnd_, GWL_EXSTYLE, (exStyle & ~WS_EX_TRANSPARENT) & ~WS_EX_NOACTIVATE);
    }
    SetWindowPos(hwnd_, HWND_TOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | (clickThrough ? SWP_NOACTIVATE : 0) | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
    InvalidateRect(hwnd_, NULL, FALSE);
  }
}

void OsdWindow::ApplyPresetPosition(const std::string& preset) {
  if (preset.empty() || preset == "custom") return;

  RECT workArea;
  if (!SystemParametersInfo(SPI_GETWORKAREA, 0, &workArea, 0)) {
    workArea.left = 0;
    workArea.top = 0;
    workArea.right = GetSystemMetrics(SM_CXSCREEN);
    workArea.bottom = GetSystemMetrics(SM_CYSCREEN);
  }

  int screenW = GetSystemMetrics(SM_CXSCREEN);
  int screenH = GetSystemMetrics(SM_CYSCREEN);

  int w = lastRenderedWidth_;
  int h = lastRenderedHeight_;
  int newX = data_.posX;
  int newY = data_.posY;

  if (preset == "top_left") {
    newX = 10;
    newY = 0; // Đè tuyệt đối lên đít/đỉnh màn hình (0px) vượt qua MyDockFinder
  } else if (preset == "top_center") {
    newX = (screenW - w) / 2;
    newY = 0; // Đè tuyệt đối đỉnh màn hình (0px)
  } else if (preset == "top_right") {
    newX = screenW - w - 10;
    newY = 0; // Đè tuyệt đối đỉnh màn hình (0px)
  } else if (preset == "bottom_left") {
    newX = 10;
    newY = screenH - h - 2;
  } else if (preset == "bottom_center") {
    newX = (screenW - w) / 2;
    newY = screenH - h - 2;
  } else if (preset == "bottom_right") {
    newX = screenW - w - 10;
    newY = screenH - h - 2;
  }

  data_.posX = newX;
  data_.posY = newY;

  if (hwnd_) {
    SetWindowPos(hwnd_, HWND_TOPMOST, newX, newY, w, h,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);
  }
}

void OsdWindow::UpdateData(const OsdData& data) {
  bool lockChanged = (data_.locked != data.locked);

  data_ = data;

  if (!isCreated_ && data_.enabled) {
    CreateOSD();
  }

  if (hwnd_ && isCreated_) {
    if (lockChanged) {
      SetClickThrough(data_.locked);
    }
    if (data_.positionPreset != "custom") {
      ApplyPresetPosition(data_.positionPreset);
    } else {
      SetWindowPos(hwnd_, HWND_TOPMOST, data_.posX, data_.posY, 0, 0,
                   SWP_NOSIZE | (data_.locked ? SWP_NOACTIVATE : 0) | SWP_SHOWWINDOW);
    }
    InvalidateRect(hwnd_, NULL, FALSE);
  }
}

void OsdWindow::ToggleLock() {
  SetClickThrough(!data_.locked);
}

LRESULT CALLBACK OsdWindow::WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  OsdWindow* self = &GetInstance();

  switch (msg) {
    case WM_ERASEBKGND:
      return 1; // Eliminate 100% flickering

    case WM_NCHITTEST: {
      if (!self->data_.locked) {
        return HTCAPTION; // Makes entire window body draggable by OS!
      }
      return DefWindowProc(hwnd, msg, wParam, lParam);
    }

    case WM_LBUTTONDOWN: {
      if (!self->data_.locked) {
        ReleaseCapture();
        SendMessage(hwnd, WM_SYSCOMMAND, SC_MOVE | 0x0002, 0);
        return 0;
      }
      return 0;
    }

    case WM_MOVE:
    case WM_EXITSIZEMOVE: {
      if (!self->data_.locked) {
        RECT rc;
        GetWindowRect(hwnd, &rc);
        self->data_.posX = rc.left;
        self->data_.posY = rc.top;
        if (self->onPositionChanged_) {
          self->onPositionChanged_(rc.left, rc.top);
        }
      }
      return 0;
    }

    case WM_PAINT: {
      PAINTSTRUCT ps;
      HDC hdc = BeginPaint(hwnd, &ps);
      self->RenderOSD(hdc);
      EndPaint(hwnd, &ps);
      return 0;
    }

    case WM_TIMER: {
      if (wParam == 1001 && self->data_.enabled && self->data_.locked) {
        SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
      }
      return 0;
    }

    case WM_RBUTTONUP: {
      self->ToggleLock();
      return 0;
    }

    case WM_DESTROY: {
      return 0;
    }
  }
  return DefWindowProc(hwnd, msg, wParam, lParam);
}

void OsdWindow::RenderOSD(HDC hdc) {
  int targetHeight = (data_.style == "upright") ? 95 : 26;

  HDC memDC = CreateCompatibleDC(hdc);
  HBITMAP memBMP = CreateCompatibleBitmap(hdc, 1800, targetHeight);
  HBITMAP oldBMP = (HBITMAP)SelectObject(memDC, memBMP);

  Graphics g(memDC);
  g.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);
  g.Clear(Color(0, 0, 0, 0));

  FontFamily fontFamily(L"Segoe UI");
  float fontSize = 13.0f;
  if (data_.fontSizeScale == "720p") fontSize = 10.5f;
  else if (data_.fontSizeScale == "1080p") fontSize = 12.0f;
  else if (data_.fontSizeScale == "4K") fontSize = 16.0f;

  Gdiplus::Font font(&fontFamily, fontSize, FontStyleBold, UnitPixel);

  SolidBrush labelBrush(Color(255, 150, 160, 175)); // Muted Grey Label
  SolidBrush greenBrush(Color(255, 0, 230, 118));  // Green
  SolidBrush yellowBrush(Color(255, 255, 214, 0));  // Yellow
  SolidBrush redBrush(Color(255, 255, 61, 0));      // Red
  SolidBrush orangeBrush(Color(255, 255, 111, 0));  // Orange
  SolidBrush cyanBrush(Color(255, 64, 196, 255));   // Cyan
  Pen dividerPen(Color(100, 90, 100, 120), 1);

  auto getTempBrush = [&](int temp) -> SolidBrush* {
    if (temp >= 76) return &orangeBrush;
    if (temp >= 60) return &yellowBrush;
    return &greenBrush;
  };

  auto getUsageBrush = [&](int usage) -> SolidBrush* {
    if (usage >= 80) return &redBrush;
    if (usage >= 50) return &yellowBrush;
    return &greenBrush;
  };

  auto getFpsBrush = [&](int fps) -> SolidBrush* {
    if (fps < 30) return &redBrush;
    if (fps < 60) return &yellowBrush;
    return &greenBrush;
  };

  wchar_t buf[256];
  REAL curX = 10.0f;
  REAL curY = 3.0f;

  auto measureWidth = [&](const wchar_t* text) -> REAL {
    RectF boundingBox;
    g.MeasureString(text, -1, &font, PointF(0, 0), &boundingBox);
    return boundingBox.Width;
  };

  // If unlocked, draw prominent Drag Handle Icon [ ❖ MOVE ] on the left!
  if (!data_.locked) {
    g.DrawString(L"❖ MOVE  ", -1, &font, PointF(curX, curY), &cyanBrush);
    curX += measureWidth(L"❖ MOVE  ") + 4.0f;
    g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
    curX += 8.0f;
  }

  if (data_.style == "horizontal") {
    // 1. FPS
    if (data_.showFps) {
      g.DrawString(L"FPS ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"FPS ");
      swprintf_s(buf, L"%d", data_.fps);
      g.DrawString(buf, -1, &font, PointF(curX, curY), getFpsBrush(data_.fps));
      curX += measureWidth(buf) + 6.0f;

      g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
      curX += 8.0f;
    }

    // 2. CPU
    if (data_.showCpuTemp || data_.showCpuUsage || data_.showCpuPower || data_.showCpuClock || data_.showCpuFanRpm) {
      g.DrawString(L"CPU ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"CPU ");

      if (data_.showCpuTemp) {
        swprintf_s(buf, L"%d \u00B0C", data_.cpuTemp);
        g.DrawString(buf, -1, &font, PointF(curX, curY), getTempBrush(data_.cpuTemp));
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showCpuUsage) {
        swprintf_s(buf, L"%d %%", data_.cpuUsage);
        g.DrawString(buf, -1, &font, PointF(curX, curY), getUsageBrush(data_.cpuUsage));
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showCpuClock) {
        swprintf_s(buf, L"%d MHz", data_.cpuClockMhz);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showCpuPower) {
        swprintf_s(buf, L"%d W", data_.cpuPowerW);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showCpuFanRpm) {
        swprintf_s(buf, L"%d RPM", data_.cpuFanRpm);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }

      g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
      curX += 8.0f;
    }

    // 3. GPU
    if (data_.showGpuTemp || data_.showGpuUsage || data_.showGpuPower || data_.showGpuClock || data_.showGpuFanRpm) {
      g.DrawString(L"GPU ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"GPU ");

      if (data_.showGpuTemp) {
        swprintf_s(buf, L"%d\u00B0C", data_.gpuTemp);
        g.DrawString(buf, -1, &font, PointF(curX, curY), getTempBrush(data_.gpuTemp));
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showGpuUsage) {
        swprintf_s(buf, L"%d%%", data_.gpuUsage);
        g.DrawString(buf, -1, &font, PointF(curX, curY), getUsageBrush(data_.gpuUsage));
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showGpuClock) {
        swprintf_s(buf, L"%dMHz", data_.gpuClockMhz);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showGpuPower) {
        swprintf_s(buf, L"%dW", data_.gpuPowerW);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showGpuFanRpm) {
        swprintf_s(buf, L"%dRPM", data_.gpuFanRpm);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }

      g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
      curX += 8.0f;
    }

    // 4. RAM
    if (data_.showRamUsage) {
      g.DrawString(L"RAM ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"RAM ");
      swprintf_s(buf, L"%d%%", data_.ramUsage);
      g.DrawString(buf, -1, &font, PointF(curX, curY), getUsageBrush(data_.ramUsage));
      curX += measureWidth(buf) + 6.0f;

      g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
      curX += 8.0f;
    }

    // 5. LLANO FAN
    if (data_.showSmartFanRpm || data_.showSmartFanPwm) {
      g.DrawString(L"FAN ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"FAN ");
      if (data_.showSmartFanPwm) {
        swprintf_s(buf, L"%d%%", data_.fanPwm);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showSmartFanRpm) {
        swprintf_s(buf, L"%d RPM", data_.fanRpm);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &greenBrush);
        curX += measureWidth(buf) + 12.0f;
      }
    }
  } else {
    // Upright / Stacked Multi-Line Style
    int yPos = 6;
    bool hasCpu = data_.showCpu || data_.showCpuTemp || data_.showCpuUsage || data_.showCpuPower || data_.showCpuClock || data_.showCpuFanRpm;
    if (hasCpu) {
      g.DrawString(L"CPU ", -1, &font, PointF(8, (REAL)yPos), &labelBrush);
      swprintf_s(buf, L"%d MHz  %d %%  %d W  %d \u00B0C", data_.cpuClockMhz, data_.cpuUsage, data_.cpuPowerW, data_.cpuTemp);
      g.DrawString(buf, -1, &font, PointF(48, (REAL)yPos), &cyanBrush);
      yPos += 22;
    }
    bool hasGpu = data_.showGpu || data_.showGpuTemp || data_.showGpuUsage || data_.showGpuPower || data_.showGpuClock || data_.showGpuFanRpm;
    if (hasGpu) {
      g.DrawString(L"GPU ", -1, &font, PointF(8, (REAL)yPos), &labelBrush);
      swprintf_s(buf, L"%d MHz  %d %%  %d W  %d \u00B0C", data_.gpuClockMhz, data_.gpuUsage, data_.gpuPowerW, data_.gpuTemp);
      g.DrawString(buf, -1, &font, PointF(48, (REAL)yPos), &cyanBrush);
      yPos += 22;
    }
    if (data_.showFps) {
      g.DrawString(L"FPS ", -1, &font, PointF(8, (REAL)yPos), &labelBrush);
      swprintf_s(buf, L"%d FPS", data_.fps);
      g.DrawString(buf, -1, &font, PointF(48, (REAL)yPos), getFpsBrush(data_.fps));
    }
    curX = 420.0f;
  }

  INT actualWidth = static_cast<INT>(curX + 14.0f);
  lastRenderedWidth_ = actualWidth;
  lastRenderedHeight_ = targetHeight;

  BYTE bgAlpha = static_cast<BYTE>((data_.opacity * 255.0));
  Color bgColor(bgAlpha, 10, 14, 20);
  SolidBrush bgBrush(bgColor);
  g.FillRectangle(&bgBrush, 0, 0, actualWidth, targetHeight);

  if (!data_.locked) {
    Pen borderPen(Color(255, 0, 229, 255), 2);
    g.DrawRectangle(&borderPen, 1, 1, actualWidth - 2, targetHeight - 2);
  }

  // Re-render text on top of background
  curX = 10.0f;
  if (!data_.locked) {
    g.DrawString(L"❖ MOVE  ", -1, &font, PointF(curX, curY), &cyanBrush);
    curX += measureWidth(L"❖ MOVE  ") + 4.0f;
    g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
    curX += 8.0f;
  }

  if (data_.style == "horizontal") {
    if (data_.showFps) {
      g.DrawString(L"FPS ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"FPS ");
      swprintf_s(buf, L"%d", data_.fps);
      g.DrawString(buf, -1, &font, PointF(curX, curY), getFpsBrush(data_.fps));
      curX += measureWidth(buf) + 6.0f;
      g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
      curX += 8.0f;
    }
    if (data_.showCpuTemp || data_.showCpuUsage || data_.showCpuPower || data_.showCpuClock || data_.showCpuFanRpm) {
      g.DrawString(L"CPU ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"CPU ");
      if (data_.showCpuTemp) {
        swprintf_s(buf, L"%d \u00B0C", data_.cpuTemp);
        g.DrawString(buf, -1, &font, PointF(curX, curY), getTempBrush(data_.cpuTemp));
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showCpuUsage) {
        swprintf_s(buf, L"%d %%", data_.cpuUsage);
        g.DrawString(buf, -1, &font, PointF(curX, curY), getUsageBrush(data_.cpuUsage));
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showCpuClock) {
        swprintf_s(buf, L"%d MHz", data_.cpuClockMhz);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showCpuPower) {
        swprintf_s(buf, L"%d W", data_.cpuPowerW);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showCpuFanRpm) {
        swprintf_s(buf, L"%d RPM", data_.cpuFanRpm);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
      curX += 8.0f;
    }
    if (data_.showGpuTemp || data_.showGpuUsage || data_.showGpuPower || data_.showGpuClock || data_.showGpuFanRpm) {
      g.DrawString(L"GPU ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"GPU ");
      if (data_.showGpuTemp) {
        swprintf_s(buf, L"%d\u00B0C", data_.gpuTemp);
        g.DrawString(buf, -1, &font, PointF(curX, curY), getTempBrush(data_.gpuTemp));
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showGpuUsage) {
        swprintf_s(buf, L"%d%%", data_.gpuUsage);
        g.DrawString(buf, -1, &font, PointF(curX, curY), getUsageBrush(data_.gpuUsage));
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showGpuClock) {
        swprintf_s(buf, L"%dMHz", data_.gpuClockMhz);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showGpuPower) {
        swprintf_s(buf, L"%dW", data_.gpuPowerW);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showGpuFanRpm) {
        swprintf_s(buf, L"%dRPM", data_.gpuFanRpm);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
      curX += 8.0f;
    }
    if (data_.showRamUsage) {
      g.DrawString(L"RAM ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"RAM ");
      swprintf_s(buf, L"%d%%", data_.ramUsage);
      g.DrawString(buf, -1, &font, PointF(curX, curY), getUsageBrush(data_.ramUsage));
      curX += measureWidth(buf) + 6.0f;
      g.DrawLine(&dividerPen, curX, curY + 2, curX, curY + fontSize + 1);
      curX += 8.0f;
    }
    if (data_.showSmartFanRpm || data_.showSmartFanPwm) {
      g.DrawString(L"FAN ", -1, &font, PointF(curX, curY), &labelBrush);
      curX += measureWidth(L"FAN ");
      if (data_.showSmartFanPwm) {
        swprintf_s(buf, L"%d%%", data_.fanPwm);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &cyanBrush);
        curX += measureWidth(buf) + 6.0f;
      }
      if (data_.showSmartFanRpm) {
        swprintf_s(buf, L"%d RPM", data_.fanRpm);
        g.DrawString(buf, -1, &font, PointF(curX, curY), &greenBrush);
      }
    }
  }

  SetWindowPos(hwnd_, HWND_TOPMOST, data_.posX, data_.posY, actualWidth, targetHeight,
               SWP_NOACTIVATE | SWP_NOZORDER);

  BitBlt(hdc, 0, 0, actualWidth, targetHeight, memDC, 0, 0, SRCCOPY);

  SelectObject(memDC, oldBMP);
  DeleteObject(memBMP);
  DeleteDC(memDC);
}
