// ABOUTME: Widget tests for custom message bubble
// ABOUTME: Tests markdown rendering, link handling, and text formatting

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:makerslab_app/features/chat/presentation/widgets/custom_message_bubble.dart';

void main() {
  group('CustomTextMessageBubble - Markdown Rendering', () {
    testWidgets('should render plain text for user messages', (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'user-123',
        text: 'Hello **world**',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: true,
              moduleKey: 'test',
            ),
          ),
        ),
      );

      // Assert - Should find plain Text widget, not MarkdownBody
      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.text('Hello **world**'), findsOneWidget); // Raw markdown
    });

    testWidgets('should render formatted markdown for assistant',
        (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'assistant',
        text: '**Bold** and *italic*',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: false,
              moduleKey: 'test',
            ),
          ),
        ),
      );

      // Assert - MarkdownBody should be used for assistant messages
      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    testWidgets('should render code blocks for assistant', (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'assistant',
        text: '```dart\nvoid main() {}\n```',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: false,
              moduleKey: 'test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - MarkdownBody should render the code
      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    testWidgets('should make assistant messages selectable', (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'assistant',
        text: 'Selectable text',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: false,
              moduleKey: 'test',
            ),
          ),
        ),
      );

      // Assert
      final markdownWidget = tester.widget<MarkdownBody>(
        find.byType(MarkdownBody),
      );
      expect(markdownWidget.selectable, isTrue);
    });

    testWidgets('should apply correct text colors in light mode',
        (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'assistant',
        text: 'Test message',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: false,
              moduleKey: 'test',
            ),
          ),
        ),
      );

      // Assert - Widget should render without errors
      expect(find.byType(CustomTextMessageBubble), findsOneWidget);
    });

    testWidgets('should apply correct text colors in dark mode',
        (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'assistant',
        text: 'Test message',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: false,
              moduleKey: 'test',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CustomTextMessageBubble), findsOneWidget);
    });
  });

  group('CustomTextMessageBubble - Link Handling', () {
    testWidgets('should render links in markdown for assistant', (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'assistant',
        text: '[Click here](https://example.com)',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: false,
              moduleKey: 'test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - MarkdownBody should render the link
      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    testWidgets('should not render links for user messages', (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'user-123',
        text: '[Link](https://example.com)',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: true,
              moduleKey: 'test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should use plain Text widget
      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.text('[Link](https://example.com)'), findsOneWidget);
    });
  });

  group('CustomTextMessageBubble - Layout', () {
    testWidgets('should align user messages to the right', (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'user-123',
        text: 'User message',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: true,
              moduleKey: 'test',
            ),
          ),
        ),
      );

      // Assert - Find the Align widget and verify alignment
      final alignWidget = tester.widget<Align>(
        find.ancestor(
          of: find.text('User message'),
          matching: find.byType(Align),
        ).first,
      );
      expect(alignWidget.alignment, Alignment.centerRight);
    });

    testWidgets('should align assistant messages to the left', (tester) async {
      // Arrange
      final message = TextMessage(
        id: '1',
        authorId: 'assistant',
        text: 'Assistant message',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: false,
              moduleKey: 'test',
            ),
          ),
        ),
      );

      // Assert
      final alignWidget = tester.widget<Align>(
        find.byType(Align).first,
      );
      expect(alignWidget.alignment, Alignment.centerLeft);
    });

    testWidgets('should display timestamp', (tester) async {
      // Arrange
      final now = DateTime(2025, 11, 18, 14, 30);
      final message = TextMessage(
        id: '1',
        authorId: 'assistant',
        text: 'Message with timestamp',
        createdAt: now,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextMessageBubble(
              message: message,
              index: 0,
              isSentByMe: false,
              moduleKey: 'test',
            ),
          ),
        ),
      );

      // Assert - Should display time as HH:mm
      expect(find.text('14:30'), findsOneWidget);
    });
  });
}
