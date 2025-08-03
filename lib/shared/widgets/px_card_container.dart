import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

//TODO: Container background color depens on darkMode
class PxCardContainer extends StatelessWidget {
  final List<Widget> children;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const PxCardContainer({
    super.key,
    required this.children,
    this.backgroundColor = AppColors.white,
    this.margin = EdgeInsets.zero,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gray400),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
