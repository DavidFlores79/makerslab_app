import 'package:flutter_chat_core/flutter_chat_core.dart';

enum ChatStatus {
  initial,
  sessionLoading,
  sessionStarted,
  messagesLoading,
  messagesLoaded,
  success,
  failure,
  sending,
}

class ChatState {
  final String? conversationId;
  final ChatStatus status;
  final List<Message> messages;
  final String? errorMessage;

  ChatState({
    required this.conversationId,
    required this.status,
    required this.messages,
    this.errorMessage,
  });

  factory ChatState.initial() =>
      ChatState(conversationId: null, status: ChatStatus.initial, messages: []);

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    String? errorMessage,
    String? conversationId,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
    );
  }
}
