import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/temperature_entity.dart';
import '../datasources/temperature_local_datasource.dart';

class TemperatureLocalDatasourceImpl implements TemperatureLocalDatasource {
  final Logger logger;

  TemperatureLocalDatasourceImpl({required this.logger});

  @override
  Future<List<TemperatureEntity>> getTemperatureData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Obteniendo temperatures localmente...");
      return sampleTemperatures;
    } catch (e, stackTrace) {
      logger.e('Error getting local data for temperature', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener temperatures locales', stackTrace);
    }
  }
}

final List<TemperatureEntity> sampleTemperatures = [
  TemperatureEntity(id: 'temperature-001'),
  TemperatureEntity(id: 'temperature-002'),
];
