// ABOUTME: This file defines the LoadThemePreferenceUseCase for retrieving theme preferences
// ABOUTME: It follows Clean Architecture by encapsulating business logic in a single-purpose use case

import 'package:dartz/dartz.dart';

import 'package:makerslab_app/core/error/failure.dart';
import '../entities/theme_preference.dart';
import '../repositories/theme_repository.dart';

class LoadThemePreferenceUseCase {
  final ThemeRepository repository;

  LoadThemePreferenceUseCase({required this.repository});

  Future<Either<Failure, ThemePreference>> call() {
    return repository.getThemePreference();
  }
}
