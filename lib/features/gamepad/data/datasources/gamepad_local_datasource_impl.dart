import '../../../../core/data/services/logger_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/gamepad_entity.dart';
import '../datasources/gamepad_local_datasource.dart';

class GamepadLocalDatasourceImpl implements GamepadLocalDatasource {
  final ILogger logger;

  GamepadLocalDatasourceImpl({required this.logger});

  @override
  Future<List<GamepadEntity>> getGamepadData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.info("Obteniendo gamepads localmente...");
      return sampleGamepads;
    } catch (e, stackTrace) {
      logger.error('Error getting local data for gamepad', e, stackTrace);
      throw CacheException('Error al obtener gamepads locales', stackTrace);
    }
  }
}

final List<GamepadEntity> sampleGamepads = [
  GamepadEntity(id: 'gamepad-001'),
  GamepadEntity(id: 'gamepad-002'),
];
