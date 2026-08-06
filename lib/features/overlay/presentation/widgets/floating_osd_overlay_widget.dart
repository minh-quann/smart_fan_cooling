import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/core/services/window_service.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_bloc.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_state.dart';
import 'package:smart_fan_cooling/features/overlay/presentation/bloc/overlay_bloc.dart';
import 'package:smart_fan_cooling/features/overlay/presentation/bloc/overlay_event.dart';
import 'package:smart_fan_cooling/features/overlay/presentation/bloc/overlay_state.dart';

/// Headless OSD Overlay Controller Widget
/// Synchronizes real-time hardware telemetry and user configuration settings
/// directly to the Standalone Native Win32 Armoury Crate OSD Sub-Window.
class FloatingOsdOverlayWidget extends StatefulWidget {
  const FloatingOsdOverlayWidget({super.key});

  @override
  State<FloatingOsdOverlayWidget> createState() => _FloatingOsdOverlayWidgetState();
}

class _FloatingOsdOverlayWidgetState extends State<FloatingOsdOverlayWidget> {
  bool _isInteractiveMoveMode = false;

  @override
  void initState() {
    super.initState();
    // Listen for global hotkey (Ctrl + Shift + O) pressed event
    WindowService.onHotkeyPressed.listen((isInteractive) {
      if (mounted) {
        setState(() {
          _isInteractiveMoveMode = isInteractive;
        });
        context.read<OverlayBloc>().add(
              ToggleOverlayLockEvent(!isInteractive),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OverlayBloc, OsdOverlayState>(
      builder: (context, overlayState) {
        final config = overlayState.config;

        return BlocBuilder<HardwareBloc, HardwareState>(
          builder: (context, hwState) {
            final stats = hwState.stats;

            // Transmit full telemetry & settings to Native Win32 Standalone OsdWindow
            WindowService.updateOsdData({
              'enabled': config.isEnabled,
              'locked': config.isLocked && !_isInteractiveMoveMode,
              'opacity': config.backgroundOpacity,
              'style': config.style,
              'fontSizeScale': config.fontSizeScale,
              'positionPreset': config.positionPreset,
              'showFps': config.showFps,
              'showTime': config.showTime,
              'showCpu': config.showCpuTemp || config.showCpuUsage || config.showCpuPower || config.showCpuClock,
              'showCpuTemp': config.showCpuTemp,
              'showCpuUsage': config.showCpuUsage,
              'showCpuPower': config.showCpuPower,
              'showCpuClock': config.showCpuClock,
              'showCpuFanRpm': config.showCpuFanRpm,
              'showGpu': config.showGpuTemp || config.showGpuUsage || config.showGpuPower || config.showGpuClock,
              'showGpuTemp': config.showGpuTemp,
              'showGpuUsage': config.showGpuUsage,
              'showGpuPower': config.showGpuPower,
              'showGpuClock': config.showGpuClock,
              'showGpuFanRpm': config.showGpuFanRpm,
              'showSmartFanRpm': config.showSmartFanRpm,
              'showSmartFanPwm': config.showSmartFanPwm,
              'showRamUsage': config.showRamUsage,
              'fps': stats.fps,
              'cpuTemp': stats.cpuTemp.round(),
              'cpuUsage': stats.cpuUsage.round(),
              'cpuClockMhz': (stats.cpuClock * 1000).round(),
              'cpuPowerW': stats.cpuPowerW.round(),
              'cpuFanRpm': stats.cpuFanRpm,
              'gpuTemp': stats.gpuTemp.round(),
              'gpuUsage': stats.gpuUsage.round(),
              'gpuClockMhz': stats.gpuClock.round(),
              'gpuPowerW': stats.gpuPowerW.round(),
              'gpuFanRpm': stats.gpuFanRpm,
              'fanPwm': stats.pwmPercent,
              'fanRpm': stats.fanRpm,
              'ramUsage': stats.ramUsage.round(),
              'posX': config.posX.round(),
              'posY': config.posY.round(),
            });

            // Handle Display Mode: 'always' vs 'game_only'
            if (config.displayMode == 'game_only') {
              final bool isGameActive = stats.gpuUsage > 12 || stats.cpuUsage > 45 || _isInteractiveMoveMode;
              if (!isGameActive) {
                WindowService.setAlwaysOnTop(false);
              } else {
                WindowService.setAlwaysOnTop(true);
              }
            } else {
              WindowService.setAlwaysOnTop(config.isEnabled);
            }

            // Return SizedBox.shrink() so ZERO duplicate bar is rendered inside Flutter app!
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
