// ABOUTME: JSON parser for module detail data with validation and error recovery
// ABOUTME: Parses modules_detail.json file and converts to ModuleDetailModel instances

import 'dart:convert';
import 'package:makerslab_app/core/data/services/logger_service.dart';
import 'package:makerslab_app/features/home/data/models/module_detail_model.dart';

class ModuleDetailJsonParser {
  final ILogger logger;

  ModuleDetailJsonParser({required this.logger});

  Future<List<ModuleDetailModel>> parseModulesJson(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate schema version
      final version = data['version'] as String?;
      if (version == null) {
        throw const FormatException('Missing schema version in modules JSON');
      }

      logger.info('Parsing modules JSON schema version: $version');

      // Validate modules array
      final modulesJson = data['modules'] as List<dynamic>?;
      if (modulesJson == null) {
        throw const FormatException('Missing modules array in JSON');
      }

      // Parse each module with error recovery
      final modules = <ModuleDetailModel>[];
      for (int i = 0; i < modulesJson.length; i++) {
        try {
          final moduleJson = modulesJson[i] as Map<String, dynamic>;
          final module = ModuleDetailModel.fromJson(moduleJson);
          modules.add(module);
          logger.info('Successfully parsed module: ${module.id}');
        } catch (e, stackTrace) {
          logger.error('Failed to parse module at index $i', e, stackTrace);
          // Continue parsing other modules instead of failing completely
        }
      }

      if (modules.isEmpty && modulesJson.isNotEmpty) {
        logger.error('All modules failed to parse', null, StackTrace.current);
        throw const FormatException('All modules failed to parse');
      }

      logger.info(
        'Successfully parsed ${modules.length} of ${modulesJson.length} modules',
      );
      return modules;
    } catch (e, stackTrace) {
      logger.error('Failed to parse modules JSON', e, stackTrace);
      rethrow;
    }
  }
}
