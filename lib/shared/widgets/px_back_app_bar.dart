// lib/shared/widgets/px_back_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_color.dart';

class PxBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? backLabel;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;

  const PxBackAppBar({
    super.key,
    this.backLabel = 'Regresar',
    this.onBackPressed,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor:
          backgroundColor ?? (isDarkMode ? AppColors.black : AppColors.white),
      //chevron back button
      leading: Container(
        margin: EdgeInsets.only(left: 6.0),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onBackPressed ?? () => context.pop(),
          child: Icon(
            Icons.chevron_left_outlined,
            size: 50,
            color: AppColors.primary,
          ),
        ),
      ),
      title: Text(
        backLabel!,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : AppColors.black,
        ),
      ),
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    );
  }
}
