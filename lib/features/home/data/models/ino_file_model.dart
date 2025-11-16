// ABOUTME: Data model for InoFile entity with JSON serialization
// ABOUTME: Handles conversion between JSON and domain entity for platform-specific INO files

import 'package:makerslab_app/features/home/domain/entities/ino_file.dart';

class InoFileModel extends InoFile {
  const InoFileModel({
    required super.platform,
    required super.fileName,
    required super.filePath,
    super.description,
  });

  factory InoFileModel.fromJson(Map<String, dynamic> json) {
    return InoFileModel(
      platform: InoPlatform.fromString(json['platform'] as String),
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      description: json['description'] as String?,
    );
  }

  factory InoFileModel.fromEntity(InoFile entity) {
    return InoFileModel(
      platform: entity.platform,
      fileName: entity.fileName,
      filePath: entity.filePath,
      description: entity.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform.displayName,
      'fileName': fileName,
      'filePath': filePath,
      if (description != null) 'description': description,
    };
  }
}
