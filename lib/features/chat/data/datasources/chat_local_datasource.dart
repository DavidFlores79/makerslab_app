import '../../domain/entities/chat_entity.dart';

abstract class ChatLocalDatasource {
  Future<List<ChatEntity>> getChatData();
}