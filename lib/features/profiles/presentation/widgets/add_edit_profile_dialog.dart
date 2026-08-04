import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_curve_point.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

class AddEditProfileDialog extends StatefulWidget {
  final FanProfile? profileToEdit;
  final ValueChanged<FanProfile> onSave;

  const AddEditProfileDialog({
    super.key,
    this.profileToEdit,
    required this.onSave,
  });

  @override
  State<AddEditProfileDialog> createState() => _AddEditProfileDialogState();
}

class _AddEditProfileDialogState extends State<AddEditProfileDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  IconData _selectedIcon = Icons.tune_rounded;
  Color _selectedColor = AppColors.primary;
  int _maxPwm = 100;
  bool _isFixedSpeed = false;
  int _fixedPwm = 50;

  final List<IconData> _iconOptions = const [
    Icons.tune_rounded,
    Icons.volume_off_rounded,
    Icons.sports_esports_rounded,
    Icons.auto_awesome_rounded,
    Icons.ac_unit_rounded,
    Icons.bolt_rounded,
    Icons.speed_rounded,
    Icons.local_fire_department_rounded,
  ];

  final List<Color> _colorOptions = const [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accentPurple,
    AppColors.accentRed,
    AppColors.accentOrange,
    AppColors.accentPink,
    AppColors.accentBlue,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.profileToEdit != null) {
      final p = widget.profileToEdit!;
      _nameController.text = p.name;
      _descController.text = p.description;
      _selectedIcon = p.icon;
      _selectedColor = p.themeColor;
      _maxPwm = p.maxFanPwm;
      _isFixedSpeed = p.isFixedSpeed;
      _fixedPwm = p.fixedPwm;
    } else {
      _nameController.text = 'Profile Tùy Chỉnh';
      _descController.text = 'Tự cấu hình mức công suất và đường cong quạt';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;

    final String id = widget.profileToEdit?.id ?? 'profile_${DateTime.now().millisecondsSinceEpoch}';

    List<FanCurvePoint> curve;
    if (_isFixedSpeed) {
      curve = [
        FanCurvePoint(30, _fixedPwm.toDouble()),
        FanCurvePoint(45, _fixedPwm.toDouble()),
        FanCurvePoint(60, _fixedPwm.toDouble()),
        FanCurvePoint(75, _fixedPwm.toDouble()),
        FanCurvePoint(90, _fixedPwm.toDouble()),
      ];
    } else {
      curve = widget.profileToEdit?.fanCurve ??
          [
            const FanCurvePoint(30, 20),
            const FanCurvePoint(45, 40),
            const FanCurvePoint(60, 60),
            const FanCurvePoint(75, 80),
            const FanCurvePoint(90, 100),
          ];
    }

    final profile = FanProfile(
      id: id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      icon: _selectedIcon,
      themeColor: _selectedColor,
      maxFanPwm: _maxPwm,
      fanCurve: curve,
      rgbMode: widget.profileToEdit?.rgbMode ?? 'Breathing',
      rgbColor: _selectedColor,
      isDefault: widget.profileToEdit?.isDefault ?? false,
      isFixedSpeed: _isFixedSpeed,
      fixedPwm: _fixedPwm,
    );

    widget.onSave(profile);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.profileToEdit != null;

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.h1(isEditing ? 'CHỈNH SỬA PROFILE' : 'TẠO PROFILE MỚI'),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile Name
              AppText.caption('TÊN PROFILE'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Nhập tên profile (VD: Render Đêm, Extreme Quiet)',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              AppText.caption('MÔ TẢ NGẮN'),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Nhập mô tả kịch bản sử dụng',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mode Selection: Fixed Speed vs Dynamic Curve
              AppText.caption('CHẾ ĐỘ ĐIỀU KHIỂN TỐC ĐỘ QUẠT'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isFixedSpeed = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: ShapeDecoration(
                          color: !_isFixedSpeed ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: !_isFixedSpeed ? AppColors.primary : AppColors.border,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.show_chart_rounded, color: !_isFixedSpeed ? AppColors.primary : AppColors.textMuted),
                            const SizedBox(height: 4),
                            AppText('Đường Cong Nhiệt', fontSize: 12, fontWeight: FontWeight.w700),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isFixedSpeed = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: ShapeDecoration(
                          color: _isFixedSpeed ? AppColors.secondary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _isFixedSpeed ? AppColors.secondary : AppColors.border,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.lock_clock_rounded, color: _isFixedSpeed ? AppColors.secondary : AppColors.textMuted),
                            const SizedBox(height: 4),
                            AppText('Khóa Cố Định PWM', fontSize: 12, fontWeight: FontWeight.w700),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fixed Speed Slider (if enabled)
              if (_isFixedSpeed) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.caption('MỨC CÔNG SUẤT PWM KHÓA CỐ ĐỊNH:'),
                    AppText('$_fixedPwm% (~${((_fixedPwm / 100.0) * 2800).round()} RPM)', fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.secondary),
                  ],
                ),
                SliderTheme(
                  data: const SliderThemeData(trackHeight: 6),
                  child: Slider(
                    value: _fixedPwm.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: AppColors.secondary,
                    onChanged: (val) => setState(() => _fixedPwm = val.round()),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Max Fan PWM Limit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.caption('GIỚI HẠN CÔNG SUẤT TỐI ĐA (MAX PWM):'),
                  AppText('$_maxPwm% (~${((_maxPwm / 100.0) * 2800).round()} RPM)', fontSize: 14, fontWeight: FontWeight.w800, color: _selectedColor),
                ],
              ),
              SliderTheme(
                data: const SliderThemeData(trackHeight: 6),
                child: Slider(
                  value: _maxPwm.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 90,
                  activeColor: _selectedColor,
                  onChanged: (val) => setState(() => _maxPwm = val.round()),
                ),
              ),
              const SizedBox(height: 16),

              // Color Selection
              AppText.caption('MÀU CHỦ ĐẠO PROFILE'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colorOptions.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 32,
                      height: 32,
                      decoration: ShapeDecoration(
                        color: color,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Icon Selection
              AppText.caption('BIỂU TƯỢNG (ICON)'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _iconOptions.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: ShapeDecoration(
                        color: isSelected ? _selectedColor.withValues(alpha: 0.2) : AppColors.surfaceLight,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? _selectedColor : AppColors.border,
                          ),
                        ),
                      ),
                      child: Icon(icon, color: isSelected ? _selectedColor : AppColors.textMuted, size: 20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: AppText('Hủy Bỏ', color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: isEditing ? 'CẬP NHẬT PROFILE' : 'TẠO PROFILE',
                    backgroundColor: _selectedColor,
                    textColor: Colors.black,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
