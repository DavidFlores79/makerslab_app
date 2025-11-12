// ABOUTME: This file contains the UploadFile use case
// ABOUTME: It uploads a file to the server and returns the public URL
import 'dart:typed_data';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/chat_repository.dart';

class UploadFile {
  final ChatRepository repository;

  UploadFile({required this.repository});

  Future<Either<Failure, String>> call(Uint8List bytes, String filename) async {
    return await repository.uploadFile(bytes, filename);
  }
}
