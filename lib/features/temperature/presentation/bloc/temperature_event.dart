// lib/features/temperature/presentation/bloc/temperature_event.dart
import '../../domain/entities/temperature_entity.dart';

abstract class TemperatureEvent {}

// Eventos que la UI puede disparar
class StartMonitoring extends TemperatureEvent {}

class StopMonitoring extends TemperatureEvent {}

class ReadNow extends TemperatureEvent {}

// Eventos internos que el BLoC usa para procesar datos del stream
class TemperatureDataReceived extends TemperatureEvent {
  final Temperature temperature;
  TemperatureDataReceived(this.temperature);
}

class TemperatureStreamFailed extends TemperatureEvent {
  final String message;
  TemperatureStreamFailed(this.message);
}
