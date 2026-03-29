// ABOUTME: This file defines the HeartbeatLocalDataSource for persisting the heartbeat toggle preference
// ABOUTME: It uses SharedPreferences to store whether heartbeat (ping/pong) is enabled globally

import 'package:shared_preferences/shared_preferences.dart';

import 'package:makerslab_app/core/error/exceptions.dart';

const String _kHeartbeatEnabledKey = 'heartbeat_enabled';

abstract class HeartbeatLocalDataSource {
  /// Returns whether heartbeat is enabled. Defaults to true if not set.
  /// Throws [CacheException] on read error.
  Future<bool> getHeartbeatEnabled();

  /// Saves the heartbeat enabled preference.
  /// Throws [CacheException] on write error.
  Future<void> saveHeartbeatEnabled(bool enabled);
}

class HeartbeatLocalDataSourceImpl implements HeartbeatLocalDataSource {
  final SharedPreferences sharedPreferences;

  HeartbeatLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<bool> getHeartbeatEnabled() async {
    try {
      // Default is true (enabled) when key has never been set
      return sharedPreferences.getBool(_kHeartbeatEnabledKey) ?? true;
    } catch (e) {
      throw CacheException(
        'Error al obtener preferencia de heartbeat: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> saveHeartbeatEnabled(bool enabled) async {
    try {
      final success = await sharedPreferences.setBool(
        _kHeartbeatEnabledKey,
        enabled,
      );
      if (!success) {
        throw CacheException('Error al guardar preferencia de heartbeat');
      }
    } catch (e) {
      throw CacheException(
        'Error al guardar preferencia de heartbeat: ${e.toString()}',
      );
    }
  }
}
