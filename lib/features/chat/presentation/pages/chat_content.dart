import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_file_message/flyer_chat_file_message.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../theme/app_color.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatContent extends StatefulWidget {
  final String moduleKey;
  final ScrollController? externalScrollController;

  const ChatContent({
    super.key,
    required this.moduleKey,
    this.externalScrollController,
  });

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  final _chatController = InMemoryChatController();
  final String _currentUserId = 'unknownUser';
  final List<Message> _localMessages = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(StartChatSessionEvent(widget.moduleKey));
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  String? _extractSource(dynamic obj) {
    if (obj == null) return null;
    try {
      if ((obj as dynamic).toJson is Function) {
        final map = (obj as dynamic).toJson();
        if (map is Map &&
            map['source'] is String &&
            (map['source'] as String).isNotEmpty) {
          return map['source'] as String;
        }
      }
    } catch (_) {}
    try {
      final dynamic val = (obj as dynamic);
      if (val.source is String && val.source.isNotEmpty) {
        return val.source;
      }
    } catch (_) {}
    return null;
  }

  bool _isRemote(String source) {
    return source.startsWith('http://') || source.startsWith('https://');
  }

  // Seleccionar imagen
  Future<void> _handleImageSelection() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1440,
      imageQuality: 80,
    );
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    final ui.Image decoded = await decodeImageFromList(bytes);

    final msg = ImageMessage(
      id: _uuid.v4(),
      authorId: _currentUserId,
      createdAt: DateTime.now().toUtc(),
      size: bytes.length,
      width: decoded.width.toDouble(),
      height: decoded.height.toDouble(),
      // usa source (si tu package lo espera). Si tu package requiere uri, cámbialo por uri: picked.path
      source: picked.path,
    );

    _chatController.insertMessage(msg);
    _localMessages.insert(0, msg);
  }

  // Seleccionar archivo
  Future<void> _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;

    final msg = FileMessage(
      id: _uuid.v4(),
      authorId: _currentUserId,
      createdAt: DateTime.now().toUtc(),
      size: f.size,
      source: f.path ?? '',
      name: f.name,
    );

    _chatController.insertMessage(msg);
    _localMessages.insert(0, msg);
  }

  Future<User> _resolveUser(UserID id) async {
    debugPrint('Resolving user for id: $id');
    return User(id: id, name: id == _currentUserId ? 'Tú' : 'IA Bot');
  }

  void _onMessageSend(String text) {
    if (text.trim().isEmpty) return;
    final msg = TextMessage(
      id: _uuid.v4(),
      authorId: _currentUserId,
      createdAt: DateTime.now().toUtc(),
      sentAt: DateTime.now().toUtc(),
      text: text,
      // opcional: adjunta meta con moduleKey para el backend/IA
      // metadata: {'moduleKey': widget.moduleKey},
    );
    _chatController.insertMessage(msg);
    _localMessages.insert(0, msg);

    // aquí podrías invocar tu IA pasando moduleKey como contexto
  }

  void _onAttachmentTap() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text('Imagen'),
                  onTap: () => Navigator.pop(context, 'image'),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('Archivo'),
                  onTap: () => Navigator.pop(context, 'file'),
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancelar'),
                  onTap: () => Navigator.pop(context, null),
                ),
              ],
            ),
          ),
    );

    if (choice == 'image') {
      await _handleImageSelection();
    } else if (choice == 'file') {
      await _handleFileSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BlocConsumer<ChatBloc, ChatState>(
        builder: (context, state) {
          final size = MediaQuery.of(context).size;

          if (state.status == ChatStatus.messagesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ChatStatus.failure) {
            return const Center(child: Text('Error al cargar el chat'));
          }

          if (state.status == ChatStatus.messagesLoaded) {
            debugPrint('State messages: ${state.messages.length}');

            return Chat(
              chatController: _chatController,
              currentUserId: _currentUserId,
              resolveUser: _resolveUser,
              onMessageSend: _onMessageSend,
              onAttachmentTap: _onAttachmentTap,
              builders: Builders(
                textMessageBuilder: (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth:
                          size.width * 0.75, // <- ancho máximo de la burbuja
                    ),
                    child: SimpleTextMessage(message: message, index: index),
                  );
                },
                composerBuilder:
                    (context) => Composer(
                      hintText: 'Escribe un mensaje...', // <- tu nueva leyenda
                      hintColor:
                          AppColors.gray700, // opcional: color del placeholder
                      maxLines: 4,
                      sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                    ),
                imageMessageBuilder: (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  final source = _extractSource(message);
                  if (source == null || source.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  if (_isRemote(source)) {
                    // remoto -> widget oficial (cached)
                    try {
                      return FlyerChatImageMessage(
                        message: message,
                        index: index,
                      );
                    } catch (_) {
                      // si el widget oficial lanza, fallback a Image.network
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            source,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    }
                  }

                  // local path -> Image.file
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                      maxHeight: 360,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(source),
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                      ),
                    ),
                  );
                },

                fileMessageBuilder: (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  final source = _extractSource(message);
                  final name = (message as dynamic).name ?? 'archivo';

                  if (source == null || source.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  if (_isRemote(source)) {
                    try {
                      return FlyerChatFileMessage(
                        message: message,
                        index: index,
                      );
                    } catch (_) {
                      // fallback simple
                      return _localFileCard(name, source, isSentByMe);
                    }
                  }

                  // local -> render card
                  return _localFileCard(name, source, isSentByMe);
                },
              ),
            );
          }
          // Default return to satisfy non-nullable return type
          return const SizedBox.shrink();
        },
        listener: (context, state) {
          if (state.status == ChatStatus.sessionStarted) {
            context.read<ChatBloc>().add(
              LoadMessages(conversationId: state.conversationId ?? ''),
            );
          }

          if (state.status == ChatStatus.messagesLoaded) {
            debugPrint('State messages: ${state.messages.length}');

            for (final msg in state.messages) {
              // evitar duplicados
              if (!_localMessages.any((m) => m.id == msg.id)) {
                _chatController.insertMessage(msg);
                _localMessages.insert(0, msg);
              }
            }
          }
        },
      ),
    );
  }

  // pequeño helper UI para archivos locales
  Widget _localFileCard(String name, String path, bool isSentByMe) {
    return GestureDetector(
      onTap: () {
        // opción: abrir con open_filex: OpenFilex.open(path);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSentByMe ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 36),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(name, overflow: TextOverflow.ellipsis)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
