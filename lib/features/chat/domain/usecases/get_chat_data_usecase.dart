import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChatDataUseCase {
  final ChatRepository repository;

  GetChatDataUseCase(this.repository);

  Future<Either<Failure, List<ChatEntity>>> call() async {
    return await repository.getChatData();
  }
}