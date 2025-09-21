import 'package:flutter_chat_core/flutter_chat_core.dart';

enum ChatStatus {
  initial,
  sessionLoading,
  sessionStarted,
  messagesLoading,
  messagesLoaded,
  messageResponseReceived,
  success,
  failure,
  sending,
}

class ChatState {
  final String? conversationId;
  final ChatStatus status;
  final List<Message> messages;
  final String? errorMessage;
  final String? responseMessage;

  ChatState({
    required this.conversationId,
    required this.status,
    required this.messages,
    this.errorMessage,
    this.responseMessage,
  });

  factory ChatState.initial() => ChatState(
    conversationId: null,
    status: ChatStatus.initial,
    messages: [],
    responseMessage: null,
    errorMessage: null,
  );

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    String? errorMessage,
    String? conversationId,
    String? responseMessage,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
      responseMessage: responseMessage ?? this.responseMessage,
    );
  }
}
