import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_state.dart'
    as conn;
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

class DesktopHeader extends StatelessWidget {
  final String activeProfileName;
  final Color activeProfileColor;
  final VoidCallback? onConnectionTap;

  const DesktopHeader({
    super.key,
    required this.activeProfileName,
    required this.activeProfileColor,
    this.onConnectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Active Profile Status Indicator
            Row(
              children: [
                const AppText(
                  'PROFILE HIỆN TẠI:',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  isMonospace: true,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: ShapeDecoration(
                    color: activeProfileColor.withValues(alpha: 0.12),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: activeProfileColor, width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: activeProfileColor),
                      const SizedBox(width: 4),
                      AppText(
                        activeProfileName.toUpperCase(),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: activeProfileColor,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Hardware & Platform Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: ShapeDecoration(
                    color: AppColors.surfaceLight,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: AppColors.border, width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Theme.of(context).platform == TargetPlatform.windows
                            ? Icons.window_rounded
                            : Icons.computer_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      AppText(
                        Theme.of(context).platform == TargetPlatform.windows
                            ? 'WINDOWS OS'
                            : 'LINUX OS',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Connection status badge - reads from ConnectionBloc
                BlocBuilder<ConnectionBloc, conn.ConnectionState>(
                  builder: (context, connState) {
                    final isConnected = connState.status == conn.ConnectionStatus.connected;
                    final isScanning = connState.status == conn.ConnectionStatus.scanning;
                    final isConnecting = connState.status == conn.ConnectionStatus.connecting;

                    // Determine badge text and color
                    String badgeText;
                    Color badgeColor;
                    IconData badgeIcon;

                    if (isConnected) {
                      final type = connState.connectionType == 'wifi'
                          ? 'WIFI'
                          : connState.connectionType == 'usb'
                              ? 'USB'
                              : 'BLE';
                      badgeText = 'ESP32 $type';
                      badgeColor = AppColors.primary;
                      badgeIcon = connState.connectionType == 'wifi'
                          ? Icons.wifi_rounded
                          : connState.connectionType == 'usb'
                              ? Icons.usb_rounded
                              : Icons.bluetooth_connected_rounded;
                    } else if (isScanning || isConnecting) {
                      badgeText = isScanning ? 'SCANNING...' : 'CONNECTING...';
                      badgeColor = AppColors.secondary;
                      badgeIcon = Icons.search_rounded;
                    } else {
                      badgeText = 'OFFLINE';
                      badgeColor = AppColors.statusOffline;
                      badgeIcon = Icons.bluetooth_disabled_rounded;
                    }

                    return GestureDetector(
                      onTap: onConnectionTap,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: ShapeDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(color: badgeColor, width: 1.0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(badgeIcon, size: 13, color: badgeColor),
                              const SizedBox(width: 5),
                              AppText(
                                badgeText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                                isMonospace: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
