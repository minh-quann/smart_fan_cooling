import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/app_mapping.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

class AddAppDialog extends StatefulWidget {
  final List<FanProfile> profiles;
  final ValueChanged<AppMapping> onAdd;

  const AddAppDialog({
    super.key,
    required this.profiles,
    required this.onAdd,
  });

  @override
  State<AddAppDialog> createState() => _AddAppDialogState();
}

class _AddAppDialogState extends State<AddAppDialog> {
  final _nameController = TextEditingController();
  final _exeController = TextEditingController();
  late String _selectedProfileId;

  @override
  void initState() {
    super.initState();
    _selectedProfileId = widget.profiles.isNotEmpty
        ? widget.profiles.first.id
        : 'profile_silent';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _exeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_to_photos_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                AppText.h2('GÁN PROFILE CHO ỨNG DỤNG MỚI'),
              ],
            ),
            const SizedBox(height: 20),

            // App Name Input
            AppText.caption('TÊN PHẦN MỀM / GAME:'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Dota 2, Photoshop, VS Code...',
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

            // Executable File Name Input
            AppText.caption('FILE THỰC THI (.EXE KHÔNG PHÂN BIỆT HOA THƯỜNG):'),
            const SizedBox(height: 6),
            TextField(
              controller: _exeController,
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'FiraCode'),
              decoration: InputDecoration(
                hintText: 'Ví dụ: dota2.exe, photoshop.exe, code.exe',
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

            // Select Profile Dropdown
            AppText.caption('CHỌN PROFILE KÍCH HOẠT:'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: ShapeDecoration(
                color: AppColors.surfaceLight,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProfileId,
                  dropdownColor: AppColors.cardBg,
                  isExpanded: true,
                  items: widget.profiles.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Row(
                        children: [
                          Icon(p.icon, color: p.themeColor, size: 18),
                          const SizedBox(width: 8),
                          AppText(p.name, fontWeight: FontWeight.w600),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProfileId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'HỦY',
                  isOutlined: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'LƯU CẤU HÌNH',
                  backgroundColor: AppColors.primary,
                  onPressed: () {
                    if (_nameController.text.isEmpty || _exeController.text.isEmpty) return;

                    final newMapping = AppMapping(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      appName: _nameController.text.trim(),
                      executableName: _exeController.text.trim().toLowerCase(),
                      iconPath: 'game',
                      profileId: _selectedProfileId,
                      isEnabled: true,
                    );

                    widget.onAdd(newMapping);
                    Navigator.of(context).pop();
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
