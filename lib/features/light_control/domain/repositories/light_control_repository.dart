import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/light_control_entity.dart';

abstract class LightControlRepository {
  Future<Either<Failure, List<LightControlEntity>>> getLightControlData();
}