import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/mark_onboarding_completed_usecase.dart';
import '../../domain/usecases/should_show_onboarding_usecase.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final ShouldShowOnboardingUseCase shouldShow;
  final MarkOnboardingCompletedUseCase markCompleted;

  OnboardingBloc(this.shouldShow, this.markCompleted)
    : super(OnboardingInitial()) {
    on<LoadOnboardingStatus>(_onLoad);
    on<OnboardingCompleted>(_onComplete);
  }

  Future<void> _onLoad(
    LoadOnboardingStatus event,
    Emitter<OnboardingState> emit,
  ) async {
    final show = await shouldShow();

    print('[OnboardingBloc] shouldShow: $show');

    if (show) {
      emit(OnboardingShouldShow());
    } else {
      emit(OnboardingSkipped());
    }
  }

  Future<void> _onComplete(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint('[OnboardingBloc] onboarding completed, marking as skipped');

    await markCompleted();
    emit(OnboardingSkipped());
  }
}
