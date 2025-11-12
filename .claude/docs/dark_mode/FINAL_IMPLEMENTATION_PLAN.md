# Dark Mode Feature - Final Implementation Plan

**Date**: 2025-11-12
**Feature**: Dark mode with iOS-style triple selector (System, Light, Dark)
**Location**: Settings page inside Profile section
**Timeline**: 7-8 days (compressed schedule)
**Status**: ✅ APPROVED - Ready for implementation

---

## Executive Summary

Implement comprehensive dark mode support for Makers Lab Flutter app following Clean Architecture and classic BLoC patterns. The feature includes:
- iOS-style triple selector (System/Light/Dark) in Settings page
- Complete Material Design 3 dark theme
- Persistent theme preference using SharedPreferences
- System theme detection with WidgetsBindingObserver
- Comprehensive widget audit for all modules
- Automated testing with >80% coverage

---

## Branch Strategy

**Branch**: `feat/dark-mode-settings`
**Base**: `develop` (will create if doesn't exist)
**Target**: `develop`
**Workflow**: Standard feature branch → PR → Review → Merge

```bash
# Create and checkout feature branch
git checkout develop
git pull origin develop
git checkout -b feat/dark-mode-settings

# After implementation
git add .
git commit -m "feat: implement dark mode with iOS-style triple selector

- Add theme infrastructure (domain/data/presentation layers)
- Create dark theme colors and AppTheme factory
- Implement SettingsPage with CupertinoSlidingSegmentedControl
- Integrate theme switching in main.dart with system detection
- Audit ALL widgets for hardcoded colors
- Add comprehensive automated tests

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feat/dark-mode-settings

# Create PR to develop
gh pr create --title "feat: Dark Mode with iOS-style Triple Selector" \
  --body "## Summary
- Implements dark mode following Clean Architecture + BLoC patterns
- iOS-style theme selector in Settings page (System/Light/Dark)
- Material Design 3 compliant dark theme
- System theme detection with WidgetsBindingObserver
- Comprehensive widget audit across all modules
- >80% test coverage

## Testing
- ✅ Unit tests (Repository, Use Cases)
- ✅ BLoC tests (all events/states)
- ✅ Widget tests (ThemeSelectorWidget)
- ✅ Manual QA on critical paths

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

---

## Approved Architectural Decisions

### 1. Color Scheme ✅
- **Primary Dark**: `#5EB1E8` (40% lighter than light mode `#247BA0`)
- **Permission**: Create additional colors as needed following Material Design 3
- **Validation**: WCAG AA compliant (4.5:1 contrast minimum)

### 2. Widget Audit Scope ✅
- **Comprehensive**: Fix ALL modules in this feature
- **Modules**: Temperature, Servo, LightControl, Gamepad, Chat, Profile, Home, Auth
- **Action**: Replace hardcoded colors with theme-aware equivalents

### 3. Timeline ✅
- **Duration**: 7-8 days (compressed, focused work)
- **Priority**: Core functionality over extensive polish
- **Iteration**: Visual refinements in future updates if needed

### 4. Theme Selector UI ✅
- **Widget**: CupertinoSlidingSegmentedControl (iOS-style)
- **Rationale**: Better UX, smoother animation, industry standard
- **Cross-platform**: Works great on both Android and iOS

### 5. Settings Page Scope ✅
- **Primary**: Theme selector section
- **Placeholders**: Notifications, Language, About (coming soon labels)
- **Design**: Allows incremental feature additions

### 6. Performance ✅
- **Startup Cost**: 50-100ms (acceptable for flicker prevention)
- **Trade-off**: Better UX prioritized over minimal startup time

### 7. Testing Strategy ✅
- **Focus**: Automated tests (unit, BLoC, widget)
- **Coverage**: >80% mandatory
- **Manual QA**: Minimal, only critical paths

### 8. ThemeBloc Registration ✅
- **Type**: Singleton (registerLazySingleton)
- **Pattern**: Same as AuthBloc, BluetoothBloc, ChatBloc
- **Rationale**: Global app state, single source of truth

---

## Implementation Timeline (7-8 Days)

### Day 1-2: Infrastructure & Foundation
**Goal**: Complete Domain, Data, and Presentation layers

**Tasks**:
1. Create domain entities and repository interface
2. Implement data layer with SharedPreferences
3. Build ThemeBloc with events and states
4. Register dependencies in service_locator.dart
5. Write unit tests for repository and use cases

**Deliverables**:
- `lib/core/domain/entities/theme_preference.dart`
- `lib/core/domain/repositories/theme_repository.dart`
- `lib/core/domain/usecases/load_theme_preference_usecase.dart`
- `lib/core/domain/usecases/save_theme_preference_usecase.dart`
- `lib/core/data/datasources/theme_local_datasource.dart`
- `lib/core/data/repositories/theme_repository_impl.dart`
- `lib/core/presentation/bloc/theme/theme_bloc.dart`
- `lib/core/presentation/bloc/theme/theme_event.dart`
- `lib/core/presentation/bloc/theme/theme_state.dart`
- `test/core/data/repositories/theme_repository_impl_test.dart`

**Success Criteria**:
- All layers follow Clean Architecture
- Repository returns Either<Failure, Success>
- 100% test coverage for repository

---

### Day 3: Theme System & Colors
**Goal**: Complete dark theme color system and theme factory

**Tasks**:
1. Add dark color variants to AppColors
2. Create AppTheme with lightTheme() and darkTheme() static methods
3. Validate contrast ratios (WebAIM checker)
4. Test color system in isolation

**Deliverables**:
- `lib/theme/app_color.dart` (modified with dark colors)
- `lib/theme/app_theme.dart` (new file)

**Color Additions to AppColors**:
```dart
// Dark theme surfaces
static const darkSurface = Color(0xFF1C1B1F);
static const darkSurfaceVariant = Color(0xFF2B2930);
static const darkBackground = Color(0xFF1C1B1F);

// Dark theme primary
static const darkPrimary = Color(0xFF5EB1E8);
static const darkOnPrimary = Color(0xFF003548);
static const darkPrimaryContainer = Color(0xFF004F7A);
static const darkOnPrimaryContainer = Color(0xFFB8E7FF);

// Dark theme text
static const darkOnSurface = Color(0xFFE6E1E5);
static const darkOnSurfaceVariant = Color(0xFFCAC4D0);
static const darkOutline = Color(0xFF938F99);

// Module colors adapted for dark
static const darkLightGreen = Color(0xFFA5D57B);
static const darkBlue = Color(0xFF64B5F6);
static const darkRed = Color(0xFFEF5350);
static const darkOrange = Color(0xFFFFB74D);
static const darkPurple = Color(0xFFBA68C8);
```

**Success Criteria**:
- All dark colors defined
- WCAG AA contrast compliance
- Both themes render correctly

---

### Day 4: Settings UI
**Goal**: Complete Settings page with theme selector and placeholders

**Tasks**:
1. Create SettingsPage with section layout
2. Build ThemeSelectorWidget using CupertinoSlidingSegmentedControl
3. Add placeholder sections (Notifications, Language, About)
4. Add Spanish localization for all UI text
5. Integrate with ThemeBloc

**Deliverables**:
- `lib/features/profile/presentation/pages/settings_page.dart`
- `lib/features/profile/presentation/widgets/theme_selector_widget.dart`

**Settings Page Structure**:
```
┌─────────────────────────────────┐
│ ← Configuración                 │
├─────────────────────────────────┤
│ APARIENCIA                       │
│ ┌───────────────────────────┐   │
│ │ Tema                       │   │
│ │ [Sistema|Claro|Oscuro]    │   │
│ │ Descripción del tema...   │   │
│ └───────────────────────────┘   │
│                                  │
│ NOTIFICACIONES (Próximamente)    │
│ ┌───────────────────────────┐   │
│ │ [Disabled Card]           │   │
│ └───────────────────────────┘   │
│                                  │
│ IDIOMA (Próximamente)            │
│ ┌───────────────────────────┐   │
│ │ [Disabled Card]           │   │
│ └───────────────────────────┘   │
│                                  │
│ ACERCA DE (Próximamente)         │
│ ┌───────────────────────────┐   │
│ │ [Disabled Card]           │   │
│ └───────────────────────────┘   │
└─────────────────────────────────┘
```

**Success Criteria**:
- Theme selector functional
- Smooth iOS-style animation
- Placeholders visible but disabled
- Spanish localization complete

---

### Day 5: App Integration
**Goal**: Integrate theme system into main app

**Tasks**:
1. Modify main.dart to pre-load theme before runApp()
2. Convert MyApp to StatefulWidget with WidgetsBindingObserver
3. Wrap MaterialApp.router with BlocBuilder<ThemeBloc>
4. Update ProfilePage to navigate to SettingsPage
5. Add SettingsPage route to app_router.dart
6. Test theme switching and system detection

**Files to Modify**:
- `lib/main.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/core/router/app_router.dart`
- `lib/di/service_locator.dart`

**main.dart Pattern**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // PRE-LOAD theme to prevent flicker
  final themeBloc = getIt<ThemeBloc>();
  themeBloc.add(const LoadThemePreference());
  await themeBloc.stream.firstWhere(
    (state) => state is ThemeLoaded,
  ).timeout(const Duration(milliseconds: 500));

  // ... rest of setup

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: themeBloc), // Use existing instance
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus())),
        BlocProvider(create: (_) => getIt<BluetoothBloc>()),
        BlocProvider(create: (_) => getIt<ChatBloc>()),
      ],
      child: const MyApp(),
    ),
  );
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
    WidgetsBinding.instance.removeObserver(this); // CRITICAL
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final themeBloc = context.read<ThemeBloc>();
    if (themeBloc.state is ThemeLoaded) {
      final state = themeBloc.state as ThemeLoaded;
      if (state.mode == ThemePreference.system) {
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
          // ... rest of config
        );
      },
    );
  }
}
```

**Success Criteria**:
- No theme flicker on startup
- Theme switches immediately
- System detection works
- Navigation to Settings functional

---

### Day 6-7: Widget Audit (COMPREHENSIVE)
**Goal**: Fix ALL modules to support dark mode

**Strategy**:
1. Search for hardcoded colors: `Colors.white`, `Colors.black`, `Colors.grey`
2. Replace with theme-aware equivalents
3. Test each module in both light and dark modes
4. Document any visual inconsistencies

**Modules to Audit**:
1. **Temperature** (`lib/features/temperature/`)
2. **Servo** (`lib/features/servo/`)
3. **LightControl** (`lib/features/light_control/`)
4. **Gamepad** (`lib/features/gamepad/`)
5. **Chat** (`lib/features/chat/`)
6. **Profile** (`lib/features/profile/`)
7. **Home** (`lib/features/home/`)
8. **Auth** (`lib/features/auth/`)

**Common Replacements**:
```dart
// BEFORE (hardcoded)
Container(
  color: Colors.white,
  child: Text('Hello', style: TextStyle(color: Colors.black)),
)

// AFTER (theme-aware)
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Hello',
    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
  ),
)

// Common patterns
Colors.white → theme.colorScheme.surface
Colors.black → theme.colorScheme.onSurface
Colors.grey[100] → theme.colorScheme.surfaceVariant
Colors.grey[600] → theme.colorScheme.onSurfaceVariant
```

**Search Commands**:
```bash
# Find hardcoded Colors usage
grep -r "Colors\." lib/features/ --include="*.dart"

# Find specific colors
grep -r "Colors.white" lib/features/ --include="*.dart"
grep -r "Colors.black" lib/features/ --include="*.dart"
grep -r "Colors.grey" lib/features/ --include="*.dart"
```

**Success Criteria**:
- All modules render correctly in dark mode
- No harsh color contrasts
- Icons and images visible
- Consistent visual language

---

### Day 8: Testing & Finalization
**Goal**: Complete automated tests and prepare PR

**Tasks**:
1. Write BLoC tests using bloc_test package
2. Write widget tests for ThemeSelectorWidget
3. Integration testing (theme switching, persistence, system detection)
4. Validate >80% code coverage
5. Run flutter analyze (0 errors)
6. Run dart format
7. Final manual QA on critical paths
8. Create PR to develop

**Test Files**:
- `test/core/data/repositories/theme_repository_impl_test.dart` (✅ from Day 1-2)
- `test/core/presentation/bloc/theme/theme_bloc_test.dart` (NEW)
- `test/features/profile/presentation/widgets/theme_selector_widget_test.dart` (NEW)

**BLoC Test Example**:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeBloc', () {
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

    blocTest<ThemeBloc, ThemeState>(
      'emits [ThemeLoading, ThemeLoaded] when LoadThemePreference succeeds',
      build: () {
        when(mockLoadUseCase(any))
            .thenAnswer((_) async => const Right(ThemePreference.dark));
        return themeBloc;
      },
      act: (bloc) => bloc.add(const LoadThemePreference()),
      expect: () => [
        const ThemeLoading(),
        const ThemeLoaded(
          mode: ThemePreference.dark,
          isDarkMode: true,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits [ThemeLoaded] when ChangeThemeMode succeeds',
      build: () {
        when(mockSaveUseCase(any))
            .thenAnswer((_) async => const Right(null));
        return themeBloc;
      },
      seed: () => const ThemeLoaded(
        mode: ThemePreference.light,
        isDarkMode: false,
      ),
      act: (bloc) => bloc.add(const ChangeThemeMode(ThemePreference.dark)),
      expect: () => [
        const ThemeLoaded(
          mode: ThemePreference.dark,
          isDarkMode: true,
        ),
      ],
    );
  });
}
```

**Coverage Commands**:
```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html

# Check coverage percentage
lcov --summary coverage/lcov.info
```

**Success Criteria**:
- >80% code coverage
- All tests pass
- 0 analysis errors
- Code properly formatted
- PR approved and merged

---

## File Checklist

### New Files (13 total)

**Domain Layer (4 files)**:
- [ ] `lib/core/domain/entities/theme_preference.dart`
- [ ] `lib/core/domain/repositories/theme_repository.dart`
- [ ] `lib/core/domain/usecases/load_theme_preference_usecase.dart`
- [ ] `lib/core/domain/usecases/save_theme_preference_usecase.dart`

**Data Layer (2 files)**:
- [ ] `lib/core/data/datasources/theme_local_datasource.dart`
- [ ] `lib/core/data/repositories/theme_repository_impl.dart`

**Presentation Layer (3 files)**:
- [ ] `lib/core/presentation/bloc/theme/theme_bloc.dart`
- [ ] `lib/core/presentation/bloc/theme/theme_event.dart`
- [ ] `lib/core/presentation/bloc/theme/theme_state.dart`

**Theme System (1 file)**:
- [ ] `lib/theme/app_theme.dart`

**Features (2 files)**:
- [ ] `lib/features/profile/presentation/pages/settings_page.dart`
- [ ] `lib/features/profile/presentation/widgets/theme_selector_widget.dart`

**Tests (3 files)**:
- [ ] `test/core/data/repositories/theme_repository_impl_test.dart`
- [ ] `test/core/presentation/bloc/theme/theme_bloc_test.dart`
- [ ] `test/features/profile/presentation/widgets/theme_selector_widget_test.dart`

### Modified Files (5 total)

- [ ] `lib/main.dart` (pre-load, observer, BlocBuilder)
- [ ] `lib/theme/app_color.dart` (add dark color variants)
- [ ] `lib/di/service_locator.dart` (register theme dependencies)
- [ ] `lib/core/router/app_router.dart` (add settings route)
- [ ] `lib/features/profile/presentation/pages/profile_page.dart` (navigation)

---

## Testing Requirements

### Coverage Targets
- **Repository**: 100% (critical persistence path)
- **BLoC**: 90%+ (all events/states)
- **Use Cases**: 100% (simple logic)
- **Widgets**: 70%+ (rendering verification)
- **Overall Feature**: >80%

### Test Types

**Unit Tests**:
- Repository implementation with mocked SharedPreferences
- Use cases with mocked repository
- Error handling and failure cases

**BLoC Tests**:
- All events trigger correct states
- State transitions are correct
- Error states handled properly
- Use bloc_test package

**Widget Tests**:
- ThemeSelectorWidget renders correctly
- User interactions work
- Theme changes propagate

**Manual QA** (Minimal):
- Theme switching works in app
- System detection works
- No visual regressions in critical paths

---

## Code Quality Checklist

### Before Submission
- [ ] All files have ABOUTME comments (2 lines each)
- [ ] Code follows Dart style guide
- [ ] `dart format lib/ test/` applied
- [ ] `flutter analyze` shows 0 errors
- [ ] No hardcoded strings (use Spanish localization)
- [ ] All widgets use theme colors (no hardcoded Colors.*)
- [ ] SafeArea used where appropriate
- [ ] Const constructors used throughout
- [ ] No TODO comments left in code

### Architecture Compliance
- [ ] Clean Architecture layers respected
- [ ] Domain has zero Flutter dependencies
- [ ] Repository returns Either<Failure, Success>
- [ ] BLoC follows classic Bloc<Event, State> pattern
- [ ] DI registered manually in service_locator.dart
- [ ] No @injectable decorators used

---

## Critical Warnings

### ⚠️ Must Not Forget

1. **Remove WidgetsBindingObserver in dispose()**
   - CRITICAL: Memory leak if forgotten
   - Add to code review checklist

2. **Pre-load Theme in main()**
   - Prevents flicker on startup
   - Add 500ms timeout for safety

3. **Widget Audit Completeness**
   - Check EVERY module
   - Test in both themes
   - Document any edge cases

4. **Contrast Validation**
   - Use WebAIM checker
   - Minimum 4.5:1 for text
   - Test on physical devices

5. **Test Coverage**
   - Must exceed 80%
   - Non-negotiable requirement

---

## Iteration & Future Enhancements

**Post-Launch Improvements** (separate PRs):
- Fine-tune colors based on user feedback
- Add theme-specific images/assets
- Implement theme preview in selector
- Add animation transitions
- Expand settings page with real features

**Settings Page Placeholders** (future PRs):
- Notifications preferences
- Language selection
- About/Legal information
- Account settings

---

## Success Criteria

### Definition of Done
- [ ] All 13 new files created with ABOUTME comments
- [ ] All 5 files modified correctly
- [ ] Theme switching works flawlessly
- [ ] System detection functional
- [ ] All modules tested in dark mode
- [ ] >80% test coverage achieved
- [ ] 0 flutter analyze errors
- [ ] Code properly formatted
- [ ] PR created and approved
- [ ] Merged to develop

### User Acceptance
- User can select theme in Settings
- Theme persists across app restarts
- System theme detection works automatically
- All modules readable in dark mode
- No visual glitches or flicker

---

## Reference Documentation

**Main Implementation Guide**:
`/Users/LAPTOP-david-001/Development/apps/Flutter/makerslab_app/.claude/docs/dark_mode/flutter-frontend.md`

**Quick Reference**:
`/Users/LAPTOP-david-001/Development/apps/Flutter/makerslab_app/.claude/docs/dark_mode/architectural-advice-summary.md`

**Session Context**:
`/Users/LAPTOP-david-001/Development/apps/Flutter/makerslab_app/.claude/sessions/context_session_dark_mode.md`

---

## Ready to Begin Implementation! 🚀

**Status**: ✅ **PLAN APPROVED - READY TO CODE**

All decisions finalized. Architecture validated. Timeline confirmed. Testing strategy defined. Widget audit scoped. Ready to create feature branch and begin Day 1-2 implementation.

**Next Command**:
```bash
git checkout develop
git checkout -b feat/dark-mode-settings
```

Let's build this! 💪
