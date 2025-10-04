import '../repositories/servo_repository.dart';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';

class SendServoPositionUseCase {
  final ServoRepository repository;

  SendServoPositionUseCase({required this.repository});

  Future<Either<Failure, void>> call(double angle) async {
    return repository.sendPosition(angle);
  }
}
