// lib/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:makerslab_app/features/home/domain/usecases/get_home_menu.dart';

import '../core/repositories/file_sharing_repository.dart';
import '../core/services/file_sharing_service.dart';
import '../core/usecases/share_file_usecase.dart';
import '../features/home/data/datasources/home_local_datasource_impl.dart';
import '../features/home/data/repository/home_repository_impl.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/domain/usecases/get_balance.dart';
import '../features/home/presentation/bloc/home_bloc.dart';

// Importa tus repositorios, usecases, Blocs

final getIt = GetIt.instance;

void setupLocator() {
  final logger = Logger();
  final homeLocalDatasource = HomeLocalDatasourceImpl(logger: logger);

  // Repositorios
  getIt.registerLazySingleton<FileSharingRepository>(
    () => FileSharingService(),
  );
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(localDatasource: homeLocalDatasource),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetBalance(repository: getIt()));
  getIt.registerLazySingleton(() => ShareFileUseCase(getIt()));
  getIt.registerLazySingleton(() => GetHomeMenu(repository: getIt()));

  // Blocs
  getIt.registerFactory(
    () => HomeBloc(getBalance: getIt(), getHomeMenuItems: getIt()),
  );
}
