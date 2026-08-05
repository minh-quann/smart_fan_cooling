import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_fan_cooling/features/connection/data/services/device_service.dart';

class BleDeviceService implements DeviceService {
  final BluetoothDevice _device;
  final _statusController = StreamController<DeviceStatus>.broadcast();
  DeviceStatus _currentStatus = const DeviceStatus();
  
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _rpmSub;
  StreamSubscription<List<int>>? _statusCharSub;

  BluetoothCharacteristic? _charFanSpeed;
  BluetoothCharacteristic? _charFanState;
  BluetoothCharacteristic? _charLedMode;
  BluetoothCharacteristic? _charLedColor;
  BluetoothCharacteristic? _charLedBrightness;
  BluetoothCharacteristic? _charTemp;
  BluetoothCharacteristic? _charWifiConfig;

  static const String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  
  BleDeviceService(this._device);

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
    // Listen for connection state changes
    _connectionSub = _device.connectionState.listen((BluetoothConnectionState state) {
      if (state == BluetoothConnectionState.disconnected) {
        _updateStatus(connected: false);
      }
    });

    // Connect with explicit settings for Linux compatibility
    await _device.connect(
      autoConnect: false,
      timeout: const Duration(seconds: 15),
    );
    
    // Linux BlueZ needs time to stabilize after connect
    await Future<void>.delayed(const Duration(seconds: 1));

    // Request reasonable MTU
    try {
      await _device.requestMtu(256);
    } catch (_) {}

    _updateStatus(connected: true);

    // Discover services
    final List<BluetoothService> services = await _device.discoverServices();
    
    for (final BluetoothService service in services) {
      if (service.uuid.toString() == _serviceUuid) {
        for (final BluetoothCharacteristic c in service.characteristics) {
          final String uuid = c.uuid.toString();
          
          if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
            _charFanSpeed = c;
          } else if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26a9") {
            _charFanState = c;
          } else if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26aa") {
            _charLedMode = c;
          } else if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26ab") {
            _charLedColor = c;
          } else if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26ac") {
            _charLedBrightness = c;
          } else if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26af") {
            _charTemp = c;
          } else if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26b0") {
            _charWifiConfig = c;
          }
        }

        // Subscribe to notify characteristics AFTER mapping all chars
        // BlueZ needs delays between notify subscriptions to avoid race conditions
        for (final BluetoothCharacteristic c in service.characteristics) {
          final String uuid = c.uuid.toString();
          try {
            if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26ad") {
              // RPM notify
              await c.setNotifyValue(true);
              await Future<void>.delayed(const Duration(milliseconds: 300));
              _rpmSub = c.lastValueStream.listen((List<int> value) {
                if (value.length >= 2) {
                  final int rpm = value[0] | (value[1] << 8);
                  _updateStatus(rpm: rpm);
                }
              });
            } else if (uuid == "beb5483e-36e1-4688-b7f5-ea07361b26ae") {
              // Status notify
              await c.setNotifyValue(true);
              await Future<void>.delayed(const Duration(milliseconds: 300));
              _statusCharSub = c.lastValueStream.listen((List<int> value) {
                if (value.length >= 4) {
                  _updateStatus(
                    fanPercent: value[0],
                    fanOn: value[1] == 1,
                    ledMode: value[2],
                    ledOn: value[3] == 1,
                  );
                }
              });
            }
          } catch (e) {
            // ponytail: notify subscription may fail on Linux BlueZ, non-fatal
            // Writes still work, just won't get RPM/status push updates
          }
        }
        break;
      }
    }
  }

  @override
  Future<void> disconnect() async {
    await _device.disconnect();
  }

  @override
  Future<void> setFanSpeed(int percent) async {
    await _charFanSpeed?.write([percent], withoutResponse: false);
  }

  @override
  Future<void> setFanState(bool on) async {
    await _charFanState?.write([on ? 1 : 0], withoutResponse: false);
  }

  @override
  Future<void> setLedMode(int mode) async {
    await _charLedMode?.write([mode], withoutResponse: false);
  }

  @override
  Future<void> setLedColor(int r, int g, int b) async {
    await _charLedColor?.write([r, g, b], withoutResponse: false);
  }

  @override
  Future<void> setLedBrightness(int brightness) async {
    await _charLedBrightness?.write([brightness], withoutResponse: false);
  }

  @override
  Future<void> sendTemperature(double cpu, double gpu) async {
    final ByteData byteData = ByteData(8);
    byteData.setFloat32(0, cpu, Endian.little);
    byteData.setFloat32(4, gpu, Endian.little);
    await _charTemp?.write(byteData.buffer.asUint8List(), withoutResponse: false);
  }

  @override
  Future<WifiConfigResult> sendWifiConfig(String ssid, String password) async {
    final json = '{"ssid":"$ssid","pass":"$password"}';
    await _charWifiConfig?.write(utf8.encode(json));
    // ponytail: BLE has no response channel for wifi_config, wait for ESP32 to try connecting
    await Future<void>.delayed(const Duration(seconds: 12));
    return const WifiConfigResult(success: true, ip: null);
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _rpmSub?.cancel();
    _statusCharSub?.cancel();
    _statusController.close();
  }
}
