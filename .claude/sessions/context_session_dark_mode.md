# Dark Mode Feature Implementation Session

## Feature Overview
Implement dark mode with triple selector (System, Light, Dark) in Settings page within Profile section, following iOS-style design patterns.

## Session Status
- **Status**: Ready for Implementation
- **Created**: 2025-11-12
- **Last Updated**: 2025-11-12
- **Branch**: feat/dark-mode-settings
- **Phase**: Branch created, ready to begin Day 1-2 (Infrastructure)

## Technology Stack
- Flutter 3.7.2+ with Dart 3.7.2+
- Clean Architecture (Domain, Data, Presentation)
- BLoC Pattern for state management
- get_it for dependency injection
- Material Design 3

## Exploration Findings

### Current State Analysis
1. **Theme Configuration**:
   - Hardcoded in [main.dart:76-93](lib/main.dart#L76-L93)
   - Only light theme defined
   - Material Design 3 enabled (`useMaterial3: true`)
   - Custom color scheme using AppColors

2. **Color System**:
   - [app_color.dart](lib/theme/app_color.dart) has light theme colors
   - No dark theme colors defined yet
   - Primary color: `#247BA0`
   - Multiple gray shades and module-specific colors available

3. **Profile/Settings Structure**:
   - Profile page exists: [profile_page.dart](lib/features/profile/presentation/pages/profile_page.dart)
   - "Configuración" card at line 81-88 with TODO for navigation
   - No settings page implemented yet
   - ProfileBloc exists but only handles profile updates

4. **Storage Infrastructure**:
   - SharedPreferences already set up in DI ([service_locator.dart:99-100](lib/di/service_locator.dart#L99-L100))
   - SecureStorageService available but not needed for theme preference
   - Ready to store theme preference

5. **Navigation**:
   - GoRouter configured in [app_router.dart](lib/core/router/app_router.dart)
   - Uses ShellRoute for persistent navigation
   - NoTransitionPage for instant transitions
   - Profile routes already registered

### Architecture Pattern Observed
- Clean Architecture with Domain/Data/Presentation layers
- BLoC pattern for state management (classic Bloc<Event, State>)
- Manual get_it registration in service_locator.dart
- Repository pattern with Either<Failure, Success>
- Feature-based folder structure

## Implementation Plan

### Phase 1: Theme Infrastructure (Domain Layer)
**Files to Create:**
1. `lib/core/domain/entities/theme_preference.dart`
   - Entity with enum ThemeMode (system, light, dark)
   - Simple class with required fields

2. `lib/core/domain/repositories/theme_repository.dart`
   - Repository interface for theme operations
   - Methods: getThemeMode(), saveThemeMode(ThemeMode)

### Phase 2: Theme Persistence (Data Layer)
**Files to Create:**
1. `lib/core/data/datasources/theme_local_datasource.dart`
   - Local data source using SharedPreferences
   - Key: 'theme_mode_preference'
   - Store as string: 'system', 'light', 'dark'

2. `lib/core/data/repositories/theme_repository_impl.dart`
   - Implementation of ThemeRepository
   - Use SharedPreferences for persistence
   - Handle exceptions → convert to Failures

### Phase 3: Theme State Management (Presentation Layer)
**Files to Create:**
1. `lib/core/presentation/bloc/theme/theme_bloc.dart`
2. `lib/core/presentation/bloc/theme/theme_event.dart`
   - LoadThemePreference
   - ChangeThemeMode(ThemeMode mode)
3. `lib/core/presentation/bloc/theme/theme_state.dart`
   - ThemeInitial
   - ThemeLoaded(ThemeMode mode, bool isDarkMode)

### Phase 4: Dark Theme Colors
**Files to Modify:**
1. `lib/theme/app_color.dart`
   - Add dark theme color variants
   - Maintain same color names with 'Dark' suffix where needed

**Files to Create:**
2. `lib/theme/app_theme.dart`
   - lightTheme() function returning ThemeData
   - darkTheme() function returning ThemeData
   - Both using Material Design 3

### Phase 5: Settings Page with iOS-style Selector
**Files to Create:**
1. `lib/features/profile/presentation/pages/settings_page.dart`
   - New settings page with sections
   - Theme selector section as first option

2. `lib/features/profile/presentation/widgets/theme_selector_widget.dart`
   - iOS-style segmented control
   - Three options: System, Light, Dark
   - CupertinoSlidingSegmentedControl or custom Material design

### Phase 6: Integration
**Files to Modify:**
1. `lib/main.dart`
   - Wrap MaterialApp.router with BlocBuilder<ThemeBloc, ThemeState>
   - Add ThemeBloc to MultiBlocProvider
   - Use theme: based on state (lightTheme or darkTheme)
   - Set themeMode: ThemeMode.system/light/dark

2. `lib/features/profile/presentation/pages/profile_page.dart`
   - Update "Configuración" onTap to navigate to SettingsPage
   - Remove TODO comment

3. `lib/core/router/app_router.dart`
   - Add SettingsPage route

4. `lib/di/service_locator.dart`
   - Register ThemeLocalDataSource
   - Register ThemeRepository
   - Register ThemeBloc as singleton (like BluetoothBloc)

### Phase 7: Testing Strategy
**Files to Create:**
1. `test/core/data/repositories/theme_repository_impl_test.dart`
   - Unit tests for repository implementation
   - Mock SharedPreferences

2. `test/core/presentation/bloc/theme/theme_bloc_test.dart`
   - BLoC tests using bloc_test package
   - Test all events and state transitions

3. `test/features/profile/presentation/widgets/theme_selector_widget_test.dart`
   - Widget tests for theme selector
   - Test user interactions

## Decisions Log

### Architecture Decisions (2025-11-12)

**1. ThemeBloc Registration: SINGLETON (Lazy)**
- **Decision**: Register ThemeBloc as `registerLazySingleton` NOT `registerFactory`
- **Rationale**: Theme is global app state like AuthBloc/BluetoothBloc/ChatBloc
- **Impact**: Single source of truth, persists throughout app lifetime

**2. Theme Loading Strategy: PRE-LOAD in main()**
- **Decision**: Load theme BEFORE runApp() to prevent flicker
- **Implementation**:
  - Call ThemeBloc.add(LoadThemePreference()) in main()
  - Wait for first state with 500ms timeout
  - Use BlocProvider.value to pass existing instance
- **Trade-off**: Adds ~50-100ms startup time (acceptable for better UX)

**3. Theme Application: BlocBuilder + MaterialApp.themeMode**
- **Decision**: Use MaterialApp's built-in theme switching
- **Pattern**:
  ```dart
  BlocBuilder<ThemeBloc, ThemeState>(
    builder: (context, state) => MaterialApp.router(
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: effectiveThemeMode, // from state
    ),
  )
  ```
- **Rationale**: Native Flutter solution, efficient rebuilds, handles system theme

**4. System Theme Detection: WidgetsBindingObserver**
- **Decision**: Convert MyApp to StatefulWidget with WidgetsBindingObserver mixin
- **Implementation**:
  - Override didChangePlatformBrightness()
  - Only reload if user preference is "System"
  - Clean up in dispose()
- **Critical**: Must remove observer to prevent memory leak

**5. Theme Selector Widget: CupertinoSlidingSegmentedControl**
- **Decision**: Use iOS-style control (NOT Material SegmentedButton)
- **Rationale**:
  - Smoother animation
  - Better UX (industry standard)
  - Educational context (users familiar with iOS controls)
  - Works well cross-platform

**6. Color System: Pre-defined Dark Variants (NO runtime transformations)**
- **Decision**: Extend AppColors with explicit dark color constants
- **Rationale**:
  - Better performance (no runtime calculations)
  - Design control (fine-tune each color)
  - Clear intent in code
- **Primary Color Adaptations**:
  - Light: #247BA0 (original)
  - Dark: #5EB1E8 (40% lighter for visibility)

**7. Theme Factory Pattern: AppTheme.lightTheme() / darkTheme()**
- **Decision**: Create new file `lib/theme/app_theme.dart` with static factory methods
- **Rationale**:
  - Centralizes theme creation
  - Ensures Material Design 3 compliance
  - Consistent configuration across themes
- **Scope**: Includes ColorScheme, AppBarTheme, CardTheme, InputDecorationTheme, ElevatedButtonTheme

### Testing Requirements

**Mandatory Coverage:**
- Repository: 100% (critical path)
- BLoC: 90%+ (all events/states)
- Use cases: 100% (simple logic)
- Widgets: 70%+ (rendering verification)
- **Overall**: >80% code coverage for feature

**Test Types:**
- Unit tests: Repository, Use cases
- BLoC tests: All events/state transitions using bloc_test
- Widget tests: ThemeSelectorWidget rendering
- Manual QA: All IoT modules in dark mode (Temperature, Servo, LightControl, Gamepad, Chat, Profile, Home, Auth)

### Critical Action Items

**BEFORE Implementation:**
1. **Widget Audit**: Scan ALL existing widgets for hardcoded colors
   - Replace `Colors.white` → `theme.colorScheme.surface`
   - Replace `Colors.black` → `theme.colorScheme.onSurface`
   - Replace `Colors.grey[X]` → `theme.colorScheme.surfaceVariant`

**AFTER Implementation:**
2. **Manual Testing**: Test EVERY module in dark mode on physical devices
3. **Contrast Validation**: Use WebAIM contrast checker for all text colors (4.5:1 minimum)
4. **Memory Leak Check**: Verify WidgetsBindingObserver properly cleaned up

### Performance Optimizations

1. **Theme Preloading**: ~50ms startup cost for flicker prevention (APPROVED)
2. **Minimal Rebuilds**: Only MaterialApp in BlocBuilder, children use Theme.of(context)
3. **Const Constructors**: Use throughout for widget caching
4. **Asset Loading**: Consider precaching theme-specific images on splash

### Known Pitfalls & Mitigations

**Pitfall**: Theme flicker on app start
**Mitigation**: Pre-load theme in main() with timeout

**Pitfall**: Hardcoded colors break in dark mode
**Mitigation**: Comprehensive widget audit + theme-aware colors

**Pitfall**: System theme changes not detected
**Mitigation**: WidgetsBindingObserver with proper cleanup

**Pitfall**: Unnecessary rebuilds
**Mitigation**: BlocBuilder only wraps MaterialApp, not entire tree

**Pitfall**: Memory leak from observer
**Mitigation**: Remove observer in dispose() (CRITICAL)

### Implementation Timeline (COMPRESSED)

**Total Estimate**: 7-8 days (focused work)

**Day 1-2: Infrastructure & Foundation**
- Phase 1: Domain layer (entities, repositories, use cases)
- Phase 2: Data layer (data sources, repository impl)
- Phase 3: BLoC (events, states, bloc logic)
- DI registration in service_locator.dart
- Unit tests for repository and use cases

**Day 3: Theme System & Colors**
- Phase 4a: Add dark color variants to AppColors
- Phase 4b: Create AppTheme.lightTheme() and darkTheme()
- Contrast validation (WebAIM checker)
- Test color system

**Day 4: Settings UI**
- Phase 5a: Create SettingsPage with theme selector section
- Phase 5b: Create ThemeSelectorWidget (CupertinoSlidingSegmentedControl)
- Phase 5c: Add placeholder sections (Notifications, Language, About)
- Spanish localization for all text

**Day 5: App Integration**
- Phase 6a: Modify main.dart (pre-load, BlocBuilder, WidgetsBindingObserver)
- Phase 6b: Update ProfilePage navigation to SettingsPage
- Phase 6c: Add SettingsPage route to app_router.dart
- Test theme switching and system detection

**Day 6-7: Widget Audit (COMPREHENSIVE)**
- Scan ALL existing widgets for hardcoded colors
- Fix Temperature, Servo, LightControl, Gamepad modules
- Fix Chat, Profile, Home, Auth modules
- Replace Colors.white → theme.colorScheme.surface
- Replace Colors.black → theme.colorScheme.onSurface
- Test each module in dark mode

**Day 8: Testing & Finalization**
- BLoC tests using bloc_test package
- Widget tests for ThemeSelectorWidget
- Integration testing (theme switching, persistence, system detection)
- Code coverage validation (>80%)
- Final polish and documentation
- Create PR to develop

### David's Decisions (2025-11-12)

**1. Color Scheme: APPROVED ✅**
- Primary Dark: #5EB1E8
- Permission to create additional colors as needed
- Will follow Material Design 3 guidelines for all color adaptations

**2. Widget Audit Scope: COMPREHENSIVE ✅**
- Include widget audit in this feature (Phase 5)
- Fix ALL modules: Temperature, Servo, LightControl, Gamepad, Chat, Profile, Home, Auth
- Replace all hardcoded colors with theme-aware equivalents

**3. Timeline: COMPRESSED (7-8 days) ✅**
- Focused work required
- Prioritize core functionality over extensive polish
- Can iterate on visual refinements in future updates

**4. Theme Selector: CupertinoSlidingSegmentedControl ✅**
- Use iOS-style control for better UX
- Cross-platform implementation (works on Android too)
- Smoother animation and industry-standard design

**5. Settings Page Scope: THEME + PLACEHOLDERS ✅**
- Theme selector as primary section
- Add placeholder sections for future settings:
  - Notifications (coming soon)
  - Language preferences (coming soon)
  - About/Legal (coming soon)
- Allows for incremental feature additions

**6. Startup Performance: ACCEPTABLE ✅**
- 50-100ms startup cost approved for flicker prevention
- Better UX prioritized over minimal startup time

**7. Testing Priority: AUTOMATE FIRST ✅**
- Focus on automated tests (unit, BLoC, widget)
- Minimal manual QA required
- >80% code coverage mandatory
- Manual testing only for critical paths

**8. Branch Strategy: CONFIRMED ✅**
- Branch: `feat/dark-mode-settings`
- Base: `develop`
- Target: `develop`
- Standard feature branch workflow

### Next Steps

1. ✅ Review implementation plan in `.claude/docs/dark_mode/flutter-frontend.md`
2. ✅ Approve color scheme (primary dark: #5EB1E8)
3. ✅ Clarify all implementation decisions
4. ✅ Finalize complete implementation plan
5. ✅ Create feature branch: feat/dark-mode-settings
6. [ ] Create GitHub issue (manual - gh CLI not available)
7. [ ] Begin Day 1-2: Infrastructure (Domain/Data/BLoC layers)
8. [ ] Update this session file with progress after each phase

## Notes & Context
- Must follow existing architectural patterns (Clean Architecture + BLoC)
- All files need ABOUTME comments (2 lines)
- Manual DI registration required (no @injectable)
- Spanish localization for UI text
- Material Design 3 compliance required
- SafeArea must be used in UI
- Tests are mandatory (>80% coverage)
