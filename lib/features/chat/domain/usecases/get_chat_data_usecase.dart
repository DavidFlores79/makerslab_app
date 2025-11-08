import 'package:dartz/dartz.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import '../../../../core/error/failure.dart';
import '../repositories/chat_repository.dart';

class GetChatDataUseCase {
  final ChatRepository repository;

  GetChatDataUseCase(this.repository);

  Future<Either<Failure, List<Message>>> call(String conversationId) async {
    return await repository.fetchMessages(conversationId);
  }
}
