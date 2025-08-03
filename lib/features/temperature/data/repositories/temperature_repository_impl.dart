import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/repositories/temperature_repository.dart';
import '../datasources/temperature_local_datasource.dart';

class TemperatureRepositoryImpl implements TemperatureRepository {
  final TemperatureLocalDatasource localDatasource;

  TemperatureRepositoryImpl({
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<TemperatureEntity>>> getTemperatureData() async {
    try {
      final data = await localDatasource.getTemperatureData(); // CAMBIO AQUÍ: 'data' en lugar de 'temperatures'
      return Right(data); // CAMBIO AQUÍ: 'data' en lugar de 'temperatures'
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}