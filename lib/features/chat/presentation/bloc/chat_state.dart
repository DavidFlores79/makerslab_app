import 'package:flutter_chat_core/flutter_chat_core.dart';

enum ChatStatus { initial, loading, success, failure, sending }

class ChatState {
  final ChatStatus status;
  final List<Message> messages;
  final String? errorMessage;

  ChatState({required this.status, required this.messages, this.errorMessage});

  factory ChatState.initial() =>
      ChatState(status: ChatStatus.initial, messages: []);

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
    );
  }
}
