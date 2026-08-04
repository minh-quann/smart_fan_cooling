import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/data/services/app_scanner_service.dart';
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
  final _searchController = TextEditingController();

  late String _selectedProfileId;
  List<ScannedAppItem> _allScannedApps = [];
  List<ScannedAppItem> _filteredApps = [];
  bool _isLoadingApps = true;
  String _activeFilter = 'ALL'; // 'ALL', 'RUNNING', 'INSTALLED'
  ScannedAppItem? _selectedAppItem;

  @override
  void initState() {
    super.initState();
    _selectedProfileId = widget.profiles.isNotEmpty
        ? widget.profiles.first.id
        : 'profile_silent';
    _loadSystemApps();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _exeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemApps() async {
    setState(() => _isLoadingApps = true);
    final apps = await AppScannerService.scanAllApps();
    if (mounted) {
      setState(() {
        _allScannedApps = apps;
        _isLoadingApps = false;
        _applyAppFilter();
      });
    }
  }

  void _applyAppFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredApps = _allScannedApps.where((app) {
        final matchesQuery = query.isEmpty ||
            app.name.toLowerCase().contains(query) ||
            app.executableName.toLowerCase().contains(query);

        if (!matchesQuery) return false;

        if (_activeFilter == 'RUNNING') return app.isRunning;
        if (_activeFilter == 'INSTALLED') return !app.isRunning;
        return true;
      }).toList();
    });
  }

  void _selectApp(ScannedAppItem app) {
    setState(() {
      _selectedAppItem = app;
      _nameController.text = app.name;
      _exeController.text = app.executableName;
    });
  }

  Future<void> _browseExecutableFile() async {
    try {
      if (Platform.isLinux) {
        final res = await Process.run('zenity', [
          '--file-selection',
          '--title=Chọn File Thực Thi Ứng Dụng'
        ]);
        if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
          final filePath = res.stdout.toString().trim();
          final fileName = filePath.split('/').last;
          final cleanName = fileName.replaceAll(RegExp(r'\.exe$', caseSensitive: false), '');
          setState(() {
            _nameController.text = cleanName;
            _exeController.text = fileName.toLowerCase();
          });
        }
      } else if (Platform.isWindows) {
        const psScript = '''
          Add-Type -AssemblyName System.Windows.Forms
          \$f = New-Object System.Windows.Forms.OpenFileDialog
          \$f.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*"
          if (\$f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { \$f.FileName }
        ''';
        final res = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
        if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
          final filePath = res.stdout.toString().trim();
          final fileName = filePath.split(RegExp(r'[/\\]')).last;
          final cleanName = fileName.replaceAll(RegExp(r'\.exe$', caseSensitive: false), '');
          setState(() {
            _nameController.text = cleanName;
            _exeController.text = fileName.toLowerCase();
          });
        }
      }
    } catch (_) {}
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
        width: 680,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.apps_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    AppText.h2('GÁN PROFILE TỰ ĐỘNG CHO ỨNG DỤNG'),
                  ],
                ),
                IconButton(
                  onPressed: _loadSystemApps,
                  icon: const Icon(Icons.sync_rounded, color: AppColors.secondary, size: 20),
                  tooltip: 'Quét lại phần mềm hệ thống',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // App Scanner Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.caption('DANH SÁCH PHẦN MỀM ĐÃ QUÉT TRÊN MÁY (${Platform.isWindows ? "WINDOWS" : "LINUX"}):'),
                TextButton.icon(
                  onPressed: _browseExecutableFile,
                  icon: const Icon(Icons.folder_open_rounded, size: 16, color: AppColors.primary),
                  label: AppText(
                    Platform.isWindows ? 'Duyệt File .exe...' : 'Duyệt File Binary...',
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search Bar & Filter Chips Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyAppFilter(),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '🔎 Tìm nhanh phần mềm, game...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Filter Buttons
                _buildFilterChip('TẤT CẢ', 'ALL'),
                const SizedBox(width: 6),
                _buildFilterChip('🟢 ĐANG CHẠY', 'RUNNING'),
                const SizedBox(width: 6),
                _buildFilterChip('💻 ĐÃ CÀI ĐẶT', 'INSTALLED'),
              ],
            ),
            const SizedBox(height: 10),

            // Scanned App Selector ListView
            Expanded(
              child: Container(
                decoration: ShapeDecoration(
                  color: AppColors.background,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                child: _isLoadingApps
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                            const SizedBox(height: 12),
                            AppText('Đang quét tự động các ứng dụng trên ${Platform.isWindows ? "Windows" : "Linux"}...', color: AppColors.textMuted),
                          ],
                        ),
                      )
                    : _filteredApps.isEmpty
                        ? const Center(
                            child: AppText('Không tìm thấy ứng dụng phù hợp', color: AppColors.textMuted),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredApps.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final app = _filteredApps[index];
                              final isSelected = _selectedAppItem == app ||
                                  _exeController.text.trim().toLowerCase() == app.executableName.toLowerCase();

                              return InkWell(
                                onTap: () => _selectApp(app),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: ShapeDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : AppColors.surfaceLight.withValues(alpha: 0.4),
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        app.isRunning ? Icons.play_circle_fill_rounded : Icons.apps_rounded,
                                        color: app.isRunning ? AppColors.primary : AppColors.secondary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AppText(
                                              app.name,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            AppText(
                                              app.executableName,
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                              isMonospace: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: ShapeDecoration(
                                          color: app.isRunning
                                              ? AppColors.primary.withValues(alpha: 0.2)
                                              : AppColors.surfaceLight,
                                          shape: RoundedSuperellipseBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: AppText(
                                          app.isRunning ? 'Đang chạy' : 'Đã cài đặt',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: app.isRunning ? AppColors.primary : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
            const SizedBox(height: 14),

            // Form Inputs for App Name & Executable
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.caption('TÊN ỨNG DỤNG / GAME:'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Google Chrome, Cyberpunk 2077...',
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.caption(
                        Platform.isWindows
                            ? 'FILE THỰC THI (.EXE KHÔNG PHÂN BIỆT):'
                            : 'TÊN KHỞI CHẠY / BINARY (KHÔNG PHÂN BIỆT):',
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _exeController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'FiraCode'),
                        decoration: InputDecoration(
                          hintText: Platform.isWindows
                              ? 'Ví dụ: chrome.exe, code.exe, photoshop.exe'
                              : 'Ví dụ: google-chrome, code, discord, vlc',
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Select Profile Dropdown Row
            Row(
              children: [
                AppText.caption('KÍCH HOẠT PROFILE:'),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: ShapeDecoration(
                      color: AppColors.surfaceLight,
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(8),
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
                                Icon(p.icon, color: p.themeColor, size: 16),
                                const SizedBox(width: 8),
                                AppText(p.name, fontWeight: FontWeight.w700, fontSize: 13),
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
                ),
                const SizedBox(width: 16),
                AppButton(
                  label: 'HỦY',
                  isOutlined: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
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

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _activeFilter == filterKey;

    return GestureDetector(
      onTap: () {
        setState(() => _activeFilter = filterKey);
        _applyAppFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: ShapeDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
        ),
        child: AppText(
          label,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}
