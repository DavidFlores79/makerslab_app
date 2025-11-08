abstract class FileSharingRepository {
  Future<void> shareAssetFile({
    required String assetPath,
    required String fileName,
    String? text,
  });
}
