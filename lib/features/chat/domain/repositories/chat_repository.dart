import 'package:dartz/dartz.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import '../../../../core/error/failure.dart';

abstract class ChatRepository {
  /// Stream de mensajes en tiempo real (local + remoto).
  Stream<List<Message>> messagesStream();

  /// Obtiene el listado de mensajes (una vez) - envuelto en Either por si falla.
  Future<Either<Failure, List<Message>>> getChatData();

  /// Envía un texto. Devuelve Either para propagar errores.
  Future<Either<Failure, void>> sendText(String authorId, String text);

  Future<Either<Failure, void>> sendImage(String authorId, String localPath);
  Future<Either<Failure, void>> sendFile(String authorId, String localPath);
}
