import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/main_menu_item_model.dart';
import '../repositories/home_repository.dart';

class GetRemoteHomeMenu {
  final HomeRepository repository;

  GetRemoteHomeMenu({required this.repository});

  Future<Either<Failure, List<MainMenuItemModel>>> call() async {
    return await repository.getRemoteMenuItems();
  }
}
