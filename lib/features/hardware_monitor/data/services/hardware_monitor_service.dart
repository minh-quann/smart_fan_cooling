import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:smart_fan_cooling/features/hardware_monitor/domain/models/hardware_stats.dart';

/// Real Hardware Telemetry Service with Internal CPU/GPU Fan Speed & Power Wattage Reading.
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

  // EMA smoothing accumulators
  double _emaCpuTemp = 0.0;
  double _emaGpuTemp = 0.0;
  double _emaCpuUsage = 0.0;
  double _emaGpuUsage = 0.0;
  double _emaRamUsage = 0.0;
  double _emaCpuClock = 0.0;
  double _emaCpuPowerW = 0.0;
  double _emaGpuPowerW = 0.0;

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

  double _applyEma(double current, double target, double alpha) {
    if (current == 0.0) return target;
    return current + alpha * (target - current);
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
      double rawCpuTemp = _currentStats.cpuTemp;
      double rawGpuTemp = _currentStats.gpuTemp;
      double rawCpuUsage = _currentStats.cpuUsage;
      double rawGpuUsage = _currentStats.gpuUsage;
      double rawRamUsage = _currentStats.ramUsage;
      double rawCpuClock = _currentStats.cpuClock;
      double rawGpuClock = _currentStats.gpuClock;
      double rawCpuPowerW = _currentStats.cpuPowerW;
      double rawGpuPowerW = _currentStats.gpuPowerW;
      int internalCpuFanRpm = _currentStats.cpuFanRpm;
      int internalGpuFanRpm = _currentStats.gpuFanRpm;

      String cpuName = _cachedCpuName ?? _currentStats.cpuName;
      String gpuName = _cachedGpuName ?? _currentStats.gpuName;

      if (Platform.isLinux) {
        rawCpuTemp = await _readLinuxAverageCpuTemp();
        rawRamUsage = await _readLinuxRamUsage();
        rawCpuUsage = await _readLinuxCpuUsage();
        rawCpuClock = await _readLinuxCpuClock();

        final linuxFans = await _readLinuxInternalFans();
        if (linuxFans != null) {
          internalCpuFanRpm = linuxFans['cpuFan'] ?? internalCpuFanRpm;
          internalGpuFanRpm = linuxFans['gpuFan'] ?? internalGpuFanRpm;
        }

        final linuxCpuPower = await _readLinuxCpuPowerW();
        if (linuxCpuPower != null) {
          rawCpuPowerW = linuxCpuPower;
        } else {
          rawCpuPowerW = 12.0 + (rawCpuUsage / 100.0) * 45.0;
        }

        final gpuMetrics = await _readNvidiaGpuMetrics();
        if (gpuMetrics != null) {
          rawGpuTemp = gpuMetrics['temp']!;
          rawGpuUsage = gpuMetrics['usage']!;
          rawGpuClock = gpuMetrics['clock']!;
          if (gpuMetrics.containsKey('powerW')) {
            rawGpuPowerW = gpuMetrics['powerW']!;
          }
          if (gpuMetrics.containsKey('fanSpeedPct')) {
            double pct = gpuMetrics['fanSpeedPct']!;
            internalGpuFanRpm = ((pct / 100.0) * 3200).round();
          }
          if (gpuMetrics.containsKey('nameString')) {
            gpuName = gpuMetrics['nameString'] as String? ?? gpuName;
          }
        } else {
          rawGpuPowerW = 15.0 + (rawGpuUsage / 100.0) * 85.0;
        }
      } else if (Platform.isWindows) {
        final winStats = await _readWindowsMetrics();
        if (winStats != null) {
          rawCpuUsage = winStats['cpuUsage'] ?? rawCpuUsage;
          rawRamUsage = winStats['ramUsage'] ?? rawRamUsage;
          rawCpuClock = winStats['cpuClock'] ?? rawCpuClock;
          rawCpuTemp = winStats['cpuTemp'] ?? rawCpuTemp;
          rawCpuPowerW =
              winStats['cpuPowerW'] ?? (15.0 + (rawCpuUsage / 100.0) * 45.0);
          // Fan RPM from LHM/OHM WMI
          if (winStats.containsKey('cpuFanRpm') && winStats['cpuFanRpm']! > 0) {
            internalCpuFanRpm = winStats['cpuFanRpm']!.round();
          }
          if (winStats.containsKey('gpuFanRpm') && winStats['gpuFanRpm']! > 0) {
            internalGpuFanRpm = winStats['gpuFanRpm']!.round();
          }
        }

        final gpuMetrics = await _readNvidiaGpuMetrics();
        if (gpuMetrics != null) {
          rawGpuTemp = gpuMetrics['temp']!;
          rawGpuUsage = gpuMetrics['usage']!;
          rawGpuClock = gpuMetrics['clock']!;
          if (gpuMetrics.containsKey('powerW')) {
            rawGpuPowerW = gpuMetrics['powerW']!;
          }
          if (gpuMetrics.containsKey('fanSpeedPct')) {
            double pct = gpuMetrics['fanSpeedPct']!;
            internalGpuFanRpm = ((pct / 100.0) * 3200).round();
          }
          if (gpuMetrics.containsKey('nameString')) {
            gpuName = gpuMetrics['nameString'] as String? ?? gpuName;
          }
        } else {
          rawGpuPowerW = 15.0 + (rawGpuUsage / 100.0) * 85.0;
        }
      }

      // Fallback for internal fan speeds if hardware sensor is unreadable
      if (internalCpuFanRpm <= 0) {
        internalCpuFanRpm = (1500 + (rawCpuTemp / 100.0) * 2200).round();
      }
      if (internalGpuFanRpm <= 0) {
        internalGpuFanRpm = (1600 + (rawGpuTemp / 100.0) * 2400).round();
      }

      // Apply EMA smoothing
      _emaCpuTemp = _applyEma(_emaCpuTemp, rawCpuTemp, 0.35);
      _emaGpuTemp = _applyEma(_emaGpuTemp, rawGpuTemp, 0.35);
      _emaCpuUsage = _applyEma(_emaCpuUsage, rawCpuUsage, 0.35);
      _emaGpuUsage = _applyEma(_emaGpuUsage, rawGpuUsage, 0.35);
      _emaRamUsage = _applyEma(_emaRamUsage, rawRamUsage, 0.35);
      _emaCpuClock = _applyEma(_emaCpuClock, rawCpuClock, 0.35);
      _emaCpuPowerW = _applyEma(_emaCpuPowerW, rawCpuPowerW, 0.35);
      _emaGpuPowerW = _applyEma(_emaGpuPowerW, rawGpuPowerW, 0.35);

      int currentPwm = _currentStats.pwmPercent;
      int expectedRpm = ((currentPwm / 100.0) * 2800).toInt();

      _currentStats = _currentStats.copyWith(
        cpuName: cpuName,
        gpuName: gpuName,
        cpuTemp: double.parse(_emaCpuTemp.toStringAsFixed(1)),
        gpuTemp: double.parse(_emaGpuTemp.toStringAsFixed(1)),
        cpuUsage: double.parse(_emaCpuUsage.toStringAsFixed(1)),
        gpuUsage: double.parse(_emaGpuUsage.toStringAsFixed(1)),
        ramUsage: double.parse(_emaRamUsage.toStringAsFixed(1)),
        cpuClock: double.parse(_emaCpuClock.toStringAsFixed(2)),
        gpuClock: double.parse(rawGpuClock.toStringAsFixed(0)),
        cpuFanRpm: internalCpuFanRpm,
        gpuFanRpm: internalGpuFanRpm,
        cpuPowerW: double.parse(_emaCpuPowerW.toStringAsFixed(1)),
        gpuPowerW: double.parse(_emaGpuPowerW.toStringAsFixed(1)),
        fanRpm: expectedRpm,
      );

      _controller.add(_currentStats);
    } catch (_) {}
  }

  /// Read Internal Fan RPMs on Linux (/sys/class/hwmon/hwmon*/fan*_input)
  Future<Map<String, int>?> _readLinuxInternalFans() async {
    try {
      final hwmonDir = Directory('/sys/class/hwmon');
      if (await hwmonDir.exists()) {
        final List<int> fans = [];
        final entities = await hwmonDir.list().toList();

        for (var entity in entities) {
          if (entity is Directory) {
            final fanFiles = entity.listSync().whereType<File>().where(
              (f) => f.path.contains('fan') && f.path.endsWith('_input'),
            );

            for (var fanFile in fanFiles) {
              final raw = await fanFile.readAsString();
              final val = int.tryParse(raw.trim());
              if (val != null && val > 0) {
                fans.add(val);
              }
            }
          }
        }

        if (fans.isNotEmpty) {
          return {
            'cpuFan': fans[0],
            'gpuFan': fans.length > 1 ? fans[1] : fans[0],
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Read CPU Power Wattage (W) on Linux (/sys/class/powercap/intel-rapl/energy_uj or power1_input)
  Future<double?> _readLinuxCpuPowerW() async {
    try {
      final powerFile = File(
        '/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj',
      );
      if (await powerFile.exists()) {
        final raw1 = await powerFile.readAsString();
        final uj1 = int.tryParse(raw1.trim());
        await Future.delayed(const Duration(milliseconds: 200));
        final raw2 = await powerFile.readAsString();
        final uj2 = int.tryParse(raw2.trim());

        if (uj1 != null && uj2 != null && uj2 > uj1) {
          double deltaJoules = (uj2 - uj1) / 1000000.0;
          double watts = deltaJoules / 0.2; // 200ms sampling window
          if (watts >= 2.0 && watts <= 150.0) {
            return watts;
          }
        }
      }
    } catch (_) {}
    return null;
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
      final res = await Process.run('nvidia-smi', [
        '--query-gpu=name',
        '--format=csv,noheader',
      ]);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }

      final lspciRes = await Process.run('sh', [
        '-c',
        "lspci | grep -i 'vga\\|3d\\|display'",
      ]);
      if (lspciRes.exitCode == 0 &&
          lspciRes.stdout.toString().trim().isNotEmpty) {
        final line = lspciRes.stdout.toString().trim().split('\n').first;
        final parts = line.split(':');
        if (parts.length >= 3) {
          return parts[2].trim();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Read CPU Package Temperature (Package id 0) from coretemp / k10temp on Linux
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
                // Read Package id 0 (temp1_input) — the overall CPU package temp
                final packageFile = File('${entity.path}/temp1_input');
                if (await packageFile.exists()) {
                  final raw = await packageFile.readAsString();
                  final val = int.tryParse(raw.trim());
                  if (val != null && val > 0) {
                    double temp = val / 1000.0;
                    if (temp >= 25.0 && temp <= 115.0) {
                      return temp;
                    }
                  }
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

            int total =
                user + nice + system + idle + iowait + irq + softirq + steal;
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
      final freqFile = File(
        '/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq',
      );
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

  /// Read NVIDIA GPU Metrics (Temp, Usage, Clock, Fan %, Power W) via nvidia-smi
  Future<Map<String, dynamic>?> _readNvidiaGpuMetrics() async {
    try {
      final result = await Process.run('nvidia-smi', [
        '--query-gpu=name,temperature.gpu,utilization.gpu,clocks.current.graphics,fan.speed,power.draw',
        '--format=csv,noheader,nounits',
      ]);

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final lines = result.stdout.toString().trim().split('\n');
        final List<double> temps = [];
        final List<double> usages = [];
        final List<double> clocks = [];
        final List<double> fanPcts = [];
        final List<double> powers = [];
        String? gpuNameStr;

        for (var line in lines) {
          final parts = line.split(',');
          if (parts.length >= 6) {
            gpuNameStr = parts[0].trim();
            double? t = double.tryParse(parts[1].trim());
            double? u = double.tryParse(parts[2].trim());
            double? c = double.tryParse(parts[3].trim());
            double? f = double.tryParse(parts[4].trim());
            double? p = double.tryParse(parts[5].trim());

            if (t != null) temps.add(t);
            if (u != null) usages.add(u);
            if (c != null) clocks.add(c);
            if (f != null) fanPcts.add(f);
            if (p != null) powers.add(p);
          }
        }

        if (temps.isNotEmpty) {
          double avgTemp = temps.reduce((a, b) => a + b) / temps.length;
          double avgUsage = usages.reduce((a, b) => a + b) / usages.length;
          double avgClock = clocks.reduce((a, b) => a + b) / clocks.length;

          final Map<String, dynamic> metrics = {
            'temp': avgTemp,
            'usage': avgUsage,
            'clock': avgClock,
            'nameString': gpuNameStr,
          };

          if (fanPcts.isNotEmpty) {
            metrics['fanSpeedPct'] =
                fanPcts.reduce((a, b) => a + b) / fanPcts.length;
          }

          if (powers.isNotEmpty) {
            metrics['powerW'] = powers.reduce((a, b) => a + b) / powers.length;
          }

          return metrics;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Read Windows Hardware Name (CPU) via WMI
  Future<String?> _readWindowsCpuName() async {
    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '(Get-CimInstance Win32_Processor).Name',
      ]);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  /// Read Windows Hardware Name (GPU) via WMI
  Future<String?> _readWindowsGpuName() async {
    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '(Get-CimInstance Win32_VideoController).Name',
      ]);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        final lines = res.stdout.toString().trim().split('\n');
        return lines.first.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Read CPU Package Temperature from LibreHardwareMonitor Web Server (http://localhost:8085/data.json)
  /// This reads the ACTUAL CPU die/package temperature via LHM's kernel driver.
  /// Returns null if LHM is not running.
  Future<double?> _readLhmCpuTemp() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 800);
      final request = await client.getUrl(
        Uri.parse('http://localhost:8085/data.json'),
      );
      final response = await request.close().timeout(
        const Duration(milliseconds: 1500),
      );

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);

        // Recursively search for CPU Package temperature in LHM JSON tree
        double? cpuPackageTemp;
        double? cpuCoreAvgTemp;
        List<double> cpuCoreTemps = [];

        void searchNode(dynamic node, bool isInsideCpu) {
          if (node is Map<String, dynamic>) {
            final text = (node['Text'] ?? '').toString();
            final value = (node['Value'] ?? '').toString();
            final children = node['Children'];

            // Detect if we're inside a CPU hardware node
            bool isCpuNode = isInsideCpu ||
                text.toLowerCase().contains('cpu') &&
                    !text.toLowerCase().contains('gpu');

            if (isCpuNode && value.contains('°C')) {
              // Extract numeric temperature value
              final match = RegExp(r'([\d.]+)').firstMatch(value);
              if (match != null) {
                double temp = double.tryParse(match.group(1)!) ?? 0;
                if (temp > 20 && temp < 115) {
                  if (text.contains('Package') || text.contains('Tctl') || text.contains('Tdie')) {
                    cpuPackageTemp = temp;
                  } else if (text.contains('Average') || text.contains('CCD')) {
                    cpuCoreAvgTemp = temp;
                  } else if (text.contains('Core')) {
                    cpuCoreTemps.add(temp);
                  }
                }
              }
            }

            if (children is List) {
              for (var child in children) {
                searchNode(child, isCpuNode);
              }
            }
          }
        }

        searchNode(json, false);

        // Priority: Package > Average > Core Average
        if (cpuPackageTemp != null) return cpuPackageTemp;
        if (cpuCoreAvgTemp != null) return cpuCoreAvgTemp;
        if (cpuCoreTemps.isNotEmpty) {
          return cpuCoreTemps.reduce((a, b) => a + b) / cpuCoreTemps.length;
        }
      }
      client.close(force: true);
    } catch (_) {}
    return null;
  }

  /// Read Full Hardware Telemetry on Windows (App runs as Administrator)
  /// Reads: CPU temp, CPU usage, RAM, Clock, Fan RPM, Power via native C# helper
  Future<Map<String, double>?> _readWindowsMetrics() async {
    try {
      // --- Step 1: Try compiled native C# hardware_helper.exe binary ---
      double? scriptCpuTemp;
      double? scriptCpuPowerW;
      double? scriptCpuClock;
      double? scriptCpuFan;
      double? scriptGpuFan;

      try {
        final exeParent = File(Platform.resolvedExecutable).parent.path;
        String helperPath = '$exeParent\\lhm\\hardware_helper.exe';
        if (!await File(helperPath).exists()) {
          helperPath = 'lhm\\hardware_helper.exe';
        }

        final scriptResult = await Process.run(helperPath, []);

        if (scriptResult.exitCode == 0 &&
            scriptResult.stdout.toString().trim().isNotEmpty) {
          final jsonStr = scriptResult.stdout.toString().trim();
          final data = jsonDecode(jsonStr);
          if (data is Map<String, dynamic>) {
            if (data.containsKey('cpuTemp') && (data['cpuTemp'] as num) > 0) {
              scriptCpuTemp = (data['cpuTemp'] as num).toDouble();
            }
            if (data.containsKey('cpuPowerW') && (data['cpuPowerW'] as num) > 0) {
              scriptCpuPowerW = (data['cpuPowerW'] as num).toDouble();
            }
            if (data.containsKey('cpuMaxClockGHz') && (data['cpuMaxClockGHz'] as num) > 0) {
              scriptCpuClock = (data['cpuMaxClockGHz'] as num).toDouble();
            }
            if (data.containsKey('cpuFanRpm') && (data['cpuFanRpm'] as num) > 0) {
              scriptCpuFan = (data['cpuFanRpm'] as num).toDouble();
            }
            if (data.containsKey('gpuFanRpm') && (data['gpuFanRpm'] as num) > 0) {
              scriptGpuFan = (data['gpuFanRpm'] as num).toDouble();
            }
          }
        }
      } catch (_) {}

      // --- Step 2: Try LibreHardwareMonitor Web Server as secondary ---
      double? lhmTemp = scriptCpuTemp ?? await _readLhmCpuTemp();

      // --- Step 3: PowerShell script for system WMI metrics (RAM, CPU Load, Clock) ---
      final psScript = '''
        \$mem = Get-CimInstance Win32_OperatingSystem;
        \$ram = [math]::Round(((\$mem.TotalVisibleMemorySize - \$mem.FreePhysicalMemory) / \$mem.TotalVisibleMemorySize) * 100, 1);
        \$cpu = Get-CimInstance Win32_Processor;
        \$cpuUsage = \$cpu.LoadPercentage;
        \$cpuClock = [math]::Round(\$cpu.CurrentClockSpeed / 1000, 2);

        \$cpuTemp = 0;
        \$cpuFanRpm = 0;
        \$gpuFanRpm = 0;
        \$cpuPowerW = 0;

        # 1. Try LibreHardwareMonitor WMI
        try {
          \$lhmSensors = Get-CimInstance -Namespace root/LibreHardwareMonitor -ClassName Sensor -ErrorAction SilentlyContinue;
          if (\$lhmSensors) {
            \$tempSensors = \$lhmSensors | Where-Object { \$_.SensorType -eq 'Temperature' -and (\$_.Name -like '*CPU Package*' -or \$_.Name -like '*Core (Tctl/Tdie)*' -or \$_.Name -like '*Core Average*') };
            if (\$tempSensors) {
              \$pkg = \$tempSensors | Where-Object { \$_.Name -like '*Package*' -or \$_.Name -like '*Tctl*' -or \$_.Name -like '*Tdie*' } | Select-Object -First 1;
              if (\$pkg) { \$cpuTemp = \$pkg.Value; }
              else { \$cpuTemp = (\$tempSensors | Measure-Object -Property Value -Average).Average; }
            }

            \$fanSensors = \$lhmSensors | Where-Object { \$_.SensorType -eq 'Fan' };
            if (\$fanSensors) {
              \$cf = \$fanSensors | Where-Object { \$_.Name -like '*CPU*' -or \$_.Name -like '*Fan #1*' -or \$_.Name -like '*Fan 1*' } | Select-Object -First 1;
              if (\$cf) { \$cpuFanRpm = [math]::Round(\$cf.Value); }
              \$gf = \$fanSensors | Where-Object { \$_.Name -like '*GPU*' -or \$_.Name -like '*Fan #2*' -or \$_.Name -like '*Fan 2*' } | Select-Object -First 1;
              if (\$gf) { \$gpuFanRpm = [math]::Round(\$gf.Value); }
            }

            \$pwrSensors = \$lhmSensors | Where-Object { \$_.SensorType -eq 'Power' -and (\$_.Name -like '*CPU Package*' -or \$_.Name -like '*CPU*') } | Select-Object -First 1;
            if (\$pwrSensors) { \$cpuPowerW = [math]::Round(\$pwrSensors.Value, 1); }
          }
        } catch {}

        Write-Output "\$ram,\$cpuUsage,\$cpuClock,\$cpuTemp,\$cpuFanRpm,\$gpuFanRpm,\$cpuPowerW"
      ''';

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        psScript,
      ]);

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final output = result.stdout.toString().trim();
        final lines = output.split('\n');
        final lastLine = lines.last.trim();
        final parts = lastLine.split(',');
        if (parts.length >= 7) {
          double? ram = double.tryParse(parts[0].trim());
          double? cpuUse = double.tryParse(parts[1].trim());
          double? cpuClk = double.tryParse(parts[2].trim());
          double? wmiTemp = double.tryParse(parts[3].trim());
          double? cpuFan = double.tryParse(parts[4].trim());
          double? gpuFan = double.tryParse(parts[5].trim());
          double? cpuPwr = double.tryParse(parts[6].trim());

          double finalTemp;
          if (lhmTemp != null && lhmTemp > 25) {
            finalTemp = lhmTemp;
          } else if (wmiTemp != null && wmiTemp > 25) {
            finalTemp = wmiTemp;
          } else {
            finalTemp = _currentStats.cpuTemp;
          }

          return {
            'ramUsage': ram ?? _currentStats.ramUsage,
            'cpuUsage': cpuUse ?? _currentStats.cpuUsage,
            'cpuClock': scriptCpuClock ?? (cpuClk ?? _currentStats.cpuClock),
            'cpuTemp': finalTemp,
            'cpuPowerW': scriptCpuPowerW ?? ((cpuPwr != null && cpuPwr > 0) ? cpuPwr : 15.0 + ((cpuUse ?? 10.0) / 100.0) * 45.0),
            'cpuFanRpm': scriptCpuFan ?? (cpuFan ?? 0),
            'gpuFanRpm': scriptGpuFan ?? (gpuFan ?? 0),
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
