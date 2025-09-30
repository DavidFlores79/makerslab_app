// lib/di/service_locator.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:makerslab_app/features/home/domain/usecases/get_home_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/data/repositories/bluetooth_repository_impl.dart';
import '../core/data/services/logger_service.dart';
import '../core/domain/repositories/bluetooth_repository.dart';
import '../core/domain/usecases/bluetooth/connect_device.dart';
import '../core/domain/usecases/bluetooth/disconnect_device.dart';
import '../core/domain/usecases/bluetooth/discover_devices.dart';
import '../core/domain/usecases/bluetooth/get_bluetooth_data_stream.dart';
import '../core/domain/usecases/bluetooth/send_bluetooth_string.dart';
import '../core/network/dio_client.dart';
import '../core/domain/repositories/file_sharing_repository.dart';
import '../core/data/services/bluetooth_service.dart';
import '../core/data/services/file_sharing_service.dart';
import '../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/ui/snackbar_service.dart';
import '../core/domain/usecases/share_file_usecase.dart';
import '../features/auth/data/datasource/auth_local_datasource.dart';
import '../features/auth/data/datasource/auth_remote_datasource.dart';
import '../features/auth/data/datasource/auth_token_local_datasource.dart';
import '../features/auth/data/datasource/auth_user_local_datasource.dart';
import '../features/auth/data/repository/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/change_password.dart';
import '../features/auth/domain/usecases/check_session.dart';
import '../features/auth/domain/usecases/confirm_sign_up.dart';
import '../features/auth/domain/usecases/forgot_password.dart';
import '../features/auth/domain/usecases/get_user_from_cache.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/logout_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/auth/domain/usecases/resend_sign_up_code.dart';
import '../features/auth/domain/usecases/signin_with_phone.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/otp/otp_bloc.dart';
import '../features/auth/presentation/bloc/register/register_cubit.dart';
import '../features/chat/data/datasources/chat_local_datasource_impl.dart';
import '../features/chat/data/datasources/chat_remote_datasource.dart';
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/get_chat_data_usecase.dart';
import '../features/chat/domain/usecases/send_file_message_usecase.dart';
import '../features/chat/domain/usecases/send_image_message_usecase.dart';
import '../features/chat/domain/usecases/send_message_usecase.dart';
import '../features/chat/domain/usecases/send_text_message_usecase.dart';
import '../features/chat/domain/usecases/start_chat_session_usecase.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/home/data/datasources/home_local_datasource_impl.dart';
import '../features/home/data/repository/home_repository_impl.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/light_control/data/repositories/light_control_repository_impl.dart';
import '../features/light_control/domain/repositories/light_control_repository.dart';
import '../features/light_control/presentation/bloc/light_control_bloc.dart';
import '../features/onboarding/data/repository/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/onboarding/domain/usecases/mark_onboarding_completed_usecase.dart';
import '../features/onboarding/domain/usecases/should_show_onboarding_usecase.dart';
import '../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../features/temperature/data/datasources/temperature_local_datasource.dart';
import '../features/temperature/data/repositories/temperature_repository_impl.dart';
import '../features/temperature/domain/repositories/temperature_repository.dart';
import '../features/temperature/presentation/bloc/temperature_bloc.dart';

// Importa tus repositorios, usecases, Blocs

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerSingleton<ILogger>(LoggerService());
  final logger = getIt<ILogger>();
  final homeLocalDatasource = HomeLocalDatasourceImpl(logger: logger);
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Flutter Secure Storage
  getIt.registerLazySingleton(() => const FlutterSecureStorage());
  getIt.registerLazySingleton<ISecureStorageService>(
    () => SecureStorageService(getIt()),
  );

  // Bluetooth Service
  getIt.registerLazySingleton(() => BluetoothService());

  // Dio client
  getIt.registerLazySingleton<Dio>(() {
    final dioClient = DioClient(
      secureStorage: getIt(),
      // baseUrl optional override
    );
    return dioClient.dio;
  });

  // Snackbar Service
  getIt.registerSingleton<SnackbarService>(SnackbarService());

  //LocalDataSources
  getIt.registerLazySingleton<AuthLocalDataSourceImpl>(
    () => AuthLocalDataSourceImpl(secureStorage: getIt(), logger: logger),
  );
  getIt.registerLazySingleton<AuthUserLocalDataSourceImpl>(
    () => AuthUserLocalDataSourceImpl(secureStorage: getIt()),
  );
  getIt.registerLazySingleton<AuthTokenLocalDataSourceImpl>(
    () => AuthTokenLocalDataSourceImpl(secureStorage: getIt()),
  );
  getIt.registerLazySingleton<LocalChatDataSourceImpl>(
    () => LocalChatDataSourceImpl(),
  );

  final authLocalDataSource = AuthLocalDataSourceImpl(
    logger: logger,
    secureStorage: getIt(),
  );
  final authTokenDataSource = AuthTokenLocalDataSourceImpl(
    secureStorage: getIt(),
  );
  final userLocalDataSource = AuthUserLocalDataSourceImpl(
    secureStorage: getIt(),
  );
  final chatLocalDataSource = LocalChatDataSourceImpl(logger: logger);

  // temperature local datasource
  getIt.registerLazySingleton<TemperatureLocalDataSource>(
    () => TemperatureLocalDataSourceImpl(prefs: getIt()),
  );

  //remote data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: getIt()),
  );

  getIt.registerLazySingleton<RemoteChatDataSource>(
    () => ChatRemoteDataSourceImpl(dio: getIt(), logger: logger),
  );

  // cubits
  getIt.registerFactory(() => RegisterCubit());

  // Repositorios
  getIt.registerLazySingleton<FileSharingRepository>(
    () => FileSharingService(),
  );

  getIt.registerLazySingleton<BluetoothRepository>(
    () => BluetoothRepositoryImpl(btService: getIt<BluetoothService>()),
  );

  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(localDatasource: homeLocalDatasource),
  );
  getIt.registerLazySingleton<OnboardingRepository>(
    () =>
        OnboardingRepositoryImpl(sharedPreferences: getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: authLocalDataSource,
      tokenLocalDataSource: authTokenDataSource,
      userLocalDataSource: userLocalDataSource,
      remoteDataSource: getIt<AuthRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      localDataSource: chatLocalDataSource,
      remoteDataSource: getIt<RemoteChatDataSource>(),
    ),
  );
  // temperature repository
  getIt.registerLazySingleton<TemperatureRepository>(
    () => TemperatureRepositoryImpl(
      bluetoothRepository: getIt<BluetoothRepository>(),
      local: getIt<TemperatureLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<LightControlRepository>(
    () => LightControlRepositoryImpl(
      bluetoothRepository: getIt<BluetoothRepository>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => ShareFileUseCase(getIt()));
  getIt.registerLazySingleton(() => MarkOnboardingCompletedUseCase(getIt()));
  getIt.registerLazySingleton(() => ShouldShowOnboardingUseCase(getIt()));
  getIt.registerLazySingleton(() => GetHomeMenu(repository: getIt()));
  // Bluetooth usecases
  getIt.registerLazySingleton(
    () => DiscoverDevicesUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton(() => ConnectDeviceUseCase(repository: getIt()));
  getIt.registerLazySingleton(
    () => DisconnectDeviceUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton(
    () => GetBluetoothDataStreamUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton(
    () => SendBluetoothStringUseCase(repository: getIt()),
  );

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
  getIt.registerLazySingleton(
    () => StartChatSessionUseCase(repository: getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton(() => LoginUser(repository: getIt()));
  getIt.registerLazySingleton(() => SigninWithPhone(repository: getIt()));
  getIt.registerLazySingleton(() => RegisterUser(repository: getIt()));
  getIt.registerLazySingleton(() => ChangePassword(repository: getIt()));
  getIt.registerLazySingleton(() => ForgotPassword(repository: getIt()));
  getIt.registerLazySingleton(() => CheckSession(repository: getIt()));
  getIt.registerLazySingleton(() => GetUserFromCache(repository: getIt()));
  getIt.registerLazySingleton(() => LogoutUser(repository: getIt()));
  getIt.registerLazySingleton(() => ResendSignUpCode(repository: getIt()));
  getIt.registerLazySingleton(() => ConfirmSignUp(repository: getIt()));
  getIt.registerLazySingleton(() => SendMessageUsecase(repository: getIt()));

  // Blocs
  getIt.registerFactory(() => OnboardingBloc(getIt(), getIt()));

  getIt.registerFactory(
    () => AuthBloc(
      loginUser: getIt(),
      registerUser: getIt(),
      changePassword: getIt(),
      forgotPassword: getIt(),
      checkSession: getIt(),
      getUserFromCache: getIt(),
      logoutUser: getIt(),
      signinWithPhone: getIt(),
    ),
  );

  getIt.registerFactory(
    () => OtpBloc(resendSignUpCode: getIt(), confirmSignUp: getIt()),
  );

  getIt.registerLazySingleton(
    () => BluetoothBloc(
      discoverDevicesUseCase: getIt(),
      connectDeviceUseCase: getIt(),
      disconnectDeviceUseCase: getIt(),
    ),
  );

  getIt.registerFactory(() => HomeBloc(getHomeMenuItems: getIt()));
  getIt.registerFactory(
    () => ChatBloc(
      repository: getIt<ChatRepository>(),
      getChatDataUseCase: getIt<GetChatDataUseCase>(),
      sendTextUseCase: getIt<SendTextMessageUseCase>(),
      sendImageUseCase: getIt<SendImageMessageUseCase>(),
      sendFileUseCase: getIt<SendFileMessageUseCase>(),
      logger: logger,
      startChatSession: getIt<StartChatSessionUseCase>(),
      sendMessageUsecase: getIt<SendMessageUsecase>(),
    ),
  );

  getIt.registerFactory<TemperatureBloc>(
    () => TemperatureBloc(
      getDataStreamUseCase: getIt<GetBluetoothDataStreamUseCase>(),
      sendStringUseCase: getIt<SendBluetoothStringUseCase>(),
      localDataSource: getIt<TemperatureLocalDataSource>(),
      bluetoothBloc: getIt<BluetoothBloc>(),
    ),
  );

  getIt.registerFactory<LightControlBloc>(
    () => LightControlBloc(
      getDataStreamUseCase: getIt<GetBluetoothDataStreamUseCase>(),
      sendStringUseCase: getIt<SendBluetoothStringUseCase>(),
      bluetoothBloc: getIt<BluetoothBloc>(),
    ),
  );
}
