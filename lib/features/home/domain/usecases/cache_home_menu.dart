import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/main_menu_item_model.dart';
import '../repositories/home_repository.dart';

class CacheHomeMenu {
  final HomeRepository repository;

  CacheHomeMenu(this.repository);

  Future<Either<Failure, void>> call(List<MainMenuItemModel> menu) async {
    return repository.cacheMainMenu(menu);
  }
}
