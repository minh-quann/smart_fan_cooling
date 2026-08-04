import 'dart:async';
import 'dart:io';

import 'package:smart_fan_cooling/features/hardware_monitor/domain/models/hardware_stats.dart';

/// Real Hardware Telemetry Service.
/// Retrieves exact hardware model names (CPU & GPU) and calculates AVERAGE temperatures across coretemp/k10temp sensors on Linux,
/// and MSAcpi_ThermalZoneTemperature / OpenHardwareMonitor / nvidia-smi on Windows.
class HardwareMonitorService {
  Timer? _timer;
  final StreamController<HardwareStats> _controller =
      StreamController<HardwareStats>.broadcast();

  HardwareStats _currentStats = HardwareStats.initial();

  // /proc/stat Ticks for CPU Usage Calculation on Linux
  int _prevTotalTime = 0;
  int _prevIdleTime = 0;

  String? _cachedCpuName;
  String? _cachedGpuName;

  Stream<HardwareStats> get statsStream => _controller.stream;
  HardwareStats get currentStats => _currentStats;

  void startMonitoring() {
    _timer?.cancel();
    _fetchHardwareNames();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchRealHardwareStats();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  void updatePwmPercent(int pwm) {
    int safePwm = pwm.clamp(0, 100);
    int expectedRpm = ((safePwm / 100.0) * 2800).toInt();
    _currentStats = _currentStats.copyWith(
      pwmPercent: safePwm,
      fanRpm: expectedRpm,
    );
    _controller.add(_currentStats);
  }

  Future<void> _fetchHardwareNames() async {
    try {
      if (Platform.isLinux) {
        _cachedCpuName = await _readLinuxCpuName();
        _cachedGpuName = await _readLinuxGpuName();
      } else if (Platform.isWindows) {
        _cachedCpuName = await _readWindowsCpuName();
        _cachedGpuName = await _readWindowsGpuName();
      }

      if (_cachedCpuName != null || _cachedGpuName != null) {
        _currentStats = _currentStats.copyWith(
          cpuName: _cachedCpuName ?? _currentStats.cpuName,
          gpuName: _cachedGpuName ?? _currentStats.gpuName,
        );
        _controller.add(_currentStats);
      }
    } catch (_) {}
  }

  Future<void> _fetchRealHardwareStats() async {
    try {
      double cpuTemp = _currentStats.cpuTemp;
      double gpuTemp = _currentStats.gpuTemp;
      double cpuUsage = _currentStats.cpuUsage;
      double gpuUsage = _currentStats.gpuUsage;
      double ramUsage = _currentStats.ramUsage;
      double cpuClock = _currentStats.cpuClock;
      double gpuClock = _currentStats.gpuClock;
      String cpuName = _cachedCpuName ?? _currentStats.cpuName;
      String gpuName = _cachedGpuName ?? _currentStats.gpuName;

      if (Platform.isLinux) {
        cpuTemp = await _readLinuxAverageCpuTemp();
        ramUsage = await _readLinuxRamUsage();
        cpuUsage = await _readLinuxCpuUsage();
        cpuClock = await _readLinuxCpuClock();

        final gpuMetrics = await _readNvidiaGpuMetrics();
        if (gpuMetrics != null) {
          gpuTemp = gpuMetrics['temp']!;
          gpuUsage = gpuMetrics['usage']!;
          gpuClock = gpuMetrics['clock']!;
          if (gpuMetrics.containsKey('nameString')) {
            gpuName = gpuMetrics['nameString'] as String? ?? gpuName;
          }
        }
      } else if (Platform.isWindows) {
        final winStats = await _readWindowsMetrics();
        if (winStats != null) {
          cpuUsage = winStats['cpuUsage'] ?? cpuUsage;
          ramUsage = winStats['ramUsage'] ?? ramUsage;
          cpuClock = winStats['cpuClock'] ?? cpuClock;
          cpuTemp = winStats['cpuTemp'] ?? cpuTemp;
        }

        final gpuMetrics = await _readNvidiaGpuMetrics();
        if (gpuMetrics != null) {
          gpuTemp = gpuMetrics['temp']!;
          gpuUsage = gpuMetrics['usage']!;
          gpuClock = gpuMetrics['clock']!;
          if (gpuMetrics.containsKey('nameString')) {
            gpuName = gpuMetrics['nameString'] as String? ?? gpuName;
          }
        }
      }

      int currentPwm = _currentStats.pwmPercent;
      int expectedRpm = ((currentPwm / 100.0) * 2800).toInt();

      _currentStats = _currentStats.copyWith(
        cpuName: cpuName,
        gpuName: gpuName,
        cpuTemp: double.parse(cpuTemp.toStringAsFixed(1)),
        gpuTemp: double.parse(gpuTemp.toStringAsFixed(1)),
        cpuUsage: double.parse(cpuUsage.toStringAsFixed(1)),
        gpuUsage: double.parse(gpuUsage.toStringAsFixed(1)),
        ramUsage: double.parse(ramUsage.toStringAsFixed(1)),
        cpuClock: double.parse(cpuClock.toStringAsFixed(2)),
        gpuClock: double.parse(gpuClock.toStringAsFixed(0)),
        fanRpm: expectedRpm,
      );

      _controller.add(_currentStats);
    } catch (_) {}
  }

  /// Read EXACT CPU Model Name on Linux
  Future<String?> _readLinuxCpuName() async {
    try {
      final file = File('/proc/cpuinfo');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (var line in lines) {
          if (line.contains('model name')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              return parts[1].trim();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Read EXACT GPU Model Name on Linux
  Future<String?> _readLinuxGpuName() async {
    try {
      final res = await Process.run('nvidia-smi', ['--query-gpu=name', '--format=csv,noheader']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }

      final lspciRes = await Process.run('sh', ['-c', "lspci | grep -i 'vga\\|3d\\|display'"]);
      if (lspciRes.exitCode == 0 && lspciRes.stdout.toString().trim().isNotEmpty) {
        final line = lspciRes.stdout.toString().trim().split('\n').first;
        final parts = line.split(':');
        if (parts.length >= 3) {
          return parts[2].trim();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Read AVERAGE CPU Temperature from coretemp / k10temp / zenpower on Linux
  Future<double> _readLinuxAverageCpuTemp() async {
    try {
      final hwmonDir = Directory('/sys/class/hwmon');
      if (await hwmonDir.exists()) {
        final entities = await hwmonDir.list().toList();

        for (var entity in entities) {
          if (entity is Directory) {
            final nameFile = File('${entity.path}/name');
            if (await nameFile.exists()) {
              final name = (await nameFile.readAsString()).trim().toLowerCase();
              if (name.contains('coretemp') ||
                  name.contains('k10temp') ||
                  name.contains('zenpower') ||
                  name.contains('cpu_thermal') ||
                  name.contains('cpu')) {
                final List<double> cpuTemps = [];
                final tempFiles = entity
                    .listSync()
                    .whereType<File>()
                    .where((f) => f.path.contains('temp') && f.path.endsWith('_input'));

                for (var tempFile in tempFiles) {
                  final raw = await tempFile.readAsString();
                  final val = int.tryParse(raw.trim());
                  if (val != null && val > 0) {
                    double temp = val / 1000.0;
                    if (temp >= 25.0 && temp <= 115.0) {
                      cpuTemps.add(temp);
                    }
                  }
                }

                if (cpuTemps.isNotEmpty) {
                  double sum = cpuTemps.reduce((a, b) => a + b);
                  return sum / cpuTemps.length;
                }
              }
            }
          }
        }
      }

      final thermalDir = Directory('/sys/class/thermal');
      if (await thermalDir.exists()) {
        final List<double> thermalTemps = [];
        final entities = await thermalDir.list().toList();
        for (var entity in entities) {
          if (entity.path.contains('thermal_zone')) {
            final tempFile = File('${entity.path}/temp');
            if (await tempFile.exists()) {
              final raw = await tempFile.readAsString();
              final val = int.tryParse(raw.trim());
              if (val != null && val > 0) {
                double temp = val / 1000.0;
                if (temp >= 35.0 && temp <= 115.0) {
                  thermalTemps.add(temp);
                }
              }
            }
          }
        }

        if (thermalTemps.isNotEmpty) {
          double sum = thermalTemps.reduce((a, b) => a + b);
          return sum / thermalTemps.length;
        }
      }
    } catch (_) {}

    return _currentStats.cpuTemp;
  }

  /// Read RAM Usage on Linux (/proc/meminfo)
  Future<double> _readLinuxRamUsage() async {
    try {
      final file = File('/proc/meminfo');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        int total = 0;
        int available = 0;

        for (var line in lines) {
          if (line.startsWith('MemTotal:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) total = int.tryParse(parts[1]) ?? 0;
          } else if (line.startsWith('MemAvailable:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) available = int.tryParse(parts[1]) ?? 0;
          }
        }

        if (total > 0 && available > 0) {
          int used = total - available;
          return (used / total) * 100.0;
        }
      }
    } catch (_) {}
    return _currentStats.ramUsage;
  }

  /// Read CPU Usage on Linux (/proc/stat Ticks)
  Future<double> _readLinuxCpuUsage() async {
    try {
      final file = File('/proc/stat');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        if (lines.isNotEmpty && lines.first.startsWith('cpu ')) {
          final parts = lines.first.trim().split(RegExp(r'\s+'));
          if (parts.length >= 8) {
            int user = int.parse(parts[1]);
            int nice = int.parse(parts[2]);
            int system = int.parse(parts[3]);
            int idle = int.parse(parts[4]);
            int iowait = int.parse(parts[5]);
            int irq = int.parse(parts[6]);
            int softirq = int.parse(parts[7]);
            int steal = parts.length > 8 ? int.parse(parts[8]) : 0;

            int total = user + nice + system + idle + iowait + irq + softirq + steal;
            int idleTime = idle + iowait;

            if (_prevTotalTime != 0) {
              int totalDelta = total - _prevTotalTime;
              int idleDelta = idleTime - _prevIdleTime;

              _prevTotalTime = total;
              _prevIdleTime = idleTime;

              if (totalDelta > 0) {
                double usage = (1.0 - (idleDelta / totalDelta)) * 100.0;
                return usage.clamp(0.0, 100.0);
              }
            } else {
              _prevTotalTime = total;
              _prevIdleTime = idleTime;
            }
          }
        }
      }
    } catch (_) {}
    return _currentStats.cpuUsage;
  }

  /// Read CPU Clock Speed on Linux
  Future<double> _readLinuxCpuClock() async {
    try {
      final freqFile = File('/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq');
      if (await freqFile.exists()) {
        final raw = await freqFile.readAsString();
        final khz = int.tryParse(raw.trim());
        if (khz != null) {
          return khz / 1000000.0;
        }
      }
    } catch (_) {}
    return _currentStats.cpuClock;
  }

  /// Read NVIDIA GPU Metrics & Name (nvidia-smi on Linux & Windows)
  Future<Map<String, dynamic>?> _readNvidiaGpuMetrics() async {
    try {
      final result = await Process.run(
        'nvidia-smi',
        ['--query-gpu=name,temperature.gpu,utilization.gpu,clocks.current.graphics', '--format=csv,noheader,nounits'],
      );

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final lines = result.stdout.toString().trim().split('\n');
        final List<double> temps = [];
        final List<double> usages = [];
        final List<double> clocks = [];
        String? gpuNameStr;

        for (var line in lines) {
          final parts = line.split(',');
          if (parts.length >= 4) {
            gpuNameStr = parts[0].trim();
            double? t = double.tryParse(parts[1].trim());
            double? u = double.tryParse(parts[2].trim());
            double? c = double.tryParse(parts[3].trim());
            if (t != null) temps.add(t);
            if (u != null) usages.add(u);
            if (c != null) clocks.add(c);
          }
        }

        if (temps.isNotEmpty) {
          double avgTemp = temps.reduce((a, b) => a + b) / temps.length;
          double avgUsage = usages.reduce((a, b) => a + b) / usages.length;
          double avgClock = clocks.reduce((a, b) => a + b) / clocks.length;

          return {
            'temp': avgTemp,
            'usage': avgUsage,
            'clock': avgClock,
            'nameString': gpuNameStr,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Read Windows Hardware Name (CPU) via WMI
  Future<String?> _readWindowsCpuName() async {
    try {
      final res = await Process.run('powershell', ['-NoProfile', '-Command', '(Get-CimInstance Win32_Processor).Name']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  /// Read Windows Hardware Name (GPU) via WMI
  Future<String?> _readWindowsGpuName() async {
    try {
      final res = await Process.run('powershell', ['-NoProfile', '-Command', '(Get-CimInstance Win32_VideoController).Name']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        final lines = res.stdout.toString().trim().split('\n');
        return lines.first.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Read Full Hardware Telemetry on Windows via PowerShell / WMI & MSAcpi_ThermalZoneTemperature
  Future<Map<String, double>?> _readWindowsMetrics() async {
    try {
      final psScript = '''
        \$mem = Get-CimInstance Win32_OperatingSystem;
        \$ram = [math]::Round(((\$mem.TotalVisibleMemorySize - \$mem.FreePhysicalMemory) / \$mem.TotalVisibleMemorySize) * 100, 1);
        \$cpu = Get-CimInstance Win32_Processor;
        \$cpuUsage = \$cpu.LoadPercentage;
        \$cpuClock = [math]::Round(\$cpu.CurrentClockSpeed / 1000, 2);

        \$cpuTemp = 0;
        try {
          \$thermal = Get-CimInstance -Namespace root/WMI -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue;
          if (\$thermal) {
            \$temps = \$thermal | ForEach-Object { [math]::Round((\$_.CurrentTemperature - 2732) / 10, 1) } | Where-Object { \$_ -gt 20 -and \$_ -lt 115 };
            if (\$temps) { \$cpuTemp = (\$temps | Measure-Object -Average).Average; }
          }
        } catch {}

        if (\$cpuTemp -eq 0) {
          try {
            \$ohm = Get-CimInstance -Namespace root/OpenHardwareMonitor -ClassName Sensor -ErrorAction SilentlyContinue | Where-Object { \$_.SensorType -eq 'Temperature' -and \$_.Name -like '*CPU*' };
            if (\$ohm) { \$cpuTemp = (\$ohm | Measure-Object -Property Value -Average).Average; }
          } catch {}
        }

        Write-Output "\$ram,\$cpuUsage,\$cpuClock,\$cpuTemp"
      ''';

      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', psScript],
      );

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final parts = result.stdout.toString().trim().split(',');
        if (parts.length >= 4) {
          double? ram = double.tryParse(parts[0].trim());
          double? cpuUse = double.tryParse(parts[1].trim());
          double? cpuClk = double.tryParse(parts[2].trim());
          double? temp = double.tryParse(parts[3].trim());

          return {
            'ramUsage': ram ?? _currentStats.ramUsage,
            'cpuUsage': cpuUse ?? _currentStats.cpuUsage,
            'cpuClock': cpuClk ?? _currentStats.cpuClock,
            'cpuTemp': (temp != null && temp > 20) ? temp : _currentStats.cpuTemp,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
