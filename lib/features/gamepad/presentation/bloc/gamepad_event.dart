part of 'gamepad_bloc.dart';

abstract class GamepadEvent {}

/// Inicia el monitoreo cuando el Bluetooth se conecta.
class StartMonitoring extends GamepadEvent {}

/// Detiene el monitoreo cuando el Bluetooth se desconecta.
class StopMonitoring extends GamepadEvent {}

/// Evento disparado por el joystick al cambiar dirección.
/// `command` es la cadena ya formateada para enviar por bluetooth (ej. "B01", "S00", etc).
class GamepadDirectionChanged extends GamepadEvent {
  final String command;
  GamepadDirectionChanged({required this.command});
}

/// Evento disparado al presionar un botón del gamepad.
/// `code` es la cadena formateada a enviar (ej. "Y00", "A00", "L02", etc).
class GamepadButtonPressed extends GamepadEvent {
  final String code;
  GamepadButtonPressed({required this.code});
}

/// Evento opcional para forzar un Stop (por ejemplo cuando joystick se suelta).
class GamepadStopRequested extends GamepadEvent {}

/// Evento interno: datos recibidos del stream (línea parseada).
class _GamepadStreamReceived extends GamepadEvent {
  final String line;
  _GamepadStreamReceived(this.line);
}

/// Evento interno: falló el stream de datos.
class _GamepadStreamFailed extends GamepadEvent {
  final String message;
  _GamepadStreamFailed(this.message);
}
