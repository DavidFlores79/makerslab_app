import '../../domain/entities/temperature_entity.dart';

abstract class TemperatureState {}

class TempInitial extends TemperatureState {}

class TempLoading extends TemperatureState {}

class TempConnecting extends TemperatureState {}

class TempConnected extends TemperatureState {
  final Temperature latest;
  final List<Temperature> history;
  TempConnected({required this.latest, required this.history});
}

class TempDisconnected extends TemperatureState {}

class TempError extends TemperatureState {
  final String message;
  TempError(this.message);
}
