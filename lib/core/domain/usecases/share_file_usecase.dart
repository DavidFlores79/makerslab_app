// ABOUTME: Use case for sharing asset files via platform share sheet
// ABOUTME: Orchestrates file sharing through the repository layer following Clean Architecture principles
import 'package:dartz/dartz.dart';
import '../../error/failure.dart';
import '../repositories/file_sharing_repository.dart';

class ShareFileUseCase {
  final FileSharingRepository repository;

  ShareFileUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    return repository.shareAssetFile(
      assetPath: assetPath,
      fileName: fileName,
      text: text,
      subject: subject,
    );
  }
}
