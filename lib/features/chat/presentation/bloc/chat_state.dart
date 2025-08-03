import '../../domain/entities/chat_entity.dart';

abstract class ChatsState {}

class InitialDataLoading extends ChatsState {}

class ChatsLoading extends ChatsState {}

class ChatsLoaded extends ChatsState {
  final List<ChatEntity> data; // CAMBIO AQUÍ: 'data' en lugar de 'investments'

  ChatsLoaded({required this.data}); // CAMBIO AQUÍ: 'data' en lugar de 'investments'
}

class ChatsError extends ChatsState {
  final String message;
  ChatsError(this.message);
}