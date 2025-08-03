import 'package:dartz/dartz.dart';

import '../../../../core/entities/main_menu_item.dart';
import '../../../../core/error/failure.dart';
import '../repositories/home_repository.dart';

class GetHomeMenu {
  final HomeRepository repository;

  GetHomeMenu({required this.repository});

  Future<Either<Failure, List<MainMenuItem>>> call() {
    return repository.getMainMenu();
  }
}
