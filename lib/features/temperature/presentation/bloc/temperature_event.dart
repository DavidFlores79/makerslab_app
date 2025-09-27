import '../../domain/entities/temperature_entity.dart';

abstract class TemperatureEvent {}

class StartScan extends TemperatureEvent {}

class SelectDevice extends TemperatureEvent {
  final String address;
  SelectDevice(this.address);
}

class StopTemperature extends TemperatureEvent {}

class ReadNowEvent extends TemperatureEvent {}

// Eventos nuevos
class TemperatureReceived extends TemperatureEvent {
  final Temperature temperature;
  TemperatureReceived(this.temperature);
}

class TemperatureStreamError extends TemperatureEvent {
  final String message;
  TemperatureStreamError(this.message);
}
