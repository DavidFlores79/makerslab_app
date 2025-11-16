# Session Context: Black Screen on App Resume Issue

## Problem Statement
When the app is running and the device is locked, after some time passes and the device is unlocked, the screen appears black. This looks like an error state, and even reloading doesn't fix it.

## Initial Investigation
Starting exploration to understand:
- Current app lifecycle handling
- State management during app pause/resume
- Bluetooth connection management during background/foreground transitions
- Error handling and recovery mechanisms

## Technology Stack
- Flutter 3.7.2+ with Dart 3.7.2+
- BLoC pattern for state management
- Bluetooth connectivity (flutter_bluetooth_serial, flutter_reactive_ble)
- GoRouter for navigation

## Key Findings from Exploration

### Current Architecture Analysis

**App Lifecycle Handling:**
- `main.dart` implements `WidgetsBindingObserver` in `_MyAppState`
- Currently only handles `didChangePlatformBrightness()` for theme changes
- **CRITICAL**: NO implementation of `didChangeAppLifecycleState()` for app pause/resume events

**Bluetooth Connection Management:**
- `BluetoothService` maintains active connection via `_connection` property
- Connection streams are active in module BLoCs (Temperature, Servo, Light, Gamepad)
- When app is backgrounded/locked, Bluetooth connections may be dropped by OS
- **No recovery mechanism** when app resumes from background

**Module BLoC Pattern:**
- All IoT modules (Temperature, Servo, LightControl, Gamepad) use persistent data streams
- TemperatureBloc subscribes to `getDataStreamUseCase()` which listens to Bluetooth data
- StreamSubscriptions (`_dataSubscription`, `_bluetoothStateSubscription`) remain active
- When connection drops silently (app in background), streams may error out
- **No state restoration** when app resumes

**Keep Screen On Plugin:**
- Temperature, Servo, Light, Gamepad modules use `keep_screen_on` plugin
- Prevents screen lock WHILE actively using those screens
- But doesn't prevent app backgrounding (home button, notification swipe, etc.)

**Potential Root Causes:**

1. **Stream Errors Unhandled**: When app is backgrounded, Bluetooth streams may emit errors or close. These errors aren't properly caught, causing BLoC to enter error state. When app resumes, UI builds with error/corrupted state → black screen

2. **Connection State Mismatch**: BluetoothService thinks it's connected but underlying connection was dropped by OS during background. When app resumes, attempts to read data fail silently.

3. **Missing Lifecycle Hooks**: No `didChangeAppLifecycleState()` to:
   - Pause Bluetooth operations when app goes to background
   - Reconnect or restore state when app resumes
   - Clean up resources to prevent memory/state corruption

4. **BLoC State Not Reset**: When connection drops during background, BLoCs may be in intermediate states (TempLoading, TempConnected with stale data). No mechanism to detect and reset these states on resume.

5. **Timer-Based Operations**: TemperatureBloc uses:
   - `_heartbeatTimer` (sends 'P\n' every 5 seconds)
   - `_timeoutTimer` (45-second timeout)
   These timers continue running when app is backgrounded, potentially causing state transitions while UI is not visible.

## CRITICAL UPDATE: Issue Only Happens on HomePage

David confirmed the black screen **ONLY happens when on the main HomePage**, not on other screens.

### HomePage-Specific Analysis

**HomePage Structure** (`lib/features/home/presentation/pages/home_page.dart`):
- StatefulWidget that loads menu items via HomeBloc
- Uses `BlocBuilder<AuthBloc>` for user info in AppBar
- Uses nested `BlocListener<AuthBloc>` + `BlocBuilder<HomeBloc>` for main content
- Calls `LoadHomeData()` event on `initState`
- Shows GridView with menu cards (images loaded via `UtilImage.buildIcon`)

**GetCombinedMenu Use Case** (`lib/features/home/domain/usecases/get_combined_menu.dart`):
- Fetches local menu items (always)
- Checks authentication via `CheckSession` use case
- If authenticated, makes API call to fetch remote menu items
- **POTENTIAL ISSUE**: Network call during resume could timeout/fail

**Image Loading**:
- Menu items display images via `UtilImage.buildIcon`
- Supports: local assets (PNG, SVG), network images (PNG, SVG)
- **POTENTIAL ISSUE**: Network images failing to reload on resume

**AppBar with BackdropFilter**:
- Uses `BackdropFilter` with blur effect
- **POTENTIAL ISSUE**: Expensive rendering operation on resume

### Revised Root Cause Analysis (HomePage-Specific)

1. **Network Call Failure on Resume**:
   - When app resumes, HomePage `initState` doesn't re-run (widget already built)
   - But if user is authenticated, HomeBloc might have stale state
   - If network call to fetch remote menu fails/times out on resume → error state
   - Error state might not be properly handled → black screen

2. **Image Loading Failures**:
   - Network images in menu items fail to reload when app resumes
   - Flutter's `Image.network` might throw error if connection dropped
   - SVG network loading (`SvgPicture.network`) might fail silently
   - No error handling in `UtilImage.buildIcon` → widget fails to build → black screen

3. **BLoC State Corruption**:
   - HomePage has nested BlocBuilders (AuthBloc + HomeBloc)
   - When app resumes after long pause, one BLoC might be in error state
   - The nested structure might cause rebuild issues
   - If HomeBloc is in `loading` or `failure` state when resumed, UI might not recover

4. **BackdropFilter Memory Issue**:
   - BackdropFilter in AppBar is expensive
   - When app resumes from background, GPU resources might not be available
   - Could cause rendering pipeline failure → black screen

5. **State Mismatch After Resume**:
   - HomePage state flag `_hasShownSnackbar` persists across resume
   - BLoC states might be stale (HomeBloc showing old menu, AuthBloc with expired token)
   - No lifecycle hooks to refresh state when app resumes

## Most Likely Cause

**Network image loading failures + missing error handling in UtilImage.buildIcon**

When app resumes after being backgrounded:
1. HomePage tries to rebuild with existing HomeBloc state
2. GridView tries to render menu cards with images
3. Network images fail to load (connection dropped, cache cleared)
4. `Image.network` or `SvgPicture.network` throws unhandled error
5. Widget tree fails to build → **black screen**

This explains why:
- Only happens on HomePage (only place with GridView of images)
- Only happens after "a while" (OS clears image cache after memory pressure)
- Doesn't happen on other screens (they don't load network images in same way)

---

# IMPLEMENTATION PLAN

## Branch Strategy
- **Branch Name**: `feat/fix-home-page-black-screen-resume`
- **Base Branch**: `develop` (create if doesn't exist)
- **Target Branch**: `develop` (PR will target this branch)

## Team Selection

For this fix, I'll consult:
- **flutter-frontend-developer**: For Flutter lifecycle management, error handling patterns, and image loading best practices specific to the HomePage issue

## Comprehensive Solution Design

### Phase 1: Add Global App Lifecycle Management (CRITICAL)

**File**: `lib/main.dart` (`_MyAppState`)

**Changes**:
1. Implement `didChangeAppLifecycleState()` override
2. Handle app lifecycle states:
   - `AppLifecycleState.resumed`: Refresh HomePage data if currently on HomePage
   - `AppLifecycleState.paused`: Optional cleanup (for future use)
   - `AppLifecycleState.inactive`: Optional handling
   - `AppLifecycleState.detached`: Optional cleanup

**Implementation**:
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);

  if (state == AppLifecycleState.resumed) {
    // Trigger HomePage refresh if needed
    // Check current route and refresh HomeBloc
  }
}
```

### Phase 2: Add Error Handling to UtilImage.buildIcon

**File**: `lib/utils/util_image.dart`

**Changes**:
1. Wrap `Image.network` in `errorBuilder`
2. Wrap `SvgPicture.network` in error handling
3. Add fallback icon when image fails to load
4. Add loading placeholder for network images

**Implementation**:
```dart
static Widget buildIcon(MainMenuItemModel m, {double size = 60}) {
  if (m.assetPath != null) {
    // Local assets (no change needed)
  } else if (m.imageUrl != null) {
    if (m.imageUrl!.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        m.imageUrl!,
        width: size,
        height: size,
        placeholderBuilder: (context) => CircularProgressIndicator(),
        // Add error handling for SVG
      );
    } else {
      return Image.network(
        m.imageUrl!,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return CircularProgressIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.broken_image, size: size);
        },
      );
    }
  }
  return const Icon(Icons.extension);
}
```

### Phase 3: Add HomePage Lifecycle Awareness

**File**: `lib/features/home/presentation/pages/home_page.dart` (`_HomePageState`)

**Changes**:
1. Implement `WidgetsBindingObserver` on `_HomePageState`
2. Add `didChangeAppLifecycleState` override
3. Refresh HomeBloc data when app resumes (only if on this page)
4. Clean up observer on dispose

**Implementation**:
```dart
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // existing code...
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload menu data to ensure fresh state
      context.read<HomeBloc>().add(LoadHomeData());
    }
  }
}
```

### Phase 4: Improve HomeBloc Error Handling

**File**: `lib/features/home/presentation/bloc/home_bloc.dart`

**Changes**:
1. Add better error handling in `_onLoad`
2. Add timeout to network calls (via use case)
3. Ensure graceful degradation (show local menu if remote fails)

**File**: `lib/features/home/domain/usecases/get_combined_menu.dart`

**Changes**:
1. Add timeout to `checkSession()` call
2. Add timeout to `getRemoteMenuItems()` call
3. Ensure `checkSession()` doesn't throw - always returns bool

### Phase 5: Add Error Recovery UI to HomePage

**File**: `lib/features/home/presentation/pages/home_page.dart`

**Changes**:
1. Improve error state UI in HomeBloc builder
2. Add "Retry" button when in failure state
3. Add better loading state indicator
4. Consider adding pull-to-refresh functionality

**Implementation**:
```dart
if (state.status == HomeStatus.failure) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text('Error: ${state.error ?? 'Algo salió mal'}'),
        SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.refresh),
          label: Text('Reintentar'),
          onPressed: () => context.read<HomeBloc>().add(LoadHomeData()),
        ),
      ],
    ),
  );
}
```

### Phase 6: Add Global Error Handler (Optional but Recommended)

**File**: `lib/main.dart`

**Changes**:
1. Wrap `runApp()` in `runZonedGuarded` to catch unhandled errors
2. Set custom `ErrorWidget.builder` to show user-friendly error screen
3. Log errors properly instead of crashing

**Implementation**:
```dart
void main() async {
  // existing setup...

  // Global error handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Algo salió mal. Por favor reinicia la app.'),
        ),
      ),
    );
  };

  runZonedGuarded(() {
    runApp(...);
  }, (error, stackTrace) {
    // Log error
    debugPrint('Unhandled error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}
```

## Testing Strategy

### Unit Tests
1. **UtilImage Tests**:
   - Test error handling for failed network images
   - Test fallback icons
   - Test loading placeholders

2. **HomeBloc Tests**:
   - Test `LoadHomeData` with network timeout
   - Test graceful degradation when remote fails
   - Test error state handling

3. **GetCombinedMenu Tests**:
   - Test timeout scenarios
   - Test when checkSession throws
   - Test when remote API fails

### Widget Tests
1. **HomePage Tests**:
   - Test lifecycle observer registration/cleanup
   - Test reload on app resume
   - Test error state UI with retry button
   - Test loading state

### Integration Tests (Manual)
1. Lock device while on HomePage → wait 30 seconds → unlock → verify no black screen
2. Switch to another app → wait → return to app → verify HomePage reloads
3. Turn off WiFi → resume app → verify graceful error handling
4. Test with authenticated user (network menu items)
5. Test with unauthenticated user (local menu only)

## File Changes Summary

### Files to Modify:
1. `lib/main.dart` - Add global lifecycle handling + error widget
2. `lib/utils/util_image.dart` - Add error handling to image loading
3. `lib/features/home/presentation/pages/home_page.dart` - Add lifecycle observer, improve error UI
4. `lib/features/home/presentation/bloc/home_bloc.dart` - Better error handling
5. `lib/features/home/domain/usecases/get_combined_menu.dart` - Add timeouts

### Files to Create:
1. `test/utils/util_image_test.dart` - Unit tests for image utility
2. `test/features/home/presentation/bloc/home_bloc_test.dart` - BLoC tests (if doesn't exist)
3. `test/features/home/domain/usecases/get_combined_menu_test.dart` - Use case tests
4. `test/features/home/presentation/pages/home_page_test.dart` - Widget tests

## Documentation Updates

### Files to Create/Update:
1. `.claude/sessions/context_session_black_screen_resume.md` - This file (keep updated)
2. Update CLAUDE.md if new patterns are established

## Performance Considerations

1. **Image Caching**: Consider adding `cached_network_image` package for better network image handling
2. **API Timeout**: Set reasonable timeout (5-10 seconds) for remote menu fetch
3. **Debounce Reloads**: Prevent multiple rapid reloads if user toggles app quickly

## Risks and Mitigation

### Risk 1: Over-reloading
**Mitigation**: Add debounce logic or check if data is already fresh

### Risk 2: Breaking existing functionality
**Mitigation**: Comprehensive testing, especially auth flow and menu loading

### Risk 3: Image loading performance
**Mitigation**: Use cached_network_image or implement proper caching strategy

## Progress Log
- **Phase 1**: ✅ Explored codebase structure and lifecycle handling
- **Phase 2**: ✅ Identified root causes and architectural gaps
- **Phase 3**: ✅ HomePage-specific investigation - FOUND LIKELY CAUSE
- **Phase 4**: ✅ Created comprehensive implementation plan
- **Phase 5**: ✅ Consulted flutter-frontend-developer sub-agent for architectural guidance
- **Phase 6**: ✅ Created detailed implementation plan with code examples
- **Phase 7**: ✅ Created GitHub issue #11: https://github.com/DavidFlores79/makerslab_app/issues/11
- **Phase 8**: ✅ Created feature branch: feat/fix-home-page-black-screen-resume

## Implementation Plan Documents

**Primary Document**: `.claude/doc/black_screen_resume/flutter-frontend.md`
- Complete architectural guidance
- Code examples for all components
- Testing strategy with specific test cases
- Performance analysis and optimizations
- Flutter-specific gotchas and pitfalls
- Risk analysis and deployment strategy

**Quick Reference**: `.claude/doc/black_screen_resume/QUICK_REFERENCE.md`
- TL;DR of key decisions
- Implementation checklist
- Success criteria
- Files to change

## Key Architectural Decisions

### 1. Image Error Handling
- **Package**: `cached_network_image: ^3.4.1` for PNG/JPG
- **SVG Handling**: Manual FutureBuilder + in-memory cache
- **Why**: CachedNetworkImage doesn't support SVG; manual caching is simple for menu icons

### 2. Lifecycle Management
- **Pattern**: WidgetsBindingObserver in _HomePageState
- **Debouncing**: 2-second timestamp-based threshold
- **Why**: Scoped to HomePage (only place with issue), prevents rapid reloads

### 3. Error Handling
- **Approach**: Three layers (BLoC error states + UI retry + Global ErrorWidget)
- **Pattern**: NO try-catch in build(), rely on error states
- **Why**: Defense in depth, graceful degradation, Flutter best practice

### 4. Testing Strategy
- **Scope**: Critical tests only (image errors, lifecycle, BLoC errors)
- **Coverage**: 80%+ for util_image, 60%+ for home_page, 80%+ for home_bloc
- **Why**: User wants "minimal now, comprehensive later"

### 5. Performance
- **Implement Now**: RepaintBoundary, debouncing, cache limits
- **Defer**: SliverGrid refactor, smart cache invalidation
- **Why**: Low-hanging fruit first, complex optimizations later

## Ready for Implementation

All architectural decisions have been made. Implementation can begin following the detailed plan in `flutter-frontend.md`.

**Next Steps**:
1. David reviews implementation plan
2. Approves or requests modifications
3. Begin implementation in phases (8 phases total)
4. Run critical tests
5. Manual QA (5 test scenarios)
6. Merge to develop branch
