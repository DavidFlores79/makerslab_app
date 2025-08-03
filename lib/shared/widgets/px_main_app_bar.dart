import 'package:flutter/material.dart';
import '../../theme/app_color.dart';
import '../../utils/date_utils.dart';

class PxMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PxMainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(75); // Altura personalizada

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: 75, // Altura personalizada
      automaticallyImplyLeading: false, // Oculta el botón de retroceso
      surfaceTintColor: Colors.transparent, // Elimina el efecto de elevación
      title: Row(
        children: [
          CircleAvatar(backgroundImage: AssetImage('assets/images/woman.jpg')),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getSaludoPorHora(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              Text(
                'María González',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.gray400, height: 1),
      ),
    );
  }
}
