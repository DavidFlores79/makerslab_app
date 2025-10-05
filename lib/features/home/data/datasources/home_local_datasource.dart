import '../models/main_menu_item_model.dart';

abstract class HomeLocalDatasource {
  Future<List<MainMenuItemModel>> getCachedModules();
  Future<void> cacheModules(List<MainMenuItemModel> modules);
}
