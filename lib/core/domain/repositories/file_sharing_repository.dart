// ABOUTME: Repository interface for file sharing operations
// ABOUTME: Defines the contract for sharing files from assets with proper error handling using Either pattern
import 'package:dartz/dartz.dart';
import '../../error/failure.dart';

abstract class FileSharingRepository {
  Future<Either<Failure, void>> shareAssetFile({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
  });
}
