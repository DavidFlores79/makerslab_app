import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/servo_entity.dart';
import '../../domain/repositories/servo_repository.dart';
import '../datasources/servo_local_datasource.dart';

class ServoRepositoryImpl implements ServoRepository {
  final ServoLocalDatasource localDatasource;

  ServoRepositoryImpl({
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<ServoEntity>>> getServoData() async {
    try {
      final data = await localDatasource.getServoData(); // CAMBIO AQUÍ: 'data' en lugar de 'servos'
      return Right(data); // CAMBIO AQUÍ: 'data' en lugar de 'servos'
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}