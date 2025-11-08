import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/services/logger_service.dart';

/// Abstracción para cumplir con el Principio de Inversión de Dependencias (DIP)
abstract class ISecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class SecureStorageService implements ISecureStorageService {
  final ILogger logger;
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage, {ILogger? logger})
    : logger = logger ?? LoggerService();

  @override
  Future<void> write(String key, String value) async {
    logger.info('Writing to secure storage: $key');
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    logger.info('Reading from secure storage: $key');
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    logger.info('Deleting from secure storage: $key');
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    logger.info('Deleting all from secure storage');
    await _storage.deleteAll();
  }
}
