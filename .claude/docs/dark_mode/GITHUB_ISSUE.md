# GitHub Issue: Dark Mode Feature

**Copy this content to create your GitHub issue manually**

---

**Title**: `feat: Implement Dark Mode with iOS-style Triple Selector`

**Labels**: `feature`, `enhancement`, `ui/ux`

**Assignees**: DavidFlores79

---

## 📋 Problem Statement

Currently, Makers Lab app only supports light theme. Users in low-light environments experience:
- Eye strain from bright white backgrounds
- Poor battery life on OLED devices
- No ability to match system dark mode preferences
- Inconsistent experience with other apps that support dark mode

This is important now because:
- Dark mode is a standard feature in modern mobile apps
- Users increasingly expect theme customization options
- Educational IoT app usage often occurs in various lighting conditions
- Improves accessibility for light-sensitive users

## 🎯 User Value

**Direct Benefits:**
- **Reduced Eye Strain**: Dark backgrounds easier on eyes in low-light environments
- **Battery Savings**: OLED screens use less power with dark pixels
- **Personalization**: Users can choose their preferred visual style
- **System Integration**: Automatic theme switching based on device settings
- **Consistency**: Matches user's device-wide theme preference

**User Scenarios:**
1. **Late Night Learning**: Student using app at night to program Arduino → dark mode reduces eye fatigue
2. **Battery Conservation**: User in field with low battery → dark mode extends usage time
3. **Personal Preference**: User who prefers dark interfaces → can set permanent dark theme
4. **Automatic Switching**: User with auto dark mode → app respects system preference

## 🔧 Technical Requirements

### Architecture (Clean Architecture + BLoC)
**Domain Layer:**
- ThemePreference entity (enum: system, light, dark)
- ThemeRepository interface
- LoadThemePreferenceUseCase
- SaveThemePreferenceUseCase

**Data Layer:**
- ThemeLocalDataSource (SharedPreferences)
- ThemeRepositoryImpl with Either<Failure, Success>
- Persistence key: 'theme_mode_preference'

**Presentation Layer:**
- ThemeBloc (singleton registration)
- ThemeEvent (LoadThemePreference, ChangeThemeMode)
- ThemeState (ThemeInitial, ThemeLoading, ThemeLoaded)

### Theme System
- AppTheme factory (lightTheme(), darkTheme())
- Dark color palette (Material Design 3 compliant)
- Primary Dark: #5EB1E8 (40% lighter than #247BA0)
- WCAG AA contrast compliance (4.5:1 minimum)

### UI Components
- SettingsPage with section layout
- ThemeSelectorWidget (CupertinoSlidingSegmentedControl)
- Placeholder sections (Notifications, Language, About)
- Spanish localization for all text

### Integration Points
- main.dart: Pre-load theme before runApp() (prevent flicker)
- MyApp: Convert to StatefulWidget with WidgetsBindingObserver
- ProfilePage: Navigation to SettingsPage
- app_router.dart: Add settings route
- service_locator.dart: Register theme dependencies (singleton)

### Widget Audit (CRITICAL)
Fix hardcoded colors in ALL modules:
- Temperature, Servo, LightControl, Gamepad
- Chat, Profile, Home, Auth
- Replace Colors.white → theme.colorScheme.surface
- Replace Colors.black → theme.colorScheme.onSurface
- Replace Colors.grey → theme.colorScheme.surfaceVariant

### Database Changes
- None (uses SharedPreferences for local storage)

### API Endpoints
- None (client-side feature)

## ✅ Definition of Done

### Implementation
- [ ] All 13 new files created with ABOUTME comments
- [ ] All 5 existing files modified correctly
- [ ] Domain/Data/Presentation layers follow Clean Architecture
- [ ] ThemeBloc registered as singleton (registerLazySingleton)
- [ ] Theme pre-loaded in main() before runApp()
- [ ] WidgetsBindingObserver implemented with proper cleanup
- [ ] CupertinoSlidingSegmentedControl for theme selector
- [ ] Dark color palette added to AppColors
- [ ] AppTheme factory with lightTheme()/darkTheme()
- [ ] ALL modules audited for hardcoded colors

### Testing
- [ ] Repository unit tests with mocked SharedPreferences (100% coverage)
- [ ] Use case unit tests (100% coverage)
- [ ] BLoC tests using bloc_test package (90%+ coverage)
- [ ] Widget tests for ThemeSelectorWidget (70%+ coverage)
- [ ] Overall feature coverage >80%
- [ ] All tests pass: `flutter test`

### Code Quality
- [ ] ABOUTME comments in all new files (2 lines each)
- [ ] Code follows Dart style guide
- [ ] `dart format lib/ test/` applied
- [ ] `flutter analyze` shows 0 errors
- [ ] No hardcoded strings (Spanish localization used)
- [ ] SafeArea used where appropriate
- [ ] Const constructors used throughout

### Documentation
- [ ] Session file updated with progress
- [ ] FINAL_IMPLEMENTATION_PLAN.md reflects actual implementation
- [ ] Code comments explain complex logic

### Review & Deployment
- [ ] Code review approved by 1 reviewer
- [ ] All CI/CD checks pass
- [ ] Manual testing completed (critical paths)
- [ ] PR merged to develop

## 🧪 Manual Testing Checklist

### Basic Flow
- [ ] Navigate to Profile → Configuración
- [ ] Settings page opens with theme selector visible
- [ ] Select "Sistema" → theme matches device setting
- [ ] Select "Claro" → app switches to light theme immediately
- [ ] Select "Oscuro" → app switches to dark theme immediately
- [ ] Close app and reopen → theme preference persisted

### Theme Switching
- [ ] No flicker on app startup in any theme mode
- [ ] Theme changes apply instantly without lag
- [ ] All text remains readable in both themes
- [ ] Icons visible in both themes
- [ ] Images display correctly in both themes
- [ ] Smooth animation on theme selector

### System Detection (Sistema mode)
- [ ] Select "Sistema" in app
- [ ] Change device theme to dark → app switches to dark
- [ ] Change device theme to light → app switches to light
- [ ] No crashes or freezes during system theme change

### Module Testing (ALL in Dark Mode)
- [ ] Temperature sensor page displays correctly
- [ ] Servo control page displays correctly
- [ ] Light control page displays correctly
- [ ] Gamepad page displays correctly
- [ ] Chat interface displays correctly
- [ ] Profile pages display correctly
- [ ] Home screen displays correctly
- [ ] Auth pages (login, signup, OTP) display correctly

### Edge Cases
- [ ] App works correctly on first install (default to Sistema)
- [ ] Switching themes rapidly doesn't cause issues
- [ ] Theme persists after app force close
- [ ] Theme persists after device restart
- [ ] Works correctly on both Android and iOS

### Error Handling
- [ ] SharedPreferences failure handled gracefully (fallback to system)
- [ ] Invalid stored preference handled (fallback to system)
- [ ] Theme loads correctly even if storage is corrupted

### Integration Testing
- [ ] Theme doesn't interfere with Bluetooth functionality
- [ ] Theme doesn't interfere with authentication
- [ ] Theme doesn't break navigation
- [ ] All dialogs and modals themed correctly
- [ ] Snackbars and toasts themed correctly

### Performance
- [ ] No noticeable lag when switching themes
- [ ] Startup time increase <100ms
- [ ] No memory leaks (WidgetsBindingObserver cleaned up)
- [ ] No unnecessary widget rebuilds

## 🏗️ Implementation Strategy

**Branch**: `feat/dark-mode-settings`
**Base**: `develop`
**Target**: `develop`
**Estimated Effort**: L (7-8 days compressed)

**Timeline Breakdown:**
- Days 1-2: Infrastructure (Domain/Data/BLoC layers)
- Day 3: Theme System & Colors
- Day 4: Settings UI
- Day 5: App Integration
- Days 6-7: Widget Audit (COMPREHENSIVE)
- Day 8: Testing & Finalization

**Dependencies:**
- None (self-contained feature)

**Blockers:**
- None identified

**Critical Path Items:**
1. Pre-load theme in main() to prevent flicker
2. Widget audit for ALL modules (Days 6-7)
3. WidgetsBindingObserver cleanup (memory leak prevention)
4. >80% test coverage requirement

## 📚 Related Documentation

**Implementation Plans:**
- `.claude/docs/dark_mode/FINAL_IMPLEMENTATION_PLAN.md` - Complete day-by-day guide
- `.claude/docs/dark_mode/flutter-frontend.md` - 10,000+ word detailed implementation
- `.claude/docs/dark_mode/architectural-advice-summary.md` - Quick reference

**Session Tracking:**
- `.claude/sessions/context_session_dark_mode.md` - All decisions and progress

**Architectural Decisions:**
- ThemeBloc: Singleton registration (like AuthBloc, BluetoothBloc)
- Theme Loading: Pre-load before runApp() (50-100ms cost acceptable)
- Theme Application: BlocBuilder + MaterialApp.themeMode (native Flutter)
- System Detection: WidgetsBindingObserver (with proper cleanup)
- Theme Selector: CupertinoSlidingSegmentedControl (iOS-style UX)
- Color System: Pre-defined dark variants (no runtime transformations)
- Theme Factory: Static methods in AppTheme class

**Design Patterns:**
- Clean Architecture (Domain/Data/Presentation)
- Classic BLoC pattern (Bloc<Event, State>)
- Repository pattern with Either<Failure, Success>
- Manual dependency injection (get_it)

**Testing Strategy:**
- Repository: 100% coverage (critical path)
- BLoC: 90%+ coverage (all events/states)
- Use Cases: 100% coverage (simple logic)
- Widgets: 70%+ coverage (rendering verification)
- Overall: >80% code coverage

## 🎨 Design Reference

**Color Scheme:**
- Light Primary: #247BA0
- Dark Primary: #5EB1E8 (40% lighter for visibility)
- Material Design 3 compliant
- WCAG AA contrast ratios (4.5:1 minimum)

**UI Components:**
- iOS-style segmented control (CupertinoSlidingSegmentedControl)
- Section-based settings layout
- Theme description text below selector
- Placeholder sections for future features

**User Flow:**
```
Profile → Configuración → Settings Page
  ↓
[APARIENCIA Section]
  ↓
Theme Selector: [Sistema | Claro | Oscuro]
  ↓
Description: "El tema se ajusta..."
  ↓
[NOTIFICACIONES Section - Próximamente]
[IDIOMA Section - Próximamente]
[ACERCA DE Section - Próximamente]
```

---

**Generated with Claude Code** 🤖
**Planning Session**: 2025-11-12
**Ready for Implementation**: ✅
