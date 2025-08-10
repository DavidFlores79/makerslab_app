import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../widgets/index.dart';

class MainSliverBackAppBar extends StatelessWidget {
  final String backLabel;
  final String assetImagePath;
  final VoidCallback? onBackPressed;
  final bool centerTitle;

  const MainSliverBackAppBar({
    super.key,
    this.backLabel = 'Regresar',
    this.onBackPressed,
    this.centerTitle = false,
    this.assetImagePath = 'assets/images/static/placeholder.png',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const expandedHeight = 220.0;
    const collapsedHeight = 80.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      pinned: true,
      backgroundColor: AppColors.white,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: BackCircleButton(
          onTap: onBackPressed ?? () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double percent =
              (constraints.maxHeight - collapsedHeight) /
              (expandedHeight - collapsedHeight);
          final bool isCollapsed = percent < 0.5;

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(bottom: 40),
            centerTitle: centerTitle,
            title: Text(
              backLabel,
              style: (isCollapsed
                      ? theme.textTheme.bodyLarge
                      : theme.textTheme.bodyLarge)
                  ?.copyWith(
                    color: isCollapsed ? AppColors.black3 : AppColors.white,
                    fontWeight: FontWeight.bold,
                    shadows:
                        isCollapsed
                            ? null
                            : [
                              Shadow(
                                color: AppColors.blackAlpha50,
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                              ),
                            ],
                  ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(assetImagePath, fit: BoxFit.cover),
                Container(color: AppColors.blackAlpha40),
              ],
            ),
          );
        },
      ),
    );
  }
}
