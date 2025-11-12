// ABOUTME: Theme factory for creating light and dark Material Design 3 themes
// ABOUTME: Provides consistent theming across the app with proper color schemes and component themes

import 'package:flutter/material.dart';
import 'package:makerslab_app/theme/app_color.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme configuration for the app
  /// Uses Material Design 3 with custom AppColors
  static ThemeData lightTheme() {
    return ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.greenLight,
        onPrimaryContainer: AppColors.greenDark,
        secondary: AppColors.gray700,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.gray200,
        onSecondaryContainer: AppColors.gray900,
        tertiary: AppColors.blue,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.blueAccent,
        onTertiaryContainer: AppColors.primaryDark,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.redAccent,
        onErrorContainer: AppColors.greenDark,
        surface: AppColors.white,
        onSurface: AppColors.black,
        onSurfaceVariant: AppColors.gray700,
        outline: AppColors.gray400,
        outlineVariant: AppColors.gray300,
        shadow: AppColors.blackAlpha30,
        scrim: AppColors.blackAlpha50,
        inverseSurface: AppColors.gray950,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.primaryLight,
        surfaceTint: AppColors.primary,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.white,
        surfaceTintColor: AppColors.primary,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: AppColors.gray600),
        labelStyle: const TextStyle(color: AppColors.gray700),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.gray700, size: 24),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.gray300,
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// Dark theme configuration for the app
  /// Uses Material Design 3 with dark color variants from AppColors
  static ThemeData darkTheme() {
    return ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnPrimaryContainer,
        secondary: AppColors.darkOnSurfaceVariant,
        onSecondary: AppColors.darkSurface,
        secondaryContainer: AppColors.darkSurfaceVariant,
        onSecondaryContainer: AppColors.darkOnSurface,
        tertiary: AppColors.darkBlue,
        onTertiary: AppColors.darkOnPrimary,
        tertiaryContainer: AppColors.darkPrimaryContainer,
        onTertiaryContainer: AppColors.darkOnPrimaryContainer,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        errorContainer: AppColors.darkRed,
        onErrorContainer: AppColors.darkOnSurface,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkSurfaceVariant,
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.white,
        onInverseSurface: AppColors.darkSurface,
        inversePrimary: AppColors.primary,
        surfaceTint: AppColors.darkPrimary,
      ),

      // AppBar theme for dark mode
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        iconTheme: IconThemeData(color: AppColors.darkOnSurface),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.darkOnSurface,
        ),
        surfaceTintColor: AppColors.darkPrimary,
      ),

      // Card theme for dark mode
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.darkSurfaceVariant,
        surfaceTintColor: AppColors.darkPrimary,
      ),

      // Elevated button theme for dark mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme for dark mode
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
        labelStyle: const TextStyle(color: AppColors.darkOnSurface),
      ),

      // Text button theme for dark mode
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Icon theme for dark mode
      iconTheme: const IconThemeData(color: AppColors.darkOnSurface, size: 24),

      // Divider theme for dark mode
      dividerTheme: const DividerThemeData(
        color: AppColors.darkOutline,
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation bar theme for dark mode
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
