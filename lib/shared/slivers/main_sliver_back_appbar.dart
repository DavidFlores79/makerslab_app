import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_color.dart';

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
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: BackButton(
        color: AppColors.white,
        onPressed: onBackPressed ?? () => context.pop(),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Calculamos si el SliverAppBar está colapsado
          final double percent =
              (constraints.maxHeight - kToolbarHeight) / (200 - kToolbarHeight);
          final bool isCollapsed = percent < 0.5;

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(bottom: 12),
            centerTitle: centerTitle,
            title: Text(
              backLabel,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isCollapsed ? AppColors.white : AppColors.black3,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Image.asset(assetImagePath, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
