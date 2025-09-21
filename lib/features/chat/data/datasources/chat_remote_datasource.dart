import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;

import 'package:makerslab_app/features/chat/data/models/get_messages_response.dart';
import 'package:makerslab_app/features/chat/data/models/message_model.dart';

abstract class RemoteChatDataSource {
  Future<String> startChatSession(String moduleKey);
  Future<void> sendMessage(String moduleKey, String message);
  Future<List<Message>> fetchMessages(String conversationId);
}

class ChatRemoteDataSourceImpl implements RemoteChatDataSource {
  final Dio dio;
  final Logger logger;
  final Uuid _uuid = const Uuid();
  final String _currentUserId = 'unknownUser';

  ChatRemoteDataSourceImpl({required this.dio, required this.logger}) {
    logger.d('ChatRemoteDataSource initialized');
  }

  @override
  Future<String> startChatSession(String moduleKey) async {
    final response = await dio.post(
      '/api/chat/start',
      data: {'module': moduleKey},
    );
    debugPrint('Chat session started: ${response.data}');
    return response.data['conversationId'] as String;
  }

  @override
  Future<void> sendMessage(String moduleKey, String message) async {
    try {
      await dio.post('/chat/$moduleKey/messages', data: {'message': message});
    } catch (e) {
      logger.e('Error sending message: $e');
    }
  }

  @override
  Future<List<Message>> fetchMessages(String conversationId) async {
    try {
      final response = await dio.get('/api/chat/$conversationId');
      final messages = GetMessagesResponse.fromJson(response.data).messages;

      logger.d('Fetched messages raw: $messages');

      if (messages == null) return [];

      List<Message> result = [];

      DateTime parseCreatedAt(String? s) {
        if (s == null) return DateTime.now().toUtc();
        try {
          return DateTime.parse(s).toUtc();
        } catch (_) {
          return DateTime.now().toUtc();
        }
      }

      for (final message in messages) {
        try {
          final createdAt = parseCreatedAt(message.createdAt);
          final role = (message.role ?? 'assistant');
          final authorId = role == 'user' ? _currentUserId : 'assistant';

          // every raw.content is a List<MessageContentModel>
          if (message.content != null &&
              message.content is List<MessageContentModel>) {
            for (final content in message.content!) {
              final type = (content.type ?? '').toLowerCase();

              // Normalizamos varios nombres posibles: 'input_text', 'text', 'input_image', 'image'
              if (type == 'input_text') {
                // Texto simple
                final text = content.text ?? '';
                result.add(
                  TextMessage(
                    id: _uuid.v4(),
                    text: text,
                    createdAt: createdAt,
                    authorId: authorId,
                  ),
                );
                continue;
              }

              if (type == 'input_image') {
                final imageUrl = content.imageUrl ?? '';
                if (imageUrl.isEmpty) {
                  // fallback: imagen inválida como texto
                  result.add(
                    TextMessage(
                      id: _uuid.v4(),
                      text: '[Imagen inválida]',
                      createdAt: createdAt,
                      authorId: authorId,
                    ),
                  );
                  continue;
                }

                // intentamos descargar la imagen para obtener tamaño y dimensiones (opcional)
                int? sizeInBytes;
                double? width;
                double? height;

                try {
                  final resp = await dio.get<List<int>>(
                    imageUrl,
                    options: Options(
                      responseType: ResponseType.bytes,
                      followRedirects: true,
                    ),
                  );
                  final bytes = Uint8List.fromList(resp.data ?? <int>[]);

                  sizeInBytes = bytes.length;

                  if (bytes.isNotEmpty) {
                    final codec = await ui.instantiateImageCodec(bytes);
                    final frame = await codec.getNextFrame();
                    final img = frame.image;
                    width = img.width.toDouble();
                    height = img.height.toDouble();
                  }
                } catch (e, st) {
                  // no rompemos el flujo: dejamos los campos opcionales nulos/0 y mostramos la imagen por URL
                  logger.w(
                    'No se pudo descargar/decodificar imagen $imageUrl: $e\n$st',
                  );
                }

                result.insert(
                  0,
                  ImageMessage(
                    id: _uuid.v4(),
                    authorId: authorId,
                    createdAt: createdAt,
                    // Adapta este campo: algunos paquetes esperan `uri`, `source` o `uri`.
                    source: imageUrl,
                    size: sizeInBytes ?? 0,
                    width: width ?? 0,
                    height: height ?? 0,
                    // metadata opcional
                    metadata: {'role': role},
                  ),
                );
                continue;
              }

              // Fallback: si el tipo no es reconocido, mostramos el contenido como texto (serializado)
              final fallbackText =
                  content.text ??
                  content.imageUrl ??
                  '[Contenido no procesable]';
              result.add(
                TextMessage(
                  id: _uuid.v4(),
                  text: fallbackText,
                  createdAt: createdAt,
                  authorId: authorId,
                  metadata: {'raw_content': content.toJson()},
                ),
              );
            }
          } else {
            logger.w(
              'Message content is empty for message with createdAt ${message.createdAt}',
            );
          }
        } catch (e, st) {
          logger.e('Error mapeando mensaje: $e\n$st');
          // continuamos con los demás mensajes
        }
      }

      return result;
    } catch (e, st) {
      logger.e('Error fetching messages: $e\n$st');
      return [];
    }
  }
}
