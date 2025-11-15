// ABOUTME: Unit tests for FileSharingRepositoryImpl
// ABOUTME: Tests repository error handling, exception to Failure conversion, and Either pattern
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:share_plus/share_plus.dart';
import 'package:makerslab_app/core/data/repositories/file_sharing_repository_impl.dart';
import 'package:makerslab_app/core/data/services/file_sharing_service.dart';
import 'package:makerslab_app/core/error/failure.dart';

import 'file_sharing_repository_impl_test.mocks.dart';

@GenerateMocks([FileSharingService])
void main() {
  late FileSharingRepositoryImpl repository;
  late MockFileSharingService mockService;

  setUp(() {
    mockService = MockFileSharingService();
    repository = FileSharingRepositoryImpl(service: mockService);
  });

  group('FileSharingRepositoryImpl', () {
    const tAssetPath = 'assets/files/test.ino';
    const tFileName = 'test.ino';
    const tText = 'Test text';
    const tSubject = 'Test subject';

    test('should return Right(null) when service completes successfully', () async {
      // Arrange
      final tShareResult = ShareResult('', ShareResultStatus.success);
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => tShareResult);

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockService.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      )).called(1);
    });

    test('should return Right(null) when user dismisses share sheet', () async {
      // Arrange - user dismissal is NOT an error
      final tShareResult = ShareResult('', ShareResultStatus.dismissed);
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => tShareResult);

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Right(null)));
    });

    test('should return Right(null) when share is unavailable', () async {
      // Arrange - unavailable is also not an error
      final tShareResult = ShareResult('', ShareResultStatus.unavailable);
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => tShareResult);

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Right(null)));
    });

    test('should return FileNotFoundFailure when PlatformException contains "Unable to load asset"',
        () async {
      // Arrange
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenThrow(PlatformException(
        code: 'AssetNotFound',
        message: 'Unable to load asset: $tAssetPath',
      ));

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<FileNotFoundFailure>());
          expect(failure.message, contains('no encontrado'));
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return ShareFailure when PlatformException without asset error', () async {
      // Arrange
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenThrow(PlatformException(
        code: 'ShareError',
        message: 'Share failed',
      ));

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<ShareFailure>());
          expect(failure.message, contains('plataforma'));
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return FileSystemFailure when FileSystemException is thrown', () async {
      // Arrange
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenThrow(const FileSystemException('Write failed'));

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<FileSystemFailure>());
          expect(failure.message, contains('guardar'));
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return ShareFailure for generic Exception', () async {
      // Arrange
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenThrow(Exception('Generic error'));

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<ShareFailure>());
          expect(failure.message, contains('compartir'));
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return UnknownFailure for unexpected errors', () async {
      // Arrange
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenThrow('String error');

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('desconocido'));
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should work with optional parameters', () async {
      // Arrange
      final tShareResult = ShareResult('', ShareResultStatus.success);
      when(mockService.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => tShareResult);

      // Act
      final result = await repository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockService.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: null,
        subject: null,
      )).called(1);
    });
  });
}
