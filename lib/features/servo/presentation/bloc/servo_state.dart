part of 'servo_bloc.dart';

abstract class ServoState {}

class ServoInitial extends ServoState {}

class ServoLoading extends ServoState {}

/// Estado conectado, con la posición actual del servo (0..180).
class ServoConnected extends ServoState {
  final double position;
  ServoConnected({required this.position});
}

class ServoDisconnected extends ServoState {}

class ServoError extends ServoState {
  final String message;
  ServoError(this.message);
}
