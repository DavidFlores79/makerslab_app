// ABOUTME: This file contains the Settings page for app configuration
// ABOUTME: It provides theme selection and placeholder sections for future settings
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../../shared/widgets/px_back_app_bar.dart';
import '../widgets/theme_selector_widget.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = "/settings";
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const PxBackAppBar(backLabel: 'Configuración'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Theme Section
              _SectionHeader(icon: Symbols.palette, title: 'Apariencia'),
              const SizedBox(height: 12),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema de la aplicación',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona cómo quieres ver la aplicación',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const ThemeSelectorWidget(),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Notifications Section (Placeholder)
              _SectionHeader(
                icon: Symbols.notifications,
                title: 'Notificaciones',
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                child: _PlaceholderContent(
                  message: 'Configuración de notificaciones próximamente',
                ),
              ),
              const SizedBox(height: 30),

              // Language Section (Placeholder)
              _SectionHeader(icon: Symbols.language, title: 'Idioma'),
              const SizedBox(height: 12),
              _SettingsCard(
                child: _PlaceholderContent(
                  message: 'Selección de idioma próximamente',
                ),
              ),
              const SizedBox(height: 30),

              // About Section (Placeholder)
              _SectionHeader(icon: Symbols.info, title: 'Acerca de'),
              const SizedBox(height: 12),
              _SettingsCard(
                child: _PlaceholderContent(
                  message: 'Información de la aplicación próximamente',
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: child,
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  final String message;

  const _PlaceholderContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.construction,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
