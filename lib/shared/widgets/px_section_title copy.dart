import 'package:flutter/material.dart';

/// PXSectionTitle
/// Widget para mostrar un título principal y un subtítulo opcional.
/// Útil para encabezados como el de la pantalla de inversiones.
class PXSectionTitle extends StatelessWidget {
  const PXSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.alignment = CrossAxisAlignment.center,
    this.padding = const EdgeInsets.symmetric(vertical: 30),
  });

  final String title;
  final String subtitle;
  final CrossAxisAlignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
        ],
      ),
    );
  }
}
