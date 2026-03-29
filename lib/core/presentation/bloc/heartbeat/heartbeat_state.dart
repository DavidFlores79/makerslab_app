// ABOUTME: This file defines states for the HeartbeatBloc state management
// ABOUTME: It includes states for initial, loading, and loaded heartbeat preference

import 'package:equatable/equatable.dart';

abstract class HeartbeatState extends Equatable {
  const HeartbeatState();

  @override
  List<Object?> get props => [];
}

/// Initial state before preference is loaded
class HeartbeatInitial extends HeartbeatState {
  const HeartbeatInitial();
}

/// State while preference is being loaded or saved
class HeartbeatLoading extends HeartbeatState {
  const HeartbeatLoading();
}

/// State when preference is loaded successfully
class HeartbeatLoaded extends HeartbeatState {
  final bool isEnabled;

  const HeartbeatLoaded({required this.isEnabled});

  @override
  List<Object?> get props => [isEnabled];
}
