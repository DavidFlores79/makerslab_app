import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/chat_repository.dart';

class SendMessageUsecase {
  final ChatRepository repository;

  SendMessageUsecase({required this.repository});

  Future<Either<Failure, String>> call(
    String conversationId,
    String content,
    String imageUrl,
  ) async {
    return await repository.sendMessage(conversationId, content, imageUrl);
  }
}
