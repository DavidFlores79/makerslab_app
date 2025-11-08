// ABOUTME: This file contains custom message bubble widgets
// ABOUTME: It implements iOS-style asymmetric corners for chat messages

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import '../theme/chat_theme_provider.dart';

/// Custom text message bubble with iOS-style asymmetric corners
class CustomTextMessageBubble extends StatelessWidget {
  final TextMessage message;
  final int index;
  final bool isSentByMe;
  final String moduleKey;
  final MessageGroupStatus? groupStatus;

  const CustomTextMessageBubble({
    required this.message,
    required this.index,
    required this.isSentByMe,
    required this.moduleKey,
    this.groupStatus,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get colors from theme provider
    final backgroundColor = isSentByMe
        ? ChatThemeProvider.getSentMessageColor(moduleKey, isDarkMode: isDark)
        : ChatThemeProvider.getReceivedMessageColor(isDarkMode: isDark);

    final textColor = isSentByMe
        ? ChatThemeProvider.getSentMessageTextColor(isDarkMode: isDark)
        : ChatThemeProvider.getReceivedMessageTextColor(isDarkMode: isDark);

    final timestampColor = isSentByMe
        ? ChatThemeProvider.getSentTimestampColor(isDarkMode: isDark)
        : ChatThemeProvider.getReceivedTimestampColor(isDarkMode: isDark);

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: ChatThemeProvider.getMessageBorderRadius(isSentByMe: isSentByMe),
          boxShadow: ChatThemeProvider.getMessageShadow(isDarkMode: isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message text
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            // Timestamp
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatTimestamp(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: timestampColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format timestamp as HH:mm
  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
