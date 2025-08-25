import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/chat_repository.dart';

class SendFileMessageUseCase {
  final ChatRepository repository;

  SendFileMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(String authorId, String localPath) async {
    return await repository.sendFile(authorId, localPath);
  }
}
