import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 220,
      backgroundColor: AppColors.blackAlpha50,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        icon: const Icon(
          Symbols.chevron_left,
          size: 40,
          color: AppColors.white,
        ),
      ),
      centerTitle: centerTitle,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: centerTitle,
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Align(
          alignment:
              centerTitle ? Alignment.bottomCenter : Alignment.bottomLeft,
          child: Text(
            backLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 6,
                  color: AppColors.blackAlpha50,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(assetImagePath, fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.transparent, AppColors.blackAlpha50],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
