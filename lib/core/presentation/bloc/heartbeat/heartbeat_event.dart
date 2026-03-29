// ABOUTME: This file defines events for the HeartbeatBloc state management
// ABOUTME: It includes events for loading and toggling the heartbeat preference

import 'package:equatable/equatable.dart';

abstract class HeartbeatEvent extends Equatable {
  const HeartbeatEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the saved heartbeat preference from storage
class LoadHeartbeatPreference extends HeartbeatEvent {
  const LoadHeartbeatPreference();
}

/// Event to change and save the heartbeat enabled state
class ChangeHeartbeatEnabled extends HeartbeatEvent {
  final bool enabled;

  const ChangeHeartbeatEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
