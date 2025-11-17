import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:makerslab_app/features/home/data/models/main_menu_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/data/services/logger_service.dart';
import '../../../../core/error/exceptions.dart';
import '../models/module_detail_model.dart';
import 'home_local_datasource.dart';
import 'module_detail_json_parser.dart';

const _kModulesKey = 'CACHED_MODULES_v1';
const _kModuleDetailsKey =
    'CACHED_MODULE_DETAILS_v4'; // Bumped to v3 for platform-specific videoUrl

class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  final SharedPreferences prefs;
  final ILogger logger;
  final ModuleDetailJsonParser jsonParser;

  HomeLocalDatasourceImpl({
    required this.logger,
    required this.prefs,
    required this.jsonParser,
  });

  @override
  Future<void> cacheModules(List<MainMenuItemModel> modules) async {
    try {
      final jsonStr = json.encode(modules.map((m) => m.toJson()).toList());
      await prefs.setString(_kModulesKey, jsonStr);
      logger.info("Saving initial menu: ${modules.length}");
    } catch (e, stackTrace) {
      logger.error('Error saving initial menu', e, stackTrace);
      throw CacheException('Error saving initial menu', stackTrace);
    }
  }

  @override
  Future<List<MainMenuItemModel>> getCachedModules() async {
    try {
      logger.info("Obtaining cached modules...");
      final raw = prefs.getString(_kModulesKey);

      if (raw == null) return Future.value([]);
      final parsed = json.decode(raw) as List<dynamic>;

      logger.info("Cached modules obtained: ${parsed.length}");
      return parsed
          .map((e) => MainMenuItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      logger.error('Error obtaining cached modules', e, stackTrace);
      throw CacheException('Error obtaining cached modules', stackTrace);
    }
  }

  @override
  Future<List<ModuleDetailModel>> getAllModuleDetails() async {
    try {
      logger.info("Loading module details from JSON...");

      // Check cache first
      final cached = prefs.getString(_kModuleDetailsKey);
      if (cached != null) {
        logger.info("Loading from cache");
        final parsed = json.decode(cached) as List<dynamic>;
        return parsed
            .map((e) => ModuleDetailModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load from assets
      final jsonString = await rootBundle.loadString(
        'assets/data/modules/modules_detail.json',
      );

      final modules = await jsonParser.parseModulesJson(jsonString);

      // Cache for next time
      await cacheModuleDetails(modules);

      logger.info("Loaded ${modules.length} module details");
      return modules;
    } catch (e, stackTrace) {
      logger.error('Error loading module details', e, stackTrace);
      throw CacheException('Error loading module details', stackTrace);
    }
  }

  @override
  Future<ModuleDetailModel> getModuleDetailById(String id) async {
    try {
      final all = await getAllModuleDetails();
      final detail = all.firstWhere(
        (m) => m.id == id,
        orElse:
            () =>
                throw CacheException(
                  'Module detail not found: $id',
                  StackTrace.current,
                ),
      );
      return detail;
    } catch (e, stackTrace) {
      logger.error('Error loading module detail: $id', e, stackTrace);
      throw CacheException('Error loading module detail: $id', stackTrace);
    }
  }

  @override
  Future<void> cacheModuleDetails(List<ModuleDetailModel> details) async {
    try {
      final jsonStr = json.encode(details.map((m) => m.toJson()).toList());
      await prefs.setString(_kModuleDetailsKey, jsonStr);
      logger.info("Cached ${details.length} module details");
    } catch (e, stackTrace) {
      logger.error('Error caching module details', e, stackTrace);
      throw CacheException('Error caching module details', stackTrace);
    }
  }
}
