// ABOUTME: This file implements the ThemeRepository interface for theme persistence
// ABOUTME: It handles data layer operations and converts exceptions to domain failures

import 'package:dartz/dartz.dart';

import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/domain/repositories/theme_repository.dart';
import 'package:makerslab_app/core/error/exceptions.dart';
import 'package:makerslab_app/core/error/failure.dart';
import '../datasources/theme_local_datasource.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeLocalDataSource localDataSource;

  ThemeRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, ThemePreference>> getThemePreference() async {
    try {
      final preference = await localDataSource.getThemePreference();
      return Right(preference);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      return Left(
        CacheFailure(
          'Error al cargar preferencia de tema: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveThemePreference(
    ThemePreference preference,
  ) async {
    try {
      await localDataSource.saveThemePreference(preference);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      return Left(
        CacheFailure(
          'Error al guardar preferencia de tema: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }
}
