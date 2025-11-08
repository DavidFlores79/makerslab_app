import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/chat_repository.dart';

class StartChatSessionUseCase {
  final ChatRepository repository;

  StartChatSessionUseCase({required this.repository});

  Future<Either<Failure, String>> call(String moduleKey) {
    return repository.startChatSession(moduleKey);
  }
}
