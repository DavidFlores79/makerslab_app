import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/entities/main_menu_item.dart';

import '../../../../core/entities/balance.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeLocalDatasource localDatasource;

  HomeRepositoryImpl({required this.localDatasource});

  @override
  Future<Either<Failure, Balance>> getBalance() async {
    try {
      final balance = await localDatasource.getBalance();
      return Right(balance);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, List<MainMenuItem>>> getMainMenu() async {
    try {
      final mainMenu = await localDatasource.getMainMenu();
      return Right(mainMenu);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  // @override
  // Future<Either<Failure, List<Remittance>>> getRemittances() async {
  //   try {
  //     final remittances = await localDatasource.getRemittances();
  //     return Right(remittances);
  //   } on CacheException catch (e, stackTrace) {
  //     return Left(CacheFailure(e.message, stackTrace));
  //   }
  // }
}
