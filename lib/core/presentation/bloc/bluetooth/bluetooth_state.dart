// lib/core/bluetooth/presentation/bloc/bluetooth_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

abstract class BluetoothState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BluetoothInitial extends BluetoothState {}

class BluetoothScanning extends BluetoothState {}

class BluetoothScanLoaded extends BluetoothState {
  final List<BluetoothDevice> devices;
  BluetoothScanLoaded(this.devices);
  @override
  List<Object?> get props => [devices];
}

class BluetoothConnecting extends BluetoothState {}

class BluetoothConnected extends BluetoothState {
  final BluetoothDevice device;
  BluetoothConnected(this.device);
  @override
  List<Object?> get props => [device];
}

class BluetoothDisconnected extends BluetoothState {}

class BluetoothError extends BluetoothState {
  final String message;
  BluetoothError(this.message);
  @override
  List<Object?> get props => [message];
}
