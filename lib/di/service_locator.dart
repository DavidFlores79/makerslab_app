// lib/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:makerslab_app/features/home/domain/usecases/get_home_menu.dart';

import '../core/repositories/file_sharing_repository.dart';
import '../core/services/file_sharing_service.dart';
import '../core/usecases/share_file_usecase.dart';
import '../features/chat/data/datasources/chat_local_datasource.dart';
import '../features/chat/data/datasources/chat_local_datasource_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/get_chat_data_usecase.dart';
import '../features/chat/domain/usecases/send_file_message_usecase.dart';
import '../features/chat/domain/usecases/send_image_message_usecase.dart';
import '../features/chat/domain/usecases/send_text_message_usecase.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
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
  getIt.registerLazySingleton<LocalChatDataSource>(
    () => LocalChatDataSourceImpl(logger: getIt<Logger>()),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetBalance(repository: getIt()));
  getIt.registerLazySingleton(() => ShareFileUseCase(getIt()));
  getIt.registerLazySingleton(() => GetHomeMenu(repository: getIt()));
  getIt.registerLazySingleton(
    () => GetChatDataUseCase(getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton(
    () => SendTextMessageUseCase(getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton(
    () => SendImageMessageUseCase(getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton(
    () => SendFileMessageUseCase(getIt<ChatRepository>()),
  );

  // Blocs
  getIt.registerFactory(
    () => HomeBloc(getBalance: getIt(), getHomeMenuItems: getIt()),
  );
  getIt.registerFactory(
    () => ChatBloc(
      repository: getIt<ChatRepository>(),
      getChatDataUseCase: getIt<GetChatDataUseCase>(),
      sendTextUseCase: getIt<SendTextMessageUseCase>(),
      sendImageUseCase: getIt<SendImageMessageUseCase>(),
      sendFileUseCase: getIt<SendFileMessageUseCase>(),
      logger: getIt<Logger>(),
    ),
  );
}
