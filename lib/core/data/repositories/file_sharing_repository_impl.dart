// ABOUTME: Implementation of FileSharingRepository that handles file sharing operations
// ABOUTME: Converts service exceptions into domain Failures following Clean Architecture principles
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import '../../domain/repositories/file_sharing_repository.dart';
import '../../error/failure.dart';
import '../services/file_sharing_service.dart';

class FileSharingRepositoryImpl implements FileSharingRepository {
  final FileSharingService service;

  FileSharingRepositoryImpl({required this.service});

  @override
  Future<Either<Failure, void>> shareAssetFile({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    try {
      // Call the service to share the file
      await service.shareAssetFile(
        assetPath: assetPath,
        fileName: fileName,
        text: text,
        subject: subject,
      );

      // All share results are treated as success (even user dismissal)
      // User dismissing the share sheet is NOT an error condition
      return const Right(null);
    } on FileSystemException catch (e, stackTrace) {
      // Error writing to temporary directory
      return Left(
        FileSystemFailure(
          'No se pudo guardar el archivo temporalmente',
          stackTrace,
        ),
      );
    } on PlatformException catch (e, stackTrace) {
      // Asset not found in bundle or platform-specific errors
      if (e.message?.contains('Unable to load asset') ?? false) {
        return Left(
          FileNotFoundFailure(
            'Archivo no encontrado en los recursos de la aplicación',
            stackTrace,
          ),
        );
      }
      return Left(
        ShareFailure(
          'Error de la plataforma: ${e.message ?? e.toString()}',
          stackTrace,
        ),
      );
    } on Exception catch (e, stackTrace) {
      // Other exceptions
      return Left(
        ShareFailure(
          'Error al compartir el archivo: ${e.toString()}',
          stackTrace,
        ),
      );
    } catch (e, stackTrace) {
      // Unknown errors
      return Left(
        UnknownFailure('Error desconocido al compartir el archivo', stackTrace),
      );
    }
  }
}
