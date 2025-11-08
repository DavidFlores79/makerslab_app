// lib/features/light_control/presentation/bloc/light_control_state.dart
part of 'light_control_bloc.dart';

abstract class LightControlState {}

class LightControlInitial extends LightControlState {}

class LightControlLoading extends LightControlState {}

class LightControlConnected extends LightControlState {
  final bool isLightOn;
  LightControlConnected({required this.isLightOn});
}

class LightControlDisconnected extends LightControlState {}

class LightControlError extends LightControlState {
  final String message;
  LightControlError(this.message);
}
