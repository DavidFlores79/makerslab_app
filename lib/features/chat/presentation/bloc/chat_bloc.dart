import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/failure.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_chat_data_usecase.dart';
import '../../domain/usecases/send_file_message_usecase.dart';
import '../../domain/usecases/send_image_message_usecase.dart';
import '../../domain/usecases/send_text_message_usecase.dart';
import '../../domain/usecases/start_chat_session_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository; // para mensajes en tiempo real (stream)
  final GetChatDataUseCase getChatDataUseCase;
  final SendTextMessageUseCase sendTextUseCase;
  final SendImageMessageUseCase sendImageUseCase;
  final SendFileMessageUseCase sendFileUseCase;
  final StartChatSessionUseCase startChatSession;
  final Logger logger;

  final InMemoryChatController chatController = InMemoryChatController();

  StreamSubscription<List<Message>>? _messagesSub;

  ChatBloc({
    required this.repository,
    required this.startChatSession,
    required this.getChatDataUseCase,
    required this.sendTextUseCase,
    required this.sendImageUseCase,
    required this.sendFileUseCase,
    Logger? logger,
  }) : logger = logger ?? Logger(),
       super(ChatState.initial()) {
    on<StartChatSessionEvent>(_onStartChatSession);
    on<LoadMessages>(_onInit);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<SendTextMessage>(_onSendText);
    on<SendImageMessage>(_onSendImage);
    on<SendFileMessage>(_onSendFile);
  }

  Future<void> _onStartChatSession(
    StartChatSessionEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.sessionLoading));
    final Either<Failure, String> res = await startChatSession(event.moduleKey);
    res.fold(
      (failure) {
        logger.e('StartChatSession failed: ${failure.message}');
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (conversationId) {
        emit(
          state.copyWith(
            status: ChatStatus.sessionStarted,
            conversationId: conversationId,
          ),
        );
      },
    );
  }

  Future<void> _onInit(LoadMessages event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.messagesLoading));
    // 1) cargar snapshot inicial
    final Either<Failure, List<Message>> res = await getChatDataUseCase(
      state.conversationId ?? '',
    );
    res.fold(
      (failure) {
        logger.e('InitChat: getChatData failed: ${failure.message}');
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (messages) {
        // actualizar estado y el chatController
        _pushMessagesToController(messages);
        emit(
          state.copyWith(status: ChatStatus.messagesLoaded, messages: messages),
        );
      },
    );

    // 2) suscribirse al stream en tiempo real (local/remote combinado por el repo)
    await _messagesSub?.cancel();
    _messagesSub = repository.messagesStream().listen((messages) {
      add(MessagesUpdated(messages));
    });
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    // Actualiza UI internamente y en estado
    _pushMessagesToController(event.messages);
    emit(state.copyWith(status: ChatStatus.success, messages: event.messages));
  }

  Future<void> _onSendText(
    SendTextMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.sending));
    final Either<Failure, void> res = await sendTextUseCase(
      event.authorId,
      event.text,
    );
    res.fold(
      (failure) {
        logger.e('sendText failed: ${failure.message}');
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (_) {
        // La persistencia local dentro del repo usará messagesStream() para notificar al Bloc
        emit(state.copyWith(status: ChatStatus.success));
      },
    );
  }

  Future<void> _onSendImage(
    SendImageMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.sending));
    final Either<Failure, void> res = await sendImageUseCase(
      event.authorId,
      event.localPath,
    );
    res.fold(
      (failure) {
        logger.e('sendImage failed: ${failure.message}');
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (_) {
        emit(state.copyWith(status: ChatStatus.success));
      },
    );
  }

  Future<void> _onSendFile(
    SendFileMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.sending));
    final Either<Failure, void> res = await sendFileUseCase(
      event.authorId,
      event.localPath,
    );
    res.fold(
      (failure) {
        logger.e('sendFile failed: ${failure.message}');
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (_) {
        emit(state.copyWith(status: ChatStatus.success));
      },
    );
  }

  void _pushMessagesToController(List<Message> messages) {
    // Insertamos en el controller para que flutter_chat_ui las muestre.
    // Insertamos en orden inverso (asumiendo que messages[0] es el más reciente)
    try {
      for (final m in messages.reversed) {
        try {
          chatController.insertMessage(m);
        } catch (_) {
          // Si ya existe o falla, ignoramos; topic de deduplicación puede mejorarse si es necesario.
        }
      }
    } catch (e, s) {
      logger.w('pushMessagesToController failed', error: e, stackTrace: s);
    }
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    try {
      chatController.dispose();
    } catch (_) {}
    return super.close();
  }
}
