import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/gamepad_entity.dart';
import '../datasources/gamepad_local_datasource.dart';

class GamepadLocalDatasourceImpl implements GamepadLocalDatasource {
  final Logger logger;

  GamepadLocalDatasourceImpl({required this.logger});

  @override
  Future<List<GamepadEntity>> getGamepadData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Obteniendo gamepads localmente...");
      return sampleGamepads;
    } catch (e, stackTrace) {
      logger.e('Error getting local data for gamepad', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener gamepads locales', stackTrace);
    }
  }
}

final List<GamepadEntity> sampleGamepads = [
  GamepadEntity(id: 'gamepad-001'),
  GamepadEntity(id: 'gamepad-002'),
];
