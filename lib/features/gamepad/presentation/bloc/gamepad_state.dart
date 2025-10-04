part of 'gamepad_bloc.dart';

abstract class GamepadState {}

class GamepadInitial extends GamepadState {}

class GamepadLoading extends GamepadState {}

/// Estado conectado. Puede contener datos de telemetría opcionales.
class GamepadConnected extends GamepadState {
  final String? lastTelemetryLine;
  GamepadConnected({this.lastTelemetryLine});
}

class GamepadDisconnected extends GamepadState {}

class GamepadError extends GamepadState {
  final String message;
  GamepadError(this.message);
}
