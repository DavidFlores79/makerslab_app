import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/servo_entity.dart';
import '../datasources/servo_local_datasource.dart';

class ServoLocalDatasourceImpl implements ServoLocalDatasource {
  final Logger logger;

  ServoLocalDatasourceImpl({required this.logger});

  @override
  Future<List<ServoEntity>> getServoData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Obteniendo servos localmente...");
      return sampleServos;
    } catch (e, stackTrace) {
      logger.e('Error getting local data for servo', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener servos locales', stackTrace);
    }
  }
}

final List<ServoEntity> sampleServos = [
  ServoEntity(id: 'servo-001'),
  ServoEntity(id: 'servo-002'),
];
