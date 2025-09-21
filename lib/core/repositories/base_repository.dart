// lib/src/core/repositories/base_repository.dart

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../error/exceptions.dart';
import '../error/failure.dart';
import '../network/api_exceptions.dart'; // opcional si usas un logger central

/// Clase base para repositorios. Centraliza manejo de errores y conversión a Either.
abstract class BaseRepository {
  Future<Either<Failure, T>> safeCall<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return Right(result);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    } on ApiException catch (e, stackTrace) {
      return Left(ServerFailure(e.message, e.statusCode, stackTrace));
    } on DioException catch (e, stackTrace) {
      final msg = _messageFromDioException(e);
      return Left(ServerFailure(msg, e.response?.statusCode, stackTrace));
    } catch (e, stackTrace) {
      return Left(
        ServerFailure(
          'Error inesperado. Intenta nuevamente.',
          null,
          stackTrace,
        ),
      );
    }
  }

  String _messageFromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    }
    if (e.type == DioExceptionType.cancel) {
      return 'Solicitud cancelada.';
    }
    if (e.response != null && e.response?.data != null) {
      try {
        final data = e.response!.data;
        if (data is Map &&
            (data['message'] != null || data['errors'] != null)) {
          if (data['message'] != null) return data['message'].toString();
          if (data['errors'] is Iterable) {
            final errors =
                List.from(data['errors'] as Iterable)
                    .map(
                      (it) =>
                          (it is Map ? (it['msg'] ?? it['message']) : it)
                              .toString(),
                    )
                    .where((s) => s.isNotEmpty)
                    .toList();
            if (errors.isNotEmpty) return errors.take(3).join(' • ');
          }
        }
      } catch (_) {}
    }
    return e.message ?? 'Error de red desconocido';
  }
}
