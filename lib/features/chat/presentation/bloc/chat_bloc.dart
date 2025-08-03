import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../domain/usecases/get_chat_data_usecase.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final GetChatDataUseCase getChatData;

  ChatsBloc({
    required this.getChatData,
  }) : super(InitialDataLoading()) {
    on<LoadChats>(_onLoadChats);
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatsState> emit,
  ) async {
    emit(ChatsLoading());
    final result = await getChatData();
    result.fold(
      (error) => emit(ChatsError(error.message)),
      (data) => emit(ChatsLoaded(data: data)), // CAMBIO AQUÍ: 'data' en lugar de 'chats'
    );
  }
}