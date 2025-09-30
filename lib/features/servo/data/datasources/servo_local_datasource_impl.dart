import '../../../../core/data/services/logger_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/servo_entity.dart';
import '../datasources/servo_local_datasource.dart';

class ServoLocalDatasourceImpl implements ServoLocalDatasource {
  final ILogger logger;

  ServoLocalDatasourceImpl({required this.logger});

  @override
  Future<List<ServoEntity>> getServoData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.info("Obteniendo servos localmente...");
      return sampleServos;
    } catch (e, stackTrace) {
      logger.error('Error getting local data for servo', e, stackTrace);
      throw CacheException('Error al obtener servos locales', stackTrace);
    }
  }
}

final List<ServoEntity> sampleServos = [
  ServoEntity(id: 'servo-001'),
  ServoEntity(id: 'servo-002'),
];
