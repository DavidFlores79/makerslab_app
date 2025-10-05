import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/data/models/main_menu_item_model.dart';
import '../mocks/main_menu_mock.dart' as mock;

Future<void> seedDefaultModulesIfNeeded(SharedPreferences prefs) async {
  const key = 'CACHED_MODULES_v1';
  final raw = prefs.getString(key);
  if (raw != null && raw.isNotEmpty) return; // ya seed-eado

  final List<MainMenuItemModel> defaults =
      mock.mainMenuMock.map((m) {
        return MainMenuItemModel.fromJson(Map<String, dynamic>.from(m));
      }).toList();

  final jsonStr = json.encode(defaults.map((m) => m.toJson()).toList());
  await prefs.setString(key, jsonStr);
}
