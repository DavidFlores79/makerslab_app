import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flyer_chat_file_message/flyer_chat_file_message.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as fcui;

import '../../../../theme/app_color.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../theme/chat_theme_provider.dart';
import '../widgets/custom_message_bubble.dart';

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

class _ChatContentState extends State<ChatContent> with WidgetsBindingObserver {
  final _chatController = InMemoryChatController();
  final String _currentUserId = 'unknownUser';
  final List<Message> _localMessages = [];
  final _uuid = const Uuid();
  String conversationId = '';

  // Pending attachment state
  File? _pendingFile;
  Uint8List? _pendingBytes;
  int? _pendingSize;
  double? _pendingWidth;
  double? _pendingHeight;
  bool _pendingIsImage = false;
  String? _pendingName;
  String? _typingMessageId;

  // Composer measurement
  final GlobalKey _composerKey = GlobalKey();
  double _composerBottom = 16.0;
  bool _measuringComposer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ChatBloc>().add(StartChatSessionEvent(widget.moduleKey));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // keyboard / window insets changed -> re-calcular posición composer
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateComposerPosition(),
    );
  }

  // cálculo dinámico de la distancia bottom desde la pantalla al composer
  void _updateComposerPosition() {
    try {
      final ctx = _composerKey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox;
      final topLeft = box.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(ctx).size.height;
      final newBottom = screenHeight - topLeft.dy - box.size.height;

      // actualiza solo si cambió lo suficiente para evitar setState continuo
      if ((newBottom - _composerBottom).abs() > 1.0) {
        setState(() {
          _composerBottom = newBottom.clamp(0.0, screenHeight);
        });
      }
    } catch (_) {
      // ignore timing errors
    }
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

    setState(() {
      _pendingFile = File(picked.path);
      _pendingBytes = bytes;
      _pendingSize = bytes.length;
      _pendingWidth = decoded.width.toDouble();
      _pendingHeight = decoded.height.toDouble();
      _pendingIsImage = true;
      _pendingName = picked.name ?? picked.path.split('/').last;
    });

    // medir composer en siguiente frame (por si su posición cambió)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateComposerPosition(),
    );
  }

  Future<void> _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    setState(() {
      _pendingFile = File(f.path ?? '');
      _pendingBytes = f.bytes;
      _pendingSize = f.size;
      _pendingWidth = null;
      _pendingHeight = null;
      _pendingIsImage = false;
      _pendingName = f.name;
    });

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateComposerPosition(),
    );
  }

  void _removePendingAttachment() {
    setState(() {
      _pendingFile = null;
      _pendingBytes = null;
      _pendingSize = null;
      _pendingWidth = null;
      _pendingHeight = null;
      _pendingIsImage = false;
      _pendingName = null;
    });

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateComposerPosition(),
    );
  }

  Future<User> _resolveUser(UserID id) async {
    debugPrint('Resolving user for id: $id');
    return User(id: id, name: id == _currentUserId ? 'Tú' : 'IA Bot');
  }

  // Stub: implementa la subida a tu servidor / storage y retorna la URL (o null si no subes)
  Future<String?> uploadPendingFileToServer(File file) async {
    // TODO: subir a tu backend y retornar la URL pública
    return null;
  }

  void _onMessageSend(String text) async {
    final trimmed = text.trim();

    if (_pendingFile != null) {
      if (trimmed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escribe un texto para enviar con la imagen/archivo'),
          ),
        );
        return;
      }

      // intenta subir primero (opcional)
      String? source = _pendingFile!.path;
      final uploadedUrl = await uploadPendingFileToServer(_pendingFile!);
      if (uploadedUrl != null) source = uploadedUrl;

      if (_pendingIsImage) {
        final imgMsg = ImageMessage(
          id: _uuid.v4(),
          authorId: _currentUserId,
          createdAt: DateTime.now().toUtc(),
          size: _pendingSize ?? 0,
          width: _pendingWidth ?? 0,
          height: _pendingHeight ?? 0,
          source: source ?? '',
        );

        _chatController.insertMessage(imgMsg);
        _localMessages.insert(0, imgMsg);

        final textMsg = TextMessage(
          id: _uuid.v4(),
          authorId: _currentUserId,
          createdAt: DateTime.now().toUtc(),
          sentAt: DateTime.now().toUtc(),
          text: trimmed,
          metadata: {
            'attachedImageId': imgMsg.id,
            'moduleKey': widget.moduleKey,
          },
        );

        _chatController.insertMessage(textMsg);
        _localMessages.insert(0, textMsg);
      } else {
        final fileMsg = FileMessage(
          id: _uuid.v4(),
          authorId: _currentUserId,
          createdAt: DateTime.now().toUtc(),
          size: _pendingSize ?? 0,
          source: source ?? '',
          name: _pendingName ?? 'archivo',
        );

        _chatController.insertMessage(fileMsg);
        _localMessages.insert(0, fileMsg);

        final textMsg = TextMessage(
          id: _uuid.v4(),
          authorId: _currentUserId,
          createdAt: DateTime.now().toUtc(),
          sentAt: DateTime.now().toUtc(),
          text: trimmed,
          metadata: {
            'attachedFileId': fileMsg.id,
            'moduleKey': widget.moduleKey,
          },
        );

        _chatController.insertMessage(textMsg);
        _localMessages.insert(0, textMsg);
      }

      _removePendingAttachment();
      return;
    }

    if (trimmed.isEmpty) return;
    final msg = TextMessage(
      id: _uuid.v4(),
      authorId: _currentUserId,
      createdAt: DateTime.now().toUtc(),
      sentAt: DateTime.now().toUtc(),
      text: trimmed,
    );

    //send message to API
    context.read<ChatBloc>().add(
      SendMessageEvent(
        conversationId: conversationId,
        content: trimmed,
        imageUrl: '',
      ),
    );

    _chatController.insertMessage(msg);
    _localMessages.insert(0, msg);

    // 3) insertar UN placeholder "IA escribiendo" (solo 1)
    final typingId = 'typing-${_uuid.v4()}';
    final typingMsg = TextMessage(
      id: typingId,
      authorId: 'assistant',
      createdAt: DateTime.now().toUtc(),
      sentAt: DateTime.now().toUtc(),
      text: '', // vacío: renderer lo reemplaza por _threeDots
      metadata: {'isTyping': true, 'moduleKey': widget.moduleKey},
    );

    _typingMessageId = typingId;
    _chatController.insertMessage(typingMsg);
    _localMessages.insert(0, typingMsg);
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
    // Programar medición en el post-frame para detectar cambios de posición (keyboard/resize)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_measuringComposer) {
        _measuringComposer = true;
        _updateComposerPosition();
        _measuringComposer = false;
      }
    });

    return SafeArea(
      top: false,
      child: BlocConsumer<ChatBloc, ChatState>(
        builder: (context, state) {
          final size = MediaQuery.of(context).size;

          if (state.status == ChatStatus.failure) {
            return const Center(child: Text('Error al cargar el chat'));
          }

          if (state.status == ChatStatus.messagesLoaded ||
              state.status == ChatStatus.messageResponseReceived ||
              state.status == ChatStatus.sending) {
            return Stack(
              children: [
                fcui.Chat(
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
                      try {
                        final meta =
                            (message as dynamic).metadata
                                as Map<String, dynamic>?;
                        if (meta != null && meta['isTyping'] == true) {
                          final theme = Theme.of(context);
                          final isDark = theme.brightness == Brightness.dark;
                          final moduleColor = ChatThemeProvider.getModuleColor(
                            widget.moduleKey,
                            isDarkMode: isDark,
                          );
                          
                          // Mostrar typing indicator con module color
                          return Align(
                            alignment:
                                isSentByMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppColors.gray800
                                        : AppColors.gray200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _threeDots(color: moduleColor),
                            ),
                          );
                        }
                      } catch (_) {
                        // ignore
                      }

                      // Use custom message bubble
                      return CustomTextMessageBubble(
                        message: message,
                        index: index,
                        isSentByMe: isSentByMe,
                        moduleKey: widget.moduleKey,
                        groupStatus: groupStatus,
                      );
                    },

                    // Composer envuelto con key para medir su posición
                    composerBuilder: (context) {
                      return Container(
                        key: _composerKey,
                        child: fcui.Composer(
                          hintText: 'Escribe un mensaje...',
                          hintColor: AppColors.gray700,
                          maxLines: 4,
                          sendButtonVisibilityMode:
                              fcui.SendButtonVisibilityMode.always,
                        ),
                      );
                    },

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
                        try {
                          return FlyerChatImageMessage(
                            message: message,
                            index: index,
                          );
                        } catch (_) {
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.65,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                source,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        const Icon(Icons.broken_image),
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
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 48,
                                  ),
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
                          return _localFileCard(name, source, isSentByMe);
                        }
                      }

                      // local -> render card
                      return _localFileCard(name, source, isSentByMe);
                    },
                  ),
                ),

                // Preview flotante justo encima del composer (bottom medido dinámicamente)
                if (_pendingFile != null)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: (_composerBottom + 8).clamp(
                      8.0,
                      MediaQuery.of(context).size.height,
                    ),
                    child: SafeArea(
                      top: false,
                      child: _pendingAttachmentPreview(),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
        listener: (context, state) {
          if (state.status == ChatStatus.sessionStarted) {
            conversationId = state.conversationId ?? '';
            context.read<ChatBloc>().add(
              LoadMessages(conversationId: conversationId),
            );
          }

          if (state.status == ChatStatus.messageResponseReceived) {
            // 1) remover el placeholder typing si existe
            if (_typingMessageId != null) {
              try {
                final toRemove = _localMessages.firstWhere(
                  (m) => m.id == _typingMessageId,
                  // orElse: () => null,
                );
                _chatController.removeMessage(toRemove);
                _localMessages.removeWhere((m) => m.id == _typingMessageId);
              } catch (_) {}
              _typingMessageId = null;
            }

            final msg = TextMessage(
              id: _uuid.v4(),
              authorId: 'assistant',
              createdAt: DateTime.now().toUtc(),
              sentAt: DateTime.now().toUtc(),
              text: state.responseMessage ?? '',
            );
            _chatController.insertMessage(msg);
            _localMessages.insert(0, msg);
          }

          if (state.status == ChatStatus.messagesLoaded) {
            for (final msg in state.messages) {
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

  Widget _pendingAttachmentPreview() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (_pendingIsImage && _pendingFile != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 84,
                        maxHeight: 84,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pendingFile!, fit: BoxFit.cover),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.insert_drive_file, size: 48),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pendingName ?? 'Adjunto',
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pendingIsImage
                              ? '${(_pendingWidth ?? 0).toInt()}×${(_pendingHeight ?? 0).toInt()}'
                              : '${_pendingSize ?? 0} bytes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _removePendingAttachment,
          ),
        ],
      ),
    );
  }

  Widget _localFileCard(String name, String path, bool isSentByMe) {
    return GestureDetector(
      onTap: () {
        // abrir con open_filex si quieres
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

Widget _threeDots({Color? color}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(3, (i) {
      return AnimatedDot(delay: i * 150, color: color ?? AppColors.primary);
    }),
  );
}

class AnimatedDot extends StatefulWidget {
  final int delay;
  final Color color;
  const AnimatedDot({Key? key, required this.delay, required this.color})
      : super(key: key);
  @override
  State<AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _a = Tween(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _a,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
