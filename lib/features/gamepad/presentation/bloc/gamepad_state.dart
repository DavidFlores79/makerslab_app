part of 'gamepad_bloc.dart';

abstract class GamepadState {}

class GamepadInitial extends GamepadState {}

class GamepadLoading extends GamepadState {}

/// Estado conectado. Puede contener datos de telemetría opcionales.
class GamepadConnected extends GamepadState {
  final String? lastTelemetryLine;

  /// Último comando enviado al dispositivo (ej. "B01", "S00").
  final String lastSentCommand;

  /// Alterna en cada actualización para que BlocListener detecte el pulso.
  final bool heartbeatBeat;

  GamepadConnected({
    this.lastTelemetryLine,
    this.lastSentCommand = 'S00',
    this.heartbeatBeat = false,
  });
}

class GamepadDisconnected extends GamepadState {}

class GamepadError extends GamepadState {
  final String message;
  GamepadError(this.message);
}
