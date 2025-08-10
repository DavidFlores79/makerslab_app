import '../../domain/entities/temperature_entity.dart';

abstract class TemperaturesState {}

class InitialDataLoading extends TemperaturesState {}

class TemperaturesLoading extends TemperaturesState {}

class TemperaturesLoaded extends TemperaturesState {
  final List<TemperatureEntity>
  data; // CAMBIO AQU�: 'data' en lugar de 'investments'

  TemperaturesLoaded({
    required this.data,
  }); // CAMBIO AQU�: 'data' en lugar de 'investments'
}

class TemperaturesError extends TemperaturesState {
  final String message;
  TemperaturesError(this.message);
}
