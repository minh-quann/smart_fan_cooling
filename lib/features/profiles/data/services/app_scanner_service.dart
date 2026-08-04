import 'dart:io';
import 'package:flutter/foundation.dart';

class ScannedAppItem {
  final String name;
  final String executableName;
  final bool isRunning;
  final String? path;

  const ScannedAppItem({
    required this.name,
    required this.executableName,
    this.isRunning = false,
    this.path,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedAppItem &&
          runtimeType == other.runtimeType &&
          executableName.toLowerCase() == other.executableName.toLowerCase();

  @override
  int get hashCode => executableName.toLowerCase().hashCode;
}

class AppScannerService {
  /// Scans both installed applications and active running processes on Linux & Windows
  static Future<List<ScannedAppItem>> scanAllApps() async {
    final Map<String, ScannedAppItem> appMap = {};

    try {
      // 1. Scan Running Processes first
      final runningApps = await scanRunningApps();
      for (var app in runningApps) {
        appMap[app.executableName.toLowerCase()] = app;
      }

      // 2. Scan Installed Applications (Running or Not Running)
      final installedApps = await scanInstalledApps();
      for (var app in installedApps) {
        final key = app.executableName.toLowerCase();
        if (appMap.containsKey(key)) {
          // Mark as running if already found
          appMap[key] = ScannedAppItem(
            name: app.name.isNotEmpty ? app.name : appMap[key]!.name,
            executableName: app.executableName,
            isRunning: true,
            path: app.path ?? appMap[key]!.path,
          );
        } else {
          appMap[key] = app;
        }
      }
    } catch (e) {
      debugPrint('App scanning error: $e');
    }

    final list = appMap.values.toList();
    // Sort running apps first, then alphabetical by name
    list.sort((a, b) {
      if (a.isRunning && !b.isRunning) return -1;
      if (!a.isRunning && b.isRunning) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  }

  /// Scan active running GUI processes
  static Future<List<ScannedAppItem>> scanRunningApps() async {
    final List<ScannedAppItem> running = [];

    try {
      if (Platform.isLinux) {
        // Use ps command to list process name & command args
        final res = await Process.run('ps', ['-eo', 'comm,args']);
        if (res.exitCode == 0) {
          final lines = res.stdout.toString().trim().split('\n');
          final Set<String> seen = {};

          for (var line in lines.skip(1)) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.isNotEmpty) {
              final comm = parts.first.trim();
              if (comm.isEmpty || _isSystemProcessLinux(comm)) continue;

              final exeName = comm.endsWith('.exe') ? comm : comm;
              if (seen.add(exeName.toLowerCase())) {
                final displayName = _cleanAppName(comm);
                running.add(ScannedAppItem(
                  name: displayName,
                  executableName: exeName,
                  isRunning: true,
                ));
              }
            }
          }
        }
      } else if (Platform.isWindows) {
        // Use PowerShell Get-Process with MainWindowTitle
        final psScript = '''
          Get-Process | Where-Object { \$_.MainWindowTitle -ne '' } | Select-Object -Property ProcessName, MainWindowTitle | ConvertTo-Json
        ''';
        final res = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
        if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
          final output = res.stdout.toString().trim();
          final Set<String> seen = {};

          // Parse process names
          final matches = RegExp(r'"ProcessName":\s*"([^"]+)"').allMatches(output);
          final titleMatches = RegExp(r'"MainWindowTitle":\s*"([^"]+)"').allMatches(output);

          final titles = titleMatches.map((m) => m.group(1)).toList();
          int i = 0;
          for (var m in matches) {
            final proc = m.group(1);
            if (proc != null && proc.isNotEmpty) {
              final exeName = proc.endsWith('.exe') ? proc : '$proc.exe';
              if (seen.add(exeName.toLowerCase())) {
                String title = (i < titles.length && titles[i] != null) ? titles[i]! : proc;
                if (title.trim().isEmpty) title = proc;

                running.add(ScannedAppItem(
                  name: title,
                  executableName: exeName,
                  isRunning: true,
                ));
              }
            }
            i++;
          }
        }
      }
    } catch (_) {}

    return running;
  }

  /// Scan all installed desktop applications (running or not)
  static Future<List<ScannedAppItem>> scanInstalledApps() async {
    final List<ScannedAppItem> installed = [];

    try {
      if (Platform.isLinux) {
        final List<String> desktopDirs = [
          '/usr/share/applications',
          '${Platform.environment['HOME']}/.local/share/applications',
          '/var/lib/flatpak/exports/share/applications',
          '${Platform.environment['HOME']}/.local/share/flatpak/exports/share/applications',
        ];

        final Set<String> seenExecs = {};

        for (var dirPath in desktopDirs) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.desktop'));

            for (var file in files) {
              try {
                final lines = await file.readAsLines();
                String? name;
                String? exec;
                bool noDisplay = false;

                for (var line in lines) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('Name=')) {
                    name ??= trimmed.substring(5).trim();
                  } else if (trimmed.startsWith('Exec=')) {
                    exec ??= trimmed.substring(5).trim();
                  } else if (trimmed.startsWith('NoDisplay=true')) {
                    noDisplay = true;
                  }
                }

                if (!noDisplay && name != null && exec != null) {
                  // Extract binary executable name from Exec line
                  final cleanExec = _extractLinuxExecBinary(exec);
                  if (cleanExec != null && cleanExec.isNotEmpty && seenExecs.add(cleanExec.toLowerCase())) {
                    installed.add(ScannedAppItem(
                      name: name,
                      executableName: cleanExec,
                      isRunning: false,
                      path: file.path,
                    ));
                  }
                }
              } catch (_) {}
            }
          }
        }
      } else if (Platform.isWindows) {
        // Scan Windows Start Menu shortcuts
        final psScript = '''
          \$paths = @(
            "\$env:ProgramData\\Microsoft\\Windows\\Start Menu\\Programs",
            "\$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs"
          );
          Get-ChildItem -Path \$paths -Recurse -Include *.lnk -ErrorAction SilentlyContinue | Select-Object -Property BaseName, FullName | ConvertTo-Json
        ''';

        final res = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
        if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
          final output = res.stdout.toString().trim();
          final matches = RegExp(r'"BaseName":\s*"([^"]+)"').allMatches(output);
          final Set<String> seen = {};

          for (var m in matches) {
            final appName = m.group(1);
            if (appName != null && appName.isNotEmpty) {
              final exeName = '${appName.replaceAll(RegExp(r'\s+'), '').toLowerCase()}.exe';
              if (seen.add(exeName.toLowerCase())) {
                installed.add(ScannedAppItem(
                  name: appName,
                  executableName: exeName,
                  isRunning: false,
                ));
              }
            }
          }
        }
      }
    } catch (_) {}

    return installed;
  }

  static String? _extractLinuxExecBinary(String execLine) {
    try {
      // Remove flags like %u, %f, --new-window
      String clean = execLine.replaceAll(RegExp(r'%\w+'), '').trim();
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        String binaryPath = parts.first;
        if (binaryPath.startsWith('"') && binaryPath.endsWith('"')) {
          binaryPath = binaryPath.substring(1, binaryPath.length - 1);
        }
        final exe = binaryPath.split('/').last.trim();
        return exe;
      }
    } catch (_) {}
    return null;
  }

  static bool _isSystemProcessLinux(String name) {
    const sysProcs = {
      'systemd', 'kthreadd', 'rcu_gp', 'kworker', 'ksoftirqd', 'dbus-daemon',
      'pipewire', 'wireplumber', 'pulseaudio', 'Xorg', 'wayland', 'gnome-shell',
      'polkitd', 'avahi-daemon', 'chronyd', 'networkmanager', 'sshd'
    };
    return sysProcs.contains(name.toLowerCase()) || name.startsWith('kworker/') || name.startsWith('rcu_');
  }

  static String _cleanAppName(String raw) {
    String name = raw.replaceAll(RegExp(r'\.exe$', caseSensitive: false), '');
    if (name.isEmpty) return raw;
    return name[0].toUpperCase() + name.substring(1);
  }
}
