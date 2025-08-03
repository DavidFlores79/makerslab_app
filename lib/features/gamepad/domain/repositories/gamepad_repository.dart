import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/gamepad_entity.dart';

abstract class GamepadRepository {
  Future<Either<Failure, List<GamepadEntity>>> getGamepadData();
}