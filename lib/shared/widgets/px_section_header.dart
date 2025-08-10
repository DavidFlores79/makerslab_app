import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.padding = EdgeInsets.zero,
    this.onViewAllLabel = 'Ver todas',
  });
  final String title;
  final VoidCallback? onViewAll;
  final EdgeInsetsGeometry padding;
  final String? onViewAllLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (onViewAll != null && onViewAllLabel != null)
            TextButton(onPressed: onViewAll, child: Text(onViewAllLabel!)),
        ],
      ),
    );
  }
}
