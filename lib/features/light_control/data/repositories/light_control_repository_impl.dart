import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/light_control_entity.dart';
import '../../domain/repositories/light_control_repository.dart';
import '../datasources/light_control_local_datasource.dart';

class LightControlRepositoryImpl implements LightControlRepository {
  final LightControlLocalDatasource localDatasource;

  LightControlRepositoryImpl({
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<LightControlEntity>>> getLightControlData() async {
    try {
      final data = await localDatasource.getLightControlData(); // CAMBIO AQUÍ: 'data' en lugar de 'light_controls'
      return Right(data); // CAMBIO AQUÍ: 'data' en lugar de 'light_controls'
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}