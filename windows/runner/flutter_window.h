#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "win32_window.h"

#define HOTKEY_OVERLAY_TOGGLE 9001

// A window that hosting a Flutter view with native Windows OSD overlay capabilities.
class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

  void SetClickThrough(bool clickThrough);
  void RegisterOverlayHotKey(UINT modifiers, UINT vkKey);

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<>> method_channel_;

  bool is_always_on_top_ = true;
  bool is_click_through_ = true;
  bool is_interactive_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
