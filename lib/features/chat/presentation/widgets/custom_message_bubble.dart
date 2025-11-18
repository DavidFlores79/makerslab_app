// ABOUTME: This file contains custom message bubble widgets with markdown support
// ABOUTME: It renders plain text for user messages and formatted markdown for assistant messages

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final isAssistant = message.authorId == 'assistant';

    // Get colors from theme provider
    final backgroundColor =
        isSentByMe
            ? ChatThemeProvider.getSentMessageColor(
              moduleKey,
              isDarkMode: isDark,
            )
            : ChatThemeProvider.getReceivedMessageColor(isDarkMode: isDark);

    final textColor =
        isSentByMe
            ? ChatThemeProvider.getSentMessageTextColor(isDarkMode: isDark)
            : ChatThemeProvider.getReceivedMessageTextColor(isDarkMode: isDark);

    final timestampColor =
        isSentByMe
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
          borderRadius: ChatThemeProvider.getMessageBorderRadius(
            isSentByMe: isSentByMe,
          ),
          boxShadow: ChatThemeProvider.getMessageShadow(isDarkMode: isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message content - Markdown for assistant, plain text for user
            if (isAssistant)
              MarkdownBody(
                data: message.text,
                shrinkWrap: true,
                selectable: true, // Allow text selection for copying
                styleSheet: MarkdownStyleSheet(
                  // Paragraph
                  p: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: textColor,
                  ),
                  // Headings
                  h1: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  h2: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  h3: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  // Lists
                  listBullet: TextStyle(fontSize: 15, color: textColor),
                  // Code
                  code: TextStyle(
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[200],
                    color: isDark ? Colors.lightGreen[300] : Colors.green[800],
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // Links
                  a: TextStyle(
                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                    decoration: TextDecoration.underline,
                  ),
                  // Blockquotes
                  blockquote: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                        width: 4,
                      ),
                    ),
                  ),
                ),
                onTapLink: (text, href, title) => _handleLinkTap(context, href),
              )
            else
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

  /// Handle link taps with confirmation dialog for security
  Future<void> _handleLinkTap(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;

    // Show confirmation dialog before opening external links
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Abrir enlace'),
            content: Text('¿Deseas abrir este enlace?\n\n$url'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Abrir'),
              ),
            ],
          ),
    );

    if (shouldOpen == true) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Format timestamp as HH:mm
  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
