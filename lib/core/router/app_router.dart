// ABOUTME: This file contains the main application router configuration
// ABOUTME: It defines all routes for the application using GoRouter
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/features/auth/presentation/pages/splash_coordinator.dart';
import '../../di/service_locator.dart';
import '../../features/auth/presentation/routes/auth_routes.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/routes/main_static_routes.dart';
import '../../features/profile/presentation/pages/personal_data_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../main_shell.dart';
import '../presentation/pages/not_found_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: SplashCoordinator.routeName,
  errorBuilder: (context, state) => const NotFoundPage(),
  routes: [
    ...authRoutes,
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: HomePage.routeName,
          name: HomePage.routeName,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: BlocProvider<HomeBloc>(
                create: (_) => getIt<HomeBloc>(),
                child: const HomePage(),
              ),
            );
          },
        ),
        ...mainStaticRoutes,
        GoRoute(
          path: ProfilePage.routeName,
          name: ProfilePage.routeName,
          pageBuilder: (c, s) => const NoTransitionPage(child: ProfilePage()),
        ),
        GoRoute(
          path: PersonalDataPage.routeName,
          name: PersonalDataPage.routeName,
          pageBuilder:
              (c, s) => const NoTransitionPage(child: PersonalDataPage()),
        ),
        GoRoute(
          path: SettingsPage.routeName,
          name: SettingsPage.routeName,
          pageBuilder: (c, s) => const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
  ],
);
