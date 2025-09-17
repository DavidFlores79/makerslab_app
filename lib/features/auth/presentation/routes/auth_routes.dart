import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/service_locator.dart';
// import '../../../notification/presentation/bloc/notification_bloc.dart';
import '../../../onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../../onboarding/presentation/screen/onboarding_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/otp/otp_bloc.dart';
import '../pages/change_password_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/login_page.dart';
import '../pages/notification_permission_request_page.dart';
import '../pages/otp_page.dart';
import '../pages/register_page.dart';
import '../pages/splash_coordinator.dart';
import '../pages/splash_view_page.dart';

final authRoutes = [
  GoRoute(
    path: SplashViewPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: SplashViewPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  GoRoute(
    path: SplashCoordinator.routeName,
    name: SplashCoordinator.routeName,
    pageBuilder: (context, state) {
      return CustomTransitionPage(
        key: state.pageKey,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<OnboardingBloc>(
              create: (_) => getIt<OnboardingBloc>(),
            ),
          ],
          child: const SplashCoordinator(),
        ),
        transitionDuration: const Duration(milliseconds: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      );
    },
  ),
  GoRoute(
    path: LoginPage.routeName,
    name: LoginPage.routeName,
    builder:
        (context, state) => BlocProvider.value(
          value: context.read<AuthBloc>(), // reutiliza el global
          child: LoginPage(),
        ),
  ),
  GoRoute(
    path: OtpPage.routeName,
    name: OtpPage.routeName,
    builder: (context, state) {
      final userId = (state.extra as Map<String, dynamic>?)?['userId'] ?? '';
      final phone = (state.extra as Map<String, dynamic>?)?['phone'] ?? '';
      final isForForgotPassword =
          (state.extra as Map<String, dynamic>?)?['isForForgotPassword'] ??
          false;

      return BlocProvider(
        create: (_) => getIt<OtpBloc>(),
        child: OtpPage(
          userId: userId,
          phone: phone,
          isForForgotPassword: isForForgotPassword,
        ),
      );
    },
  ),
  GoRoute(
    path: RegisterPage.routeName,
    name: RegisterPage.routeName,
    builder:
        (context, state) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: RegisterPage(),
        ),
  ),

  GoRoute(
    path: ChangePasswordPage.routeName,
    name: ChangePasswordPage.routeName,
    builder: (context, state) {
      final phone = (state.extra as Map<String, dynamic>?)?['phone'] ?? '';
      return BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: ChangePasswordPage(phone: phone),
      );
    },
  ),
  GoRoute(
    path: ForgotPasswordPage.routeName,
    name: ForgotPasswordPage.routeName,
    builder:
        (context, state) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: ForgotPasswordPage(),
        ),
  ),
  //Onboarding pages
  GoRoute(
    path: OnboardingPage.routeName,
    name: OnboardingPage.routeName,
    pageBuilder: (context, state) {
      return CustomTransitionPage(
        key: state.pageKey,
        child: BlocProvider<OnboardingBloc>(
          create: (_) => getIt<OnboardingBloc>(),
          child: const OnboardingPage(),
        ),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
  ),
  // GoRoute(
  //   path: NotificationPermissionRequestPage.routeName,
  //   name: NotificationPermissionRequestPage.routeName,
  //   pageBuilder: (context, state) {
  //     return CustomTransitionPage(
  //       key: state.pageKey,
  //       child: BlocProvider<NotificationBloc>(
  //         create: (_) => getIt<NotificationBloc>(),
  //         child: const NotificationPermissionRequestPage(),
  //       ),
  //       transitionDuration: const Duration(milliseconds: 700),
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         return FadeTransition(opacity: animation, child: child);
  //       },
  //     );
  //   },
  // ),
];
