import 'dart:async';
import 'package:flutter/services.dart';

class WindowService {
  static const _channel = MethodChannel('smart_fan_cooling/window');
  static final StreamController<bool> _hotkeyStreamController =
      StreamController<bool>.broadcast();
  static final StreamController<Map<String, double>> _positionStreamController =
      StreamController<Map<String, double>>.broadcast();

  static Stream<bool> get onHotkeyPressed => _hotkeyStreamController.stream;
  static Stream<Map<String, double>> get onPositionChanged => _positionStreamController.stream;
  static bool _isInitialized = false;

  static void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onHotkeyPressed') {
        final bool isInteractive = call.arguments as bool? ?? false;
        _hotkeyStreamController.add(isInteractive);
      } else if (call.method == 'onPositionChanged') {
        if (call.arguments is Map) {
          final Map map = call.arguments as Map;
          final double posX = (map['posX'] as num).toDouble();
          final double posY = (map['posY'] as num).toDouble();
          _positionStreamController.add({'posX': posX, 'posY': posY});
        }
      }
    });
  }

  /// Transmits telemetry & configuration data directly to Native Win32 Armoury OsdWindow
  static Future<void> updateOsdData(Map<String, dynamic> data) async {
    try {
      await _channel.invokeMethod('updateOsdData', data);
    } catch (_) {}
  }

  /// Sets whether the window stays on top of all other windows (HWND_TOPMOST)
  static Future<void> setAlwaysOnTop(bool enable) async {
    try {
      await _channel.invokeMethod('setAlwaysOnTop', enable);
    } catch (_) {}
  }

  /// Sets WS_EX_TRANSPARENT style (true = click through to games/apps, false = interactive move mode)
  static Future<void> setClickThrough(bool enable) async {
    try {
      await _channel.invokeMethod('setClickThrough', enable);
    } catch (_) {}
  }

  /// Customize global Windows HotKey (e.g. MOD_CONTROL | MOD_SHIFT, 'O')
  static Future<void> setHotKey(int modifiers, int vkKey) async {
    try {
      await _channel.invokeMethod('setHotKey', {
        'modifiers': modifiers,
        'key': vkKey,
      });
    } catch (_) {}
  }
}
