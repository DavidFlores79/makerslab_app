// chat_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:flyer_chat_file_message/flyer_chat_file_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:uuid/uuid.dart';

import '../../../../theme/app_color.dart';

class ChatPage extends StatefulWidget {
  static const String routeName = '/chat';
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _chatController = InMemoryChatController();
  final String _currentUserId = 'user-1';
  final List<Message> _localMessages = [];
  final _uuid = const Uuid();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  // Helper: extrae el campo 'source' si existe y es String no vacío
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

  // Enviar texto
  void _onMessageSend(String text) {
    if (text.trim().isEmpty) return;
    final msg = TextMessage(
      id: _uuid.v4(),
      authorId: _currentUserId,
      createdAt: DateTime.now().toUtc(),
      text: text,
    );
    _chatController.insertMessage(msg);
    _localMessages.insert(0, msg);
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
    return User(id: id, name: id == _currentUserId ? 'Tú' : 'IA Bot');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxBackAppBar(
        backLabel: '',
        backgroundColor: AppColors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Chat(
            builders: Builders(
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
                    return FlyerChatFileMessage(message: message, index: index);
                  } catch (_) {
                    // fallback simple
                    return _localFileCard(name, source, isSentByMe);
                  }
                }

                // local -> render card
                return _localFileCard(name, source, isSentByMe);
              },
            ),

            chatController: _chatController,
            currentUserId: _currentUserId,
            resolveUser: _resolveUser,
            onMessageSend: _onMessageSend,
            onAttachmentTap: () async {
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
            },
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   tooltip: 'Ver mensajes locales (debug)',
      //   child: const Icon(Icons.list),
      //   onPressed: () {
      //     showModalBottomSheet(
      //       context: context,
      //       builder:
      //           (_) => ListView.builder(
      //             itemCount: _localMessages.length,
      //             itemBuilder: (_, i) {
      //               final m = _localMessages[i];
      //               return ListTile(
      //                 title: Text('${m.runtimeType} — id: ${m.id}'),
      //                 subtitle: Text('authorId: ${m.authorId}'),
      //               );
      //             },
      //           ),
      //     );
      //   },
      // ),
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
