# Dark Mode Implementation - Expert Architectural Advice Summary

**Date**: 2025-11-12
**For**: David - Makers Lab Dark Mode Feature
**Context**: Flutter 3.7.2+ with Clean Architecture + Classic BLoC Pattern

---

## Executive Summary

I've provided comprehensive architectural guidance for implementing dark mode with iOS-style triple selector in your Makers Lab Flutter app. The solution prioritizes **user experience** (no flicker), **code quality** (testable, maintainable), and **performance** (efficient rebuilds) while strictly following your existing Clean Architecture and BLoC patterns.

**Key deliverable**: `/Users/LAPTOP-david-001/Development/apps/Flutter/makerslab_app/.claude/docs/dark_mode/flutter-frontend.md` (10,000+ words, production-ready implementation plan)

---

## Your 7 Questions - Quick Answers

### 1. Theme State Management Pattern

**✅ ThemeBloc Registration: SINGLETON (Lazy)**

```dart
// lib/di/service_locator.dart
getIt.registerLazySingleton<ThemeBloc>(  // NOT registerFactory
  () => ThemeBloc(
    loadThemeUseCase: getIt(),
    saveThemeUseCase: getIt(),
  ),
);
```

**Why Singleton:**
- Theme is global app state (like your existing AuthBloc, BluetoothBloc, ChatBloc)
- Single source of truth throughout app lifetime
- Survives navigation changes

**Initial Theme Loading:**
```dart
// lib/main.dart - BEFORE runApp()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // PRE-LOAD to prevent flicker
  final themeBloc = getIt<ThemeBloc>();
  themeBloc.add(LoadThemePreference());

  await themeBloc.stream.firstWhere(
    (state) => state is ThemeLoaded,
  ).timeout(const Duration(milliseconds: 500));

  // ... rest of main()
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: themeBloc), // Use .value for existing instance
        // ... other providers
      ],
      child: const MyApp(),
    ),
  );
}
```

**Theme Switching:**
Use `BlocBuilder` with MaterialApp's native theme switching:

```dart
class MyApp extends StatelessWidget {
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
          theme: AppTheme.lightTheme(),      // ← Used when light
          darkTheme: AppTheme.darkTheme(),   // ← Used when dark
          themeMode: effectiveThemeMode,     // ← Controls which
          // ... rest of config
        );
      },
    );
  }
}
```

**Why This Pattern:**
- MaterialApp handles theme switching natively (no manual rebuilds)
- BlocBuilder only rebuilds MaterialApp when theme changes (efficient)
- System theme detection built-in

---

### 2. iOS-Style Theme Selector Widget

**✅ RECOMMENDATION: CupertinoSlidingSegmentedControl**

**Comparison:**

| Feature | CupertinoSlidingSegmentedControl | Material SegmentedButton |
|---------|----------------------------------|--------------------------|
| Animation | ✅ Smooth sliding | ⚠️ Less fluid |
| UX | ✅ Industry standard | ⚠️ Less familiar |
| Cross-platform | ✅ Works great on Android too | ✅ Native Material |
| Code complexity | ✅ Minimal | ⚠️ More styling needed |
| Design compliance | ⚠️ iOS-style | ✅ Material Design 3 |

**Decision: CupertinoSlidingSegmentedControl**

**Rationale:**
1. Educational context (users familiar with iOS controls)
2. Smoother UX trumps strict Material adherence
3. Even Google apps use iOS-style controls sometimes
4. Easier to implement and maintain

**Implementation Preview:**
```dart
CupertinoSlidingSegmentedControl<ThemePreference>(
  groupValue: currentMode,
  backgroundColor: isDarkMode ? theme.colorScheme.surface : Colors.grey.shade300,
  thumbColor: theme.colorScheme.primary,
  children: {
    ThemePreference.system: _buildSegment(icon: Icons.brightness_auto, label: 'Sistema'),
    ThemePreference.light: _buildSegment(icon: Icons.light_mode, label: 'Claro'),
    ThemePreference.dark: _buildSegment(icon: Icons.dark_mode, label: 'Oscuro'),
  },
  onValueChanged: (value) {
    context.read<ThemeBloc>().add(ChangeThemeMode(value));
  },
)
```

**Visual Result:**
- Three segments with icons + labels
- Smooth sliding animation on selection
- Description text updates below selector
- Theme-aware colors (works in light and dark)

---

### 3. Dark Theme Color Scheme

**✅ Material Design 3 Dark Theme with Pre-defined Colors**

**Primary Color Adaptations:**

| Color | Light Theme | Dark Theme | Reason |
|-------|-------------|------------|--------|
| Primary | `#247BA0` | `#5EB1E8` | 40% lighter for visibility |
| Primary Container | `#E8F6EC` | `#004F7A` | Dark blue, visible on dark surface |
| On Primary | `#FFFFFF` | `#003548` | Dark text for contrast |
| On Primary Container | `#00461A` | `#B8E7FF` | Light text for contrast |

**Complete Color System:**
```dart
// lib/theme/app_color.dart - ADD these dark variants

class AppColors {
  // ... existing light colors ...

  // Dark theme surfaces (Material Design 3)
  static const darkSurface = Color(0xFF1C1B1F);           // Main surface
  static const darkSurfaceVariant = Color(0xFF2B2930);    // Elevated +1dp
  static const darkBackground = Color(0xFF1C1B1F);

  // Dark theme primary
  static const darkPrimary = Color(0xFF5EB1E8);           // Lighter blue
  static const darkOnPrimary = Color(0xFF003548);
  static const darkPrimaryContainer = Color(0xFF004F7A);
  static const darkOnPrimaryContainer = Color(0xFFB8E7FF);

  // Dark theme text
  static const darkOnSurface = Color(0xFFE6E1E5);         // 87% white
  static const darkOnSurfaceVariant = Color(0xFFCAC4D0);  // 60% white
  static const darkOutline = Color(0xFF938F99);           // 38% white

  // Module colors adapted for dark
  static const darkLightGreen = Color(0xFFA5D57B);        // Gamepad (brighter)
  static const darkBlue = Color(0xFF64B5F6);              // Sensor DHT (lighter)
  static const darkRed = Color(0xFFEF5350);               // Servos (lighter)
  static const darkOrange = Color(0xFFFFB74D);            // Light Control (lighter)
  static const darkPurple = Color(0xFFBA68C8);            // Chat (lighter)
}
```

**Theme Factory Pattern:**
```dart
// NEW FILE: lib/theme/app_theme.dart

class AppTheme {
  AppTheme._(); // Private constructor

  static ThemeData lightTheme() {
    return ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        // ... complete scheme in full doc
      ),
      // ... AppBarTheme, CardTheme, InputDecorationTheme, etc.
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        // ... complete dark scheme in full doc
      ),
      // ... Dark theme component themes
    );
  }
}
```

**Design Principles:**
- NO runtime color transformations (pre-defined for performance)
- Each color fine-tuned for optimal contrast
- WCAG AA compliant (4.5:1 contrast for text)
- Module colors slightly brighter in dark mode

---

### 4. Theme Persistence & System Theme Detection

**✅ WidgetsBindingObserver Pattern for System Theme**

**Challenge**: When user selects "System", app must:
1. Reflect current device theme immediately
2. Update automatically when device theme changes
3. Not leak memory

**Solution:**
```dart
// lib/main.dart - Convert MyApp to StatefulWidget

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // CRITICAL: Prevent leak
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
        themeBloc.add(const LoadThemePreference());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>( /* ... */ );
  }
}
```

**How It Works:**
1. Observer monitors platform-level brightness changes
2. `didChangePlatformBrightness()` triggered when device theme toggles
3. Check if preference is "System" before reloading (avoid unnecessary work)
4. BLoC emits new state with updated `isDarkMode`
5. MaterialApp rebuilds with correct theme

**CRITICAL:**
- **MUST** call `removeObserver()` in dispose() to prevent memory leak
- Only check/reload when preference is "System"
- Lightweight callback (no heavy work)

**Persistence:**
```dart
// lib/core/data/datasources/theme_local_datasource.dart

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _themePreferenceKey = 'theme_mode_preference';

  @override
  Future<ThemePreference> getThemePreference() async {
    final themeString = sharedPreferences.getString(_themePreferenceKey);
    return themeString == null
        ? ThemePreference.system // Default
        : ThemePreference.fromStorageString(themeString);
  }

  @override
  Future<void> saveThemePreference(ThemePreference preference) async {
    await sharedPreferences.setString(
      _themePreferenceKey,
      preference.toStorageString(), // 'system', 'light', or 'dark'
    );
  }
}
```

---

### 5. Integration Architecture

**✅ Three-Layer Integration: BLoC → MaterialApp → Routes**

**Layer 1: Main App (lib/main.dart)**
```dart
void main() async {
  // 1. Pre-load theme (prevent flicker)
  final themeBloc = getIt<ThemeBloc>();
  themeBloc.add(LoadThemePreference());
  await themeBloc.stream.firstWhere(/* ... */).timeout(/* ... */);

  // 2. Provide to app
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: themeBloc), // Existing instance
        // ... other providers
      ],
      child: const MyApp(),
    ),
  );
}
```

**Layer 2: Theme Application (MyApp Widget)**
```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Observer for system theme detection (see Q4)

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp.router(
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: _computeThemeMode(themeState),
          // ... localization, routing, etc.
        );
      },
    );
  }

  ThemeMode _computeThemeMode(ThemeState state) {
    if (state is ThemeLoaded) {
      return switch (state.mode) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      };
    }
    return ThemeMode.system; // Default
  }
}
```

**Layer 3: Settings Navigation**
```dart
// lib/core/router/app_router.dart
GoRoute(
  path: SettingsPage.routeName,
  name: 'settings',
  pageBuilder: (context, state) => NoTransitionPage(
    child: BlocProvider.value(
      value: getIt<ThemeBloc>(), // Reuse singleton
      child: const SettingsPage(),
    ),
  ),
),

// lib/features/profile/presentation/pages/profile_page.dart
ProfileCard(
  icon: Icons.settings,
  title: 'Configuración',
  onTap: () => context.push(SettingsPage.routeName),
),
```

**Splash Screen Handling:**
- Theme pre-loaded in main() BEFORE splash screen appears
- No special handling needed (theme already ready)
- 500ms timeout ensures app doesn't hang if loading fails

**Theme vs ColorScheme:**
- Use **both** `theme` and `darkTheme` in MaterialApp
- Each contains full ThemeData (ColorScheme + component themes)
- MaterialApp automatically picks based on `themeMode`

---

### 6. Testing Strategy

**✅ Comprehensive Multi-Layer Testing**

**Coverage Requirements:**
- **Repository**: 100% (critical persistence path)
- **BLoC**: 90%+ (all events/states)
- **Use Cases**: 100% (simple logic)
- **Widgets**: 70%+ (rendering verification)
- **Overall Feature**: >80%

**Test Structure:**
```
test/
  core/
    data/
      repositories/
        theme_repository_impl_test.dart      # Unit tests with mocked SharedPreferences
    presentation/
      bloc/
        theme/
          theme_bloc_test.dart                # BLoC tests with bloc_test package
  features/
    profile/
      presentation/
        widgets/
          theme_selector_widget_test.dart     # Widget rendering tests
```

**Critical Test Scenarios:**

**1. Repository Tests (Unit)**
```dart
test('should return theme preference when data source succeeds', () async {
  // Arrange: Mock data source
  when(mockLocalDataSource.getThemePreference())
      .thenAnswer((_) async => ThemePreference.dark);

  // Act
  final result = await repository.getThemePreference();

  // Assert
  expect(result, equals(Right(ThemePreference.dark)));
});

test('should return CacheFailure when data source throws exception', () async {
  when(mockLocalDataSource.getThemePreference())
      .thenThrow(CacheException(message: 'Failed'));

  final result = await repository.getThemePreference();

  expect(result, isA<Left>());
});
```

**2. BLoC Tests (State Management)**
```dart
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
);
```

**3. Widget Tests (UI Rendering)**
```dart
testWidgets('displays all three theme options', (tester) async {
  when(mockThemeBloc.state).thenReturn(
    const ThemeLoaded(mode: ThemePreference.system, isDarkMode: false),
  );

  await tester.pumpWidget(createWidgetUnderTest());

  expect(find.text('Sistema'), findsOneWidget);
  expect(find.text('Claro'), findsOneWidget);
  expect(find.text('Oscuro'), findsOneWidget);
});
```

**4. Manual QA (CRITICAL)**
Test EVERY module in dark mode:
- ✅ Temperature sensor page
- ✅ Servo control page
- ✅ Light control page
- ✅ Gamepad page
- ✅ Chat interface
- ✅ Profile pages
- ✅ Home screen
- ✅ Auth pages (login, signup, OTP)

**Mock Strategy:**
```dart
// Use mockito for generating mocks
@GenerateMocks([
  ThemeLocalDataSource,
  LoadThemePreferenceUseCase,
  SaveThemePreferenceUseCase,
  ThemeBloc,
])
```

**Run Tests:**
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

### 7. Potential Pitfalls

**✅ 5 CRITICAL Pitfalls + Mitigations**

**PITFALL 1: Theme Flicker on App Start**

**Problem:**
```dart
// BAD - theme loads after MaterialApp builds
void main() {
  runApp(MyApp()); // Shows light theme briefly
}

// ThemeBloc loads asynchronously later → flicker
```

**Mitigation:**
```dart
// GOOD - pre-load theme BEFORE runApp()
void main() async {
  final themeBloc = getIt<ThemeBloc>();
  themeBloc.add(LoadThemePreference());
  await themeBloc.stream.firstWhere(/* ... */).timeout(500ms);

  runApp(MyApp()); // Theme ready!
}
```

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

**Mitigation:**
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

**CRITICAL ACTION: Widget Audit**
Before launching dark mode, scan ALL existing widgets:
- Replace `Colors.white` → `theme.colorScheme.surface`
- Replace `Colors.black` → `theme.colorScheme.onSurface`
- Replace `Colors.grey[X]` → `theme.colorScheme.surfaceVariant`

---

**PITFALL 3: System Theme Detection Not Working**

**Problem:**
User selects "System" mode, but app doesn't update when device theme changes.

**Mitigation:**
```dart
// Implement WidgetsBindingObserver (see Q4)
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // CRITICAL: Clean up
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // React to system theme change
    final themeBloc = context.read<ThemeBloc>();
    if (themeBloc.state is ThemeLoaded &&
        (themeBloc.state as ThemeLoaded).mode == ThemePreference.system) {
      themeBloc.add(const LoadThemePreference());
    }
  }
}
```

---

**PITFALL 4: Unnecessary Rebuilds (Performance)**

**Problem:**
```dart
// BAD - entire tree rebuilds on theme change
Widget build(BuildContext context) {
  return BlocBuilder<ThemeBloc, ThemeState>(
    builder: (context, state) {
      return Scaffold( // Entire tree rebuilds!
        body: ComplexWidgetTree(...),
      );
    },
  );
}
```

**Mitigation:**
```dart
// GOOD - only MaterialApp in BlocBuilder
Widget build(BuildContext context) {
  return BlocBuilder<ThemeBloc, ThemeState>(
    builder: (context, state) {
      return MaterialApp.router(...); // Only this rebuilds
    },
  );
}

// Children use Theme.of(context) - no rebuilds
Widget build(BuildContext context) {
  final theme = Theme.of(context); // Inherited, not rebuilt
  return Container(color: theme.colorScheme.surface);
}
```

---

**PITFALL 5: Memory Leak from Observer**

**Problem:**
```dart
// BAD - observer never removed
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
  }

  // Missing dispose() → memory leak!
}
```

**Mitigation:**
```dart
// GOOD - always clean up
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this); // CRITICAL
  super.dispose();
}
```

**Why Critical:**
- Observer holds reference to widget
- Widget won't be garbage collected
- Memory usage grows over time

---

## Implementation Timeline

**Total Estimate: 11 days** (can compress to 7-8 with focused work)

**Phase 1 (Days 1-2): Infrastructure**
- Domain layer (entities, repositories, use cases)
- Data layer (data sources, repository impl)
- BLoC (events, states, bloc)
- DI registration
- Unit tests

**Phase 2 (Day 3): Color System**
- Add dark colors to AppColors
- Create AppTheme.lightTheme()/darkTheme()
- Test contrast ratios

**Phase 3 (Days 4-5): UI Integration**
- Create SettingsPage
- Create ThemeSelectorWidget (iOS-style)
- Update ProfilePage navigation
- Add route

**Phase 4 (Day 6): App Integration**
- Modify main.dart (pre-load, BlocBuilder, observer)
- Test theme switching
- Test system detection

**Phase 5 (Days 7-8): Widget Audit** ⚠️ CRITICAL
- Scan ALL existing widgets for hardcoded colors
- Replace with theme-aware colors
- Test every module in dark mode

**Phase 6 (Days 9-10): Testing**
- Repository tests
- BLoC tests
- Widget tests
- Manual QA on physical devices

**Phase 7 (Day 11): Polish**
- Fix visual inconsistencies
- Edge case testing
- Documentation

---

## Key Files to Create/Modify

**NEW FILES (13 files):**
```
lib/core/domain/entities/theme_preference.dart
lib/core/domain/repositories/theme_repository.dart
lib/core/domain/usecases/load_theme_preference_usecase.dart
lib/core/domain/usecases/save_theme_preference_usecase.dart
lib/core/data/datasources/theme_local_datasource.dart
lib/core/data/repositories/theme_repository_impl.dart
lib/core/presentation/bloc/theme/theme_bloc.dart
lib/core/presentation/bloc/theme/theme_event.dart
lib/core/presentation/bloc/theme/theme_state.dart
lib/theme/app_theme.dart
lib/features/profile/presentation/pages/settings_page.dart
lib/features/profile/presentation/widgets/theme_selector_widget.dart

test/core/data/repositories/theme_repository_impl_test.dart
test/core/presentation/bloc/theme/theme_bloc_test.dart
test/features/profile/presentation/widgets/theme_selector_widget_test.dart
```

**MODIFY FILES (4 files):**
```
lib/main.dart                                # Pre-load theme, observer, BlocBuilder
lib/theme/app_color.dart                     # Add dark color variants
lib/di/service_locator.dart                  # Register theme dependencies
lib/core/router/app_router.dart              # Add settings route
lib/features/profile/presentation/pages/profile_page.dart  # Navigation to settings
```

---

## Next Steps for David

1. **Review Full Implementation Plan**
   - Location: `/Users/LAPTOP-david-001/Development/apps/Flutter/makerslab_app/.claude/docs/dark_mode/flutter-frontend.md`
   - 10,000+ words with complete code examples

2. **Approve Color Scheme**
   - Primary Dark: #5EB1E8 (40% lighter than #247BA0)
   - All dark variants defined in plan

3. **Begin Phase 1 Implementation**
   - Start with Domain layer (simplest)
   - Follow file structure in plan
   - Update session file after each phase

4. **Schedule Widget Audit**
   - Phase 5 is CRITICAL
   - Must scan ALL existing widgets
   - Replace hardcoded colors

5. **Plan Testing Days**
   - Reserve Days 9-10 for comprehensive testing
   - Manual QA on physical devices required
   - >80% coverage mandatory

---

## Documentation Locations

**Main Implementation Plan:**
`/Users/LAPTOP-david-001/Development/apps/Flutter/makerslab_app/.claude/docs/dark_mode/flutter-frontend.md`

**Session Context:**
`/Users/LAPTOP-david-001/Development/apps/Flutter/makerslab_app/.claude/sessions/context_session_dark_mode.md`

**This Summary:**
`/Users/LAPTOP-david-001/Development/apps/Flutter/makerslab_app/.claude/docs/dark_mode/architectural-advice-summary.md`

---

## Final Checklist

Before submitting PR, verify:

**Architecture:**
- [ ] ThemeBloc registered as singleton
- [ ] Theme pre-loaded in main()
- [ ] WidgetsBindingObserver implemented and cleaned up
- [ ] MaterialApp uses theme/darkTheme/themeMode

**Implementation:**
- [ ] All domain/data/presentation layers created
- [ ] AppTheme factory methods created
- [ ] ThemeSelectorWidget uses CupertinoSlidingSegmentedControl
- [ ] Dark colors defined in AppColors
- [ ] ALL widgets audited for hardcoded colors

**Testing:**
- [ ] Repository tests (100% coverage)
- [ ] BLoC tests (90%+ coverage)
- [ ] Widget tests (70%+ coverage)
- [ ] Manual QA on ALL modules in dark mode
- [ ] System theme detection tested

**Code Quality:**
- [ ] ABOUTME comments in all new files
- [ ] dart format applied
- [ ] flutter analyze with no errors
- [ ] >80% overall test coverage

---

## Questions?

If you need clarification on any architectural decision, please ask. I'm ready to provide:
- Additional code examples
- Alternative approaches with trade-off analysis
- Specific guidance on widget audit process
- Testing strategy details

All advice aligns with your existing Clean Architecture + BLoC patterns and follows CLAUDE.md guidelines.
