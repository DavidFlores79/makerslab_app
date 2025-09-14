import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'di/service_locator.dart';
import 'theme/app_color.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersive,
    overlays: [SystemUiOverlay.top],
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 👈 App siempre en vertical
  ]);

  await initializeDateFormatting('es_MX');
  EquatableConfig.stringify = true;
  Bloc.observer = SimpleBlocObserver();

  runApp(const MyApp());
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
