import 'package:flutter_chat_core/flutter_chat_core.dart';

abstract class ChatEvent {}

class LoadMessages extends ChatEvent {}

class SendTextMessage extends ChatEvent {
  final String authorId;
  final String text;
  SendTextMessage(this.authorId, this.text);
}

class SendImageMessage extends ChatEvent {
  final String authorId;
  final String localPath;
  SendImageMessage(this.authorId, this.localPath);
}

class SendFileMessage extends ChatEvent {
  final String authorId;
  final String localPath;
  final String name;
  final int size;
  SendFileMessage(this.authorId, this.localPath, this.name, this.size);
}

class MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  MessagesUpdated(this.messages);
}
