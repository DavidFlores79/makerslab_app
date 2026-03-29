// ABOUTME: This file implements the HeartbeatBloc for managing the heartbeat toggle preference
// ABOUTME: It handles loading and saving whether the global heartbeat (ping/pong) is enabled

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:makerslab_app/core/domain/usecases/load_heartbeat_preference_usecase.dart';
import 'package:makerslab_app/core/domain/usecases/save_heartbeat_preference_usecase.dart';
import 'heartbeat_event.dart';
import 'heartbeat_state.dart';

class HeartbeatBloc extends Bloc<HeartbeatEvent, HeartbeatState> {
  final LoadHeartbeatPreferenceUseCase loadHeartbeatUseCase;
  final SaveHeartbeatPreferenceUseCase saveHeartbeatUseCase;

  HeartbeatBloc({
    required this.loadHeartbeatUseCase,
    required this.saveHeartbeatUseCase,
  }) : super(const HeartbeatInitial()) {
    on<LoadHeartbeatPreference>(_onLoadHeartbeatPreference);
    on<ChangeHeartbeatEnabled>(_onChangeHeartbeatEnabled);
  }

  Future<void> _onLoadHeartbeatPreference(
    LoadHeartbeatPreference event,
    Emitter<HeartbeatState> emit,
  ) async {
    emit(const HeartbeatLoading());

    final result = await loadHeartbeatUseCase();

    result.fold(
      // On error, default to enabled
      (failure) => emit(const HeartbeatLoaded(isEnabled: true)),
      (enabled) => emit(HeartbeatLoaded(isEnabled: enabled)),
    );
  }

  Future<void> _onChangeHeartbeatEnabled(
    ChangeHeartbeatEnabled event,
    Emitter<HeartbeatState> emit,
  ) async {
    final result = await saveHeartbeatUseCase(event.enabled);

    result.fold(
      // If save fails, still update UI optimistically
      (failure) => emit(HeartbeatLoaded(isEnabled: event.enabled)),
      (_) => emit(HeartbeatLoaded(isEnabled: event.enabled)),
    );
  }
}
