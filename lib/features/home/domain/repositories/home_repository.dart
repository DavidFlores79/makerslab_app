import 'package:dartz/dartz.dart';

import '../../../../core/entities/main_menu_item.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/entities/balance.dart';

abstract class HomeRepository {
  // Future<Either<Failure, List<Remittance>>> getRemittances();
  Future<Either<Failure, Balance>> getBalance();
  Future<Either<Failure, List<MainMenuItem>>> getMainMenu();
}
