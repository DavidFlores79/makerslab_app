import '../../domain/entities/gamepad_entity.dart';

abstract class GamepadsState {}

class InitialDataLoading extends GamepadsState {}

class GamepadsLoading extends GamepadsState {}

class GamepadsLoaded extends GamepadsState {
  final List<GamepadEntity>
  data; // CAMBIO AQU�: 'data' en lugar de 'investments'

  GamepadsLoaded({
    required this.data,
  }); // CAMBIO AQU�: 'data' en lugar de 'investments'
}

class GamepadsError extends GamepadsState {
  final String message;
  GamepadsError(this.message);
}
