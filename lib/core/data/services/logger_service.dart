// lib/core/services/logger_service.dart
import 'package:logger/logger.dart'; // O usa fimber, etc.

abstract class ILogger {
  void info(String message);
  void warning(String message);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  // Otros niveles: debug, warning, etc.
}

class LoggerService implements ILogger {
  final Logger _logger = Logger(level: Level.info); // Configura nivel global

  @override
  void info(String message) => _logger.i(message);

  @override
  void warning(String message) => _logger.w(message);

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
