import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/gamepad_entity.dart';
import '../../domain/repositories/gamepad_repository.dart';
import '../datasources/gamepad_local_datasource.dart';

class GamepadRepositoryImpl implements GamepadRepository {
  final GamepadLocalDatasource localDatasource;

  GamepadRepositoryImpl({
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<GamepadEntity>>> getGamepadData() async {
    try {
      final data = await localDatasource.getGamepadData(); // CAMBIO AQUÍ: 'data' en lugar de 'gamepads'
      return Right(data); // CAMBIO AQUÍ: 'data' en lugar de 'gamepads'
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}