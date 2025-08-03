import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

/// PXSectionTitle
/// Widget para mostrar un título principal y un subtítulo opcional.
/// Útil para encabezados como el de la pantalla de inversiones.
class PXCenteredSectionTitle extends StatelessWidget {
  const PXCenteredSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconBackground = AppColors.gray300,
    this.padding = const EdgeInsets.symmetric(vertical: 30),
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Color iconBackground;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            if (icon != null)
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBackground,
                    ),
                    child: Icon(icon),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
