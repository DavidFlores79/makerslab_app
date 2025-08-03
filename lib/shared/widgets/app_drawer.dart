import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../theme/app_color.dart';

class PxAppDrawer extends StatelessWidget {
  const PxAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDrawer(
      menuItems: [
        DrawerMenuItem(label: 'Inicio', icon: Symbols.home, onTap: () {}),
        DrawerMenuItem(
          label: 'Sucursales',
          icon: Symbols.location_pin,
          onTap: () {},
        ),
        DrawerMenuItem(label: 'Contáctanos', icon: Symbols.mail, onTap: () {}),
        DrawerMenuItem(label: 'Síguenos', icon: Symbols.favorite, onTap: () {}),
        DrawerMenuItem(label: 'Legal', icon: Symbols.balance, onTap: () {}),
        DrawerMenuItem(label: 'Salir', icon: Symbols.logout, onTap: () {}),
      ],
      selectedIndex: 0, // opcional, resalta "Inicio"
    );
  }
}

/// Modelo de cada opción de menú
class DrawerMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const DrawerMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// Drawer estándar para iOS/Android
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.menuItems,
    this.selectedIndex,
    this.highlightColor = AppColors.greenLight, // verde claro
  });

  /// Lista de opciones que se mostrarán
  final List<DrawerMenuItem> menuItems;

  /// Índice del item actualmente activo (opcional)
  final int? selectedIndex;

  /// Color de fondo para el item seleccionado
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título fijo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Menú',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
            ),

            // Opciones
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: menuItems.length,
                // separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final item = menuItems[idx];
                  final isSelected = idx == selectedIndex;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Material(
                        color: isSelected ? highlightColor : Colors.transparent,
                        child: ListTile(
                          splashColor: AppColors.primary,
                          leading: Icon(
                            item.icon,
                            color: AppColors.gray800,
                            weight: 600,
                          ),
                          title: Text(
                            item.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.gray800,
                            ),
                          ),
                          onTap: item.onTap,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
