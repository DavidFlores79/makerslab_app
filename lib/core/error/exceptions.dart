// core/error/exceptions.dart
import 'failure.dart';

class ServerException implements Exception {
  final String message;
  final int statusCode;
  final StackTrace? stackTrace;

  ServerException(this.message, this.statusCode, [this.stackTrace]);

  @override
  String toString() => 'ServerException: $message (status $statusCode)';
}

class CacheException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  CacheException(this.message, [this.stackTrace]);

  @override
  String toString() => 'CacheException: $message';
}

// Extensión para convertir excepciones en Failures
extension FailureMapper on Exception {
  Failure toFailure() {
    if (this is ServerException) {
      final e = this as ServerException;
      return ServerFailure(e.message, e.statusCode, e.stackTrace);
    } else if (this is CacheException) {
      final e = this as CacheException;
      return CacheFailure(e.message, e.stackTrace);
    } else {
      return ServerFailure(toString(), 0, null);
    }
  }
}
