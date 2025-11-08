// ABOUTME: This file contains the chat modal header widget
// ABOUTME: It displays module-specific branding and controls

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../features/chat/presentation/theme/chat_theme_provider.dart';

/// Custom header for chat modal with module branding
class ChatModalHeader extends StatelessWidget {
  final String moduleKey;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const ChatModalHeader({
    required this.moduleKey,
    required this.onMinimize,
    required this.onClose,
    super.key,
  });

  /// Get module-specific icon
  IconData _getModuleIcon(String key) {
    switch (key) {
      case 'temperature_sensor':
        return Symbols.thermostat;
      case 'gamepad':
        return Symbols.sports_esports;
      case 'servo':
        return Symbols.precision_manufacturing;
      case 'light_control':
        return Symbols.light_mode;
      case 'chat':
        return Symbols.smart_toy;
      default:
        return Symbols.chat;
    }
  }

  /// Get module-specific display name
  String _getModuleName(String key) {
    switch (key) {
      case 'temperature_sensor':
        return 'Sensor de Temperatura';
      case 'gamepad':
        return 'Control de Juego';
      case 'servo':
        return 'Control de Servos';
      case 'light_control':
        return 'Control de Luces';
      case 'chat':
        return 'Asistente IA';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final moduleColor = ChatThemeProvider.getModuleColor(moduleKey, isDarkMode: isDark);

    return Container(
      decoration: BoxDecoration(
        color: moduleColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Module Icon/Avatar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getModuleIcon(moduleKey),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _getModuleName(moduleKey),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            IconButton(
              icon: const Icon(Icons.expand_more, color: Colors.white),
              onPressed: onMinimize,
              tooltip: 'Minimizar',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClose,
              tooltip: 'Cerrar',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
