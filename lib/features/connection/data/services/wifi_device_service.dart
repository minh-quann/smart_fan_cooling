import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:smart_fan_cooling/features/connection/data/services/device_service.dart';

class WifiDeviceService implements DeviceService {
  final String _wsUrl;
  WebSocketChannel? _channel;
  final _statusController = StreamController<DeviceStatus>.broadcast();
  final _rawJsonController = StreamController<Map<String, dynamic>>.broadcast();
  DeviceStatus _currentStatus = const DeviceStatus();
  
  StreamSubscription<dynamic>? _wsSub;
  Completer<WifiConfigResult>? _wifiConfigCompleter;

  WifiDeviceService(this._wsUrl);

  @override
  Stream<DeviceStatus> get statusStream => _statusController.stream;

  @override
  Stream<Map<String, dynamic>> get rawJsonStream => _rawJsonController.stream;

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
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      await _channel!.ready;
      _updateStatus(connected: true);
      
      _wsSub = _channel!.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> data = jsonDecode(message as String) as Map<String, dynamic>;
            final String? cmd = data['cmd'] as String?;
            
            // Handle wifi_config response
            if (cmd == 'wifi_config' && _wifiConfigCompleter != null && !_wifiConfigCompleter!.isCompleted) {
              final bool ok = data['status'] == 'ok';
              _wifiConfigCompleter!.complete(WifiConfigResult(
                success: ok,
                ip: ok ? data['ip'] as String? : null,
              ));
              return;
            }
            
            // Handle pin_test response
            if (cmd == 'pin_test') {
              if (!_rawJsonController.isClosed) {
                _rawJsonController.add(data);
              }
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
          } catch (e) {
            // Ignore parse errors
          }
        },
        onDone: () => _updateStatus(connected: false),
        onError: (_) => _updateStatus(connected: false),
      );
    } catch (e) {
      _updateStatus(connected: false);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _updateStatus(connected: false);
  }
  
  void _sendJson(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
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
    
    // Wait for ESP32 response with 15s timeout (ESP32 tries connecting for ~10s)
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
  Future<void> sendCommand(String cmd, dynamic value) async {
    _sendJson({"cmd": cmd, "value": value});
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _channel?.sink.close();
    _statusController.close();
    _rawJsonController.close();
  }
}
