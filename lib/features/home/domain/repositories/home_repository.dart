import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/main_menu_item_model.dart';

abstract class HomeRepository {
  Future<Either<Failure, void>> cacheMainMenu(List<MainMenuItemModel> menu);
  Future<Either<Failure, List<MainMenuItemModel>>> getMainMenu();
}
