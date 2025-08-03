import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/light_control_entity.dart';
import '../datasources/light_control_local_datasource.dart';

class LightControlLocalDatasourceImpl implements LightControlLocalDatasource {
  final Logger logger;

  LightControlLocalDatasourceImpl({required this.logger});

  @override
  Future<List<LightControlEntity>> getLightControlData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Obteniendo light_controls localmente...");
      return sampleLightControls;
    } catch (e, stackTrace) {
      logger.e('Error getting local data for light_control', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener light_controls locales', stackTrace);
    }
  }
}

final List<LightControlEntity> sampleLightControls = [
  LightControlEntity(id: 'light_control-001'),
  LightControlEntity(id: 'light_control-002'),
];
