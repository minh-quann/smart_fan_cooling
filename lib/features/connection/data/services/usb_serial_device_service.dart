import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:smart_fan_cooling/features/connection/data/services/device_service.dart';

/// USB Serial device service for ESP32-S3 USB CDC connection.
/// Uses newline-delimited JSON protocol over serial port.
/// This is the fastest and most reliable connection method.
class UsbSerialDeviceService implements DeviceService {
  final String _portName;
  SerialPort? _port;
  SerialPortReader? _reader;
  final _statusController = StreamController<DeviceStatus>.broadcast();
  DeviceStatus _currentStatus = const DeviceStatus();

  Timer? _pingTimer;
  Completer<WifiConfigResult>? _wifiConfigCompleter;
  String _rxBuffer = '';

  UsbSerialDeviceService(this._portName);

  @override
  Stream<DeviceStatus> get statusStream => _statusController.stream;

  void _updateStatus({
    bool? connected,
    int? rpm,
    int? fanPercent,
    bool? fanOn,
    int? ledMode,
    bool? ledOn,
  }) {
    _currentStatus = _currentStatus.copyWith(
      connected: connected,
      rpm: rpm,
      fanPercent: fanPercent,
      fanOn: fanOn,
      ledMode: ledMode,
      ledOn: ledOn,
    );
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
  }

  @override
  Future<void> connect() async {
    try {
      _port = SerialPort(_portName);

      // Open port with read/write
      if (!_port!.openReadWrite()) {
        throw Exception('Cannot open port $_portName');
      }

      // Configure port: 115200 baud, 8N1
      final config = SerialPortConfig()
        ..baudRate = 115200
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1
        ..setFlowControl(SerialPortFlowControl.none);
      _port!.config = config;
      config.dispose();

      // Start reading
      _reader = SerialPortReader(_port!, timeout: 100);
      _reader!.stream.listen(
        (data) {
          _processIncomingData(data);
        },
        onError: (_) {
          _updateStatus(connected: false);
        },
        onDone: () {
          _updateStatus(connected: false);
        },
      );

      // Start heartbeat ping every 2 seconds
      _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _sendJson({"cmd": "ping"});
      });

      // Send initial ping to establish connection
      _sendJson({"cmd": "ping"});

      // Wait a bit for pong response
      await Future.delayed(const Duration(milliseconds: 500));
      _updateStatus(connected: true);
    } catch (e) {
      _updateStatus(connected: false);
      rethrow;
    }
  }

  void _processIncomingData(Uint8List data) {
    _rxBuffer += utf8.decode(data, allowMalformed: true);

    // Process complete lines
    while (_rxBuffer.contains('\n')) {
      final newlineIndex = _rxBuffer.indexOf('\n');
      final line = _rxBuffer.substring(0, newlineIndex).trim();
      _rxBuffer = _rxBuffer.substring(newlineIndex + 1);

      if (line.isEmpty || !line.startsWith('{')) continue;

      try {
        final Map<String, dynamic> jsonData =
            jsonDecode(line) as Map<String, dynamic>;
        _processJsonMessage(jsonData);
      } catch (_) {
        // Ignore non-JSON lines (debug prints from firmware)
      }
    }

    // Prevent buffer overflow
    if (_rxBuffer.length > 2048) {
      _rxBuffer = '';
    }
  }

  void _processJsonMessage(Map<String, dynamic> data) {
    final String? cmd = data['cmd'] as String?;

    // Handle pong response (connection confirmed)
    if (cmd == 'pong') {
      if (!_currentStatus.connected) {
        _updateStatus(connected: true);
      }
      return;
    }

    // Handle wifi_config response
    if (cmd == 'wifi_config' &&
        _wifiConfigCompleter != null &&
        !_wifiConfigCompleter!.isCompleted) {
      final bool ok = data['status'] == 'ok';
      _wifiConfigCompleter!.complete(WifiConfigResult(
        success: ok,
        ip: ok ? data['ip'] as String? : null,
      ));
      return;
    }

    // Handle normal status updates
    _updateStatus(
      fanPercent: data['fan_pct'] as int?,
      fanOn: data['fan_on'] as bool?,
      ledMode: data['led_mode'] as int?,
      ledOn: data['led_on'] as bool?,
      rpm: data['rpm'] as int?,
    );
  }

  @override
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reader?.close();
    _port?.close();
    _port = null;
    _reader = null;
    _updateStatus(connected: false);
  }

  void _sendJson(Map<String, dynamic> data) {
    if (_port == null || !_port!.isOpen) return;
    final jsonStr = '${jsonEncode(data)}\n';
    try {
      _port!.write(Uint8List.fromList(utf8.encode(jsonStr)));
    } catch (_) {
      // Port may have been disconnected
    }
  }

  @override
  Future<void> setFanSpeed(int percent) async {
    _sendJson({"cmd": "fan_speed", "value": percent});
  }

  @override
  Future<void> setFanState(bool on) async {
    _sendJson({"cmd": "fan_state", "value": on ? 1 : 0});
  }

  @override
  Future<void> setLedMode(int mode) async {
    _sendJson({"cmd": "led_mode", "value": mode});
  }

  @override
  Future<void> setLedColor(int r, int g, int b) async {
    _sendJson({"cmd": "led_color", "r": r, "g": g, "b": b});
  }

  @override
  Future<void> setLedBrightness(int brightness) async {
    _sendJson({"cmd": "led_brightness", "value": brightness});
  }

  @override
  Future<void> sendTemperature(double cpu, double gpu) async {
    _sendJson({"cmd": "temp", "cpu": cpu, "gpu": gpu});
  }

  @override
  Future<WifiConfigResult> sendWifiConfig(String ssid, String password) async {
    _wifiConfigCompleter = Completer<WifiConfigResult>();
    _sendJson({"cmd": "wifi_config", "ssid": ssid, "pass": password});

    try {
      return await _wifiConfigCompleter!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => const WifiConfigResult(success: false),
      );
    } catch (_) {
      return const WifiConfigResult(success: false);
    }
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _reader?.close();
    _port?.close();
    _statusController.close();
  }

  /// Espressif USB VID for ESP32-S3 native USB
  static const int espressifVid = 0x303A;

  /// WCH CH340/CH343 USB-UART bridge VID (used on YD-ESP32-S3 boards)
  static const int wchVid = 0x1A86;

  /// Known VIDs for USB-UART bridges commonly used on ESP32 boards
  static const List<int> knownVids = [
    espressifVid, // 0x303A — ESP32-S3 native USB
    wchVid,       // 0x1A86 — CH340/CH343 (YD-ESP32-S3, NodeMCU clones)
    0x10C4,       // Silicon Labs CP2102/CP2104
    0x0403,       // FTDI FT232
  ];

  /// Scan available serial ports and return those matching known ESP32 VIDs.
  /// Returns list of port names (e.g., 'COM3', '/dev/ttyACM0').
  static List<String> scanForEsp32Ports() {
    final List<String> espPorts = [];

    try {
      final availablePorts = SerialPort.availablePorts;
      for (final portName in availablePorts) {
        try {
          final port = SerialPort(portName);
          // Check against all known ESP32-related VIDs
          if (knownVids.contains(port.vendorId)) {
            espPorts.add(portName);
          }
          port.dispose();
        } catch (_) {
          // Some ports may not be accessible, skip them
        }
      }
    } catch (_) {
      // SerialPort not available on this platform
    }

    return espPorts;
  }

  /// Check if any ESP32-S3 USB device is available
  static bool isEsp32Available() {
    return scanForEsp32Ports().isNotEmpty;
  }
}
