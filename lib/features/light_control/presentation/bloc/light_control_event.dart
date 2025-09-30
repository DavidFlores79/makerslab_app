// lib/features/light_control/presentation/bloc/light_control_event.dart
part of 'light_control_bloc.dart';

abstract class LightControlEvent {}

/// Evento para iniciar el monitoreo cuando el Bluetooth se conecta.
class StartMonitoring extends LightControlEvent {}

/// Evento para detener el monitoreo cuando el Bluetooth se desconecta.
class StopMonitoring extends LightControlEvent {}

/// Evento disparado por el usuario para encender/apagar el LED.
class LightControlToggleRequested extends LightControlEvent {}

/// Evento interno para actualizar el estado del LED a partir de los datos recibidos.
class _LightStatusUpdated extends LightControlEvent {
  final bool isLightOn;
  _LightStatusUpdated(this.isLightOn);
}

/// Evento interno para manejar errores en el stream de datos.
class _LightStreamFailed extends LightControlEvent {
  final String message;
  _LightStreamFailed(this.message);
}
