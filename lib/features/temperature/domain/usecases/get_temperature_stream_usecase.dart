import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/temperature_entity.dart';
import '../repositories/temperature_repository.dart';

class GetTemperatureStream {
  final TemperatureRepository repository;
  GetTemperatureStream({required this.repository});

  Stream<Either<Failure, Temperature>> call() {
    return repository.temperatureStream();
  }
}
