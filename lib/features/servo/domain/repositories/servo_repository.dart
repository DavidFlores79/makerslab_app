import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/servo_entity.dart';

abstract class ServoRepository {
  Future<Either<Failure, List<ServoEntity>>> getServoData();
}