// ABOUTME: Domain entity representing detailed module information for IoT modules
// ABOUTME: Includes instructions, materials, videos, and multi-platform INO files

import 'package:makerslab_app/features/home/domain/entities/ino_file.dart';
import 'package:makerslab_app/features/home/domain/entities/instruction_item.dart';
import 'package:makerslab_app/features/home/domain/entities/material_item.dart';

class ModuleDetail {
  final String id;
  final String title;
  final String description;
  final String route;
  final String interfaceRoute;
  final String? image;
  final String? videoId;
  final String? chatModuleKey;
  final List<InstructionItem> instructions;
  final List<MaterialItem> materials;
  final List<InoFile> inoFiles;

  const ModuleDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.route,
    required this.interfaceRoute,
    required this.instructions,
    required this.materials,
    required this.inoFiles,
    this.image,
    this.videoId,
    this.chatModuleKey,
  });
}
