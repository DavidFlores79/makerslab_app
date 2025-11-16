// ABOUTME: Data model for ModuleDetail entity with JSON serialization
// ABOUTME: Handles conversion between JSON and domain entity for complete module information

import 'package:makerslab_app/features/home/domain/entities/module_detail.dart';
import 'package:makerslab_app/features/home/data/models/ino_file_model.dart';
import 'package:makerslab_app/features/home/data/models/instruction_item_model.dart';
import 'package:makerslab_app/features/home/data/models/material_item_model.dart';

class ModuleDetailModel extends ModuleDetail {
  const ModuleDetailModel({
    required super.id,
    required super.title,
    required super.description,
    required super.route,
    required super.interfaceRoute,
    required super.instructions,
    required super.materials,
    required super.inoFiles,
    super.image,
    super.videoId,
    super.chatModuleKey,
  });

  factory ModuleDetailModel.fromJson(Map<String, dynamic> json) {
    return ModuleDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      route: json['route'] as String,
      interfaceRoute: json['interfaceRoute'] as String,
      image: json['image'] as String?,
      videoId: json['videoId'] as String?,
      chatModuleKey: json['chatModuleKey'] as String?,
      inoFiles: (json['inoFiles'] as List<dynamic>)
          .map((e) => InoFileModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => InstructionItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      materials: (json['materials'] as List<dynamic>)
          .map((e) => MaterialItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ModuleDetailModel.fromEntity(ModuleDetail entity) {
    return ModuleDetailModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      route: entity.route,
      interfaceRoute: entity.interfaceRoute,
      image: entity.image,
      videoId: entity.videoId,
      chatModuleKey: entity.chatModuleKey,
      inoFiles: entity.inoFiles,
      instructions: entity.instructions,
      materials: entity.materials,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'route': route,
      'interfaceRoute': interfaceRoute,
      if (image != null) 'image': image,
      if (videoId != null) 'videoId': videoId,
      if (chatModuleKey != null) 'chatModuleKey': chatModuleKey,
      'inoFiles': inoFiles.map((e) => InoFileModel.fromEntity(e).toJson()).toList(),
      'instructions': instructions.map((e) => InstructionItemModel.fromEntity(e).toJson()).toList(),
      'materials': materials.map((e) => MaterialItemModel.fromEntity(e).toJson()).toList(),
    };
  }
}
