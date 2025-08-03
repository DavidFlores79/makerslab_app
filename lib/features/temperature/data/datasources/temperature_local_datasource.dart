import '../../domain/entities/temperature_entity.dart';

abstract class TemperatureLocalDatasource {
  Future<List<TemperatureEntity>> getTemperatureData();
}