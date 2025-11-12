import '../../domain/entities/gamepad_entity.dart';

abstract class GamepadLocalDatasource {
  Future<List<GamepadEntity>> getGamepadData();
}
