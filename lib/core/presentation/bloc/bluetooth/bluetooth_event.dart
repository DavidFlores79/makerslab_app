// lib/core/bluetooth/presentation/bloc/bluetooth_event.dart
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

abstract class BluetoothEvent {}

class BluetoothScanRequested extends BluetoothEvent {}

class BluetoothDeviceSelected extends BluetoothEvent {
  final BluetoothDevice device;
  BluetoothDeviceSelected(this.device);
}

class BluetoothDisconnectRequested extends BluetoothEvent {}
