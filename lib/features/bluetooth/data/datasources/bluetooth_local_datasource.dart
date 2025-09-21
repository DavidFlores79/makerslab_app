import '../../domain/entities/bluetooth_entity.dart';

abstract class BluetoothLocalDatasource {
  Future<List<BluetoothEntity>> getBluetoothData();
}