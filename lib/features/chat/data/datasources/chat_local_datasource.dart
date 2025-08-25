import 'dart:async';

import 'package:flutter_chat_core/flutter_chat_core.dart';

abstract class LocalChatDataSource {
  Stream<List<Message>> messages();
  Future<void> saveMessage(Message message);
}
