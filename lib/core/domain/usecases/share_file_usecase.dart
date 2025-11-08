import '../repositories/file_sharing_repository.dart';

class ShareFileUseCase {
  final FileSharingRepository repository;

  ShareFileUseCase(this.repository);

  Future<void> call({
    required String assetPath,
    required String fileName,
    String? text,
  }) async {
    return repository.shareAssetFile(
      assetPath: assetPath,
      fileName: fileName,
      text: text,
    );
  }
}
