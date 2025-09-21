import '../../domain/entities/bluetooth_entity.dart';

abstract class BluetoothsState {}

class InitialDataLoading extends BluetoothsState {}

class BluetoothsLoading extends BluetoothsState {}

class BluetoothsLoaded extends BluetoothsState {
  final List<BluetoothEntity> data; // CAMBIO AQUÍ: 'data' en lugar de 'investments'

  BluetoothsLoaded({required this.data}); // CAMBIO AQUÍ: 'data' en lugar de 'investments'
}

class BluetoothsError extends BluetoothsState {
  final String message;
  BluetoothsError(this.message);
}