import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/temperature_entity.dart';
import '../repositories/temperature_repository.dart';

class GetTemperatureDataUseCase {
  final TemperatureRepository repository;

  GetTemperatureDataUseCase(this.repository);

  Future<Either<Failure, List<TemperatureEntity>>> call() async {
    return await repository.getTemperatureData();
  }
}