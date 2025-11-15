import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'core/domain/entities/theme_preference.dart';
import 'core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import 'core/presentation/bloc/theme/theme_bloc.dart';
import 'core/presentation/bloc/theme/theme_event.dart';
import 'core/presentation/bloc/theme/theme_state.dart';
import 'core/router/app_router.dart';
import 'core/ui/snackbar_service.dart';
import 'di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'theme/app_theme.dart';
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

  // Pre-load theme preference to prevent flicker
  final themeBloc = getIt<ThemeBloc>();
  themeBloc.add(LoadThemePreference());

  // Wait for theme to load (with timeout to prevent hang)
  await themeBloc.stream
      .firstWhere(
        (state) => state is ThemeLoaded || state is ThemeInitial,
        orElse: () => ThemeInitial(),
      )
      .timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => ThemeInitial(),
      );

  // Configure global error widget for better user experience
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Log error for debugging
    if (kDebugMode) {
      debugPrint('Global error caught: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }

    // Show user-friendly error screen instead of red screen
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Algo salió mal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por favor reinicia la aplicación',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${details.exception}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus()),
          lazy: false,
        ),
        BlocProvider(create: (_) => getIt<BluetoothBloc>()),
        BlocProvider(create: (_) => getIt<ChatBloc>()),
        BlocProvider.value(value: themeBloc), // Use pre-loaded instance
      ],
      child: const MyApp(),
    ),
  );
}

void _configSystemUIMode() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

void _configEnvironment() {
  Logger.level = kDebugMode ? Level.all : Level.info;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Only reload theme if user preference is "System"
    final themeBloc = context.read<ThemeBloc>();
    final currentState = themeBloc.state;
    if (currentState is ThemeLoaded &&
        currentState.mode == ThemePreference.system) {
      themeBloc.add(LoadThemePreference());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        // Determine effective theme mode based on state
        ThemeMode effectiveThemeMode = ThemeMode.system;

        if (state is ThemeLoaded) {
          switch (state.mode) {
            case ThemePreference.light:
              effectiveThemeMode = ThemeMode.light;
              break;
            case ThemePreference.dark:
              effectiveThemeMode = ThemeMode.dark;
              break;
            case ThemePreference.system:
              effectiveThemeMode = ThemeMode.system;
              break;
          }
        }

        return MaterialApp.router(
          title: 'Makers Lab',
          routerConfig: appRouter,
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
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: effectiveThemeMode,
          scaffoldMessengerKey: SnackbarService().messengerKey,
        );
      },
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
