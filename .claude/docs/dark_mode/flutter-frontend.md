# Dark Mode Implementation Plan - Flutter Frontend

## Document Overview
This document provides detailed architectural guidance and implementation specifications for adding dark mode with iOS-style triple selector (System, Light, Dark) to the Makers Lab Flutter application.

**Target Audience**: Flutter developers implementing the feature
**Date Created**: 2025-11-12
**Architecture**: Clean Architecture with classic BLoC pattern
**Status**: Planning Phase

---

## Table of Contents
1. [Architectural Decisions](#architectural-decisions)
2. [Theme State Management Strategy](#theme-state-management-strategy)
3. [Dark Theme Color System](#dark-theme-color-system)
4. [iOS-Style Theme Selector](#ios-style-theme-selector)
5. [System Theme Detection](#system-theme-detection)
6. [File Structure & Implementation](#file-structure--implementation)
7. [Integration Points](#integration-points)
8. [Testing Strategy](#testing-strategy)
9. [Pitfalls & Performance](#pitfalls--performance)
10. [Migration Path](#migration-path)

---

## 1. Architectural Decisions

### 1.1 ThemeBloc Registration Pattern

**DECISION: Register ThemeBloc as Singleton (Lazy)**

**Rationale:**
- Theme preference is **global application state** (similar to AuthBloc, BluetoothBloc, ChatBloc)
- Single source of truth for theme across entire app
- Must survive navigation changes and persist throughout app lifetime
- Needs to be initialized BEFORE MaterialApp builds to avoid theme flicker

**Registration Pattern:**
```dart
// lib/di/service_locator.dart
getIt.registerLazySingleton<ThemeBloc>(
  () => ThemeBloc(
    loadThemeUseCase: getIt(),
    saveThemeUseCase: getIt(),
  ),
);
```

**Key Points:**
- Use `registerLazySingleton` NOT `registerFactory`
- Will be created on first access, then reused
- Same pattern as existing global BLoCs (AuthBloc, BluetoothBloc, ChatBloc)

---

### 1.2 Initial Theme Loading Strategy

**DECISION: Load theme in main() BEFORE app starts**

**Problem:**
- If theme loads asynchronously after MaterialApp builds, users see theme flicker (light → dark transition)
- Poor UX during splash screen phase

**Solution:**
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // PRE-LOAD theme preference to avoid flicker
  final themeBloc = getIt<ThemeBloc>();
  themeBloc.add(LoadThemePreference());

  // Wait for theme to load (with timeout)
  await themeBloc.stream.firstWhere(
    (state) => state is ThemeLoaded,
    orElse: () => ThemeLoaded(mode: ThemePreference.system, isDarkMode: false),
  ).timeout(
    const Duration(milliseconds: 500),
    onTimeout: () => ThemeLoaded(mode: ThemePreference.system, isDarkMode: false),
  );

  _configSystemUIMode();
  _configEnvironment();
  await initializeDateFormatting('es_MX');
  EquatableConfig.stringify = true;
  Bloc.observer = SimpleBlocObserver();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: themeBloc), // Use .value for existing instance
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus()), lazy: false),
        BlocProvider(create: (_) => getIt<BluetoothBloc>()),
        BlocProvider(create: (_) => getIt<ChatBloc>()),
      ],
      child: const MyApp(),
    ),
  );
}
```

**Benefits:**
- No theme flicker on app start
- Theme ready before first frame
- Graceful fallback if theme loading fails (timeout)
- Theme preference cached for instant future access

**Trade-offs:**
- Adds ~50-100ms to app startup (acceptable for better UX)
- Requires timeout handling

---

### 1.3 Theme Application Pattern

**DECISION: Use BlocBuilder with MaterialApp theme properties**

**Architecture:**
```dart
// lib/main.dart - MyApp widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // Determine effective theme mode
        ThemeMode effectiveThemeMode = ThemeMode.system;

        if (themeState is ThemeLoaded) {
          effectiveThemeMode = switch (themeState.mode) {
            ThemePreference.system => ThemeMode.system,
            ThemePreference.light => ThemeMode.light,
            ThemePreference.dark => ThemeMode.dark,
          };
        }

        return MaterialApp.router(
          title: 'Makers Lab',
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,

          // THEME CONFIGURATION
          theme: AppTheme.lightTheme(),        // Used when light mode active
          darkTheme: AppTheme.darkTheme(),     // Used when dark mode active
          themeMode: effectiveThemeMode,       // Controls which theme to use

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'MX'),
            Locale('en', 'US'),
          ],
          locale: const Locale('es', 'MX'),
          scaffoldMessengerKey: SnackbarService().messengerKey,
        );
      },
    );
  }
}
```

**Why This Pattern:**
1. **MaterialApp handles theme switching natively** - no manual widget rebuilds needed
2. **ThemeMode.system respects device theme** automatically
3. **BlocBuilder only rebuilds MaterialApp** when theme changes (efficient)
4. **No cascading rebuilds** - Flutter's theme system propagates changes efficiently

**Alternative Considered (REJECTED):**
- Manual theme propagation with InheritedWidget → Too complex, reinvents the wheel
- Theme switching with setState in StatefulWidget → Violates BLoC architecture

---

## 2. Theme State Management Strategy

### 2.1 BLoC Structure

**ThemeEvent (lib/core/presentation/bloc/theme/theme_event.dart):**
```dart
// ABOUTME: This file defines events for theme management
// ABOUTME: Supports loading saved preference and changing theme mode

abstract class ThemeEvent {
  const ThemeEvent();
}

class LoadThemePreference extends ThemeEvent {
  const LoadThemePreference();
}

class ChangeThemeMode extends ThemeEvent {
  final ThemePreference mode;

  const ChangeThemeMode(this.mode);
}
```

**ThemeState (lib/core/presentation/bloc/theme/theme_state.dart):**
```dart
// ABOUTME: This file defines states for theme management
// ABOUTME: Tracks current theme preference and effective dark mode status

abstract class ThemeState {
  const ThemeState();
}

class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

class ThemeLoading extends ThemeState {
  const ThemeLoading();
}

class ThemeLoaded extends ThemeState {
  final ThemePreference mode;       // User's preference (system/light/dark)
  final bool isDarkMode;            // Effective dark mode state (for system mode)

  const ThemeLoaded({
    required this.mode,
    required this.isDarkMode,
  });
}

class ThemeError extends ThemeState {
  final String message;

  const ThemeError({required this.message});
}
```

**Key Design Decisions:**
- `ThemeLoaded.isDarkMode` is computed based on:
  - If `mode == system`: Use device's current brightness
  - If `mode == light`: Always false
  - If `mode == dark`: Always true
- This allows UI to show correct icons/labels based on effective theme

---

### 2.2 BLoC Implementation

**ThemeBloc (lib/core/presentation/bloc/theme/theme_bloc.dart):**
```dart
// ABOUTME: This BLoC manages theme preference state and persistence
// ABOUTME: Handles loading saved preference and changing theme mode

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final LoadThemePreferenceUseCase loadThemeUseCase;
  final SaveThemePreferenceUseCase saveThemeUseCase;

  ThemeBloc({
    required this.loadThemeUseCase,
    required this.saveThemeUseCase,
  }) : super(const ThemeInitial()) {
    on<LoadThemePreference>(_onLoadThemePreference);
    on<ChangeThemeMode>(_onChangeThemeMode);
  }

  Future<void> _onLoadThemePreference(
    LoadThemePreference event,
    Emitter<ThemeState> emit,
  ) async {
    emit(const ThemeLoading());

    final result = await loadThemeUseCase(NoParams());

    result.fold(
      (failure) {
        // On failure, default to system theme
        emit(const ThemeLoaded(
          mode: ThemePreference.system,
          isDarkMode: false, // Will be updated by system listener
        ));
      },
      (preference) {
        final isDarkMode = _computeEffectiveDarkMode(preference);
        emit(ThemeLoaded(mode: preference, isDarkMode: isDarkMode));
      },
    );
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<ThemeState> emit,
  ) async {
    final result = await saveThemeUseCase(SaveThemeParams(mode: event.mode));

    result.fold(
      (failure) {
        emit(ThemeError(message: _mapFailureToMessage(failure)));
        // Revert to previous state
        if (state is ThemeLoaded) {
          emit(state as ThemeLoaded);
        }
      },
      (_) {
        final isDarkMode = _computeEffectiveDarkMode(event.mode);
        emit(ThemeLoaded(mode: event.mode, isDarkMode: isDarkMode));
      },
    );
  }

  bool _computeEffectiveDarkMode(ThemePreference mode) {
    switch (mode) {
      case ThemePreference.light:
        return false;
      case ThemePreference.dark:
        return true;
      case ThemePreference.system:
        // Get system brightness - will be updated by listener
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is CacheFailure) {
      return 'Error al guardar la preferencia de tema';
    }
    return 'Error inesperado';
  }
}
```

**Important Notes:**
- Use case pattern for domain logic separation
- Graceful failure handling (default to system theme)
- Revert to previous state on save failure (optimistic UI pattern)
- `_computeEffectiveDarkMode` handles system theme detection

---

## 3. Dark Theme Color System

### 3.1 Material Design 3 Dark Theme Principles

**Official Guidelines:**
1. **Surface Colors**: Elevated surfaces get lighter (not darker like MD2)
2. **Primary Color**: Slightly desaturated in dark mode (better readability)
3. **Contrast**: Ensure 4.5:1 contrast ratio for text
4. **On-Colors**: Light text on dark surfaces
5. **Error Colors**: Adjust for dark backgrounds

**Key Transformations for Primary #247BA0:**
- **Light Primary**: `#247BA0` (original)
- **Dark Primary**: `#5EB1E8` (40% lighter, more saturated for visibility)
- **Primary Container (Light)**: `#E8F6EC` (very light greenish)
- **Primary Container (Dark)**: `#004F7A` (dark blue, visible against dark surface)

---

### 3.2 AppColors Extension

**RECOMMENDATION: Extend app_color.dart with dark variants**

**DO NOT use color transformations at runtime** - Pre-define all dark colors for:
1. **Performance**: No runtime color calculations
2. **Design Control**: Fine-tune each color for optimal contrast
3. **Maintainability**: Clear intent in code

**Implementation:**
```dart
// lib/theme/app_color.dart
class AppColors {
  // ============ EXISTING LIGHT COLORS ============
  static const black = Color(0xFF000000);
  // ... existing colors ...
  static const primary = Color(0xFF247BA0);

  // ============ DARK THEME COLORS ============

  // Dark theme surfaces (Material Design 3)
  static const darkSurface = Color(0xFF1C1B1F);           // Main surface
  static const darkSurfaceVariant = Color(0xFF2B2930);    // Elevated +1dp
  static const darkSurfaceContainerHigh = Color(0xFF36343B); // Elevated +2dp
  static const darkBackground = Color(0xFF1C1B1F);        // Same as surface

  // Dark theme primary colors
  static const darkPrimary = Color(0xFF5EB1E8);           // Lighter blue for visibility
  static const darkOnPrimary = Color(0xFF003548);         // Dark blue text
  static const darkPrimaryContainer = Color(0xFF004F7A);  // Container background
  static const darkOnPrimaryContainer = Color(0xFFB8E7FF); // Light blue text

  // Dark theme secondary colors
  static const darkSecondary = Color(0xFFB8C8D8);         // Lighter gray
  static const darkOnSecondary = Color(0xFF23323F);       // Dark text
  static const darkSecondaryContainer = Color(0xFF394856); // Container
  static const darkOnSecondaryContainer = Color(0xFFD4E4F4); // Light text

  // Dark theme text colors
  static const darkOnSurface = Color(0xFFE6E1E5);         // Primary text (87% white)
  static const darkOnSurfaceVariant = Color(0xFFCAC4D0);  // Secondary text (60% white)
  static const darkOutline = Color(0xFF938F99);           // Borders/dividers (38% white)

  // Dark theme error colors
  static const darkError = Color(0xFFFFB4AB);             // Light red
  static const darkOnError = Color(0xFF690005);           // Dark red text
  static const darkErrorContainer = Color(0xFF93000A);    // Container
  static const darkOnErrorContainer = Color(0xFFFFDAD6);  // Light red text

  // Module colors adapted for dark theme
  static const darkLightGreen = Color(0xFFA5D57B);        // Gamepad (brighter)
  static const darkBlue = Color(0xFF64B5F6);              // Sensor DHT (lighter)
  static const darkRed = Color(0xFFEF5350);               // Servos (lighter)
  static const darkOrange = Color(0xFFFFB74D);            // Light Control (lighter)
  static const darkPurple = Color(0xFFBA68C8);            // Chat (lighter)
}
```

**Color Contrast Testing:**
- Use https://webaim.org/resources/contrastchecker/
- Minimum 4.5:1 for normal text
- Minimum 3:1 for large text (18pt+)
- Test all color combinations

---

### 3.3 AppTheme Factory

**NEW FILE: lib/theme/app_theme.dart**

This centralizes theme creation and ensures consistency.

```dart
// ABOUTME: This file provides ThemeData factories for light and dark themes
// ABOUTME: Ensures Material Design 3 compliance with consistent color schemes

import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Returns light theme configuration
  static ThemeData lightTheme() {
    return ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme(
        brightness: Brightness.light,

        // Primary colors
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.greenLight,
        onPrimaryContainer: AppColors.greenDark,

        // Secondary colors
        secondary: AppColors.gray700,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.gray200,
        onSecondaryContainer: AppColors.gray600,

        // Surface colors
        surface: AppColors.white,
        onSurface: AppColors.black,
        surfaceVariant: AppColors.gray100,
        onSurfaceVariant: AppColors.gray700,

        // Background (deprecated but still used by some widgets)
        background: AppColors.white,
        onBackground: AppColors.black,

        // Error colors
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),

        // Utility colors
        outline: AppColors.gray400,
        outlineVariant: AppColors.gray300,
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.gray900,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.primaryLight,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Returns dark theme configuration
  static ThemeData darkTheme() {
    return ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme(
        brightness: Brightness.dark,

        // Primary colors
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnPrimaryContainer,

        // Secondary colors
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        secondaryContainer: AppColors.darkSecondaryContainer,
        onSecondaryContainer: AppColors.darkOnSecondaryContainer,

        // Surface colors
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,

        // Background
        background: AppColors.darkBackground,
        onBackground: AppColors.darkOnSurface,

        // Error colors
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        errorContainer: AppColors.darkErrorContainer,
        onErrorContainer: AppColors.darkOnErrorContainer,

        // Utility colors
        outline: AppColors.darkOutline,
        outlineVariant: Color(0xFF49454F),
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.gray200,
        onInverseSurface: AppColors.gray900,
        inversePrimary: AppColors.primary,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurfaceVariant,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
        centerTitle: true,
      ),

      // Card theme
      cardTheme: CardTheme(
        color: AppColors.darkSurfaceVariant,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryContainer,
          foregroundColor: AppColors.darkOnPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
```

**Key Points:**
- Static factory methods (no instantiation needed)
- Comprehensive theme configuration (not just ColorScheme)
- Consistent border radius, padding, elevation across themes
- Material Design 3 compliant

---

## 4. iOS-Style Theme Selector

### 4.1 Widget Choice Analysis

**OPTION 1: CupertinoSlidingSegmentedControl (RECOMMENDED)**

**Pros:**
- Native iOS look and feel
- Smooth sliding animation built-in
- Excellent touch feedback
- Works well on Android (users familiar with iOS-style controls)
- Minimal code required

**Cons:**
- Requires Cupertino package (already available in Flutter)
- May look out of place in pure Material apps (NOT an issue here - many apps use iOS controls)

**OPTION 2: Material SegmentedButton (Flutter 3.7+)**

**Pros:**
- Official Material Design 3 component
- Consistent with Material theme
- Better Android design language adherence

**Cons:**
- Less smooth animation than Cupertino
- Requires Flutter 3.7+ (you have 3.7.2+ ✓)
- More code for custom styling

**DECISION: Use CupertinoSlidingSegmentedControl**

**Rationale:**
1. Makers Lab users are in educational context (familiar with iOS controls)
2. Smoother UX trumps strict Material adherence
3. Easier to implement and maintain
4. Industry standard (even Google apps use iOS-style controls sometimes)

---

### 4.2 Theme Selector Widget Implementation

**NEW FILE: lib/features/profile/presentation/widgets/theme_selector_widget.dart**

```dart
// ABOUTME: This widget provides iOS-style theme selector with three options
// ABOUTME: Supports System, Light, and Dark theme modes with smooth animations

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/presentation/bloc/theme/theme_bloc.dart';
import 'package:makerslab_app/core/presentation/bloc/theme/theme_event.dart';
import 'package:makerslab_app/core/presentation/bloc/theme/theme_state.dart';

class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        ThemePreference currentMode = ThemePreference.system;

        if (state is ThemeLoaded) {
          currentMode = state.mode;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Apariencia',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Segmented Control Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // iOS-style Segmented Control
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<ThemePreference>(
                      groupValue: currentMode,
                      backgroundColor: isDarkMode
                          ? theme.colorScheme.surface
                          : Colors.grey.shade300,
                      thumbColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.all(4),
                      children: {
                        ThemePreference.system: _buildSegment(
                          context: context,
                          icon: Icons.brightness_auto,
                          label: 'Sistema',
                          isSelected: currentMode == ThemePreference.system,
                        ),
                        ThemePreference.light: _buildSegment(
                          context: context,
                          icon: Icons.light_mode,
                          label: 'Claro',
                          isSelected: currentMode == ThemePreference.light,
                        ),
                        ThemePreference.dark: _buildSegment(
                          context: context,
                          icon: Icons.dark_mode,
                          label: 'Oscuro',
                          isSelected: currentMode == ThemePreference.dark,
                        ),
                      },
                      onValueChanged: (ThemePreference? value) {
                        if (value != null) {
                          context.read<ThemeBloc>().add(ChangeThemeMode(value));
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description text
                  Text(
                    _getDescriptionText(currentMode),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getDescriptionText(ThemePreference mode) {
    switch (mode) {
      case ThemePreference.system:
        return 'El tema se ajustará automáticamente según la configuración de tu dispositivo';
      case ThemePreference.light:
        return 'Usa el tema claro en todo momento';
      case ThemePreference.dark:
        return 'Usa el tema oscuro en todo momento';
    }
  }
}
```

**Design Highlights:**
- Three segments with icons and labels
- Description text updates based on selection
- Smooth sliding animation from CupertinoSlidingSegmentedControl
- Theme-aware colors (works in light and dark)
- Spanish localization
- Accessibility labels built-in

---

## 5. System Theme Detection

### 5.1 Challenge: Reactive System Theme

**Problem:**
When user selects "System" mode, app must:
1. Immediately reflect current device theme
2. Update automatically when device theme changes (Settings → Display → Dark Mode)
3. Not leak memory or cause performance issues

**Solution: WidgetsBindingObserver Pattern**

---

### 5.2 System Theme Listener Implementation

**MODIFY: lib/main.dart - MyApp widget**

Convert MyApp to StatefulWidget to add observer:

```dart
// ABOUTME: Main app widget with theme management and localization
// ABOUTME: Observes system theme changes to update UI reactively

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register observer to listen for system theme changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Clean up observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Called when device theme changes (Settings → Dark Mode toggled)
    super.didChangePlatformBrightness();

    final themeBloc = context.read<ThemeBloc>();

    // Only reload if user has "System" preference
    if (themeBloc.state is ThemeLoaded) {
      final state = themeBloc.state as ThemeLoaded;
      if (state.mode == ThemePreference.system) {
        // Trigger state update with new brightness
        themeBloc.add(const LoadThemePreference());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        ThemeMode effectiveThemeMode = ThemeMode.system;

        if (themeState is ThemeLoaded) {
          effectiveThemeMode = switch (themeState.mode) {
            ThemePreference.system => ThemeMode.system,
            ThemePreference.light => ThemeMode.light,
            ThemePreference.dark => ThemeMode.dark,
          };
        }

        return MaterialApp.router(
          title: 'Makers Lab',
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: effectiveThemeMode,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'MX'),
            Locale('en', 'US'),
          ],
          locale: const Locale('es', 'MX'),
          scaffoldMessengerKey: SnackbarService().messengerKey,
        );
      },
    );
  }
}
```

**How It Works:**
1. `WidgetsBindingObserver` monitors platform-level changes
2. `didChangePlatformBrightness()` triggered when device theme toggles
3. Check if user preference is "System" before reloading
4. BLoC emits new state with updated `isDarkMode` value
5. MaterialApp rebuilds with correct theme

**Performance:**
- Observer callback is lightweight (only checks BLoC state)
- No unnecessary rebuilds (only when system theme actually changes)
- Properly cleaned up in dispose()

---

## 6. File Structure & Implementation

### 6.1 Complete File Tree

```
lib/
  core/
    domain/
      entities/
        theme_preference.dart                 # NEW - Enum: system/light/dark
      repositories/
        theme_repository.dart                 # NEW - Repository interface
      usecases/
        load_theme_preference_usecase.dart    # NEW - Load saved theme
        save_theme_preference_usecase.dart    # NEW - Save theme preference

    data/
      datasources/
        theme_local_datasource.dart           # NEW - SharedPreferences wrapper
      repositories/
        theme_repository_impl.dart            # NEW - Repository implementation

    presentation/
      bloc/
        theme/
          theme_bloc.dart                     # NEW - Theme state management
          theme_event.dart                    # NEW - LoadThemePreference, ChangeThemeMode
          theme_state.dart                    # NEW - ThemeInitial, Loading, Loaded, Error

  theme/
    app_color.dart                            # MODIFY - Add dark color variants
    app_theme.dart                            # NEW - lightTheme(), darkTheme() factories

  features/
    profile/
      presentation/
        pages/
          settings_page.dart                  # NEW - Settings screen
        widgets/
          theme_selector_widget.dart          # NEW - iOS-style selector

  di/
    service_locator.dart                      # MODIFY - Register theme dependencies

  main.dart                                   # MODIFY - Add ThemeBloc, observer pattern

test/
  core/
    data/
      repositories/
        theme_repository_impl_test.dart       # NEW - Repository tests
    presentation/
      bloc/
        theme/
          theme_bloc_test.dart                # NEW - BLoC tests

  features/
    profile/
      presentation/
        widgets/
          theme_selector_widget_test.dart     # NEW - Widget tests
```

---

### 6.2 Domain Layer Implementation

**6.2.1 Theme Preference Entity**

**NEW FILE: lib/core/domain/entities/theme_preference.dart**

```dart
// ABOUTME: This file defines the theme preference entity
// ABOUTME: Represents user's theme choice: system, light, or dark

enum ThemePreference {
  system,
  light,
  dark;

  /// Convert enum to string for persistence
  String toStorageString() {
    switch (this) {
      case ThemePreference.system:
        return 'system';
      case ThemePreference.light:
        return 'light';
      case ThemePreference.dark:
        return 'dark';
    }
  }

  /// Parse string from storage to enum
  static ThemePreference fromStorageString(String value) {
    switch (value) {
      case 'system':
        return ThemePreference.system;
      case 'light':
        return ThemePreference.light;
      case 'dark':
        return ThemePreference.dark;
      default:
        return ThemePreference.system; // Default fallback
    }
  }
}
```

**Why Enum:**
- Type-safe (no invalid values)
- Easy to serialize/deserialize
- Clear intent in code
- Switch exhaustiveness checking

---

**6.2.2 Theme Repository Interface**

**NEW FILE: lib/core/domain/repositories/theme_repository.dart**

```dart
// ABOUTME: This file defines the theme repository interface
// ABOUTME: Contract for loading and saving theme preferences

import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';

abstract class ThemeRepository {
  /// Load saved theme preference from local storage
  /// Returns Either<Failure, ThemePreference>
  /// Defaults to system if no preference saved
  Future<Either<Failure, ThemePreference>> getThemePreference();

  /// Save theme preference to local storage
  /// Returns Either<Failure, void> for success/failure indication
  Future<Either<Failure, void>> saveThemePreference(ThemePreference preference);
}
```

**Key Points:**
- Uses Either pattern for error handling
- Async operations (SharedPreferences is async)
- Simple contract (2 methods only)

---

**6.2.3 Use Cases**

**NEW FILE: lib/core/domain/usecases/load_theme_preference_usecase.dart**

```dart
// ABOUTME: This use case loads the saved theme preference
// ABOUTME: Returns system theme as default if no preference saved

import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/domain/repositories/theme_repository.dart';

class LoadThemePreferenceUseCase {
  final ThemeRepository repository;

  LoadThemePreferenceUseCase({required this.repository});

  Future<Either<Failure, ThemePreference>> call(NoParams params) async {
    return await repository.getThemePreference();
  }
}

// NoParams class for use cases without parameters
class NoParams {}
```

**NEW FILE: lib/core/domain/usecases/save_theme_preference_usecase.dart**

```dart
// ABOUTME: This use case saves the user's theme preference
// ABOUTME: Persists choice to local storage for future sessions

import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/domain/repositories/theme_repository.dart';

class SaveThemePreferenceUseCase {
  final ThemeRepository repository;

  SaveThemePreferenceUseCase({required this.repository});

  Future<Either<Failure, void>> call(SaveThemeParams params) async {
    return await repository.saveThemePreference(params.mode);
  }
}

class SaveThemeParams {
  final ThemePreference mode;

  SaveThemeParams({required this.mode});
}
```

**Why Use Cases:**
- Single responsibility (one operation per class)
- Easy to test in isolation
- Clear dependencies (only repository)
- Consistent pattern across app

---

### 6.3 Data Layer Implementation

**6.3.1 Local Data Source**

**NEW FILE: lib/core/data/datasources/theme_local_datasource.dart**

```dart
// ABOUTME: This data source manages theme preference in local storage
// ABOUTME: Uses SharedPreferences for persistent storage

import 'package:shared_preferences/shared_preferences.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/error/exceptions.dart';

abstract class ThemeLocalDataSource {
  /// Get saved theme preference
  /// Throws CacheException on failure
  Future<ThemePreference> getThemePreference();

  /// Save theme preference
  /// Throws CacheException on failure
  Future<void> saveThemePreference(ThemePreference preference);
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _themePreferenceKey = 'theme_mode_preference';

  ThemeLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<ThemePreference> getThemePreference() async {
    try {
      final themeString = sharedPreferences.getString(_themePreferenceKey);

      if (themeString == null) {
        // No preference saved, return default
        return ThemePreference.system;
      }

      return ThemePreference.fromStorageString(themeString);
    } catch (e) {
      throw CacheException(message: 'Failed to load theme preference: $e');
    }
  }

  @override
  Future<void> saveThemePreference(ThemePreference preference) async {
    try {
      final success = await sharedPreferences.setString(
        _themePreferenceKey,
        preference.toStorageString(),
      );

      if (!success) {
        throw CacheException(message: 'Failed to save theme preference');
      }
    } catch (e) {
      throw CacheException(message: 'Failed to save theme preference: $e');
    }
  }
}
```

**Design Decisions:**
- Throws exceptions (not Either) - data sources throw, repositories catch
- Single storage key for preference
- Default to system theme if no value saved
- SharedPreferences injected (testable)

---

**6.3.2 Repository Implementation**

**NEW FILE: lib/core/data/repositories/theme_repository_impl.dart**

```dart
// ABOUTME: This repository implements theme persistence operations
// ABOUTME: Converts data source exceptions to domain failures

import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/core/error/exceptions.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/domain/repositories/theme_repository.dart';
import 'package:makerslab_app/core/data/datasources/theme_local_datasource.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeLocalDataSource localDataSource;

  ThemeRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, ThemePreference>> getThemePreference() async {
    try {
      final preference = await localDataSource.getThemePreference();
      return Right(preference);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveThemePreference(
    ThemePreference preference,
  ) async {
    try {
      await localDataSource.saveThemePreference(preference);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }
}
```

**Error Handling:**
- Catches data source exceptions
- Converts to domain Failures
- Preserves error messages for debugging
- Returns Right(null) for successful save (no return value needed)

---

### 6.4 Settings Page Implementation

**NEW FILE: lib/features/profile/presentation/pages/settings_page.dart**

```dart
// ABOUTME: This page displays app settings including theme preferences
// ABOUTME: Provides organized sections for user configuration options

import 'package:flutter/material.dart';
import 'package:makerslab_app/features/profile/presentation/widgets/theme_selector_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: [
            // Theme Section
            const ThemeSelectorWidget(),

            const Divider(height: 32),

            // Future sections can be added here:
            // - Notifications settings
            // - Language preferences
            // - Privacy settings
            // - About app

            _buildSectionPlaceholder(
              context: context,
              title: 'Notificaciones',
              subtitle: 'Próximamente',
            ),

            const Divider(height: 32),

            _buildSectionPlaceholder(
              context: context,
              title: 'Privacidad',
              subtitle: 'Próximamente',
            ),

            const Divider(height: 32),

            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPlaceholder({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acerca de',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Makers Lab v1.0.0',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'App educativa para control de dispositivos IoT',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Design Decisions:**
- ListView for scrollable content (future sections)
- SafeArea for proper screen edge handling
- Dividers separate sections clearly
- Placeholder sections for future features
- Theme-aware colors throughout

---

### 6.5 Dependency Injection Registration

**MODIFY: lib/di/service_locator.dart**

Add theme-related registrations:

```dart
// Add to setupLocator() function, after SharedPreferences registration

// ============ THEME MANAGEMENT ============

// Data sources
getIt.registerLazySingleton<ThemeLocalDataSource>(
  () => ThemeLocalDataSourceImpl(sharedPreferences: getIt()),
);

// Repositories
getIt.registerLazySingleton<ThemeRepository>(
  () => ThemeRepositoryImpl(localDataSource: getIt()),
);

// Use cases
getIt.registerLazySingleton(
  () => LoadThemePreferenceUseCase(repository: getIt()),
);

getIt.registerLazySingleton(
  () => SaveThemePreferenceUseCase(repository: getIt()),
);

// BLoC (singleton - global app state)
getIt.registerLazySingleton<ThemeBloc>(
  () => ThemeBloc(
    loadThemeUseCase: getIt(),
    saveThemeUseCase: getIt(),
  ),
);
```

**Registration Order:**
1. Data sources (depends on SharedPreferences)
2. Repositories (depends on data sources)
3. Use cases (depends on repositories)
4. BLoC (depends on use cases)

**Important:**
- ThemeBloc is `registerLazySingleton` NOT `registerFactory`
- Will be created on first access (when called in main())
- Same instance reused throughout app lifetime

---

### 6.6 Routing Integration

**MODIFY: lib/core/router/app_router.dart**

Add settings route:

```dart
// Add to routes list after ProfilePage routes

GoRoute(
  path: SettingsPage.routeName,
  name: 'settings',
  pageBuilder: (context, state) => NoTransitionPage(
    child: BlocProvider.value(
      value: getIt<ThemeBloc>(), // Reuse singleton instance
      child: const SettingsPage(),
    ),
  ),
),
```

**Why BlocProvider.value:**
- SettingsPage needs access to ThemeBloc
- Don't create new instance (use existing singleton)
- BlocProvider.value passes existing instance down widget tree

---

**MODIFY: lib/features/profile/presentation/pages/profile_page.dart**

Update "Configuración" card onTap:

```dart
// Find the "Configuración" card (around line 81-88)
// Replace the TODO with navigation:

ProfileCard(
  icon: Icons.settings,
  title: 'Configuración',
  subtitle: 'Tema, notificaciones',
  onTap: () {
    context.push(SettingsPage.routeName);
  },
),
```

**Remove:**
- TODO comment about navigation

---

## 7. Testing Strategy

### 7.1 Unit Tests - Repository

**NEW FILE: test/core/data/repositories/theme_repository_impl_test.dart**

```dart
// ABOUTME: Unit tests for theme repository implementation
// ABOUTME: Verifies correct error handling and data source interaction

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/data/datasources/theme_local_datasource.dart';
import 'package:makerslab_app/core/data/repositories/theme_repository_impl.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/error/exceptions.dart';
import 'package:makerslab_app/core/error/failure.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([ThemeLocalDataSource])
import 'theme_repository_impl_test.mocks.dart';

void main() {
  late ThemeRepositoryImpl repository;
  late MockThemeLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockThemeLocalDataSource();
    repository = ThemeRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('getThemePreference', () {
    test('should return theme preference when data source succeeds', () async {
      // Arrange
      when(mockLocalDataSource.getThemePreference())
          .thenAnswer((_) async => ThemePreference.dark);

      // Act
      final result = await repository.getThemePreference();

      // Assert
      expect(result, equals(Right(ThemePreference.dark)));
      verify(mockLocalDataSource.getThemePreference()).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return CacheFailure when data source throws CacheException', () async {
      // Arrange
      when(mockLocalDataSource.getThemePreference())
          .thenThrow(CacheException(message: 'Failed to load'));

      // Act
      final result = await repository.getThemePreference();

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect((failure as CacheFailure).message, contains('Failed to load'));
        },
        (_) => fail('Should return Left'),
      );
    });

    test('should return UnknownFailure on unexpected exception', () async {
      // Arrange
      when(mockLocalDataSource.getThemePreference())
          .thenThrow(Exception('Unexpected error'));

      // Act
      final result = await repository.getThemePreference();

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
        },
        (_) => fail('Should return Left'),
      );
    });
  });

  group('saveThemePreference', () {
    test('should return Right when data source succeeds', () async {
      // Arrange
      when(mockLocalDataSource.saveThemePreference(any))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.saveThemePreference(ThemePreference.dark);

      // Assert
      expect(result, equals(const Right(null)));
      verify(mockLocalDataSource.saveThemePreference(ThemePreference.dark)).called(1);
    });

    test('should return CacheFailure when data source throws CacheException', () async {
      // Arrange
      when(mockLocalDataSource.saveThemePreference(any))
          .thenThrow(CacheException(message: 'Failed to save'));

      // Act
      final result = await repository.saveThemePreference(ThemePreference.dark);

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect((failure as CacheFailure).message, contains('Failed to save'));
        },
        (_) => fail('Should return Left'),
      );
    });
  });
}
```

**Test Coverage:**
- Success cases (happy path)
- Exception handling (CacheException, generic Exception)
- Verify method calls
- Assert return types (Right/Left)

---

### 7.2 BLoC Tests

**NEW FILE: test/core/presentation/bloc/theme/theme_bloc_test.dart**

```dart
// ABOUTME: BLoC tests for theme management
// ABOUTME: Verifies state transitions and event handling

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/presentation/bloc/theme/theme_bloc.dart';
import 'package:makerslab_app/core/presentation/bloc/theme/theme_event.dart';
import 'package:makerslab_app/core/presentation/bloc/theme/theme_state.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/domain/usecases/load_theme_preference_usecase.dart';
import 'package:makerslab_app/core/domain/usecases/save_theme_preference_usecase.dart';
import 'package:makerslab_app/core/error/failure.dart';

@GenerateMocks([LoadThemePreferenceUseCase, SaveThemePreferenceUseCase])
import 'theme_bloc_test.mocks.dart';

void main() {
  late ThemeBloc themeBloc;
  late MockLoadThemePreferenceUseCase mockLoadUseCase;
  late MockSaveThemePreferenceUseCase mockSaveUseCase;

  setUp(() {
    mockLoadUseCase = MockLoadThemePreferenceUseCase();
    mockSaveUseCase = MockSaveThemePreferenceUseCase();
    themeBloc = ThemeBloc(
      loadThemeUseCase: mockLoadUseCase,
      saveThemeUseCase: mockSaveUseCase,
    );
  });

  tearDown(() {
    themeBloc.close();
  });

  test('initial state is ThemeInitial', () {
    expect(themeBloc.state, equals(const ThemeInitial()));
  });

  group('LoadThemePreference', () {
    blocTest<ThemeBloc, ThemeState>(
      'emits [ThemeLoading, ThemeLoaded] when loading succeeds',
      build: () {
        when(mockLoadUseCase(any))
            .thenAnswer((_) async => Right(ThemePreference.dark));
        return themeBloc;
      },
      act: (bloc) => bloc.add(const LoadThemePreference()),
      expect: () => [
        const ThemeLoading(),
        const ThemeLoaded(mode: ThemePreference.dark, isDarkMode: true),
      ],
      verify: (_) {
        verify(mockLoadUseCase(any)).called(1);
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits [ThemeLoading, ThemeLoaded(system)] when loading fails',
      build: () {
        when(mockLoadUseCase(any))
            .thenAnswer((_) async => Left(CacheFailure(message: 'Error')));
        return themeBloc;
      },
      act: (bloc) => bloc.add(const LoadThemePreference()),
      expect: () => [
        const ThemeLoading(),
        const ThemeLoaded(mode: ThemePreference.system, isDarkMode: false),
      ],
    );
  });

  group('ChangeThemeMode', () {
    blocTest<ThemeBloc, ThemeState>(
      'emits ThemeLoaded with new mode when save succeeds',
      build: () {
        when(mockSaveUseCase(any))
            .thenAnswer((_) async => const Right(null));
        return themeBloc;
      },
      act: (bloc) => bloc.add(const ChangeThemeMode(ThemePreference.light)),
      expect: () => [
        const ThemeLoaded(mode: ThemePreference.light, isDarkMode: false),
      ],
      verify: (_) {
        verify(mockSaveUseCase(any)).called(1);
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits [ThemeError, previous state] when save fails',
      build: () {
        when(mockSaveUseCase(any))
            .thenAnswer((_) async => Left(CacheFailure(message: 'Save failed')));
        return themeBloc;
      },
      seed: () => const ThemeLoaded(mode: ThemePreference.system, isDarkMode: false),
      act: (bloc) => bloc.add(const ChangeThemeMode(ThemePreference.dark)),
      expect: () => [
        const ThemeError(message: 'Error al guardar la preferencia de tema'),
        const ThemeLoaded(mode: ThemePreference.system, isDarkMode: false),
      ],
    );
  });
}
```

**Test Scenarios:**
- Initial state verification
- Loading success/failure
- Save success/failure with state reversion
- Verify use case calls

---

### 7.3 Widget Tests

**NEW FILE: test/features/profile/presentation/widgets/theme_selector_widget_test.dart**

```dart
// ABOUTME: Widget tests for theme selector component
// ABOUTME: Verifies UI rendering and user interaction behavior

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:makerslab_app/features/profile/presentation/widgets/theme_selector_widget.dart';
import 'package:makerslab_app/core/presentation/bloc/theme/theme_bloc.dart';
import 'package:makerslab_app/core/presentation/bloc/theme/theme_state.dart';
import 'package:makerslab_app/core/domain/entities/theme_preference.dart';

@GenerateMocks([ThemeBloc])
import 'theme_selector_widget_test.mocks.dart';

void main() {
  late MockThemeBloc mockThemeBloc;

  setUp(() {
    mockThemeBloc = MockThemeBloc();
    when(mockThemeBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ThemeBloc>.value(
          value: mockThemeBloc,
          child: const ThemeSelectorWidget(),
        ),
      ),
    );
  }

  testWidgets('displays all three theme options', (tester) async {
    // Arrange
    when(mockThemeBloc.state).thenReturn(
      const ThemeLoaded(mode: ThemePreference.system, isDarkMode: false),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
  });

  testWidgets('shows correct description for system mode', (tester) async {
    // Arrange
    when(mockThemeBloc.state).thenReturn(
      const ThemeLoaded(mode: ThemePreference.system, isDarkMode: false),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(
      find.text('El tema se ajustará automáticamente según la configuración de tu dispositivo'),
      findsOneWidget,
    );
  });

  testWidgets('shows correct description for light mode', (tester) async {
    // Arrange
    when(mockThemeBloc.state).thenReturn(
      const ThemeLoaded(mode: ThemePreference.light, isDarkMode: false),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(
      find.text('Usa el tema claro en todo momento'),
      findsOneWidget,
    );
  });

  testWidgets('shows correct description for dark mode', (tester) async {
    // Arrange
    when(mockThemeBloc.state).thenReturn(
      const ThemeLoaded(mode: ThemePreference.dark, isDarkMode: true),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(
      find.text('Usa el tema oscuro en todo momento'),
      findsOneWidget,
    );
  });

  // Note: Testing CupertinoSlidingSegmentedControl interaction is complex
  // and may require integration tests. Focus on state display verification.
}
```

**Widget Test Focus:**
- Verify all options render
- Correct description text for each mode
- State reflection in UI
- (Integration tests needed for tap interactions)

---

### 7.4 Test Coverage Goals

**Minimum Coverage (80%):**
- Repository: 100% (critical path)
- BLoC: 90%+ (all events/states)
- Use cases: 100% (simple logic)
- Widgets: 70%+ (rendering verification)

**Run Coverage:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 8. Pitfalls & Performance

### 8.1 Common Dark Mode Pitfalls

**PITFALL 1: Theme Flicker on App Start**

**Problem:**
- App shows light theme briefly, then switches to dark
- Happens when theme loads asynchronously after MaterialApp builds

**Solution:**
- Pre-load theme in main() BEFORE runApp() (as shown in section 1.2)
- Use timeout to prevent hanging app
- Cache theme in ThemeBloc singleton

---

**PITFALL 2: Hardcoded Colors Break in Dark Mode**

**Problem:**
```dart
// BAD - hardcoded colors don't adapt
Container(
  color: Colors.white,
  child: Text('Hello', style: TextStyle(color: Colors.black)),
)
```

**Solution:**
```dart
// GOOD - use theme colors
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Hello',
    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
  ),
)
```

**Action Required:**
- **Audit ALL existing widgets** for hardcoded colors
- Replace with theme-aware colors
- Common culprits:
  - `Colors.white` → `theme.colorScheme.surface`
  - `Colors.black` → `theme.colorScheme.onSurface`
  - `Colors.grey[300]` → `theme.colorScheme.surfaceVariant`

---

**PITFALL 3: Asset Images Without Dark Variants**

**Problem:**
- Light-themed images look bad on dark backgrounds
- Example: White logo on white surface vs white logo on dark surface

**Solutions:**
1. **Use SVG with theme colors** (preferred)
2. **Provide dark variants:**
   ```dart
   Image.asset(
     isDarkMode
       ? 'assets/images/logo_dark.png'
       : 'assets/images/logo_light.png',
   )
   ```
3. **Apply color filter:**
   ```dart
   ColorFiltered(
     colorFilter: ColorFilter.mode(
       Theme.of(context).colorScheme.primary,
       BlendMode.srcIn,
     ),
     child: Image.asset('assets/images/icon.png'),
   )
   ```

---

**PITFALL 4: System Theme Detection Not Working**

**Problem:**
- App doesn't update when device theme changes in Settings

**Solution:**
- Implement WidgetsBindingObserver (as shown in section 5.2)
- **Must** clean up observer in dispose()
- Only reload if user preference is "System"

---

**PITFALL 5: Unnecessary Rebuilds**

**Problem:**
```dart
// BAD - rebuilds entire tree on theme change
return Consumer<ThemeProvider>(
  builder: (context, theme, _) {
    return MaterialApp(...);
  },
);
```

**Solution:**
```dart
// GOOD - MaterialApp only rebuilds when ThemeBloc emits
return BlocBuilder<ThemeBloc, ThemeState>(
  builder: (context, themeState) {
    return MaterialApp(...);
  },
);
```

**Why BlocBuilder is Better:**
- More efficient state updates
- Only rebuilds when state actually changes
- MaterialApp's built-in theme switching handles child rebuilds

---

### 8.2 Performance Optimization

**OPTIMIZATION 1: Theme Preloading**

- Load theme in main() (adds ~50ms startup time)
- Prevents flicker (better UX worth the cost)
- Use timeout to prevent hang

**OPTIMIZATION 2: Minimal BLoC Rebuilds**

- Only MaterialApp wrapped in BlocBuilder
- Child widgets use `Theme.of(context)` (no rebuilds)
- Flutter's theme propagation is highly optimized

**OPTIMIZATION 3: Const Constructors**

```dart
// Use const wherever possible
const ThemeSelectorWidget({super.key});
const SizedBox(height: 16);
const EdgeInsets.symmetric(horizontal: 16.0);
```

**Benefits:**
- Widget caching by Flutter
- Reduced allocations
- Faster rebuilds

**OPTIMIZATION 4: Asset Loading**

- Pre-cache critical images on splash screen
- Use `precacheImage()` for theme-specific assets

---

### 8.3 Memory Management

**CRITICAL: Clean Up Observer**

```dart
@override
void dispose() {
  // MUST remove observer to prevent memory leak
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

**Why It Matters:**
- WidgetsBindingObserver holds reference to widget
- Not removing causes memory leak
- Widget won't be garbage collected

---

### 8.4 Accessibility Considerations

**HIGH CONTRAST MODE:**

Flutter automatically adjusts for high contrast accessibility setting:
```dart
// Check if high contrast is enabled
final bool highContrast = MediaQuery.of(context).highContrast;

// Adjust colors accordingly
final Color textColor = highContrast
    ? Colors.white // Maximum contrast
    : theme.colorScheme.onSurface; // Standard contrast
```

**SCREEN READERS:**

- CupertinoSlidingSegmentedControl has built-in accessibility
- Ensure semantic labels are clear
- Test with TalkBack (Android) and VoiceOver (iOS)

**MINIMUM CONTRAST:**
- Text: 4.5:1 (WCAG AA)
- Large text: 3:1 (WCAG AA)
- Interactive elements: 3:1 (WCAG AA)

---

## 9. Migration Path

### Phase 1: Infrastructure (Days 1-2)
1. Create domain layer (entities, repositories, use cases)
2. Create data layer (data sources, repository impl)
3. Create BLoC (events, states, bloc)
4. Register in DI
5. Write unit tests

**Deliverable:** Theme persistence working (no UI yet)

---

### Phase 2: Color System (Day 3)
1. Add dark colors to AppColors
2. Create AppTheme with lightTheme()/darkTheme()
3. Test color contrast ratios
4. Document color usage guidelines

**Deliverable:** Dark theme colors defined and validated

---

### Phase 3: UI Integration (Days 4-5)
1. Create SettingsPage
2. Create ThemeSelectorWidget
3. Update ProfilePage navigation
4. Add route to app_router

**Deliverable:** Settings page with theme selector functional

---

### Phase 4: App Integration (Day 6)
1. Modify main.dart (pre-load theme, BlocBuilder, observer)
2. Convert MyApp to StatefulWidget
3. Add WidgetsBindingObserver
4. Test theme switching

**Deliverable:** Dark mode fully functional with system detection

---

### Phase 5: Widget Audit (Days 7-8)
1. **CRITICAL:** Audit ALL existing widgets for hardcoded colors
2. Replace with theme-aware colors
3. Test every module in dark mode:
   - Temperature
   - Servo
   - LightControl
   - Gamepad
   - Chat
   - Profile
   - Home
   - Auth pages

**Deliverable:** All screens work correctly in dark mode

---

### Phase 6: Testing (Days 9-10)
1. Write repository tests
2. Write BLoC tests
3. Write widget tests
4. Integration tests for theme switching
5. Manual QA on physical devices

**Deliverable:** >80% test coverage, all tests passing

---

### Phase 7: Polish & Documentation (Day 11)
1. Fix any visual inconsistencies
2. Test edge cases (rapid switching, low memory)
3. Update README with theme system docs
4. Record demo video

**Deliverable:** Production-ready dark mode feature

---

## 10. Final Checklist

Before submitting PR, verify:

**Architecture:**
- [ ] Clean Architecture layers properly separated
- [ ] ThemeBloc registered as singleton in DI
- [ ] Either pattern used for error handling
- [ ] Use cases follow single responsibility

**Implementation:**
- [ ] Theme pre-loaded in main() before app starts
- [ ] WidgetsBindingObserver properly implemented and cleaned up
- [ ] MaterialApp uses theme/darkTheme/themeMode pattern
- [ ] ThemeSelectorWidget uses CupertinoSlidingSegmentedControl
- [ ] All colors in AppColors defined (light + dark variants)
- [ ] AppTheme factory methods created

**Integration:**
- [ ] SettingsPage created and routed correctly
- [ ] ProfilePage navigation updated
- [ ] ALL existing widgets audited for hardcoded colors
- [ ] Spanish localization for all UI text

**Testing:**
- [ ] Repository tests written (100% coverage)
- [ ] BLoC tests written (>90% coverage)
- [ ] Widget tests written (>70% coverage)
- [ ] Manual testing on Android + iOS
- [ ] System theme detection tested

**Code Quality:**
- [ ] ABOUTME comments in all new files
- [ ] dart format lib/ test/ applied
- [ ] flutter analyze with no errors
- [ ] No hardcoded colors remaining
- [ ] Const constructors used throughout

**Documentation:**
- [ ] Session file updated with decisions
- [ ] Implementation notes documented
- [ ] Known issues logged (if any)

---

## Conclusion

This implementation plan provides a complete blueprint for adding dark mode to Makers Lab following Clean Architecture and BLoC patterns. The approach prioritizes:

1. **User Experience**: No theme flicker, smooth transitions
2. **Code Quality**: Testable, maintainable, follows existing patterns
3. **Performance**: Minimal rebuilds, efficient state management
4. **Accessibility**: High contrast support, semantic labels

By following this plan, David will have a production-ready dark mode feature that integrates seamlessly with the existing codebase and provides an excellent user experience.

**Estimated Timeline:** 11 days (can be compressed to 7-8 days with focused work)

**Key Success Factors:**
- Pre-loading theme prevents flicker
- System detection with WidgetsBindingObserver
- Singleton ThemeBloc for global state
- Comprehensive widget audit for hardcoded colors
- Thorough testing (>80% coverage)

**Next Steps:**
1. Review this plan with David
2. Get approval on color scheme and UX decisions
3. Begin Phase 1 (Infrastructure) implementation
4. Continuously update session file with progress and decisions
