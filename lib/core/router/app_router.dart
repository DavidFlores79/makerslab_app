import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../di/service_locator.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/routes/main_static_routes.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../main_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
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
          name: 'profile',
          pageBuilder: (c, s) => const NoTransitionPage(child: ProfilePage()),
        ),
      ],
    ),
  ],
);
