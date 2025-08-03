// core/error/failure.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.stackTrace]);

  @override
  List<Object?> get props => [message, stackTrace];

  @override
  String toString() =>
      stackTrace != null
          ? 'Failure: $message\n$stackTrace'
          : 'Failure: $message';
}

// Errores específicos de la aplicación
class CacheFailure extends Failure {
  const CacheFailure(String message, [StackTrace? stackTrace])
    : super(message, stackTrace);
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(String message, this.statusCode, [StackTrace? stackTrace])
    : super(message, stackTrace);

  @override
  List<Object?> get props => [...super.props, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, [StackTrace? stackTrace])
    : super(message, stackTrace);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, [StackTrace? stackTrace])
    : super(message, stackTrace);
}
