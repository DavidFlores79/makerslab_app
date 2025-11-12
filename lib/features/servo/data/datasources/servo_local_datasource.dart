import '../../domain/entities/servo_entity.dart';

abstract class ServoLocalDatasource {
  Future<List<ServoEntity>> getServoData();
}
