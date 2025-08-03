import '../../domain/entities/servo_entity.dart';

abstract class ServosState {}

class InitialDataLoading extends ServosState {}

class ServosLoading extends ServosState {}

class ServosLoaded extends ServosState {
  final List<ServoEntity> data; // CAMBIO AQUÍ: 'data' en lugar de 'investments'

  ServosLoaded({required this.data}); // CAMBIO AQUÍ: 'data' en lugar de 'investments'
}

class ServosError extends ServosState {
  final String message;
  ServosError(this.message);
}