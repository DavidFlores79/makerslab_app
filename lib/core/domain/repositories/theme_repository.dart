// ABOUTME: This file defines the ThemeRepository interface for theme persistence operations
// ABOUTME: It follows Clean Architecture by defining domain contracts without implementation details

import 'package:dartz/dartz.dart';

import 'package:makerslab_app/core/error/failure.dart';
import '../entities/theme_preference.dart';

abstract class ThemeRepository {
  /// Retrieves the user's saved theme preference from storage
  Future<Either<Failure, ThemePreference>> getThemePreference();

  /// Saves the user's theme preference to storage
  Future<Either<Failure, void>> saveThemePreference(ThemePreference preference);
}
