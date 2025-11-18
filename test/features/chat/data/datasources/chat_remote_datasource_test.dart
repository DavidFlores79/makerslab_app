// ABOUTME: Unit tests for chat remote datasource
// ABOUTME: Tests message ordering, content type mapping, and API response parsing

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:makerslab_app/core/data/services/logger_service.dart';
import 'package:makerslab_app/features/chat/data/datasources/chat_remote_datasource.dart';

import 'chat_remote_datasource_test.mocks.dart';

@GenerateMocks([Dio, ILogger])
void main() {
  late ChatRemoteDataSourceImpl dataSource;
  late MockDio mockDio;
  late MockILogger mockLogger;

  setUp(() {
    mockDio = MockDio();
    mockLogger = MockILogger();
    dataSource = ChatRemoteDataSourceImpl(dio: mockDio, logger: mockLogger);
  });

  group('ChatRemoteDataSource - Message Ordering', () {
    test('should preserve API order: text then image', () async {
      // Arrange
      final mockResponse = {
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "input_text", "text": "Look at this"},
              {
                "type": "input_image",
                "image_url": "https://example.com/img.jpg",
              },
            ],
            "createdAt": "2025-11-18T02:00:00Z",
          },
        ],
      };

      when(mockDio.get('/api/chat/conv-id')).thenAnswer(
        (_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/chat/conv-id'),
        ),
      );

      // Mock image download to avoid actual network call
      when(
        mockDio.get<List<int>>(
          'https://example.com/img.jpg',
          options: anyNamed('options'),
        ),
      ).thenThrow(Exception('Network error')); // Simulate download failure

      // Act
      final result = await dataSource.fetchMessages('conv-id');

      // Assert
      expect(result.length, 2);
      expect(result[0], isA<TextMessage>());
      expect((result[0] as TextMessage).text, 'Look at this');
      expect(result[1], isA<ImageMessage>());
      expect((result[1] as ImageMessage).source, 'https://example.com/img.jpg');
    });

    test('should preserve API order: image then text', () async {
      // Arrange
      final mockResponse = {
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "input_image",
                "image_url": "https://example.com/img.jpg",
              },
              {"type": "input_text", "text": "What do you see?"},
            ],
            "createdAt": "2025-11-18T02:00:00Z",
          },
        ],
      };

      when(mockDio.get('/api/chat/conv-id')).thenAnswer(
        (_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/chat/conv-id'),
        ),
      );

      when(
        mockDio.get<List<int>>(
          'https://example.com/img.jpg',
          options: anyNamed('options'),
        ),
      ).thenThrow(Exception('Network error'));

      // Act
      final result = await dataSource.fetchMessages('conv-id');

      // Assert
      expect(result.length, 2);
      expect(result[0], isA<ImageMessage>());
      expect(result[1], isA<TextMessage>());
      expect((result[1] as TextMessage).text, 'What do you see?');
    });

    test('should preserve order with multiple mixed messages', () async {
      // Arrange
      final mockResponse = {
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "input_text", "text": "First text"},
              {"type": "input_image", "image_url": "https://example.com/1.jpg"},
              {"type": "input_text", "text": "Second text"},
              {"type": "input_image", "image_url": "https://example.com/2.jpg"},
            ],
            "createdAt": "2025-11-18T02:00:00Z",
          },
        ],
      };

      when(mockDio.get('/api/chat/conv-id')).thenAnswer(
        (_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/chat/conv-id'),
        ),
      );

      // Mock image downloads to fail gracefully
      when(
        mockDio.get<List<int>>(
          argThat(contains('example.com')),
          options: anyNamed('options'),
        ),
      ).thenThrow(Exception('Network error'));

      // Act
      final result = await dataSource.fetchMessages('conv-id');

      // Assert
      expect(result.length, 4);
      expect(result[0], isA<TextMessage>());
      expect((result[0] as TextMessage).text, 'First text');
      expect(result[1], isA<ImageMessage>());
      expect(result[2], isA<TextMessage>());
      expect((result[2] as TextMessage).text, 'Second text');
      expect(result[3], isA<ImageMessage>());
    });

    test('should handle empty content list gracefully', () async {
      // Arrange
      final mockResponse = {
        "messages": [
          {
            "role": "user",
            "content": [],
            "createdAt": "2025-11-18T02:00:00Z",
          },
        ],
      };

      when(mockDio.get('/api/chat/conv-id')).thenAnswer(
        (_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/chat/conv-id'),
        ),
      );

      // Act
      final result = await dataSource.fetchMessages('conv-id');

      // Assert
      expect(result, isEmpty);
    });

    test('should map assistant messages correctly', () async {
      // Arrange
      final mockResponse = {
        "messages": [
          {
            "role": "assistant",
            "content": [
              {"type": "input_text", "text": "AI response here"},
            ],
            "createdAt": "2025-11-18T02:00:00Z",
          },
        ],
      };

      when(mockDio.get('/api/chat/conv-id')).thenAnswer(
        (_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/chat/conv-id'),
        ),
      );

      // Act
      final result = await dataSource.fetchMessages('conv-id');

      // Assert
      expect(result.length, 1);
      expect(result[0], isA<TextMessage>());
      expect((result[0] as TextMessage).authorId, 'assistant');
      expect((result[0] as TextMessage).text, 'AI response here');
    });
  });
}
