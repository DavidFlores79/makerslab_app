// ABOUTME: This file implements HeartbeatRepository using the HeartbeatLocalDataSource
// ABOUTME: It converts CacheExceptions to domain Failures following the repository pattern

import 'package:dartz/dartz.dart';

import 'package:makerslab_app/core/data/datasources/heartbeat_local_datasource.dart';
import 'package:makerslab_app/core/domain/repositories/heartbeat_repository.dart';
import 'package:makerslab_app/core/error/exceptions.dart';
import 'package:makerslab_app/core/error/failure.dart';

class HeartbeatRepositoryImpl implements HeartbeatRepository {
  final HeartbeatLocalDataSource localDataSource;

  HeartbeatRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, bool>> getHeartbeatEnabled() async {
    try {
      final enabled = await localDataSource.getHeartbeatEnabled();
      return Right(enabled);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      return Left(
        CacheFailure(
          'Error al cargar preferencia de heartbeat: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveHeartbeatEnabled(bool enabled) async {
    try {
      await localDataSource.saveHeartbeatEnabled(enabled);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      return Left(
        CacheFailure(
          'Error al guardar preferencia de heartbeat: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }
}
