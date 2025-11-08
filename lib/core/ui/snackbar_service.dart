import 'package:flutter/material.dart';

enum SnackbarStyle { basic, withAction, withClose, withActionAndClose }

class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();

  factory SnackbarService() => _instance;

  SnackbarService._internal();

  GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void show({
    required String message,
    SnackbarStyle style = SnackbarStyle.basic,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    Color backgroundColor = Colors.black87,
    TextStyle textStyle = const TextStyle(color: Colors.white),
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    // Acción opcional
    SnackBarAction? action;
    if (style == SnackbarStyle.withAction ||
        style == SnackbarStyle.withActionAndClose) {
      action = SnackBarAction(
        label: actionLabel ?? 'Action',
        onPressed: onAction ?? () {},
        textColor: Colors.green,
      );
    }

    // Contenido con posible botón de cierre
    Widget content = Text(
      message,
      style: textStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (style == SnackbarStyle.withClose ||
        style == SnackbarStyle.withActionAndClose) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: textStyle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
        ],
      );
    }

    messenger.showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
