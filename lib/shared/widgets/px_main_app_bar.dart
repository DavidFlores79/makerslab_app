import 'dart:ui';
import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../../utils/date_utils.dart';

class PxMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName; // null si no está registrado
  final String? userImage; // null si no hay imagen

  const PxMainAppBar({super.key, this.userName, this.userImage});

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoggedIn = userName != null && userName!.isNotEmpty;

    return AppBar(
      toolbarHeight: 90,
      backgroundColor: AppColors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: AppColors.white.withOpacity(0.3)),
        ),
      ),
      title:
          isLoggedIn
              ? Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage(
                      userImage ?? 'assets/images/default_avatar.png',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.waving_hand_rounded,
                            color: AppColors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            waveMeByHour(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        userName!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    color: AppColors.orange,
                    size: 30,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    waveMeByHour(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
    );
  }
}
