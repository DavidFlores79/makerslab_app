import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../theme/app_color.dart';

class PxBottomNavigationBar extends StatelessWidget {
  PxBottomNavigationBar({super.key});

  final routes = [HomePage.routeName, ProfilePage.routeName];
  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray400)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        indicatorColor: AppColors.primaryLight,
        onDestinationSelected: (index) {
          context.go(routes[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.home, color: AppColors.gray800),
            selectedIcon: Icon(Icons.home_filled, color: AppColors.gray800),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Symbols.person, color: AppColors.gray800),
            selectedIcon: Icon(Icons.person, color: AppColors.gray800),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    for (int i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) {
        return i;
      }
    }
    return 0;
  }
}
