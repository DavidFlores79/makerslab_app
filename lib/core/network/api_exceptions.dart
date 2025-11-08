// lib/core/network/api_exceptions.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NotFoundException extends ApiException {
  NotFoundException(super.message) : super(statusCode: 404);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(statusCode: 401);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message) : super(statusCode: 400);
}

class ServerException extends ApiException {
  ServerException(super.message) : super(statusCode: 500);
}
