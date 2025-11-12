// ABOUTME: This file defines the ThemeLocalDataSource for local theme preference storage
// ABOUTME: It uses SharedPreferences to persist user theme selection across app restarts

import 'package:shared_preferences/shared_preferences.dart';

import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/error/exceptions.dart';

const String _kThemePreferenceKey = 'theme_mode_preference';

abstract class ThemeLocalDataSource {
  /// Gets the cached theme preference from SharedPreferences
  /// Throws [CacheException] if no preference is found
  Future<ThemePreference> getThemePreference();

  /// Saves the theme preference to SharedPreferences
  /// Throws [CacheException] if save fails
  Future<void> saveThemePreference(ThemePreference preference);
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  final SharedPreferences sharedPreferences;

  ThemeLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<ThemePreference> getThemePreference() async {
    try {
      final storedValue = sharedPreferences.getString(_kThemePreferenceKey);

      if (storedValue == null) {
        // Return system as default if no preference is stored
        return ThemePreference.system;
      }

      return ThemePreference.fromStorageString(storedValue);
    } catch (e) {
      throw CacheException(
        'Error al obtener preferencia de tema: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> saveThemePreference(ThemePreference preference) async {
    try {
      final success = await sharedPreferences.setString(
        _kThemePreferenceKey,
        preference.toStorageString(),
      );

      if (!success) {
        throw CacheException('Error al guardar preferencia de tema');
      }
    } catch (e) {
      throw CacheException(
        'Error al guardar preferencia de tema: ${e.toString()}',
      );
    }
  }
}
