import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDatasource localDatasource;

  ChatRepositoryImpl({
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<ChatEntity>>> getChatData() async {
    try {
      final data = await localDatasource.getChatData(); // CAMBIO AQUÍ: 'data' en lugar de 'chats'
      return Right(data); // CAMBIO AQUÍ: 'data' en lugar de 'chats'
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}