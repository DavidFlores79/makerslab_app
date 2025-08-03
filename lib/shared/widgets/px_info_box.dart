import 'package:flutter/material.dart';
import '../../theme/app_color.dart';

class PxInfoBox extends StatelessWidget {
  final String text;
  final int maxLines;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const PxInfoBox({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 35),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.gray200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style:
            textStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
