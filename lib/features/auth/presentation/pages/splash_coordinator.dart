import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../../onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../../onboarding/presentation/bloc/onboarding_event.dart';
import '../../../onboarding/presentation/bloc/onboarding_state.dart';
import '../../../onboarding/presentation/screen/onboarding_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';
import 'splash_view_page.dart';

class SplashCoordinator extends StatefulWidget {
  static const String routeName = "/";

  const SplashCoordinator({super.key});

  @override
  State<SplashCoordinator> createState() => _SplashCoordinatorState();
}

class _SplashCoordinatorState extends State<SplashCoordinator> {
  late final OnboardingBloc onboardingBloc;
  bool _isAnimationCompleted = false;

  @override
  void initState() {
    super.initState();

    // Obtener los blocs globales
    onboardingBloc = context.read<OnboardingBloc>();
    final authBloc = context.read<AuthBloc>();

    // Disparar solo al inicio de la app
    onboardingBloc.add(LoadOnboardingStatus());
    authBloc.add(CheckAuthStatus());

    // Escuchar streams y navegar cuando ambos estén listos
    onboardingBloc.stream.listen((_) => _tryNavigate());
    authBloc.stream.listen((_) => _tryNavigate());
  }

  void _tryNavigate() {
    if (!_isAnimationCompleted || !mounted) return;

    final onboardingState = context.read<OnboardingBloc>().state;
    final authState = context.read<AuthBloc>().state;

    if (onboardingState is OnboardingShouldShow) {
      context.go(OnboardingPage.routeName);
      return;
    }

    if (authState is Authenticated) {
      context.go(HomePage.routeName);
    } else if (authState is Unauthenticated) {
      context.go(LoginPage.routeName);
    }
    // Si está AuthLoading o AuthError, puedes mostrar un loader o mensaje
  }

  @override
  Widget build(BuildContext context) {
    return SplashViewPage(
      onAnimationCompleted: () {
        _isAnimationCompleted = true;
        _tryNavigate();
      },
    );
  }
}
