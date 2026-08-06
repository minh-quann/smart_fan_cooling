import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_state.dart'
    as conn;
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

/// Real-time GPIO pin test screen for encoder and button diagnostics.
class GpioTestScreen extends StatefulWidget {
  const GpioTestScreen({super.key});

  @override
  State<GpioTestScreen> createState() => _GpioTestScreenState();
}

class _GpioTestScreenState extends State<GpioTestScreen> {
  Timer? _pollTimer;
  bool _isRunning = false;

  // Pin states
  int _encA = -1; // -1 = unknown
  int _encB = -1;
  int _enc2A = -1;
  int _enc2B = -1;
  int _enc2A_adc = 0;
  int _enc2B_adc = 0;
  int _enc2Count = 0;
  int _btnPsh = -1;
  int _btnCon = -1;
  int _btnBak = -1;

  // History for encoder waveform (last 60 samples)
  final List<int> _encAHistory = [];
  final List<int> _encBHistory = [];
  final List<int> _enc2AHistory = [];
  final List<int> _enc2BHistory = [];
  static const int _maxHistory = 60;

  // Stats
  int _sampleCount = 0;
  int _encChanges = 0;
  int _enc2Changes = 0;
  int _lastEncA = -1;
  int _lastEncB = -1;
  int _lastEnc2A = -1;
  int _lastEnc2B = -1;

  StreamSubscription? _statusSub;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _statusSub?.cancel();
    _statusSub = null;
    _isRunning = false;
    super.dispose();
  }

  void _startPolling() {
    final bloc = context.read<ConnectionBloc>();
    final state = bloc.state;
    if (state.status != conn.ConnectionStatus.connected ||
        state.activeService == null) {
      return;
    }

    if (mounted) setState(() => _isRunning = true);

    // Listen for pin_test responses from rawJsonStream
    _statusSub = state.activeService!.rawJsonStream.listen(
      (data) {
        if (data['cmd'] == 'pin_test' && mounted) {
          updatePinStates(data);
        }
      },
      onError: (_) {
        // Ignore stream errors
      },
    );

    // Poll every 200ms (slower to avoid flooding serial)
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _sendPinTestCommand();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _statusSub?.cancel();
    _statusSub = null;
    if (mounted) setState(() => _isRunning = false);
  }

  void _sendPinTestCommand() {
    try {
      final bloc = context.read<ConnectionBloc>();
      final state = bloc.state;
      if (state.status != conn.ConnectionStatus.connected ||
          state.activeService == null) {
        _stopPolling();
        return;
      }
      state.activeService!.sendCommand('pin_test', null).catchError((_) {});
    } catch (_) {
      // Widget might be disposed
    }
  }

  void _resetStats() {
    setState(() {
      _sampleCount = 0;
      _encChanges = 0;
      _enc2Changes = 0;
      _encAHistory.clear();
      _encBHistory.clear();
      _enc2AHistory.clear();
      _enc2BHistory.clear();
    });
  }

  /// Called when a pin_test response is received from the device
  void updatePinStates(Map<String, dynamic> data) {
    setState(() {
      _encA = data['enc_a'] ?? -1;
      _encB = data['enc_b'] ?? -1;
      _enc2A = data['enc2_a'] ?? -1;
      _enc2B = data['enc2_b'] ?? -1;
      _enc2A_adc = data['enc2_a_adc'] ?? 0;
      _enc2B_adc = data['enc2_b_adc'] ?? 0;
      _enc2Count = data['enc2_count'] ?? 0;
      _btnPsh = data['btn_psh'] ?? -1;
      _btnCon = data['btn_con'] ?? -1;
      _btnBak = data['btn_bak'] ?? -1;

      _sampleCount++;

      // Track encoder 1 changes
      if (_lastEncA != -1 && (_encA != _lastEncA || _encB != _lastEncB)) {
        _encChanges++;
      }
      _lastEncA = _encA;
      _lastEncB = _encB;

      // Track encoder 2 changes
      if (_lastEnc2A != -1 && (_enc2A != _lastEnc2A || _enc2B != _lastEnc2B)) {
        _enc2Changes++;
      }
      _lastEnc2A = _enc2A;
      _lastEnc2B = _enc2B;

      // Append to history
      _encAHistory.add(_encA);
      _encBHistory.add(_encB);
      _enc2AHistory.add(_enc2A);
      _enc2BHistory.add(_enc2B);
      if (_encAHistory.length > _maxHistory) _encAHistory.removeAt(0);
      if (_encBHistory.length > _maxHistory) _encBHistory.removeAt(0);
      if (_enc2AHistory.length > _maxHistory) _enc2AHistory.removeAt(0);
      if (_enc2BHistory.length > _maxHistory) _enc2BHistory.removeAt(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, conn.ConnectionState>(
      builder: (context, connState) {
        final isConnected =
            connState.status == conn.ConnectionStatus.connected;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.h1('TEST GPIO — CHẨN ĐOÁN PHẦN CỨNG'),
              const SizedBox(height: 4),
              AppText.caption(
                  'Đọc trạng thái chân GPIO real-time từ ESP32-S3. Dùng để kiểm tra encoder và nút bấm.'),
              const SizedBox(height: 16),

              // Control bar
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _isRunning ? Icons.sensors : Icons.sensors_off,
                        color: _isRunning
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      AppText(
                        _isRunning
                            ? 'ĐANG ĐỌC TÍN HIỆU...'
                            : 'SẴN SÀNG',
                        fontSize: 12,
                        color: _isRunning
                            ? AppColors.primary
                            : AppColors.textMuted,
                        isMonospace: true,
                        fontWeight: FontWeight.w600,
                      ),
                      const Spacer(),
                      if (_isRunning)
                        AppText(
                          '$_sampleCount mẫu | $_encChanges thay đổi',
                          fontSize: 10,
                          color: AppColors.textMuted,
                          isMonospace: true,
                        ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        icon: Icons.restart_alt,
                        label: 'Reset',
                        onTap: _resetStats,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: _isRunning ? Icons.stop : Icons.play_arrow,
                        label: _isRunning ? 'Dừng' : 'Bắt đầu',
                        onTap: isConnected
                            ? (_isRunning ? _stopPolling : _startPolling)
                            : null,
                        color: _isRunning
                            ? AppColors.statusOffline
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              if (!isConnected) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        AppText(
                          'Chưa kết nối ESP32. Hãy kết nối trước khi test.',
                          fontSize: 12,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Pin layout info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encoder 1 section (OLED module)
                  Expanded(
                    flex: 2,
                    child: _buildEncoderSection(),
                  ),
                  const SizedBox(width: 12),
                  // Encoder 2 section (mouse scroll wheel)
                  Expanded(
                    flex: 2,
                    child: _buildEncoder2Section(),
                  ),
                  const SizedBox(width: 12),
                  // Buttons section
                  Expanded(
                    flex: 2,
                    child: _buildButtonSection(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Waveform
              _buildWaveformSection(),

              const SizedBox(height: 16),

              // Pin mapping reference
              _buildPinMappingCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEncoderSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                AppText(
                  'ROTARY ENCODER',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  isMonospace: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPinIndicator('ENC_A', 'GPIO 10', _encA, const Color(0xFF4CAF50))),
                const SizedBox(width: 12),
                Expanded(child: _buildPinIndicator('ENC_B', 'GPIO 11', _encB, const Color(0xFF2196F3))),
              ],
            ),
            const SizedBox(height: 12),
            // Rotation direction hint
            if (_encA >= 0 && _encB >= 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'A=$_encA B=$_encB',
                      fontSize: 11,
                      color: AppColors.textPrimary,
                      isMonospace: true,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      _encChanges == 0
                          ? 'Chưa phát hiện xoay'
                          : '✓ Encoder hoạt động!',
                      fontSize: 10,
                      color: _encChanges > 0
                          ? AppColors.primary
                          : AppColors.textMuted,
                      isMonospace: true,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEncoder2Section() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mouse, color: const Color(0xFFFF9800), size: 18),
                const SizedBox(width: 6),
                AppText(
                  'CON LĂN CHUỘT',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF9800),
                  isMonospace: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppText(
              'GPIO 15 + 16 (Interrupt)',
              fontSize: 9,
              color: AppColors.textMuted,
              isMonospace: true,
            ),
            const SizedBox(height: 12),
            // Big count display
            Center(
              child: AppText(
                '$_enc2Count',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _enc2Count != 0
                    ? const Color(0xFF4CAF50)
                    : AppColors.textMuted,
                isMonospace: true,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: AppText(
                _enc2Count == 0
                    ? 'Xoay encoder để test'
                    : _enc2Count > 0
                        ? '↻ Xoay phải (+$_enc2Count)'
                        : '↺ Xoay trái ($_enc2Count)',
                fontSize: 10,
                color: _enc2Count != 0
                    ? const Color(0xFF4CAF50)
                    : AppColors.textMuted,
                isMonospace: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.touch_app, color: AppColors.secondary, size: 18),
                const SizedBox(width: 6),
                AppText(
                  'NÚT BẤM',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                  isMonospace: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildButtonIndicator('PSH', 'GPIO 14', _btnPsh, 'Nhấn encoder'),
            const SizedBox(height: 8),
            _buildButtonIndicator('CON', 'GPIO 12', _btnCon, 'Toggle LED'),
            const SizedBox(height: 8),
            _buildButtonIndicator('BAK', 'GPIO 13', _btnBak, 'Chuyển mode'),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                AppText(
                  'SÓNG TÍN HIỆU ENCODER',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  isMonospace: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Encoder 1 label
            AppText('Enc1 (OLED Module)', fontSize: 10, color: AppColors.textMuted, isMonospace: true),
            const SizedBox(height: 4),
            // Channel A waveform
            _buildWaveformRow('A', _encAHistory, const Color(0xFF4CAF50)),
            const SizedBox(height: 4),
            // Channel B waveform
            _buildWaveformRow('B', _encBHistory, const Color(0xFF2196F3)),
            const SizedBox(height: 12),
            // Encoder 2 label
            AppText('Enc2 (Con Lăn Chuột)', fontSize: 10, color: const Color(0xFFFF9800), isMonospace: true),
            const SizedBox(height: 4),
            _buildWaveformRow('A', _enc2AHistory, const Color(0xFFFF9800)),
            const SizedBox(height: 4),
            _buildWaveformRow('B', _enc2BHistory, const Color(0xFFE91E63)),
            const SizedBox(height: 8),
            AppText(
              'Xoay encoder để thấy sóng vuông lệch pha 90°. Nếu cả 2 kênh luôn giống nhau → sai dây.',
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformRow(String label, List<int> history, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: AppText(
            label,
            fontSize: 10,
            color: color,
            isMonospace: true,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 30,
            child: CustomPaint(
              painter: _WaveformPainter(history, color),
              size: const Size(double.infinity, 30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinMappingCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 6),
                AppText(
                  'SƠ ĐỒ CHÂN ENCODER',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  isMonospace: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: AppText(
                '  Encoder (nhìn từ trên)\n'
                '  ┌───────────┐\n'
                '  │   (xoay)  │\n'
                '  └─┬───┬───┬─┘\n'
                '    A   C   B\n'
                '    │   │   │\n'
                '  GPIO GND GPIO\n'
                '   10       11\n'
                '\n'
                '  C (giữa) = GND\n'
                '  A (trái) = GPIO 10\n'
                '  B (phải) = GPIO 11\n'
                '  * Nếu xoay ngược → đổi A↔B',
                fontSize: 11,
                color: AppColors.textSecondary,
                isMonospace: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinIndicator(
      String name, String gpio, int state, Color color) {
    final isHigh = state == 1;
    final isUnknown = state == -1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnknown
            ? AppColors.surface
            : isHigh
                ? color.withValues(alpha: 0.15)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnknown
              ? AppColors.border
              : isHigh
                  ? color
                  : AppColors.border,
          width: isHigh ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          AppText(
            name,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isHigh ? color : AppColors.textMuted,
            isMonospace: true,
          ),
          const SizedBox(height: 2),
          AppText(
            gpio,
            fontSize: 9,
            color: AppColors.textMuted,
            isMonospace: true,
          ),
          const SizedBox(height: 6),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnknown
                  ? AppColors.surface
                  : isHigh
                      ? color
                      : AppColors.surface,
              border: Border.all(
                color: isUnknown ? AppColors.border : color,
                width: 2,
              ),
              boxShadow: isHigh
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AppText(
                isUnknown ? '?' : isHigh ? 'H' : 'L',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isUnknown
                    ? AppColors.textMuted
                    : isHigh
                        ? Colors.white
                        : color,
                isMonospace: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonIndicator(
      String name, String gpio, int state, String desc) {
    final isPressed = state == 0; // Buttons are active-low with pull-up
    final isUnknown = state == -1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPressed
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPressed ? AppColors.secondary : AppColors.border,
          width: isPressed ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnknown
                  ? AppColors.textMuted
                  : isPressed
                      ? AppColors.secondary
                      : AppColors.surface,
              border: Border.all(
                color: isUnknown ? AppColors.textMuted : AppColors.secondary,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppText(
            '$name ($gpio)',
            fontSize: 11,
            color: isPressed ? AppColors.secondary : AppColors.textSecondary,
            isMonospace: true,
            fontWeight: FontWeight.w600,
          ),
          const Spacer(),
          AppText(
            isUnknown ? '---' : isPressed ? 'NHẤN' : 'THẢ',
            fontSize: 10,
            color: isUnknown
                ? AppColors.textMuted
                : isPressed
                    ? AppColors.secondary
                    : AppColors.textMuted,
            isMonospace: true,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              AppText(
                label,
                fontSize: 10,
                color: color,
                isMonospace: true,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for simple digital waveform
class _WaveformPainter extends CustomPainter {
  final List<int> data;
  final Color color;

  _WaveformPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      // Draw empty line
      final paint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stepWidth = size.width / _GpioTestScreenState._maxHistory;
    final highY = 4.0;
    final lowY = size.height - 4;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepWidth;
      final y = data[i] == 1 ? highY : lowY;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Step waveform: vertical then horizontal
        final prevY = data[i - 1] == 1 ? highY : lowY;
        if (y != prevY) {
          path.lineTo(x, prevY);
          path.lineTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(path, paint);

    // Draw labels
    final labelPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, highY), Offset(size.width, highY), labelPaint);
    canvas.drawLine(Offset(0, lowY), Offset(size.width, lowY), labelPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return data.length != oldDelegate.data.length ||
        (data.isNotEmpty && oldDelegate.data.isNotEmpty && data.last != oldDelegate.data.last);
  }
}
