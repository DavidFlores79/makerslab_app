import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/temperature_entity.dart';

abstract class TemperatureRepository {
  Future<Either<Failure, List<TemperatureEntity>>> getTemperatureData();
}