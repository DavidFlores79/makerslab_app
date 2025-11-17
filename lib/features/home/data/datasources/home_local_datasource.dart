import '../models/main_menu_item_model.dart';
import '../models/module_detail_model.dart';

abstract class HomeLocalDatasource {
  Future<List<MainMenuItemModel>> getCachedModules();
  Future<void> cacheModules(List<MainMenuItemModel> modules);

  // Module Detail Support
  Future<ModuleDetailModel> getModuleDetailById(String id);
  Future<List<ModuleDetailModel>> getAllModuleDetails();
  Future<void> cacheModuleDetails(List<ModuleDetailModel> details);
}
