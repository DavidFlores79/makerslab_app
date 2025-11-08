import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/main_menu_item_model.dart';
import '../repositories/home_repository.dart';

class GetHomeMenu {
  final HomeRepository repository;

  GetHomeMenu({required this.repository});

  Future<Either<Failure, List<MainMenuItemModel>>> call() {
    return repository.getMainMenu();
  }
}
