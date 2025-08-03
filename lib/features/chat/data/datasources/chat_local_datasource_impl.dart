import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/chat_entity.dart';
import '../datasources/chat_local_datasource.dart';

class ChatLocalDatasourceImpl implements ChatLocalDatasource {
  final Logger logger;

  ChatLocalDatasourceImpl({required this.logger});

  @override
  Future<List<ChatEntity>> getChatData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Obteniendo chats localmente...");
      return sampleChats;
    } catch (e, stackTrace) {
      logger.e('Error getting local data for chat', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener chats locales', stackTrace);
    }
  }
}

final List<ChatEntity> sampleChats = [
  ChatEntity(id: 'chat-001'),
  ChatEntity(id: 'chat-002'),
];
