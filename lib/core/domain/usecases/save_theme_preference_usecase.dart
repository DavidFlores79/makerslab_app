// ABOUTME: This file defines the SaveThemePreferenceUseCase for persisting theme preferences
// ABOUTME: It follows Clean Architecture by encapsulating business logic in a single-purpose use case

import 'package:dartz/dartz.dart';

import 'package:makerslab_app/core/error/failure.dart';
import '../entities/theme_preference.dart';
import '../repositories/theme_repository.dart';

class SaveThemePreferenceUseCase {
  final ThemeRepository repository;

  SaveThemePreferenceUseCase({required this.repository});

  Future<Either<Failure, void>> call(ThemePreference preference) {
    return repository.saveThemePreference(preference);
  }
}
