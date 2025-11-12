// ABOUTME: This file contains unit tests for ThemeRepositoryImpl
// ABOUTME: It tests theme persistence operations with mocked data sources following TDD principles

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:makerslab_app/core/data/datasources/theme_local_datasource.dart';
import 'package:makerslab_app/core/data/repositories/theme_repository_impl.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/error/exceptions.dart';
import 'package:makerslab_app/core/error/failure.dart';

import 'theme_repository_impl_test.mocks.dart';

@GenerateMocks([ThemeLocalDataSource])
void main() {
  late ThemeRepositoryImpl repository;
  late MockThemeLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockThemeLocalDataSource();
    repository = ThemeRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('getThemePreference', () {
    test('should return ThemePreference.dark when datasource returns dark', () async {
      // Arrange
      when(mockLocalDataSource.getThemePreference())
          .thenAnswer((_) async => ThemePreference.dark);

      // Act
      final result = await repository.getThemePreference();

      // Assert
      expect(result, equals(const Right(ThemePreference.dark)));
      verify(mockLocalDataSource.getThemePreference());
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return ThemePreference.light when datasource returns light', () async {
      // Arrange
      when(mockLocalDataSource.getThemePreference())
          .thenAnswer((_) async => ThemePreference.light);

      // Act
      final result = await repository.getThemePreference();

      // Assert
      expect(result, equals(const Right(ThemePreference.light)));
      verify(mockLocalDataSource.getThemePreference());
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return ThemePreference.system when datasource returns system', () async {
      // Arrange
      when(mockLocalDataSource.getThemePreference())
          .thenAnswer((_) async => ThemePreference.system);

      // Act
      final result = await repository.getThemePreference();

      // Assert
      expect(result, equals(const Right(ThemePreference.system)));
      verify(mockLocalDataSource.getThemePreference());
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return CacheFailure when datasource throws CacheException', () async {
      // Arrange
      const errorMessage = 'No theme preference found';
      when(mockLocalDataSource.getThemePreference())
          .thenThrow(CacheException(errorMessage));

      // Act
      final result = await repository.getThemePreference();

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, equals(errorMessage));
        },
        (_) => fail('Should return Left'),
      );
      verify(mockLocalDataSource.getThemePreference());
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return CacheFailure when datasource throws generic exception', () async {
      // Arrange
      when(mockLocalDataSource.getThemePreference())
          .thenThrow(Exception('Unexpected error'));

      // Act
      final result = await repository.getThemePreference();

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, contains('Error'));
        },
        (_) => fail('Should return Left'),
      );
      verify(mockLocalDataSource.getThemePreference());
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });

  group('saveThemePreference', () {
    test('should call datasource to save ThemePreference.dark', () async {
      // Arrange
      when(mockLocalDataSource.saveThemePreference(ThemePreference.dark))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.saveThemePreference(ThemePreference.dark);

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockLocalDataSource.saveThemePreference(ThemePreference.dark));
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should call datasource to save ThemePreference.light', () async {
      // Arrange
      when(mockLocalDataSource.saveThemePreference(ThemePreference.light))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.saveThemePreference(ThemePreference.light);

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockLocalDataSource.saveThemePreference(ThemePreference.light));
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should call datasource to save ThemePreference.system', () async {
      // Arrange
      when(mockLocalDataSource.saveThemePreference(ThemePreference.system))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.saveThemePreference(ThemePreference.system);

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockLocalDataSource.saveThemePreference(ThemePreference.system));
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return CacheFailure when datasource throws CacheException', () async {
      // Arrange
      const errorMessage = 'Failed to save theme preference';
      when(mockLocalDataSource.saveThemePreference(any))
          .thenThrow(CacheException(errorMessage));

      // Act
      final result = await repository.saveThemePreference(ThemePreference.dark);

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, equals(errorMessage));
        },
        (_) => fail('Should return Left'),
      );
      verify(mockLocalDataSource.saveThemePreference(ThemePreference.dark));
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return CacheFailure when datasource throws generic exception', () async {
      // Arrange
      when(mockLocalDataSource.saveThemePreference(any))
          .thenThrow(Exception('Unexpected save error'));

      // Act
      final result = await repository.saveThemePreference(ThemePreference.light);

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, contains('Error'));
        },
        (_) => fail('Should return Left'),
      );
      verify(mockLocalDataSource.saveThemePreference(ThemePreference.light));
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });
}
