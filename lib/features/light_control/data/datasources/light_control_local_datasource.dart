import '../../domain/entities/light_control_entity.dart';

abstract class LightControlLocalDatasource {
  Future<List<LightControlEntity>> getLightControlData();
}