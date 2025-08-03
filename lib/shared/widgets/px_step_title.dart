import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

/// Widget auxiliar para los pasos numerados.
class PxStepTile extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final bool isSelected;

  const PxStepTile({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = AppColors.black3;
    final color = AppColors.gray500;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isSelected ? selectedColor : color,
        child: Text(
          '$step',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? color : selectedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: isSelected ? selectedColor : color),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: isSelected ? selectedColor : color),
      ),
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 12,
    );
  }
}
