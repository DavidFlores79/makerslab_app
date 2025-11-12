// lib/shared/widgets/px_back_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PxBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? backLabel;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final List<Widget>? actions;

  const PxBackAppBar({
    super.key,
    this.backLabel = 'Regresar',
    this.onBackPressed,
    this.backgroundColor,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      //chevron back button
      leading: Container(
        margin: EdgeInsets.only(left: 6.0),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onBackPressed ?? () => context.pop(),
          child: Icon(Icons.chevron_left_outlined, size: 40),
        ),
      ),
      title: Text(
        backLabel!,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      actions: actions,
    );
  }
}
