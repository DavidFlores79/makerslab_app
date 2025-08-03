import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_color.dart';
import 'px_button.dart';
import 'px_card_container.dart';
import 'px_info_box.dart';

/// common/widgets/px_action_card.dart
class PxActionCard extends StatelessWidget {
  const PxActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.infoText,
    this.buttonLabel,
    this.onButtonPressed,
    this.trailingButton, // para la ruta “avanzada”
  });

  // ────────────────────────────────────────────────────────────────────
  //  API pública (ruta básica)
  // ────────────────────────────────────────────────────────────────────
  final IconData icon;
  final String title;
  final String subtitle;
  final String infoText;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  // ────────────────────────────────────────────────────────────────────
  //  API avanzada (composición)
  //    - Si envías un [trailingButton], se ignoran [buttonLabel] y
  //      [onButtonPressed]. Útil si necesitas un PXButton con loading,
  //      un Outlined, etc.
  // ────────────────────────────────────────────────────────────────────
  final Widget? trailingButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Botón efectivo según la ruta elegida
    final Widget? effectiveButton =
        trailingButton ??
        (buttonLabel != null
            ? PXButton(label: buttonLabel!, onPressed: onButtonPressed)
            : null);

    return PxCardContainer(
      children: [
        Row(
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray400),
                color: AppColors.gray300,
              ),
              child: Icon(icon, color: AppColors.gray700, weight: 700),
            ),
            const SizedBox(width: 15),

            // Título + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            const Icon(Symbols.navigate_next),
          ],
        ),
        const SizedBox(height: 15),

        // Texto de ayuda
        PxInfoBox(text: infoText),

        // Botón (opcional)
        if (effectiveButton != null) ...[
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: effectiveButton,
          ),
        ],
      ],
    );
  }
}
