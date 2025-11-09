import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datesource.dart';
import '../models/main_menu_item_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeLocalDatasource localDatasource;
  final HomeRemoteDataSource remoteDatasource;

  HomeRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  @override
  Future<Either<Failure, List<MainMenuItemModel>>> getMainMenu() async {
    try {
      final mainMenu = await localDatasource.getCachedModules();
      return Right(mainMenu);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> cacheMainMenu(
    List<MainMenuItemModel> menu,
  ) async {
    try {
      await localDatasource.cacheModules(menu);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, List<MainMenuItemModel>>> getRemoteMenuItems() async {
    try {
      final remoteMenu = await remoteDatasource.getRemoteMenuItems();
      return Right(remoteMenu);
    } on ServerException catch (e, stackTrace) {
      return Left(ServerFailure(e.message, e.statusCode, stackTrace));
    }
  }
}
