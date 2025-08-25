import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final LocalChatDataSource localDataSource;
  final Logger logger;

  ChatRepositoryImpl({required this.localDataSource, Logger? logger})
    : logger = logger ?? Logger();

  final _uuid = const Uuid();

  @override
  Future<Either<Failure, void>> sendText(String authorId, String text) async {
    final msg = TextMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      authorId: authorId,
      createdAt: DateTime.now().toUtc(),
      text: text,
    );

    try {
      await localDataSource.saveMessage(msg);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> sendImage(
    String authorId,
    String localPath,
  ) async {
    try {
      final Uint8List bytes = await File(localPath).readAsBytes();
      final ui.Image decoded = await decodeImageFromList(bytes);

      final msg = ImageMessage(
        id: _uuid.v4(),
        authorId: authorId,
        createdAt: DateTime.now().toUtc(),
        size: bytes.length,
        width: decoded.width.toDouble(),
        height: decoded.height.toDouble(),
        source: localPath,
      );

      await localDataSource.saveMessage(msg);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> sendFile(
    String authorId,
    String localPath,
  ) async {
    try {
      final PlatformFile file = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.any)
          .then((result) => result!.files.first);

      final msg = FileMessage(
        id: _uuid.v4(),
        authorId: authorId,
        createdAt: DateTime.now().toUtc(),
        size: file.size,
        source: localPath,
        name: file.name,
      );

      await localDataSource.saveMessage(msg);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getChatData() async {
    try {
      final messages = await localDataSource.messages().first;
      return Right(messages);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Stream<List<Message>> messagesStream() {
    return localDataSource.messages();
  }
}
