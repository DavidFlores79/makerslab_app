import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/main_menu_item_model.dart';
import '../entities/module_detail.dart';

abstract class HomeRepository {
  Future<Either<Failure, void>> cacheMainMenu(List<MainMenuItemModel> menu);
  Future<Either<Failure, List<MainMenuItemModel>>> getMainMenu();
  Future<Either<Failure, List<MainMenuItemModel>>> getRemoteMenuItems();

  // Module Detail Support
  Future<Either<Failure, ModuleDetail>> getModuleDetailById(String id);
  Future<Either<Failure, List<ModuleDetail>>> getAllModuleDetails();
  Future<Either<Failure, void>> cacheModuleDetails(List<ModuleDetail> details);
}
