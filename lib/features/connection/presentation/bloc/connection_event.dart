import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_fan_cooling/features/connection/data/services/device_service.dart';

abstract class ConnectionEvent {}

class StartScanEvent extends ConnectionEvent {}

class StopScanEvent extends ConnectionEvent {}

class BleDeviceFoundEvent extends ConnectionEvent {
  final BluetoothDevice device;
  final int rssi;
  final String advName;

  BleDeviceFoundEvent(this.device, this.rssi, this.advName);
}

class ConnectBleEvent extends ConnectionEvent {
  final BluetoothDevice device;

  ConnectBleEvent(this.device);
}

class ConnectWifiEvent extends ConnectionEvent {
  final String wsUrl;

  ConnectWifiEvent(this.wsUrl);
}

class DisconnectEvent extends ConnectionEvent {}

/// Triggered on app start — tries reconnecting to last saved device
class AutoReconnectEvent extends ConnectionEvent {}

class DeviceStatusUpdatedEvent extends ConnectionEvent {
  final DeviceStatus status;

  DeviceStatusUpdatedEvent(this.status);
}

class SendFanSpeedEvent extends ConnectionEvent {
  final int percent;

  SendFanSpeedEvent(this.percent);
}

class SendFanStateEvent extends ConnectionEvent {
  final bool on;

  SendFanStateEvent(this.on);
}

class SendLedModeEvent extends ConnectionEvent {
  final int mode;

  SendLedModeEvent(this.mode);
}

class SendLedColorEvent extends ConnectionEvent {
  final int r;
  final int g;
  final int b;

  SendLedColorEvent(this.r, this.g, this.b);
}

class SendLedBrightnessEvent extends ConnectionEvent {
  final int brightness;

  SendLedBrightnessEvent(this.brightness);
}

class SendWifiConfigEvent extends ConnectionEvent {
  final String ssid;
  final String password;

  SendWifiConfigEvent(this.ssid, this.password);
}
