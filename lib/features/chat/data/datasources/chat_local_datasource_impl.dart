import 'dart:async';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../datasources/chat_local_datasource.dart';

class LocalChatDataSourceImpl implements LocalChatDataSource {
  final Logger logger;
  final _controller = StreamController<List<Message>>.broadcast();
  final List<Message> _messages = [];
  final _uuid = const Uuid();

  LocalChatDataSourceImpl({Logger? logger}) : logger = logger ?? Logger() {
    // push initial empty list
    _controller.add(_messages);
    this.logger.d('LocalChatDataSource initialized');
  }

  @override
  Stream<List<Message>> messages() => _controller.stream;

  @override
  Future<void> saveMessage(Message message) async {
    try {
      // simple in-memory store; later persist to sqlite/hive if needed
      _messages.insert(0, message);
      _controller.add(List.unmodifiable(_messages));
      logger.d('Saved message locally: ${message.id}');
    } catch (e, s) {
      logger.e('Failed saving message locally', error: e, stackTrace: s);
      rethrow;
    }
  }
}
