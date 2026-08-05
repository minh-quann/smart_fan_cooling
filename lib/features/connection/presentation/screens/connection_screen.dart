import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';


import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_state.dart'
    as bloc_state;
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_event.dart';
import 'package:smart_fan_cooling/features/connection/presentation/widgets/wifi_provisioning_widget.dart';

/// Compact connection dialog for scanning and connecting to ESP32 via BLE or WiFi.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Auto-start scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<ConnectionBloc>();
      if (bloc.state.status != bloc_state.ConnectionStatus.connected) {
        bloc.add(StartScanEvent());
      }
    });
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: ShapeDecoration(
          color: AppColors.background,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BlocBuilder<ConnectionBloc, bloc_state.ConnectionState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(state),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: ShapeDecoration(
                        color: AppColors.statusOffline.withValues(alpha: 0.1),
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: AppText.caption(
                        state.errorMessage!,
                        color: AppColors.statusOffline,
                      ),
                    ),
                  ),
                Flexible(
                  child: state.status == bloc_state.ConnectionStatus.connected
                      ? _buildConnectedView(state)
                      : _buildScanView(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bloc_state.ConnectionState state) {
    final isScanning =
        state.status == bloc_state.ConnectionStatus.scanning ||
        state.status == bloc_state.ConnectionStatus.connecting;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Icon(
              Icons.cast_connected_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Kết Nối Thiết Bị',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                AppText(
                  _statusText(state.status),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isScanning ? AppColors.secondary : AppColors.textMuted,
                  isMonospace: true,
                ),
              ],
            ),
          ),
          // Scan/Refresh button
          if (isScanning)
            RotationTransition(
              turns: _scanAnim,
              child: const Icon(Icons.radar_rounded, color: AppColors.primary, size: 22),
            )
          else if (state.status != bloc_state.ConnectionStatus.connected)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
              onPressed: () => context.read<ConnectionBloc>().add(StartScanEvent()),
              tooltip: 'Quét lại',
            ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  String _statusText(bloc_state.ConnectionStatus status) {
    switch (status) {
      case bloc_state.ConnectionStatus.scanning:
        return 'ĐANG QUÉT...';
      case bloc_state.ConnectionStatus.connecting:
        return 'ĐANG KẾT NỐI...';
      case bloc_state.ConnectionStatus.connected:
        return 'ĐÃ KẾT NỐI';
      case bloc_state.ConnectionStatus.disconnected:
        return 'CHƯA KẾT NỐI';
    }
  }

  Widget _buildConnectedView(bloc_state.ConnectionState state) {
    final isBle = state.connectionType == 'ble';
    final isUsb = state.connectionType == 'usb';
    final connectionLabel = isUsb ? 'USB Serial' : isBle ? 'Bluetooth LE' : 'WiFi WebSocket';
    final connectionIcon = isUsb ? Icons.usb_rounded : isBle ? Icons.bluetooth_connected_rounded : Icons.wifi_rounded;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Connected device card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: ShapeDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(
                    connectionIcon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        'Llano Smart Fan',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      AppText(
                        connectionLabel,
                        fontSize: 11,
                        color: AppColors.primary,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: ShapeDecoration(
                    color: AppColors.statusOnline.withValues(alpha: 0.15),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const AppText(
                    'ONLINE',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.statusOnline,
                    isMonospace: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // WiFi provisioning - let user connect ESP32 to home WiFi
          WifiProvisioningWidget(
            activeService: state.activeService,
          ),
          const SizedBox(height: 12),
          // Disconnect button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                context.read<ConnectionBloc>().add(DisconnectEvent());
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.statusOffline,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.statusOffline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: const AppText(
                'Ngắt Kết Nối',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.statusOffline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanView(bloc_state.ConnectionState state) {
    final hasBle = state.bleDevices.isNotEmpty;
    final hasWifi = state.wifiDevices.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // USB section (highest priority — shown first)
          if (state.usbDevices.isNotEmpty) ...[
            _buildSectionHeader(Icons.usb_rounded, 'USB Serial', const Color(0xFF4CAF50)),
            const SizedBox(height: 8),
            ...state.usbDevices.map((d) => _buildDeviceTile(d, 'usb', state.status)),
            const SizedBox(height: 16),
          ],

          // WiFi section (always show AP option)
          _buildSectionHeader(Icons.wifi_rounded, 'WiFi', AppColors.secondary),
          const SizedBox(height: 8),
          ...state.wifiDevices.map((d) => _buildDeviceTile(d, 'wifi', state.status)),
          if (!hasWifi)
            _buildDeviceTile(
              const bloc_state.DiscoveredDevice(
                name: 'LlanoFan AP',
                id: '192.168.4.1',
                ipAddress: '192.168.4.1',
                type: 'wifi',
              ),
              'wifi',
              state.status,
            ),
          const SizedBox(height: 16),

          // BLE section
          _buildSectionHeader(
            Icons.bluetooth_rounded,
            'Bluetooth LE',
            const Color(0xFF5B8DEF),
          ),
          const SizedBox(height: 8),
          if (hasBle)
            ...state.bleDevices.map((d) => _buildDeviceTile(d, 'ble', state.status))
          else if (state.status == bloc_state.ConnectionStatus.scanning)
            _buildEmptyHint('Đang tìm thiết bị BLE...')
          else
            _buildEmptyHint('Không tìm thấy. Bấm ↻ để quét lại.'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        AppText(
          title.toUpperCase(),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          isMonospace: true,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.2), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildDeviceTile(
    bloc_state.DiscoveredDevice device,
    String deviceType,
    bloc_state.ConnectionStatus status,
  ) {
    final isConnecting = status == bloc_state.ConnectionStatus.connecting;
    final isBle = deviceType == 'ble';
    final isUsb = deviceType == 'usb';
    final color = isUsb ? const Color(0xFF4CAF50) : isBle ? const Color(0xFF5B8DEF) : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnecting
              ? null
              : () {
                  context.read<ConnectionBloc>().add(StopScanEvent());
                  if (isUsb) {
                    context.read<ConnectionBloc>().add(
                          ConnectUsbEvent(device.id),
                        );
                  } else if (isBle) {
                    context.read<ConnectionBloc>().add(
                          ConnectBleEvent(BluetoothDevice.fromId(device.id)),
                        );
                  } else {
                    final ip = device.ipAddress.isNotEmpty
                        ? device.ipAddress
                        : '192.168.4.1';
                    context.read<ConnectionBloc>().add(
                          ConnectWifiEvent('ws://$ip:81'),
                        );
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: ShapeDecoration(
              color: AppColors.surface,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Device icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: ShapeDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Icon(
                    isUsb ? Icons.usb_rounded : isBle ? Icons.bluetooth_rounded : Icons.wifi_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                // Device info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        device.name.isNotEmpty ? device.name : 'Unknown Device',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      AppText(
                        isBle
                            ? '${device.rssi} dBm'
                            : isUsb ? device.id : device.ipAddress,
                        fontSize: 10,
                        color: AppColors.textMuted,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
                // Connect arrow
                Icon(
                  isConnecting
                      ? Icons.hourglass_top_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: AppText(
          text,
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
