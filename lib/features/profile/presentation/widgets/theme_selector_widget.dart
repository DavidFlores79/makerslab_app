// ABOUTME: This file contains the theme selector widget with iOS-style control
// ABOUTME: It allows users to select between System, Light, and Dark themes
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/theme_preference.dart';
import '../../../../core/presentation/bloc/theme/theme_bloc.dart';
import '../../../../core/presentation/bloc/theme/theme_event.dart';
import '../../../../core/presentation/bloc/theme/theme_state.dart';

class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        ThemePreference currentMode = ThemePreference.system;

        if (state is ThemeLoaded) {
          currentMode = state.mode;
        }

        return Container(
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: CupertinoSlidingSegmentedControl<ThemePreference>(
            backgroundColor: Colors.transparent,
            thumbColor: theme.colorScheme.surface,
            groupValue: currentMode,
            onValueChanged: (ThemePreference? value) {
              if (value != null) {
                context.read<ThemeBloc>().add(ChangeThemeMode(value));
              }
            },
            children: {
              ThemePreference.system: _buildSegment(
                context,
                icon: Icons.brightness_auto,
                label: 'Sistema',
                isSelected: currentMode == ThemePreference.system,
              ),
              ThemePreference.light: _buildSegment(
                context,
                icon: Icons.light_mode,
                label: 'Claro',
                isSelected: currentMode == ThemePreference.light,
              ),
              ThemePreference.dark: _buildSegment(
                context,
                icon: Icons.dark_mode,
                label: 'Oscuro',
                isSelected: currentMode == ThemePreference.dark,
              ),
            },
          ),
        );
      },
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final color =
        isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
