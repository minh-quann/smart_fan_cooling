abstract class DeviceService {
  Stream<DeviceStatus> get statusStream;
  
  Future<void> connect();
  Future<void> disconnect();
  Future<void> setFanSpeed(int percent);
  Future<void> setFanState(bool on);
  Future<void> setLedMode(int mode);
  Future<void> setLedColor(int r, int g, int b);
  Future<void> setLedBrightness(int brightness);
  Future<void> sendTemperature(double cpu, double gpu);
  Future<WifiConfigResult> sendWifiConfig(String ssid, String password);
  void dispose();
}

/// Result of WiFi provisioning attempt
class WifiConfigResult {
  final bool success;
  final String? ip;
  
  const WifiConfigResult({required this.success, this.ip});
}

class DeviceStatus {
  final bool connected;
  final int rpm;
  final int fanPercent;
  final bool fanOn;
  final int ledMode;
  final bool ledOn;

  const DeviceStatus({
    this.connected = false,
    this.rpm = 0,
    this.fanPercent = 0,
    this.fanOn = false,
    this.ledMode = 0,
    this.ledOn = false,
  });

  DeviceStatus copyWith({
    bool? connected,
    int? rpm,
    int? fanPercent,
    bool? fanOn,
    int? ledMode,
    bool? ledOn,
  }) {
    return DeviceStatus(
      connected: connected ?? this.connected,
      rpm: rpm ?? this.rpm,
      fanPercent: fanPercent ?? this.fanPercent,
      fanOn: fanOn ?? this.fanOn,
      ledMode: ledMode ?? this.ledMode,
      ledOn: ledOn ?? this.ledOn,
    );
  }
}
