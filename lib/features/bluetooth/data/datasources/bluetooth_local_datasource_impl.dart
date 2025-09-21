import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/bluetooth_entity.dart';
import '../datasources/bluetooth_local_datasource.dart';

class BluetoothLocalDatasourceImpl implements BluetoothLocalDatasource {
  final Logger logger;

  BluetoothLocalDatasourceImpl({required this.logger});

  @override
  Future<List<BluetoothEntity>> getBluetoothData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Obteniendo bluetooths localmente...");
      return sampleBluetooths;
    } catch (e, stackTrace) {
      logger.e('Error getting local data for bluetooth', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener bluetooths locales', stackTrace);
    }
  }
}

final List<BluetoothEntity> sampleBluetooths = [
  BluetoothEntity(id: 'bluetooth-001'),
  BluetoothEntity(id: 'bluetooth-002'),
];
