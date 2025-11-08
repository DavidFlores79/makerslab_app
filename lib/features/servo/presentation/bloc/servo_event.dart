part of 'servo_bloc.dart';

abstract class ServoEvent {}

/// Inicia el monitoreo cuando el Bluetooth se conecta.
class StartMonitoring extends ServoEvent {}

/// Detiene el monitoreo cuando el Bluetooth se desconecta.
class StopMonitoring extends ServoEvent {}

/// Evento disparado por el usuario para enviar una posición final al servo.
class ServoPositionRequested extends ServoEvent {
  final double angle; // 0..180
  ServoPositionRequested({required this.angle});
}

/// Evento disparado mientras el usuario desliza el slider (preview).
/// Se puede usar para enviar previews o actualizar la UI en tiempo real.
class ServoPositionPreviewRequested extends ServoEvent {
  final double angle;
  ServoPositionPreviewRequested({required this.angle});
}

/// Evento interno: actualización de posición proveniente del stream de datos.
class _ServoPositionUpdated extends ServoEvent {
  final double angle;
  _ServoPositionUpdated(this.angle);
}

/// Evento interno: falló el stream de datos / ocurrió un error.
class _ServoStreamFailed extends ServoEvent {
  final String message;
  _ServoStreamFailed(this.message);
}
