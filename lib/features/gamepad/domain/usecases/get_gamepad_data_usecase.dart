import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/gamepad_entity.dart';
import '../repositories/gamepad_repository.dart';

class GetGamepadDataUseCase {
  final GamepadRepository repository;

  GetGamepadDataUseCase(this.repository);

  Future<Either<Failure, List<GamepadEntity>>> call() async {
    return await repository.getGamepadData();
  }
}