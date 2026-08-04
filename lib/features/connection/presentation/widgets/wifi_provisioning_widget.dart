import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/connection/data/services/device_service.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

class WifiProvisioningWidget extends StatefulWidget {
  final DeviceService? activeService;

  const WifiProvisioningWidget({
    super.key,
    required this.activeService,
  });

  @override
  State<WifiProvisioningWidget> createState() => _WifiProvisioningWidgetState();
}

class _WifiProvisioningWidgetState extends State<WifiProvisioningWidget> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _statusMessage = '';
  bool _isSending = false;
  bool? _lastSuccess;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendWifiConfig() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text;

    if (ssid.isEmpty) {
      setState(() {
        _statusMessage = 'Vui lòng nhập tên WiFi';
        _lastSuccess = false;
      });
      return;
    }

    if (widget.activeService == null) {
      setState(() {
        _statusMessage = 'Chưa kết nối thiết bị';
        _lastSuccess = false;
      });
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = 'Đang gửi... ESP32 sẽ thử kết nối (~10s)';
      _lastSuccess = null;
    });

    try {
      final result = await widget.activeService!.sendWifiConfig(ssid, password);
      if (mounted) {
        setState(() {
          _isSending = false;
          _lastSuccess = result.success;
          if (result.success) {
            _statusMessage = result.ip != null
                ? '✅ Kết nối thành công! IP: ${result.ip}'
                : '✅ Đã gửi cấu hình WiFi';
          } else {
            _statusMessage = '❌ Kết nối WiFi thất bại. Kiểm tra lại tên và mật khẩu.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _lastSuccess = false;
          _statusMessage = '❌ Gửi thất bại: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.wifi_rounded, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              const AppText(
                'Kết Nối WiFi Nhà',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // SSID field
          TextField(
            controller: _ssidController,
            decoration: InputDecoration(
              labelText: 'Tên WiFi nhà',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 10),
          // Password field
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Mật khẩu WiFi',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Status message
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                color: _lastSuccess == true
                    ? AppColors.statusOnline.withValues(alpha: 0.1)
                    : _lastSuccess == false
                        ? AppColors.statusOffline.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: AppText(
                _statusMessage,
                fontSize: 12,
                color: _lastSuccess == true
                    ? AppColors.statusOnline
                    : _lastSuccess == false
                        ? AppColors.statusOffline
                        : AppColors.primary,
              ),
            ),
          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendWifiConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.surfaceLight,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const AppText(
                          'Đang kết nối...',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    )
                  : const AppText(
                      'Gửi Cấu Hình WiFi',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
