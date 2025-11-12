import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:makerslab_app/core/app_keys.dart';

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
    final isDarkMode = theme.brightness == Brightness.dark;

    return AppBar(
      toolbarHeight: 90,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color:
                isDarkMode
                    ? theme.colorScheme.surface.withValues(alpha: 0.7)
                    : theme.colorScheme.surface.withValues(alpha: 0.3),
          ),
        ),
      ),
      title:
          isLoggedIn
              ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        userImage != null && userImage!.isNotEmpty
                            ? (userImage!.startsWith('http')
                                ? NetworkImage(userImage!) as ImageProvider
                                : AssetImage(userImage!))
                            : const AssetImage(
                              'assets/images/default_avatar.png',
                            ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.waving_hand_rounded,
                            color:
                                isDarkMode
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFFFF9800),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            waveMeByHour(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
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
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
                  ),
                  Icon(
                    Icons.waving_hand_rounded,
                    color:
                        isDarkMode
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFFFF9800),
                    size: 30,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    waveMeByHour(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
    );
  }
}
