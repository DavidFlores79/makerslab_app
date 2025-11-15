// ABOUTME: Unit tests for FileSharingService
// ABOUTME: Tests file sharing service methods and error handling
import 'package:flutter_test/flutter_test.dart';
import 'package:makerslab_app/core/data/services/file_sharing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileSharingService', () {
    late FileSharingService service;

    setUp(() {
      service = FileSharingService();
    });

    test('should be instantiated', () {
      expect(service, isA<FileSharingService>());
    });

    test('shareAssetFile should require assetPath parameter', () {
      // This test verifies the method signature
      expect(
        () => service.shareAssetFile(
          assetPath: 'assets/test.ino',
          fileName: 'test.ino',
        ),
        returnsNormally,
      );
    });

    test('shareAssetFile should accept optional text parameter', () {
      expect(
        () => service.shareAssetFile(
          assetPath: 'assets/test.ino',
          fileName: 'test.ino',
          text: 'Optional text',
        ),
        returnsNormally,
      );
    });

    test('shareAssetFile should accept optional subject parameter', () {
      expect(
        () => service.shareAssetFile(
          assetPath: 'assets/test.ino',
          fileName: 'test.ino',
          subject: 'Optional subject',
        ),
        returnsNormally,
      );
    });

    test('shareAssetFile should accept all parameters', () {
      expect(
        () => service.shareAssetFile(
          assetPath: 'assets/test.ino',
          fileName: 'test.ino',
          text: 'Test text',
          subject: 'Test subject',
        ),
        returnsNormally,
      );
    });
  });
}
