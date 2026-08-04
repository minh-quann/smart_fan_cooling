import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Startup & Tray State
  bool _startWithSystem = true;
  bool _minimizeToTrayOnClose = true;
  bool _showTrayIcon = true;
  bool _runInBackground = true;

  // Hardware & Communication State
  String _selectedComPort = Platform.isWindows ? 'COM3 (ESP32-S3)' : '/dev/ttyACM0 (ESP32-S3)';
  int _baudRate = 115200;
  final int _pwmFrequencyKHz = 25;
  final int _safeFallbackPwm = 40;

  // General & Alert State
  bool _overheatAlertEnabled = true;
  final int _overheatThresholdTemp = 85;

  void _saveSettings() {
    // Handle Linux autostart file creation/deletion
    if (Platform.isLinux) {
      _toggleLinuxAutostart(_startWithSystem);
    } else if (Platform.isWindows) {
      _toggleWindowsAutostart(_startWithSystem);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: AppText(
          'Đã lưu toàn bộ thiết lập hệ thống & cấu hình Tray Icon!',
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleLinuxAutostart(bool enable) async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null) return;

      final autostartDir = Directory('$home/.config/autostart');
      if (!await autostartDir.exists()) {
        await autostartDir.create(recursive: true);
      }

      final desktopFile = File('${autostartDir.path}/smart_fan_cooling.desktop');
      if (enable) {
        final content = '''
[Desktop Entry]
Type=Application
Name=Llano Smart Fan Hub
Exec=${Platform.resolvedExecutable}
Icon=utilities-system-monitor
Terminal=false
Categories=System;ControlCenter;
X-GNOME-Autostart-enabled=true
''';
        await desktopFile.writeAsString(content);
      } else {
        if (await desktopFile.exists()) {
          await desktopFile.delete();
        }
      }
    } catch (_) {}
  }

  void _toggleWindowsAutostart(bool enable) async {
    try {
      final appPath = Platform.resolvedExecutable;
      final command = enable
          ? 'REG ADD "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" /v "LlanoSmartFan" /t REG_SZ /d "$appPath" /f'
          : 'REG DELETE "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" /v "LlanoSmartFan" /f';
      await Process.run('cmd', ['/c', command]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Action Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.h1('THIẾT LẬP HỆ THỐNG & KHAY CÔNG CỤ (TRAY ICON)'),
                AppText.caption('Cấu hình khởi động cùng HĐH, chạy ngầm dưới khay hệ thống và kết nối ESP32-S3'),
              ],
            ),
            AppButton(
              label: 'LƯU THIẾT LẬP',
              icon: Icons.save_rounded,
              backgroundColor: AppColors.primary,
              textColor: Colors.black,
              onPressed: _saveSettings,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Settings Section 1: System Startup & Tray Icon
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.display_settings_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  AppText.h2('KHỞI ĐỘNG HỆ THỐNG & TRAY ICON KHAY CÔNG CỤ'),
                ],
              ),
              const SizedBox(height: 16),

              _buildSwitchTile(
                title: 'Khởi động ứng dụng cùng hệ thống (${Platform.isWindows ? 'Windows Startup' : 'Linux Autostart'})',
                subtitle: 'Tự động mở Llano Smart Fan Hub ngay khi máy tính khởi động vào hệ điều hành',
                icon: Icons.power_settings_new_rounded,
                value: _startWithSystem,
                onChanged: (val) => setState(() => _startWithSystem = val),
              ),
              const Divider(color: AppColors.border, height: 24),

              _buildSwitchTile(
                title: 'Thu nhỏ ứng dụng xuống System Tray khi đóng cửa sổ',
                subtitle: 'Khi bấm nút X đóng cửa sổ, ứng dụng sẽ thu nhỏ xuống khay Taskbar thay vì thoát hẳn',
                icon: Icons.compress_rounded,
                value: _minimizeToTrayOnClose,
                onChanged: (val) => setState(() => _minimizeToTrayOnClose = val),
              ),
              const Divider(color: AppColors.border, height: 24),

              _buildSwitchTile(
                title: 'Hiển thị Icon biểu tượng dưới thanh khay công cụ (System Tray)',
                subtitle: 'Hiển thị icon quạt Llano thu nhỏ ở góc màn hình để bật nhanh các profile làm mát',
                icon: Icons.widgets_rounded,
                value: _showTrayIcon,
                onChanged: (val) => setState(() => _showTrayIcon = val),
              ),
              const Divider(color: AppColors.border, height: 24),

              _buildSwitchTile(
                title: 'Duy trì dịch vụ điều tốc chạy ngầm (Background Service)',
                subtitle: 'Đảm bảo quạt Llano luôn tự động chỉnh tốc độ theo nhiệt độ ngay cả khi ẩn cửa sổ',
                icon: Icons.published_with_changes_rounded,
                value: _runInBackground,
                onChanged: (val) => setState(() => _runInBackground = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Settings Section 2: Hardware & Communication Settings
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.usb_rounded, color: AppColors.secondary, size: 22),
                  const SizedBox(width: 10),
                  AppText.h2('GIAO TIẾP PHẦN CỨNG BO MẠCH ESP32-S3'),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.caption('CỔNG KẾT NỐI USB SERIAL PORT:'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: ShapeDecoration(
                            color: AppColors.surfaceLight,
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedComPort,
                              dropdownColor: AppColors.cardBg,
                              isExpanded: true,
                              items: [
                                _selectedComPort,
                                Platform.isWindows ? 'COM4 (Standard Serial)' : '/dev/ttyUSB0 (UART Adapter)',
                              ].map((port) {
                                return DropdownMenuItem(
                                  value: port,
                                  child: AppText(port, fontSize: 13),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedComPort = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.caption('BAUDRATE NẠP DỮ LIỆU:'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: ShapeDecoration(
                            color: AppColors.surfaceLight,
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _baudRate,
                              dropdownColor: AppColors.cardBg,
                              isExpanded: true,
                              items: const [9600, 57600, 115200, 921600].map((rate) {
                                return DropdownMenuItem(
                                  value: rate,
                                  child: AppText('$rate bps (USB CDC High-Speed)', fontSize: 13),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _baudRate = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.caption('TẦN SỐ XUNG PWM DÀNH CHO QUẠT LLANO:'),
                        const SizedBox(height: 6),
                        AppText('$_pwmFrequencyKHz kHz (Sóng siêu âm không tiềng rít)', fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w700),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.caption('TỐC ĐỘ AN TOÀN KHI MẤT KẾT NỐI ESP32:'),
                        const SizedBox(height: 6),
                        AppText('$_safeFallbackPwm% PWM (~${((_safeFallbackPwm / 100.0) * 2800).round()} RPM)', fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Settings Section 3: General & Overheat Alerts
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.thermostat_rounded, color: AppColors.accentOrange, size: 22),
                  const SizedBox(width: 10),
                  AppText.h2('CẢNH BÁO NHIỆT ĐỘ & TÙY CHỌN HIỂN THỊ'),
                ],
              ),
              const SizedBox(height: 16),

              _buildSwitchTile(
                title: 'Bật cảnh báo khi nhiệt độ CPU / GPU vượt mức an toàn (> $_overheatThresholdTemp°C)',
                subtitle: 'Tự động kích hoạt quạt Llano lên 100% MAX speed và phát âm thanh/thông báo cảnh báo nóng máy',
                icon: Icons.warning_amber_rounded,
                value: _overheatAlertEnabled,
                onChanged: (val) => setState(() => _overheatAlertEnabled = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: ShapeDecoration(
            color: value ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: value ? AppColors.primary : AppColors.border),
            ),
          ),
          child: Icon(icon, color: value ? AppColors.primary : AppColors.textMuted, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(title, fontSize: 14, fontWeight: FontWeight.w700),
              const SizedBox(height: 2),
              AppText.caption(subtitle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          activeTrackColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
