import 'dart:async';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/data/services/logger_service.dart';
import '../datasources/chat_local_datasource.dart';

class LocalChatDataSourceImpl implements LocalChatDataSource {
  final ILogger logger;
  final _controller = StreamController<List<Message>>.broadcast();
  final List<Message> _messages = [];
  final _uuid = const Uuid();

  LocalChatDataSourceImpl({ILogger? logger})
    : logger = logger ?? LoggerService() {
    // push initial empty list
    _controller.add(_messages);
    this.logger.info('LocalChatDataSource initialized');
  }

  @override
  Stream<List<Message>> messages() => _controller.stream;

  @override
  Future<void> saveMessage(Message message) async {
    try {
      // simple in-memory store; later persist to sqlite/hive if needed
      _messages.insert(0, message);
      _controller.add(List.unmodifiable(_messages));
      logger.info('Saved message locally: ${message.id}');
    } catch (e, s) {
      logger.error('Failed saving message locally', e, s);
      rethrow;
    }
  }
}
