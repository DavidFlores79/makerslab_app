import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/servo_repository.dart';

class GetServoPositionUseCase {
  final ServoRepository repository;

  GetServoPositionUseCase({required this.repository});

  Future<Stream<Either<Failure, double>>> call() async {
    return repository.positionStream();
  }
}
