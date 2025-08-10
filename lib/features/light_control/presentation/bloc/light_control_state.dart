import '../../domain/entities/light_control_entity.dart';

abstract class LightControlsState {}

class InitialDataLoading extends LightControlsState {}

class LightControlsLoading extends LightControlsState {}

class LightControlsLoaded extends LightControlsState {
  final List<LightControlEntity>
  data; // CAMBIO AQU�: 'data' en lugar de 'investments'

  LightControlsLoaded({
    required this.data,
  }); // CAMBIO AQU�: 'data' en lugar de 'investments'
}

class LightControlsError extends LightControlsState {
  final String message;
  LightControlsError(this.message);
}
