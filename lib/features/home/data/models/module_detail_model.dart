// ABOUTME: Data model for ModuleDetail entity with JSON serialization
// ABOUTME: Handles conversion between JSON and domain entity for complete module information

import 'package:makerslab_app/features/home/domain/entities/module_detail.dart';
import 'package:makerslab_app/features/home/data/models/platform_config_model.dart';

class ModuleDetailModel extends ModuleDetail {
  const ModuleDetailModel({
    required super.id,
    required super.title,
    required super.description,
    required super.route,
    required super.interfaceRoute,
    required super.platformConfigs,
    super.image,
    super.chatModuleKey,
  });

  factory ModuleDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      final platformConfigsJson = json['platformConfigs'];
      if (platformConfigsJson == null) {
        throw FormatException(
          'Missing required field "platformConfigs" in module: ${json['id']}',
        );
      }

      return ModuleDetailModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        route: json['route'] as String,
        interfaceRoute: json['interfaceRoute'] as String,
        image: json['image'] as String?,
        chatModuleKey: json['chatModuleKey'] as String?,
        platformConfigs: (platformConfigsJson as List<dynamic>)
            .map((e) => PlatformConfigModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, stackTrace) {
      throw FormatException(
        'Failed to parse ModuleDetail from JSON: $e\nModule ID: ${json['id']}\nJSON: $json',
      );
    }
  }

  factory ModuleDetailModel.fromEntity(ModuleDetail entity) {
    return ModuleDetailModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      route: entity.route,
      interfaceRoute: entity.interfaceRoute,
      image: entity.image,
      chatModuleKey: entity.chatModuleKey,
      platformConfigs: entity.platformConfigs,
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
      if (chatModuleKey != null) 'chatModuleKey': chatModuleKey,
      'platformConfigs': platformConfigs
          .map((e) => PlatformConfigModel.fromEntity(e).toJson())
          .toList(),
    };
  }
}
