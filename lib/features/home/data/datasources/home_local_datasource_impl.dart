import 'dart:convert';

import 'package:makerslab_app/core/mocks/main_menu_mock.dart';
import 'package:makerslab_app/features/home/data/models/main_menu_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/data/services/logger_service.dart';
import '../../../../core/error/exceptions.dart';
import 'home_local_datasource.dart';

const _kModulesKey = 'CACHED_MODULES_v1';

class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  final SharedPreferences prefs;
  final ILogger logger;

  HomeLocalDatasourceImpl({required this.logger, required this.prefs});

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
}
