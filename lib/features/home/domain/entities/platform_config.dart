// ABOUTME: Domain entity for platform-specific module configuration
// ABOUTME: Groups INO file, instructions, and materials for a specific platform (ESP32, Arduino UNO, etc.)

import 'package:makerslab_app/features/home/domain/entities/ino_file.dart';
import 'package:makerslab_app/features/home/domain/entities/instruction_item.dart';
import 'package:makerslab_app/features/home/domain/entities/material_item.dart';

class PlatformConfig {
  final InoPlatform platform;
  final InoFile inoFile;
  final List<InstructionItem> instructions;
  final List<MaterialItem> materials;

  const PlatformConfig({
    required this.platform,
    required this.inoFile,
    required this.instructions,
    required this.materials,
  });
}
