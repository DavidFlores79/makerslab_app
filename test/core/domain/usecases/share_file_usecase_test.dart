// ABOUTME: Unit tests for ShareFileUseCase
// ABOUTME: Tests use case orchestration and Either pattern pass-through from repository
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:makerslab_app/core/domain/repositories/file_sharing_repository.dart';
import 'package:makerslab_app/core/domain/usecases/share_file_usecase.dart';
import 'package:makerslab_app/core/error/failure.dart';

import 'share_file_usecase_test.mocks.dart';

@GenerateMocks([FileSharingRepository])
void main() {
  late ShareFileUseCase useCase;
  late MockFileSharingRepository mockRepository;

  setUp(() {
    mockRepository = MockFileSharingRepository();
    useCase = ShareFileUseCase(mockRepository);
  });

  group('ShareFileUseCase', () {
    const tAssetPath = 'assets/files/test.ino';
    const tFileName = 'test.ino';
    const tText = 'Test text';
    const tSubject = 'Test subject';

    test('should pass through Right(null) from repository on success', () async {
      // Arrange
      when(mockRepository.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockRepository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass through FileNotFoundFailure from repository', () async {
      // Arrange
      const tFailure = FileNotFoundFailure('File not found');
      when(mockRepository.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Left(tFailure)));
      verify(mockRepository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      )).called(1);
    });

    test('should pass through FileSystemFailure from repository', () async {
      // Arrange
      const tFailure = FileSystemFailure('Cannot write to temp directory');
      when(mockRepository.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Left(tFailure)));
    });

    test('should pass through ShareFailure from repository', () async {
      // Arrange
      const tFailure = ShareFailure('Platform share error');
      when(mockRepository.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Left(tFailure)));
    });

    test('should pass through UnknownFailure from repository', () async {
      // Arrange
      const tFailure = UnknownFailure('Unknown error');
      when(mockRepository.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Left(tFailure)));
    });

    test('should work with only required parameters', () async {
      // Arrange
      when(mockRepository.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(
        assetPath: tAssetPath,
        fileName: tFileName,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockRepository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: null,
        subject: null,
      )).called(1);
    });

    test('should work with text but no subject', () async {
      // Arrange
      when(mockRepository.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockRepository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: tText,
        subject: null,
      )).called(1);
    });

    test('should work with subject but no text', () async {
      // Arrange
      when(mockRepository.shareAssetFile(
        assetPath: anyNamed('assetPath'),
        fileName: anyNamed('fileName'),
        text: anyNamed('text'),
        subject: anyNamed('subject'),
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(
        assetPath: tAssetPath,
        fileName: tFileName,
        subject: tSubject,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockRepository.shareAssetFile(
        assetPath: tAssetPath,
        fileName: tFileName,
        text: null,
        subject: tSubject,
      )).called(1);
    });
  });
}
