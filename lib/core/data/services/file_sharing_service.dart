// ABOUTME: Service for file sharing operations without business logic
// ABOUTME: Handles low-level file operations and platform sharing, throws exceptions for error handling in repository layer
import 'dart:io';
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileSharingService {
  /// Shares an asset file from the Flutter bundle using the platform share sheet.
  ///
  /// This method loads a file from assets, writes it to a temporary directory,
  /// and shares it using the native share sheet with proper MIME type.
  ///
  /// Parameters:
  /// - [assetPath]: Path to the asset file in the bundle (e.g., 'assets/files/example.ino')
  /// - [fileName]: Name for the shared file (e.g., 'example.ino')
  /// - [text]: Optional descriptive text to accompany the file
  /// - [subject]: Optional subject line for the share (used by email apps)
  ///
  /// Throws:
  /// - [FlutterError] if the asset is not found in the bundle
  /// - [FileSystemException] if writing to temp directory fails
  /// - [Exception] for any platform-specific sharing errors
  ///
  /// Returns [ShareResult] containing the status of the share operation.
  Future<ShareResult> shareAssetFile({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    try {
      // Load asset file from bundle
      final byteData = await rootBundle.load(assetPath);
      debugPrint('File loaded from assets: $assetPath');

      // Get temporary directory and write file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      debugPrint('File written to temp directory: $filePath');

      // Share using share_plus API (11.1.0)
      // XFile with explicit MIME type ensures maximum app compatibility
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'text/plain')],
          text: text,
          subject: subject,
        ),
      );

      debugPrint('Share result status: ${result.status}');
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error sharing file: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
