import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fan_cooling/features/connection/data/services/ble_device_service.dart';
import 'package:smart_fan_cooling/features/connection/data/services/windows_ble_device_service.dart';
import 'package:smart_fan_cooling/features/connection/data/services/wifi_device_service.dart';
import 'package:smart_fan_cooling/features/connection/data/services/device_service.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_event.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_state.dart';

// SharedPreferences keys for saved connection
const _kConnType = 'conn_type';   // 'ble' or 'wifi'
const _kConnId = 'conn_id';       // BLE remoteId or WebSocket URL

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<dynamic>? _statusSubscription;

  ConnectionBloc() : super(const ConnectionState()) {
    on<StartScanEvent>(_onStartScan);
    on<StopScanEvent>(_onStopScan);
    on<BleDeviceFoundEvent>(_onBleDeviceFound);
    on<ConnectBleEvent>(_onConnectBle);
    on<ConnectWifiEvent>(_onConnectWifi);
    on<DisconnectEvent>(_onDisconnect);
    on<AutoReconnectEvent>(_onAutoReconnect);
    on<DeviceStatusUpdatedEvent>(_onDeviceStatusUpdated);
    on<SendFanSpeedEvent>(_onSendFanSpeed);
    on<SendFanStateEvent>(_onSendFanState);
    on<SendLedModeEvent>(_onSendLedMode);
    on<SendLedColorEvent>(_onSendLedColor);
    on<SendLedBrightnessEvent>(_onSendLedBrightness);
    on<SendWifiConfigEvent>(_onSendWifiConfig);
    on<SendTemperatureEvent>(_onSendTemperature);
  }

  // ---- Save / Load connection config ----

  Future<void> _saveConnection(String type, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kConnType, type);
    await prefs.setString(_kConnId, id);
  }

  Future<void> _clearSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kConnType);
    await prefs.remove(_kConnId);
  }

  // ---- Auto Reconnect ----

  Future<void> _onAutoReconnect(AutoReconnectEvent event, Emitter<ConnectionState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final String? type = prefs.getString(_kConnType);
    final String? id = prefs.getString(_kConnId);

    if (type == null || id == null) return;

    emit(state.copyWith(status: ConnectionStatus.connecting, connectionType: type));

    try {
      if (type == 'wifi') {
        final service = WifiDeviceService(id);
        await service.connect();
        _statusSubscription = service.statusStream.listen((status) {
          add(DeviceStatusUpdatedEvent(status));
        });
        emit(state.copyWith(
          status: ConnectionStatus.connected,
          activeService: service,
        ));
      } else if (type == 'ble') {
        final DeviceService service;
        if (Platform.isWindows) {
          service = WindowsBleDeviceService(id);
        } else {
          final device = BluetoothDevice.fromId(id);
          service = BleDeviceService(device);
        }
        await service.connect();
        _statusSubscription = service.statusStream.listen((status) {
          add(DeviceStatusUpdatedEvent(status));
        });
        emit(state.copyWith(
          status: ConnectionStatus.connected,
          activeService: service,
        ));
      }
    } catch (_) {
      // Auto-reconnect failed silently — user can manually connect
      emit(state.copyWith(
        status: ConnectionStatus.disconnected,
        connectionType: null,
      ));
    }
  }

  // ---- Scan ----

  Future<void> _onStartScan(StartScanEvent event, Emitter<ConnectionState> emit) async {
    emit(state.copyWith(status: ConnectionStatus.scanning, bleDevices: [], wifiDevices: []));
    
    try {
      if (!Platform.isWindows) {
        _scanSubscription?.cancel();
        _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult r in results) {
            String name = r.advertisementData.advName;
            if (name.isEmpty) name = r.device.advName;
            if (name.isEmpty) name = r.device.platformName;
            add(BleDeviceFoundEvent(r.device, r.rssi, name));
          }
        });

        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 10),
        );
      } else {
        // Windows platform BLE handling via UniversalBle
        UniversalBle.onScanResult = (BleDevice device) {
          String name = device.name ?? '';
          if (name.isNotEmpty) {
            final bDevice = BluetoothDevice.fromId(device.deviceId);
            add(BleDeviceFoundEvent(bDevice, device.rssi ?? -70, name));
          }
        };
        try {
          await UniversalBle.startScan();
        } catch (_) {}
      }
      
      // Always show ESP32 AP as WiFi option
      emit(state.copyWith(
        wifiDevices: [
          const DiscoveredDevice(
            name: "LlanoFan WiFi AP",
            id: "192.168.4.1",
            ipAddress: "192.168.4.1",
            type: "wifi",
          ),
        ],
      ));
    } catch (e) {
      if (!Platform.isWindows) {
        emit(state.copyWith(errorMessage: e.toString()));
      }
    }
  }

  Future<void> _onStopScan(StopScanEvent event, Emitter<ConnectionState> emit) async {
    if (!Platform.isWindows) {
      await FlutterBluePlus.stopScan();
    } else {
      try {
        await UniversalBle.stopScan();
      } catch (_) {}
    }
    _scanSubscription?.cancel();
    if (state.status == ConnectionStatus.scanning) {
      emit(state.copyWith(status: ConnectionStatus.disconnected));
    }
  }

  void _onBleDeviceFound(BleDeviceFoundEvent event, Emitter<ConnectionState> emit) {
    final String deviceId = event.device.remoteId.str;
    final String deviceName = event.advName;

    if (deviceName.isEmpty) return;

    final List<DiscoveredDevice> currentDevices = List.from(state.bleDevices);
    final newDevice = DiscoveredDevice(
      name: deviceName,
      id: deviceId,
      rssi: event.rssi,
      type: 'ble',
    );

    final existingIdx = currentDevices.indexWhere((d) => d.id == deviceId);
    if (existingIdx >= 0) {
      currentDevices[existingIdx] = newDevice;
    } else {
      currentDevices.add(newDevice);
    }
    currentDevices.sort((a, b) => b.rssi.compareTo(a.rssi));
    emit(state.copyWith(bleDevices: currentDevices));
  }

  // ---- Connect ----

  Future<void> _onConnectBle(ConnectBleEvent event, Emitter<ConnectionState> emit) async {
    emit(state.copyWith(status: ConnectionStatus.connecting, connectionType: 'ble'));
    
    await _stopScanningAndDisconnect();
    
    try {
      final DeviceService service;
      if (Platform.isWindows) {
        service = WindowsBleDeviceService(event.device.remoteId.str);
      } else {
        service = BleDeviceService(event.device);
      }
      await service.connect();
      
      _statusSubscription = service.statusStream.listen((status) {
        add(DeviceStatusUpdatedEvent(status));
      });
      
      // Save for auto-reconnect
      await _saveConnection('ble', event.device.remoteId.str);
      
      emit(state.copyWith(
        status: ConnectionStatus.connected,
        activeService: service,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ConnectionStatus.disconnected,
        errorMessage: 'Failed to connect via BLE: $e',
      ));
    }
  }

  Future<void> _onConnectWifi(ConnectWifiEvent event, Emitter<ConnectionState> emit) async {
    emit(state.copyWith(status: ConnectionStatus.connecting, connectionType: 'wifi'));
    
    await _stopScanningAndDisconnect();
    
    try {
      final WifiDeviceService service = WifiDeviceService(event.wsUrl);
      await service.connect();
      
      _statusSubscription = service.statusStream.listen((status) {
        add(DeviceStatusUpdatedEvent(status));
      });
      
      // Save for auto-reconnect
      await _saveConnection('wifi', event.wsUrl);
      
      emit(state.copyWith(
        status: ConnectionStatus.connected,
        activeService: service,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ConnectionStatus.disconnected,
        errorMessage: 'Failed to connect via WiFi: $e',
      ));
    }
  }

  // ---- Disconnect ----

  Future<void> _onDisconnect(DisconnectEvent event, Emitter<ConnectionState> emit) async {
    await _clearSavedConnection();
    await _stopScanningAndDisconnect();
    emit(state.copyWith(
      status: ConnectionStatus.disconnected,
      activeService: null,
      deviceStatus: null,
      connectionType: null,
    ));
  }

  void _onDeviceStatusUpdated(DeviceStatusUpdatedEvent event, Emitter<ConnectionState> emit) {
    if (!event.status.connected && state.status == ConnectionStatus.connected) {
      emit(state.copyWith(
        status: ConnectionStatus.disconnected,
        deviceStatus: event.status,
      ));
    } else {
      emit(state.copyWith(deviceStatus: event.status));
    }
  }

  // ---- Send commands ----

  Future<void> _onSendFanSpeed(SendFanSpeedEvent event, Emitter<ConnectionState> emit) async {
    await state.activeService?.setFanSpeed(event.percent);
  }

  Future<void> _onSendFanState(SendFanStateEvent event, Emitter<ConnectionState> emit) async {
    await state.activeService?.setFanState(event.on);
  }

  Future<void> _onSendLedMode(SendLedModeEvent event, Emitter<ConnectionState> emit) async {
    await state.activeService?.setLedMode(event.mode);
  }

  Future<void> _onSendLedColor(SendLedColorEvent event, Emitter<ConnectionState> emit) async {
    await state.activeService?.setLedColor(event.r, event.g, event.b);
  }

  Future<void> _onSendLedBrightness(SendLedBrightnessEvent event, Emitter<ConnectionState> emit) async {
    await state.activeService?.setLedBrightness(event.brightness);
  }

  Future<void> _onSendWifiConfig(SendWifiConfigEvent event, Emitter<ConnectionState> emit) async {
    await state.activeService?.sendWifiConfig(event.ssid, event.password);
  }

  Future<void> _onSendTemperature(SendTemperatureEvent event, Emitter<ConnectionState> emit) async {
    await state.activeService?.sendTemperature(event.cpuTemp, event.gpuTemp);
  }

  // ---- Helpers ----

  Future<void> _stopScanningAndDisconnect() async {
    if (!Platform.isWindows) {
      await FlutterBluePlus.stopScan();
    } else {
      try {
        await UniversalBle.stopScan();
      } catch (_) {}
    }
    _scanSubscription?.cancel();
    _statusSubscription?.cancel();
    await state.activeService?.disconnect();
    state.activeService?.dispose();
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _statusSubscription?.cancel();
    state.activeService?.dispose();
    return super.close();
  }
}
