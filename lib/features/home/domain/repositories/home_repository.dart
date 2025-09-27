import 'package:dartz/dartz.dart';

import '../../../../core/entities/main_menu_item.dart';
import '../../../../core/error/failure.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<MainMenuItem>>> getMainMenu();
}
