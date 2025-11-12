import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors
  // Surfaces
  static const darkSurface = Color(0xFF1C1B1F);
  static const darkSurfaceVariant = Color(0xFF2B2930);
  static const darkBackground = Color(0xFF1C1B1F);

  // Primary (APPROVED: #5EB1E8 - 40% lighter than light mode #247BA0)
  static const darkPrimary = Color(0xFF5EB1E8);
  static const darkOnPrimary = Color(0xFF003548);
  static const darkPrimaryContainer = Color(0xFF004F7A);
  static const darkOnPrimaryContainer = Color(0xFFB8E7FF);

  // Text colors
  static const darkOnSurface = Color(0xFFE6E1E5); // 87% white
  static const darkOnSurfaceVariant = Color(0xFFCAC4D0); // 60% white
  static const darkOutline = Color(0xFF938F99); // 38% white

  // Module colors adapted for dark mode (brighter versions)
  static const darkLightGreen = Color(0xFFA5D57B); // Gamepad (brighter)
  static const darkBlue = Color(0xFF64B5F6); // Sensor DHT (lighter)
  static const darkRed = Color(0xFFEF5350); // Servos (lighter)
  static const darkOrange = Color(0xFFFFB74D); // Light Control (lighter)
  static const darkPurple = Color(0xFFBA68C8); // Chat (lighter)

  // Error colors for dark theme
  static const darkError = Color(0xFFCF6679);
  static const darkOnError = Color(0xFF000000);

  // Light Theme Colors
  static const black = Color(0xFF000000);
  static const black2 = Color(0xFF111111);
  static const black3 = Color(0xFF222222);
  static const blackAlpha30 = Color(0x4D222222); // 30% opacity
  static const blackAlpha40 = Color(0x66222222); // 40% opacity
  static const blackAlpha50 = Color(0x80222222); // 50% opacity
  static const blackAlpha80 = Color(0xCC444555); // 80% opacity
  static const blackAlpha90 = Color(0xE6456666); // 90% opacity

  static const white = Color(0xFFFFFFFF);
  static const white2 = Color(0xFFFAFAFA);
  static const white3 = Color(0xFFFFFBFE);
  static const whiteAlpha10 = Color(0x1AFFFFFF); // 10% opacity
  static const whiteAlpha20 = Color(0x33FFFFFF); // 20% opacity

  static const gray100 = Color(0xFFF9FAFB);
  static const gray200 = Color(0xFFF3F4F6);
  static const gray300 = Color(0xFFEEEEEE);
  static const gray400 = Color(0xFFE5E7EB);
  static const gray500 = Color(0xFFCCCCCC);
  static const gray600 = Color(0xFFAAAAAA);
  static const gray700 = Color(0xFF666666);
  static const gray800 = Color(0xFF49454F);
  static const gray900 = Color(0xFF374151);
  static const gray950 = Color(0xFF111827);

  static const primary = Color(0xFF247BA0); // Tu nuevo primary color
  static const primaryLight = Color(0xFFA8D0E6);
  static const primaryDark = Color(0xFF004F7A);
  static const greenDark = Color(0xFF00461A);
  static const greenLight = Color(0xFFE8F6EC);
  static const greenLightAlpha5 = Color(0x0DE8F6EC); // 5% opacity

  static const surface = Color(0xFF1C1B1F);
  static const nearBlack = Color(0xFF010101);

  static const transparent = Color(0x00000000);
  static const error = Color(0xFFB00020);

  // Colores agregados de tu lista
  static const lightGreen = Color(0xFF8BC34A); // Color para Gamepad
  // const Color.fromARGB(255, 9, 241, 86),
  // const Color.fromARGB(255, 72, 184, 75)
  static const lightGreenAccent = Color(
    0xFFCDDC39,
  ); // Color para Gamepad (Accent)

  static const blue = Color(0xFF2196F3); // Color para Sensor DHT
  static const blueAccent = Color(0xFF448AFF); // Color para Sensor DHT (Accent)
  static const red = Color(0xFFF44336); // Color para Servos
  static const redAccent = Color(0xFFFF5252); // Color para Servos (Accent)
  static const orange = Color(0xFFFF9800); // Color para Control de Luces
  static const purple = Color(0xFF9C27B0); // Color para Chat
}
