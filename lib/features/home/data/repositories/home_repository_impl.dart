import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/module_detail.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datesource.dart';
import '../models/main_menu_item_model.dart';
import '../models/module_detail_model.dart';

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

  @override
  Future<Either<Failure, ModuleDetail>> getModuleDetailById(String id) async {
    try {
      final detail = await localDatasource.getModuleDetailById(id);
      return Right(detail);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      return Left(
        CacheFailure('Unexpected error: ${e.toString()}', stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, List<ModuleDetail>>> getAllModuleDetails() async {
    try {
      final details = await localDatasource.getAllModuleDetails();
      return Right(details);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      return Left(
        CacheFailure('Unexpected error: ${e.toString()}', stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, void>> cacheModuleDetails(
    List<ModuleDetail> details,
  ) async {
    try {
      final models =
          details
              .map(
                (d) => ModuleDetailModel(
                  id: d.id,
                  title: d.title,
                  description: d.description,
                  route: d.route,
                  interfaceRoute: d.interfaceRoute,
                  platformConfigs: d.platformConfigs,
                  image: d.image,
                  chatModuleKey: d.chatModuleKey,
                ),
              )
              .toList();
      await localDatasource.cacheModuleDetails(models);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    } catch (e, stackTrace) {
      return Left(
        CacheFailure('Unexpected error: ${e.toString()}', stackTrace),
      );
    }
  }
}
