// lib/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shared/widgets/app_drawer.dart';
import 'shared/widgets/index.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static final _mainTabs = ['/home', '/investments', '/profile'];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _mainTabs.length; i++) {
      if (location.endsWith(_mainTabs[i])) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final showBottomBar = currentIndex >= 0;

    return Scaffold(
      drawer: PxAppDrawer(),
      body: child,
      bottomNavigationBar: showBottomBar ? PxBottomNavigationBar() : null,
    );
  }
}
