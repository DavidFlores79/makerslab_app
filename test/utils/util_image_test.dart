// ABOUTME: This file contains unit tests for UtilImage utility class
// ABOUTME: Tests image loading, error handling, and caching behavior

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makerslab_app/features/home/data/models/main_menu_item_model.dart';
import 'package:makerslab_app/utils/util_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  group('UtilImage.buildIcon', () {
    testWidgets('returns Icon when no assetPath or imageUrl provided',
        (WidgetTester tester) async {
      final menuItem = MainMenuItemModel(
        id: '1',
        title: 'Test',
        route: '/test',
        assetPath: null,
        imageUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      expect(find.byIcon(Icons.extension), findsOneWidget);
    });

    testWidgets('returns CachedNetworkImage for network PNG imageUrl',
        (WidgetTester tester) async {
      final menuItem = MainMenuItemModel(
        id: '1',
        title: 'Test',
        route: '/test',
        assetPath: null,
        imageUrl: 'https://example.com/image.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('returns FutureBuilder for network SVG imageUrl and shows error icon on failure',
        (WidgetTester tester) async {
      final menuItem = MainMenuItemModel(
        id: '1',
        title: 'Test',
        route: '/test',
        assetPath: null,
        imageUrl: 'https://example.com/image.svg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      // FutureBuilder starts in waiting state, showing CircularProgressIndicator
      expect(find.byType(FutureBuilder<String>), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump frames to let the future complete (will fail in test environment)
      // This tests that error handling works correctly
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 11)); // Wait past timeout
      await tester.pumpAndSettle();

      // Should show error icon when SVG fails to load (proves error handling works!)
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('respects custom size parameter', (WidgetTester tester) async {
      final menuItem = MainMenuItemModel(
        id: '1',
        title: 'Test',
        route: '/test',
        assetPath: null,
        imageUrl: null,
      );

      const customSize = 100.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem, size: customSize),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.extension));
      expect(icon.size, customSize);
    });


    testWidgets('CachedNetworkImage has error widget configured',
        (WidgetTester tester) async {
      final menuItem = MainMenuItemModel(
        id: '1',
        title: 'Test',
        route: '/test',
        assetPath: null,
        imageUrl: 'https://example.com/image.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      final cachedImage =
          tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

      expect(cachedImage.errorWidget, isNotNull);
      expect(cachedImage.placeholder, isNotNull);
    });

    testWidgets('CachedNetworkImage has disk cache size limits',
        (WidgetTester tester) async {
      final menuItem = MainMenuItemModel(
        id: '1',
        title: 'Test',
        route: '/test',
        assetPath: null,
        imageUrl: 'https://example.com/image.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      final cachedImage =
          tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

      expect(cachedImage.maxWidthDiskCache, 400);
      expect(cachedImage.maxHeightDiskCache, 400);
    });
  });
}
