// ABOUTME: This file defines the ThemePreference entity representing user's theme mode selection
// ABOUTME: It includes an enum for theme modes (system, light, dark) and conversion methods for storage

enum ThemePreference {
  system,
  light,
  dark;

  /// Converts the theme preference to a string for storage
  String toStorageString() {
    return switch (this) {
      ThemePreference.system => 'system',
      ThemePreference.light => 'light',
      ThemePreference.dark => 'dark',
    };
  }

  /// Creates a ThemePreference from a storage string
  static ThemePreference fromStorageString(String value) {
    return switch (value.toLowerCase()) {
      'light' => ThemePreference.light,
      'dark' => ThemePreference.dark,
      'system' => ThemePreference.system,
      _ => ThemePreference.system, // Default to system if invalid
    };
  }
}
