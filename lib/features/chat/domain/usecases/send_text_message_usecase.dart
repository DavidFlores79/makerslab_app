import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/chat_repository.dart';

class SendTextMessageUseCase {
  final ChatRepository repository;

  SendTextMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(String authorId, String text) async {
    return await repository.sendText(authorId, text);
  }
}
