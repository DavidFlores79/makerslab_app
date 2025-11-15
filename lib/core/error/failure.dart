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
  const CacheFailure(super.message, [super.stackTrace]);
}

class BluetoothFailure extends Failure {
  const BluetoothFailure(super.message, [super.stackTrace]);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.stackTrace]);
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(String message, this.statusCode, [StackTrace? stackTrace])
    : super(message, stackTrace);

  @override
  List<Object?> get props => [...super.props, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.stackTrace]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.stackTrace]);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.stackTrace]);
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure(super.message, [super.stackTrace]);
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message, [super.stackTrace]);
}

class ShareFailure extends Failure {
  const ShareFailure(super.message, [super.stackTrace]);
}
