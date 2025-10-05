import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../../onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../../onboarding/presentation/bloc/onboarding_event.dart';
import '../../../onboarding/presentation/bloc/onboarding_state.dart';
import '../../../onboarding/presentation/screen/onboarding_page.dart';
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

    onboardingBloc = context.read<OnboardingBloc>();
    onboardingBloc.add(LoadOnboardingStatus());
    onboardingBloc.stream.listen((_) => _tryNavigate());
  }

  void _tryNavigate() {
    if (!_isAnimationCompleted || !mounted) return;

    final onboardingState = context.read<OnboardingBloc>().state;
    if (onboardingState is OnboardingShouldShow) {
      context.go(OnboardingPage.routeName);
      return;
    }
    context.go(HomePage.routeName);
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
