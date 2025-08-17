import 'dart:io';
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/file_sharing_repository.dart';

class FileSharingService implements FileSharingRepository {
  @override
  Future<void> shareAssetFile({
    required String assetPath,
    required String fileName,
    String? text,
  }) async {
    // Cargar archivo desde assets
    final byteData = await rootBundle.load(assetPath);

    // Guardarlo en temporal
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    // Compartir
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text, title: text),
    );

    if (result.status == ShareResultStatus.success) {
      debugPrint('File shared successfully!');
    }
  }
}
