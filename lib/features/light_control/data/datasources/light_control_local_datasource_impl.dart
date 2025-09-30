import '../../../../core/data/services/logger_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/light_control_entity.dart';
import '../datasources/light_control_local_datasource.dart';

class LightControlLocalDatasourceImpl implements LightControlLocalDatasource {
  final ILogger logger;

  LightControlLocalDatasourceImpl({required this.logger});

  @override
  Future<List<LightControlEntity>> getLightControlData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.info("Obteniendo light_controls localmente...");
      return sampleLightControls;
    } catch (e, stackTrace) {
      logger.error('Error getting local data for light_control', e, stackTrace);
      throw CacheException(
        'Error al obtener light_controls locales',
        stackTrace,
      );
    }
  }
}

final List<LightControlEntity> sampleLightControls = [
  LightControlEntity(id: 'light_control-001'),
  LightControlEntity(id: 'light_control-002'),
];
