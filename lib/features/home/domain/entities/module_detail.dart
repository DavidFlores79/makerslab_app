// ABOUTME: Domain entity representing detailed module information for IoT modules
// ABOUTME: Includes platform-specific configurations with instructions, materials, and INO files

import 'package:makerslab_app/features/home/domain/entities/platform_config.dart';

class ModuleDetail {
  final String id;
  final String title;
  final String description;
  final String route;
  final String interfaceRoute;
  final String? image;
  final String? videoId;
  final String? chatModuleKey;
  final List<PlatformConfig> platformConfigs;

  const ModuleDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.route,
    required this.interfaceRoute,
    required this.platformConfigs,
    this.image,
    this.videoId,
    this.chatModuleKey,
  });
}
