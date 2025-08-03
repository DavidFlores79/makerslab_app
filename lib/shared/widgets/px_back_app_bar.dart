// lib/shared/widgets/px_back_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_color.dart';

class PxBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? backLabel;
  final VoidCallback? onBackPressed;

  const PxBackAppBar({
    super.key,
    this.backLabel = 'Regresar',
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AppBar(
      leading: BackButton(
        color: isDarkMode ? Colors.white : AppColors.black,
        onPressed: onBackPressed ?? () => context.pop(),
      ),
      title: Text(
        backLabel!,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : AppColors.black,
        ),
      ),
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.gray400),
      ),
    );
  }
}
