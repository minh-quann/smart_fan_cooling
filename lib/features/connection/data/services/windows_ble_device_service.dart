import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_ble/universal_ble.dart';
import 'package:smart_fan_cooling/features/connection/data/services/device_service.dart';

/// Dedicated Windows BLE Service implementation using UniversalBle (Windows WinRT API).
class WindowsBleDeviceService implements DeviceService {
  final String _deviceId;
  final _statusController = StreamController<DeviceStatus>.broadcast();
  DeviceStatus _currentStatus = const DeviceStatus();

  static const String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  WindowsBleDeviceService(this._deviceId);

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
    UniversalBle.onConnectionChange = (String deviceId, bool isConnected, String? error) {
      if (deviceId == _deviceId && !isConnected) {
        _updateStatus(connected: false);
      }
    };

    UniversalBle.onValueChange = (String deviceId, String characteristicId, Uint8List value, int? timestamp) {
      if (deviceId == _deviceId) {
        final charUuid = characteristicId.toLowerCase();
        if (charUuid.contains("beb5483e-36e1-4688-b7f5-ea07361b26ad")) {
          // RPM Notify
          if (value.length >= 2) {
            final int rpm = value[0] | (value[1] << 8);
            _updateStatus(rpm: rpm);
          }
        } else if (charUuid.contains("beb5483e-36e1-4688-b7f5-ea07361b26ae")) {
          // Status Notify
          if (value.length >= 4) {
            _updateStatus(
              fanPercent: value[0],
              fanOn: value[1] == 1,
              ledMode: value[2],
              ledOn: value[3] == 1,
            );
          }
        }
      }
    };

    await UniversalBle.connect(_deviceId);
    _updateStatus(connected: true);

    try {
      final services = await UniversalBle.discoverServices(_deviceId);
      for (final service in services) {
        final sUuid = service.uuid.toLowerCase();
        if (sUuid.contains("4fafc201")) {
          for (final char in service.characteristics) {
            final cUuid = char.uuid.toLowerCase();
            if (cUuid.contains("beb5483e-36e1-4688-b7f5-ea07361b26ad") ||
                cUuid.contains("beb5483e-36e1-4688-b7f5-ea07361b26ae")) {
              await UniversalBle.subscribeNotifications(_deviceId, service.uuid, char.uuid);
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> disconnect() async {
    await UniversalBle.disconnect(_deviceId);
  }

  Future<void> _writeChar(String charUuidSuffix, List<int> value) async {
    try {
      await UniversalBle.write(
        _deviceId,
        _serviceUuid,
        "beb5483e-36e1-4688-b7f5-$charUuidSuffix",
        Uint8List.fromList(value),
        withoutResponse: false,
      );
    } catch (e) {
      // ignore: avoid_print
      print("Windows BLE write error ($charUuidSuffix): $e");
    }
  }

  @override
  Future<void> setFanSpeed(int percent) async {
    await _writeChar("ea07361b26a8", [percent]);
  }

  @override
  Future<void> setFanState(bool on) async {
    await _writeChar("ea07361b26a9", [on ? 1 : 0]);
  }

  @override
  Future<void> setLedMode(int mode) async {
    await _writeChar("ea07361b26aa", [mode]);
  }

  @override
  Future<void> setLedColor(int r, int g, int b) async {
    await _writeChar("ea07361b26ab", [r, g, b]);
  }

  @override
  Future<void> setLedBrightness(int brightness) async {
    await _writeChar("ea07361b26ac", [brightness]);
  }

  @override
  Future<void> sendTemperature(double cpu, double gpu) async {
    final ByteData byteData = ByteData(8);
    byteData.setFloat32(0, cpu, Endian.little);
    byteData.setFloat32(4, gpu, Endian.little);
    await _writeChar("ea07361b26af", byteData.buffer.asUint8List());
  }

  @override
  Future<WifiConfigResult> sendWifiConfig(String ssid, String password) async {
    final jsonStr = '{"ssid":"$ssid","pass":"$password"}';
    await _writeChar("ea07361b26b0", utf8.encode(jsonStr));
    await Future<void>.delayed(const Duration(seconds: 12));
    return const WifiConfigResult(success: true, ip: null);
  }

  @override
  void dispose() {
    _statusController.close();
  }
}
