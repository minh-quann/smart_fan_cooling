import 'package:smart_fan_cooling/features/connection/data/services/device_service.dart';

enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
}

class DiscoveredDevice {
  final String name;
  final String id;
  final int rssi;
  final String ipAddress;
  final String type; // 'ble' or 'wifi'

  const DiscoveredDevice({
    required this.name,
    required this.id,
    this.rssi = 0,
    this.ipAddress = '',
    required this.type,
  });
}

class ConnectionState {
  final ConnectionStatus status;
  final List<DiscoveredDevice> bleDevices;
  final List<DiscoveredDevice> wifiDevices;
  final List<DiscoveredDevice> usbDevices;
  final DeviceService? activeService;
  final DeviceStatus? deviceStatus;
  final String? connectionType;
  final String? errorMessage;

  const ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.bleDevices = const [],
    this.wifiDevices = const [],
    this.usbDevices = const [],
    this.activeService,
    this.deviceStatus,
    this.connectionType,
    this.errorMessage,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    List<DiscoveredDevice>? bleDevices,
    List<DiscoveredDevice>? wifiDevices,
    List<DiscoveredDevice>? usbDevices,
    DeviceService? activeService,
    DeviceStatus? deviceStatus,
    String? connectionType,
    String? errorMessage,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      bleDevices: bleDevices ?? this.bleDevices,
      wifiDevices: wifiDevices ?? this.wifiDevices,
      usbDevices: usbDevices ?? this.usbDevices,
      activeService: activeService ?? this.activeService,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      connectionType: connectionType ?? this.connectionType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
