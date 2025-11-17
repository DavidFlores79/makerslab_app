// ABOUTME: Data model for PlatformConfig entity with JSON serialization
// ABOUTME: Handles conversion between JSON and domain entity for platform-specific configurations

import 'package:makerslab_app/features/home/domain/entities/ino_file.dart';
import 'package:makerslab_app/features/home/domain/entities/platform_config.dart';
import 'package:makerslab_app/features/home/data/models/ino_file_model.dart';
import 'package:makerslab_app/features/home/data/models/instruction_item_model.dart';
import 'package:makerslab_app/features/home/data/models/material_item_model.dart';

class PlatformConfigModel extends PlatformConfig {
  const PlatformConfigModel({
    required super.platform,
    required super.inoFile,
    required super.instructions,
    required super.materials,
  });

  factory PlatformConfigModel.fromJson(Map<String, dynamic> json) {
    try {
      return PlatformConfigModel(
        platform: InoPlatform.fromString(json['platform'] as String),
        inoFile: InoFileModel.fromJson(json['inoFile'] as Map<String, dynamic>),
        instructions: (json['instructions'] as List<dynamic>?)
                ?.map(
                  (e) =>
                      InstructionItemModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        materials: (json['materials'] as List<dynamic>?)
                ?.map((e) => MaterialItemModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e, stackTrace) {
      throw FormatException(
        'Failed to parse PlatformConfig from JSON: $e\nJSON: $json',
      );
    }
  }

  factory PlatformConfigModel.fromEntity(PlatformConfig entity) {
    return PlatformConfigModel(
      platform: entity.platform,
      inoFile: entity.inoFile,
      instructions: entity.instructions,
      materials: entity.materials,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform.displayName,
      'inoFile': InoFileModel.fromEntity(inoFile).toJson(),
      'instructions': instructions
          .map((e) => InstructionItemModel.fromEntity(e).toJson())
          .toList(),
      'materials': materials
          .map((e) => MaterialItemModel.fromEntity(e).toJson())
          .toList(),
    };
  }
}
