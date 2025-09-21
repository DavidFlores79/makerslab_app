import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'core/router/app_router.dart';
import 'core/ui/snackbar_service.dart';
import 'di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'theme/app_color.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  _configSystemUIMode();
  _configEnvironment();
  await initializeDateFormatting('es_MX');
  EquatableConfig.stringify = true;
  Bloc.observer = SimpleBlocObserver();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus()),
          lazy: false,
        ),
        BlocProvider(create: (_) => getIt<ChatBloc>()),
      ],
      child: const MyApp(),
    ),
  );
}

void _configSystemUIMode() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

void _configEnvironment() {
  Logger.level = kDebugMode ? Level.all : Level.info;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Makers Lab',
      routerConfig: appRouter, // ← aquí enchufas go_router
      debugShowCheckedModeBanner: false,
      // Configuración de localización
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'), // Español México como principal
        Locale('en', 'US'), // Inglés como respaldo
      ],
      locale: const Locale('es', 'MX'),
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.greenLight,
          onPrimaryContainer: AppColors.greenDark,
          secondary: AppColors.gray700,
          onSecondary: Colors.white,
          onSecondaryContainer: AppColors.gray600,
          surface: AppColors.white,
          onSurface: AppColors.black,
          error: Colors.red,
          onError: Colors.white,
        ),
        useMaterial3: true,
      ),
      scaffoldMessengerKey: SnackbarService().messengerKey,
    );
  }
}

class SimpleBlocObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint("Transition $transition");
  }
}
