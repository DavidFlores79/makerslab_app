// ABOUTME: This file provides module-specific chat themes and colors
// ABOUTME: It manages light and dark mode variants for each IoT module

import 'package:flutter/material.dart';
import '../../../../theme/app_color.dart';

/// Provides module-specific colors and theming for chat UI
class ChatThemeProvider {
  /// Module-specific color mapping
  static final Map<String, Color> moduleColors = {
    'temperature_sensor': AppColors.blue,
    'gamepad': AppColors.lightGreen,
    'servo': AppColors.red,
    'light_control': AppColors.orange,
    'chat': AppColors.purple,
  };

  /// Get the primary color for a specific module
  static Color getModuleColor(String moduleKey, {bool isDarkMode = false}) {
    final color = moduleColors[moduleKey] ?? AppColors.primary;
    return isDarkMode ? _lightenColor(color, 0.2) : color;
  }

  /// Get the background color for sent messages
  static Color getSentMessageColor(String moduleKey, {bool isDarkMode = false}) {
    return getModuleColor(moduleKey, isDarkMode: isDarkMode);
  }

  /// Get the background color for received messages
  static Color getReceivedMessageColor({bool isDarkMode = false}) {
    return isDarkMode ? AppColors.gray800 : AppColors.gray200;
  }

  /// Get text color for sent messages (always white for good contrast)
  static Color getSentMessageTextColor({bool isDarkMode = false}) {
    return Colors.white;
  }

  /// Get text color for received messages
  static Color getReceivedMessageTextColor({bool isDarkMode = false}) {
    return isDarkMode ? Colors.white : AppColors.black;
  }

  /// Get timestamp color for sent messages
  static Color getSentTimestampColor({bool isDarkMode = false}) {
    return Colors.white.withValues(alpha: 0.7);
  }

  /// Get timestamp color for received messages
  static Color getReceivedTimestampColor({bool isDarkMode = false}) {
    return isDarkMode ? AppColors.gray400 : AppColors.gray600;
  }

  /// Get background color for chat
  static Color getBackgroundColor({bool isDarkMode = false}) {
    return isDarkMode ? AppColors.surface : AppColors.white;
  }

  /// Get composer background color
  static Color getComposerBackgroundColor({bool isDarkMode = false}) {
    return isDarkMode ? AppColors.gray900 : AppColors.white;
  }

  /// Get composer text color
  static Color getComposerTextColor({bool isDarkMode = false}) {
    return isDarkMode ? AppColors.white : AppColors.black;
  }

  /// Get composer hint color
  static Color getComposerHintColor({bool isDarkMode = false}) {
    return isDarkMode ? AppColors.gray500 : AppColors.gray700;
  }

  /// Text styles for messages
  static TextStyle getMessageTextStyle({bool isDarkMode = false, required bool isSentByMe}) {
    return TextStyle(
      color: isSentByMe 
          ? getSentMessageTextColor(isDarkMode: isDarkMode)
          : getReceivedMessageTextColor(isDarkMode: isDarkMode),
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
    );
  }

  /// Text styles for timestamps
  static TextStyle getTimestampTextStyle({bool isDarkMode = false, required bool isSentByMe}) {
    return TextStyle(
      color: isSentByMe
          ? getSentTimestampColor(isDarkMode: isDarkMode)
          : getReceivedTimestampColor(isDarkMode: isDarkMode),
      fontSize: 11,
      fontWeight: FontWeight.w400,
    );
  }

  /// Lighten a color by a percentage (0.0 to 1.0)
  static Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    return Color.lerp(color, Colors.white, amount)!;
  }

  /// Darken a color by a percentage (0.0 to 1.0)
  static Color darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    return Color.lerp(color, Colors.black, amount)!;
  }

  /// iOS-style asymmetric border radius for user messages
  static BorderRadius getUserMessageBorderRadius() {
    return const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4), // Sharp corner
    );
  }

  /// iOS-style asymmetric border radius for assistant messages
  static BorderRadius getAssistantMessageBorderRadius() {
    return const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4), // Sharp corner
      bottomRight: Radius.circular(16),
    );
  }

  /// Get border radius based on who sent the message
  static BorderRadius getMessageBorderRadius({required bool isSentByMe}) {
    return isSentByMe ? getUserMessageBorderRadius() : getAssistantMessageBorderRadius();
  }

  /// Get box shadow for message bubbles
  static List<BoxShadow> getMessageShadow({bool isDarkMode = false}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
