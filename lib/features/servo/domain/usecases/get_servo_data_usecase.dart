import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/servo_entity.dart';
import '../repositories/servo_repository.dart';

class GetServoDataUseCase {
  final ServoRepository repository;

  GetServoDataUseCase(this.repository);

  Future<Either<Failure, List<ServoEntity>>> call() async {
    return await repository.getServoData();
  }
}