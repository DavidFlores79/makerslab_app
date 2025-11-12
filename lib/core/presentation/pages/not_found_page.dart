// ABOUTME: This file contains the Not Found / Feature Under Construction page
// ABOUTME: Displayed when users navigate to non-existent routes

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/widgets/px_back_app_bar.dart';
import '../../../theme/app_color.dart';

class NotFoundPage extends StatelessWidget {
  static const routeName = '/not-found';

  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const PxBackAppBar(backLabel: 'Volver'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Construction icon
                Icon(
                  Symbols.construction,
                  size: 120,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  '¡En Construcción!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  'Esta función está en desarrollo.\nPronto estará disponible.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Go back button (removed since we have app bar back button)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
