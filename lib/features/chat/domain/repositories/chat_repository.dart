import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import '../../../../core/error/failure.dart';

abstract class ChatRepository {
  /// Inicia una nueva sesión de chat.
  Future<Either<Failure, String>> startChatSession(String moduleKey);

  /// Stream de mensajes en tiempo real (local + remoto).
  Stream<List<Message>> messagesStream();

  /// Obtiene el listado de mensajes (una vez) - envuelto en Either por si falla.
  Future<Either<Failure, List<Message>>> fetchMessages(String conversationId);

  Future<Either<Failure, String>> sendMessage(
    String conversationId,
    String content,
    String imageUrl,
  );

  /// Sube un archivo al servidor y retorna la URL pública.
  Future<Either<Failure, String>> uploadFile(Uint8List bytes, String filename);

  /// Envía un texto. Devuelve Either para propagar errores.
  Future<Either<Failure, void>> sendText(String authorId, String text);

  Future<Either<Failure, void>> sendImage(String authorId, String localPath);
  Future<Either<Failure, void>> sendFile(String authorId, String localPath);
}
