import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/chat_repository.dart';

class SendImageMessageUseCase {
  final ChatRepository repository;

  SendImageMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(String authorId, String localPath) async {
    return await repository.sendImage(authorId, localPath);
  }
}
