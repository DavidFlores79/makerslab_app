# Flutter Frontend Implementation Plan: Black Screen on App Resume Fix

## Executive Summary

David, after analyzing the context session file and your codebase, I've identified the architectural approach to fix the black screen issue on HomePage resume. The root cause is **unhandled network image loading failures** combined with **missing lifecycle awareness**. Below is the detailed architectural guidance.

---

## 1. Image Error Handling with cached_network_image

### Package Selection & Rationale

**Recommendation**: Add `cached_network_image: ^3.4.1` to pubspec.yaml

**Why cached_network_image over alternatives:**
- Industry standard for Flutter network image handling
- Built-in error handling, loading placeholders, and retry mechanisms
- Automatic disk and memory caching
- Better performance than raw `Image.network`
- Handles edge cases (network timeouts, 404s, SSL errors)

**Current Gap**: Your project already has image caching dependencies (via `image_picker`) but NOT dedicated network image caching.

### Implementation Strategy for UtilImage.buildIcon

**Problem**: Current implementation has ZERO error handling:
```dart
// Current code - NO error handling
Image.network(m.imageUrl!, width: size, height: size);
SvgPicture.network(m.imageUrl!, width: size, height: size);
```

**Solution**: Replace with cached_network_image + error handling

#### For PNG/JPG Images (Use CachedNetworkImage Widget)

```dart
import 'package:cached_network_image/cached_network_image.dart';

// Inside buildIcon method for non-SVG network images
return CachedNetworkImage(
  imageUrl: m.imageUrl!,
  width: size,
  height: size,
  fit: BoxFit.contain, // Maintain aspect ratio

  // Loading placeholder - shows while downloading
  placeholder: (context, url) => SizedBox(
    width: size,
    height: size,
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  ),

  // Error widget - shows on failure with retry button
  errorWidget: (context, url, error) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: size * 0.4,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          SizedBox(height: 4),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          // Optional: Add retry button
          // IconButton(
          //   icon: Icon(Icons.refresh, size: 16),
          //   onPressed: () {
          //     // Trigger reload by clearing cache
          //     CachedNetworkImage.evictFromCache(url);
          //     // Force widget rebuild
          //     (context as Element).markNeedsBuild();
          //   },
          // ),
        ],
      ),
    );
  },

  // Cache configuration
  cacheKey: m.imageUrl, // Use URL as cache key
  maxHeightDiskCache: 400, // Reasonable size for menu icons
  maxWidthDiskCache: 400,
  memCacheWidth: (size * MediaQuery.of(context).devicePixelRatio).toInt(),
  memCacheHeight: (size * MediaQuery.of(context).devicePixelRatio).toInt(),
);
```

#### For SVG Network Images (Use flutter_svg with Error Handling)

**Important**: `cached_network_image` does NOT natively support SVG. You must use `flutter_svg` with custom caching.

**Recommended Approach** - Use `SvgPicture.network` with enhanced error handling:

```dart
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;

// For SVG network images
return SvgPicture.network(
  m.imageUrl!,
  width: size,
  height: size,
  fit: BoxFit.contain,

  // Loading placeholder
  placeholderBuilder: (BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  },

  // Error handling - CRITICAL for preventing black screen
  // This is called when SVG fails to load or parse
  // NOTE: flutter_svg doesn't have built-in errorBuilder, we handle via try-catch
);
```

**Problem**: `SvgPicture.network` doesn't have an `errorBuilder` parameter like `Image.network`.

**Solution**: Wrap in FutureBuilder with manual error handling:

```dart
import 'package:http/http.dart' as http;

// For SVG network images - with error handling
return FutureBuilder<String>(
  future: _fetchSvgString(m.imageUrl!),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // Loading state
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      // Error state - show fallback icon
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: size * 0.4,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            SizedBox(height: 4),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }

    // Success - render SVG from string
    return SvgPicture.string(
      snapshot.data!,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  },
);

// Helper method to fetch SVG as string (with caching)
static final Map<String, String> _svgCache = {};

static Future<String> _fetchSvgString(String url) async {
  // Check cache first
  if (_svgCache.containsKey(url)) {
    return _svgCache[url]!;
  }

  // Fetch from network with timeout
  final response = await http.get(
    Uri.parse(url),
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('SVG load timeout'),
  );

  if (response.statusCode != 200) {
    throw HttpException('Failed to load SVG: ${response.statusCode}');
  }

  // Cache the result
  _svgCache[url] = response.body;
  return response.body;
}
```

**IMPORTANT**: This manual SVG caching is simple but has limitations (memory-only, no disk persistence). For production, consider:
- Using `shared_preferences` or `path_provider` to cache SVG files to disk
- Implementing LRU cache eviction
- For now, this in-memory cache is sufficient for HomePage menu icons

### Alternative Approach: Simplified SVG Handling

**If manual caching is too complex**, use this simpler fallback approach:

```dart
// Simpler SVG approach - no caching but with error handling
return SvgPicture.network(
  m.imageUrl!,
  width: size,
  height: size,
  fit: BoxFit.contain,
  placeholderBuilder: (context) => SizedBox(
    width: size,
    height: size,
    child: Center(
      child: CircularProgressIndicator(strokeWidth: 2.0),
    ),
  ),
  // Wrap the whole widget in a try-catch via ErrorWidget override
);
```

Then wrap the entire GridView item in an `ErrorBoundary` widget (custom implementation).

### Complete Updated UtilImage.buildIcon Method

```dart
// ABOUTME: This file contains utility methods for managing image assets in the app
// ABOUTME: It handles local assets (PNG, SVG) and network images with error handling and caching

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';

import '../features/home/data/models/main_menu_item_model.dart';

class UtilImage {
  // ... existing constants ...

  // In-memory SVG cache (simple approach)
  static final Map<String, String> _svgCache = {};

  /// Builds an icon widget for a menu item with proper error handling
  /// Supports: local assets (PNG, SVG), network images (PNG, SVG)
  /// Returns fallback icon if loading fails
  static Widget buildIcon(MainMenuItemModel m, {double size = 60}) {
    if (m.assetPath != null) {
      // LOCAL ASSETS - no changes needed, these always work
      if (m.assetPath!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(m.assetPath!, width: size, height: size);
      } else {
        return Image.asset(m.assetPath!, width: size, height: size);
      }
    } else if (m.imageUrl != null) {
      // NETWORK IMAGES - enhanced with error handling
      if (m.imageUrl!.toLowerCase().endsWith('.svg')) {
        // SVG Network Image - use FutureBuilder for error handling
        return _buildNetworkSvg(m.imageUrl!, size);
      } else {
        // PNG/JPG Network Image - use cached_network_image
        return _buildNetworkImage(m.imageUrl!, size);
      }
    } else {
      // FALLBACK - no image specified
      return Icon(Icons.extension, size: size);
    }
  }

  /// Build network PNG/JPG with caching and error handling
  static Widget _buildNetworkImage(String url, double size) {
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (context, url) => _buildLoadingPlaceholder(size),
      errorWidget: (context, url, error) => _buildErrorWidget(size),
      cacheKey: url,
      maxHeightDiskCache: 400,
      maxWidthDiskCache: 400,
    );
  }

  /// Build network SVG with error handling (using FutureBuilder)
  static Widget _buildNetworkSvg(String url, double size) {
    return FutureBuilder<String>(
      future: _fetchSvgString(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder(size);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          debugPrint('SVG load error for $url: ${snapshot.error}');
          return _buildErrorWidget(size);
        }

        return SvgPicture.string(
          snapshot.data!,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      },
    );
  }

  /// Fetch SVG string with in-memory caching
  static Future<String> _fetchSvgString(String url) async {
    // Check cache first
    if (_svgCache.containsKey(url)) {
      return _svgCache[url]!;
    }

    try {
      // Fetch from network with timeout
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('SVG load timeout'),
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to load SVG: ${response.statusCode}');
      }

      // Cache the result
      _svgCache[url] = response.body;
      return response.body;
    } catch (e) {
      debugPrint('Error fetching SVG from $url: $e');
      rethrow;
    }
  }

  /// Clear SVG cache (call this if memory pressure detected)
  static void clearSvgCache() {
    _svgCache.clear();
  }

  /// Loading placeholder widget
  static Widget _buildLoadingPlaceholder(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: const CircularProgressIndicator(strokeWidth: 2.0),
        ),
      ),
    );
  }

  /// Error widget with broken image icon
  static Widget _buildErrorWidget(double size) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: size * 0.4,
                color: theme.colorScheme.onErrorContainer,
              ),
              SizedBox(height: 4),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Key Architectural Decisions

1. **Widget Choice**: Use `CachedNetworkImage` widget (NOT `CachedNetworkImageProvider`) because:
   - Widget provides built-in `errorWidget` and `placeholder` parameters
   - Provider requires manual error handling in parent widget
   - Widget is more declarative and Flutter-idiomatic

2. **SVG Handling**: Use manual `FutureBuilder` + in-memory cache because:
   - `cached_network_image` doesn't support SVG
   - Full disk caching would require additional complexity
   - Menu icons are small and infrequently change
   - In-memory cache is cleared on app restart (acceptable for this use case)

3. **Error Widget**: Show branded error state (not just icon) because:
   - Maintains grid layout even when images fail
   - Provides visual feedback (not silent failure)
   - User knows something went wrong but UI doesn't break

---

## 2. HomePage Lifecycle Management

### Problem Analysis

**Current State**: HomePage has NO lifecycle awareness. When app resumes:
- `initState()` doesn't re-run (widget already built)
- BLoC state might be stale
- Network images fail to reload
- No refresh mechanism

**User Requirement**: "Always reload" behavior - fresh data on every resume.

### Recommended Implementation Pattern

#### Step 1: Implement WidgetsBindingObserver

```dart
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _hasShownSnackbar = false;
  DateTime? _lastResumeTime; // Track last resume to prevent rapid reloads

  @override
  void initState() {
    super.initState();

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    debugPrint('>>> HomePage initState');
    context.read<HomeBloc>().add(LoadHomeData());

    // ... existing snackbar logic ...
  }

  @override
  void dispose() {
    // CRITICAL: Always remove observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('>>> HomePage lifecycle state changed to: $state');

    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    } else if (state == AppLifecycleState.paused) {
      _handleAppPause();
    }
  }

  void _handleAppResume() {
    debugPrint('>>> HomePage - App resumed, reloading data');

    // Debounce: Only reload if enough time has passed since last resume
    final now = DateTime.now();
    if (_lastResumeTime != null) {
      final timeSinceLastResume = now.difference(_lastResumeTime!);
      if (timeSinceLastResume.inSeconds < 2) {
        debugPrint('>>> Skipping reload - too soon since last resume');
        return;
      }
    }

    _lastResumeTime = now;

    // Reload home data to get fresh menu items
    if (mounted && context.mounted) {
      context.read<HomeBloc>().add(LoadHomeData());
    }

    // Optional: Clear image caches to force reload
    // CachedNetworkImage.evictFromCache(url); // For specific URLs
    // UtilImage.clearSvgCache(); // For SVG cache
  }

  void _handleAppPause() {
    debugPrint('>>> HomePage - App paused');
    // Optional: Clean up resources, pause timers, etc.
    // For now, no action needed
  }

  // ... rest of build method ...
}
```

### Debouncing Strategy

**Why Debounce?**
- User might quickly switch apps (swipe through recent apps)
- Multiple rapid `resumed` events could trigger excessive API calls
- Network pressure, battery drain, potential rate limiting

**Recommended Debounce Time**: 2 seconds
- Short enough for responsive feel
- Long enough to prevent rapid-fire reloads
- Balances UX and performance

**Alternative Debouncing Approaches**:

1. **Timer-Based Debounce** (more sophisticated):
```dart
Timer? _debounceTimer;

void _handleAppResume() {
  // Cancel existing timer
  _debounceTimer?.cancel();

  // Start new timer
  _debounceTimer = Timer(const Duration(seconds: 2), () {
    if (mounted && context.mounted) {
      context.read<HomeBloc>().add(LoadHomeData());
    }
  });
}

@override
void dispose() {
  _debounceTimer?.cancel();
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

2. **Timestamp-Based Debounce** (simpler, recommended):
```dart
// Already shown above - tracks _lastResumeTime
```

**Recommendation**: Use **timestamp-based debounce** (shown in code above) because:
- Simpler implementation
- No timer management needed
- More predictable behavior
- Sufficient for this use case

### Preventing Multiple Rapid Reloads

**Additional Safeguards**:

1. **Check BLoC State Before Reload**:
```dart
void _handleAppResume() {
  // Only reload if not already loading
  final currentState = context.read<HomeBloc>().state;
  if (currentState.status == HomeStatus.loading) {
    debugPrint('>>> Skipping reload - already loading');
    return;
  }

  // ... proceed with reload ...
}
```

2. **Use BLoC Event Debouncing** (in HomeBloc):
```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(...) : super(HomeInitial()) {
    // Add debouncing to LoadHomeData event
    on<LoadHomeData>(
      _onLoad,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
  }
}

// Helper transformer
EventTransformer<T> debounce<T>(Duration duration) {
  return (events, mapper) => events
      .debounceTime(duration)
      .switchMap(mapper);
}
```

**Note**: Requires `rxdart` package for `debounceTime` and `switchMap`.

### Best Practice Recommendation

**For this fix, use BOTH**:
1. **Timestamp-based debouncing in HomePage** (2-second threshold)
2. **State check before reload** (don't reload if already loading)

This provides defense-in-depth without adding package dependencies.

---

## 3. Error Handling Pattern

### Current Architecture Analysis

**Nested BlocBuilder Structure**:
```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, authState) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            // UI rendering here
          },
        ),
      ),
    );
  },
);
```

**Potential Issues**:
1. Outer `BlocBuilder<AuthBloc>` rebuilds entire scaffold when auth changes
2. Inner `BlocBuilder<HomeBloc>` rebuilds menu grid when home state changes
3. If either BLoC enters error state unexpectedly, widget tree might fail to build
4. No top-level error boundary to catch widget build errors

### Should You Add try-catch in build Method?

**NO - Never add try-catch in build() method**

**Why?**:
- Flutter framework handles widget build errors gracefully
- try-catch in build() masks real issues
- Prevents Flutter DevTools from showing error details
- Not idiomatic Flutter pattern

**Instead**: Rely on BLoC error states + custom ErrorWidget.

### Recommended Error Handling Architecture

#### Layer 1: BLoC Error States (Already Implemented)

```dart
// HomeBloc already has error handling
if (state.status == HomeStatus.failure) {
  return Center(
    child: Text('Error: ${state.error ?? 'Algo salió mal'}'),
  );
}
```

**Enhancement**: Add retry button (already shown in Phase 5 of context session).

#### Layer 2: Global ErrorWidget Override (App-Level)

**File**: `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... existing setup ...

  // Set custom error widget builder (replaces default red screen)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Log error for debugging
    debugPrint('>>> Widget build error: ${details.exception}');
    debugPrint('>>> Stack trace: ${details.stack}');

    // Show user-friendly error UI
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[700],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Algo salió mal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Por favor reinicia la aplicación',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  // Optional: Show error details in debug mode
                  if (kDebugMode) ...[
                    Text(
                      'Error: ${details.exception}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  // Optional: Catch unhandled exceptions in zone
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('>>> Unhandled error in zone: $error');
      debugPrint('>>> Stack trace: $stackTrace');
      // Optional: Send to crash reporting service (Firebase Crashlytics, Sentry)
    },
  );
}
```

#### Layer 3: Enhanced HomePage Error UI

**Current error UI** (line 115-118 in home_page.dart):
```dart
if (state.status == HomeStatus.failure) {
  return Center(
    child: Text('Error: ${state.error ?? 'Algo salió mal'}'),
  );
}
```

**Enhanced error UI** (add retry, better styling):
```dart
if (state.status == HomeStatus.failure) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'Error al cargar menú',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.error ?? 'Algo salió mal al cargar los módulos',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            onPressed: () {
              context.read<HomeBloc>().add(LoadHomeData());
            },
          ),
        ],
      ),
    ),
  );
}
```

### Flutter Best Practice for Widget Build Errors

**Recommended Pattern** (what we're implementing):
1. **BLoC Layer**: Handle domain/data errors → emit error states
2. **UI Layer**: Render error states with user-friendly messages
3. **App Layer**: Override `ErrorWidget.builder` for catastrophic failures
4. **Development**: Use Flutter DevTools to debug widget build issues

**What NOT to Do**:
- ❌ try-catch in build() method
- ❌ Suppressing errors without logging
- ❌ Showing generic "Something went wrong" without retry
- ❌ Ignoring error states in BLoC

**What TO Do**:
- ✅ Explicit error state handling in BLoCs
- ✅ User-friendly error UI with retry options
- ✅ Logging errors for debugging
- ✅ Global ErrorWidget.builder as last resort
- ✅ Prevent errors at source (image error handlers, null checks)

---

## 4. Testing Approach

### Testing Philosophy

**User's Request**: "Minimal tests now, comprehensive later"

**Interpretation**: Focus on CRITICAL tests that prevent regressions. Skip edge cases for now.

### CRITICAL Tests to Implement Now

#### Test 1: UtilImage.buildIcon Error Handling

**File**: `test/utils/util_image_test.dart`

**Test Cases** (MUST IMPLEMENT):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:makerslab_app/utils/util_image.dart';
import 'package:makerslab_app/features/home/data/models/main_menu_item_model.dart';

void main() {
  group('UtilImage.buildIcon', () {
    testWidgets('should show loading placeholder for network PNG', (tester) async {
      final menuItem = MainMenuItemModel(
        imageUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      // Should show CircularProgressIndicator while loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error widget for failed network PNG', (tester) async {
      final menuItem = MainMenuItemModel(
        imageUrl: 'https://invalid-url-that-will-fail.com/icon.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      // Pump until image fails to load
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      // Should show error icon (broken_image_outlined)
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('should render local asset PNG successfully', (tester) async {
      final menuItem = MainMenuItemModel(
        assetPath: 'assets/images/brand/logo-app.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render Image widget without errors
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should show fallback icon when no image specified', (tester) async {
      final menuItem = MainMenuItemModel(
        // No assetPath or imageUrl
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show fallback Icon(Icons.extension)
      expect(find.byIcon(Icons.extension), findsOneWidget);
    });

    // CRITICAL: Test SVG error handling
    testWidgets('should handle SVG network failures gracefully', (tester) async {
      final menuItem = MainMenuItemModel(
        imageUrl: 'https://invalid-url.com/icon.svg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtilImage.buildIcon(menuItem),
          ),
        ),
      );

      // Should show loading first
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for SVG fetch to fail
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      // Should show error widget
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });
  });
}
```

**Why These Tests are CRITICAL**:
- Network image failures are the ROOT CAUSE of black screen
- These tests verify error handling prevents widget tree crash
- Cover all code paths (local asset, network PNG, network SVG, fallback)

#### Test 2: HomePage Lifecycle Observer

**File**: `test/features/home/presentation/pages/home_page_test.dart`

**Test Cases** (MUST IMPLEMENT):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:makerslab_app/features/home/presentation/pages/home_page.dart';
import 'package:makerslab_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:makerslab_app/features/auth/presentation/bloc/auth_bloc.dart';

// Mock classes (generate with mockito)
class MockHomeBloc extends Mock implements HomeBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockHomeBloc mockHomeBloc;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockHomeBloc = MockHomeBloc();
    mockAuthBloc = MockAuthBloc();

    // Setup default states
    when(mockHomeBloc.state).thenReturn(HomeInitial());
    when(mockAuthBloc.state).thenReturn(Unauthenticated());
    when(mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());
    when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('should register WidgetsBindingObserver on initState', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<HomeBloc>.value(value: mockHomeBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const HomePage(),
        ),
      ),
    );

    // Observer should be registered
    // (Hard to test directly, but we can verify no exceptions)
    expect(tester.takeException(), isNull);
  });

  testWidgets('should reload data on app resume', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<HomeBloc>.value(value: mockHomeBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const HomePage(),
        ),
      ),
    );

    // Clear previous calls
    clearInteractions(mockHomeBloc);

    // Simulate app going to background then resuming
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Verify LoadHomeData event was dispatched
    verify(mockHomeBloc.add(any)).called(1);
  });

  testWidgets('should NOT reload if resumed too quickly (debounce)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<HomeBloc>.value(value: mockHomeBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const HomePage(),
        ),
      ),
    );

    clearInteractions(mockHomeBloc);

    // First resume
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Second resume immediately (within 2 seconds)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Should only trigger once (debounced)
    verify(mockHomeBloc.add(any)).called(1); // Not 2
  });

  testWidgets('should remove observer on dispose', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<HomeBloc>.value(value: mockHomeBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const HomePage(),
        ),
      ),
    );

    // Navigate away (triggers dispose)
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    // No exceptions should occur
    expect(tester.takeException(), isNull);
  });
}
```

**Why These Tests are CRITICAL**:
- Verify lifecycle observer is properly registered/unregistered
- Prevent memory leaks (observer not removed)
- Validate debouncing logic works correctly
- Ensure reload triggers on resume

#### Test 3: HomeBloc Error Scenarios

**File**: `test/features/home/presentation/bloc/home_bloc_test.dart`

**Test Cases** (MUST IMPLEMENT):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:makerslab_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:makerslab_app/features/home/domain/usecases/get_combined_menu.dart';
import 'package:makerslab_app/core/error/failure.dart';

// Mock use case
class MockGetCombinedMenu extends Mock implements GetCombinedMenu {}

void main() {
  late MockGetCombinedMenu mockGetCombinedMenu;
  late HomeBloc homeBloc;

  setUp(() {
    mockGetCombinedMenu = MockGetCombinedMenu();
    homeBloc = HomeBloc(getCombinedMenu: mockGetCombinedMenu);
  });

  tearDown(() {
    homeBloc.close();
  });

  group('LoadHomeData', () {
    blocTest<HomeBloc, HomeState>(
      'should emit [loading, success] when data loads successfully',
      build: () {
        when(mockGetCombinedMenu(any))
            .thenAnswer((_) async => Right([])); // Empty menu
        return homeBloc;
      },
      act: (bloc) => bloc.add(LoadHomeData()),
      expect: () => [
        HomeState(status: HomeStatus.loading),
        HomeState(status: HomeStatus.success, mainMenuItems: []),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'should emit [loading, failure] when network fails',
      build: () {
        when(mockGetCombinedMenu(any))
            .thenAnswer((_) async => Left(NetworkFailure('No internet')));
        return homeBloc;
      },
      act: (bloc) => bloc.add(LoadHomeData()),
      expect: () => [
        HomeState(status: HomeStatus.loading),
        HomeState(
          status: HomeStatus.failure,
          error: 'No internet',
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'should emit [loading, failure] when server fails',
      build: () {
        when(mockGetCombinedMenu(any))
            .thenAnswer((_) async => Left(ServerFailure('Server error')));
        return homeBloc;
      },
      act: (bloc) => bloc.add(LoadHomeData()),
      expect: () => [
        HomeState(status: HomeStatus.loading),
        HomeState(
          status: HomeStatus.failure,
          error: 'Server error',
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'should handle use case throwing exception',
      build: () {
        when(mockGetCombinedMenu(any))
            .thenThrow(Exception('Unexpected error'));
        return homeBloc;
      },
      act: (bloc) => bloc.add(LoadHomeData()),
      expect: () => [
        HomeState(status: HomeStatus.loading),
        HomeState(
          status: HomeStatus.failure,
          error: isA<String>(), // Should have error message
        ),
      ],
    );
  });
}
```

**Why These Tests are CRITICAL**:
- Verify BLoC handles all failure scenarios gracefully
- Ensure error states are properly emitted
- Prevent unhandled exceptions from reaching UI
- Cover network, server, and unexpected errors

### Additional Tests (Implement Later)

**Defer to "comprehensive testing" phase**:
- Integration tests (manual testing for now)
- Golden tests for error UI
- Performance tests (frame rate during reload)
- Edge cases (malformed image URLs, very large images)

### Test Coverage Requirements

**Minimum for this PR**:
- `util_image.dart`: 80%+ coverage (all error paths)
- `home_page.dart`: 60%+ coverage (lifecycle hooks)
- `home_bloc.dart`: 80%+ coverage (error scenarios)

**Tools**:
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 5. Performance Concerns

### Current Performance Issues

#### Issue 1: BackdropFilter in AppBar

**Code** (from `PxMainAppBar` widget):
```dart
// Likely implementation
AppBar(
  flexibleSpace: ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(...),
    ),
  ),
)
```

**Performance Impact**:
- `BackdropFilter` is GPU-intensive (blur effect)
- On resume, GPU resources might not be immediately available
- Could cause frame drops (jank) during transition

**Mitigation Strategies**:

1. **Reduce blur intensity** (if visually acceptable):
```dart
filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Lower = faster
```

2. **Use RepaintBoundary** (isolate expensive widget):
```dart
RepaintBoundary(
  child: BackdropFilter(...),
)
```

3. **Conditionally disable blur on low-end devices**:
```dart
final bool shouldBlur = MediaQuery.of(context).size.width > 600; // Example heuristic

AppBar(
  flexibleSpace: shouldBlur
      ? BackdropFilter(...)
      : Container(color: Colors.transparent),
)
```

**Recommendation for this PR**: Leave as-is. BackdropFilter is NOT the root cause of black screen (confirmed by user: "only happens on HomePage"). If performance issues arise later, implement strategy #2 (RepaintBoundary).

#### Issue 2: GridView with Network Images

**Code** (from `home_page.dart`):
```dart
GridView.builder(
  shrinkWrap: true, // WARNING: Performance issue
  physics: const BouncingScrollPhysics(),
  itemCount: menu.length,
  itemBuilder: (context, index) {
    return Card(
      child: UtilImage.buildIcon(menu[index]), // Network image
    );
  },
)
```

**Performance Issues**:
1. `shrinkWrap: true` forces GridView to layout all children immediately (no lazy loading)
2. Network images load on every rebuild
3. No image size constraints (could load huge images)

**Optimizations**:

1. **Remove shrinkWrap** (use SliverGrid instead):
```dart
// Replace SingleChildScrollView + GridView with CustomScrollView
CustomScrollView(
  physics: const BouncingScrollPhysics(),
  slivers: [
    SliverPadding(
      padding: const EdgeInsets.all(20.0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final m = menu[index];
            return Card(...); // Same card implementation
          },
          childCount: menu.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1,
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
      ),
    ),
  ],
)
```

2. **Add RepaintBoundary to each GridView item**:
```dart
itemBuilder: (context, index) {
  return RepaintBoundary(
    key: ValueKey(menu[index].id), // Use unique key
    child: Card(...),
  );
}
```

3. **Limit image cache size** (already implemented in UtilImage):
```dart
maxHeightDiskCache: 400,
maxWidthDiskCache: 400,
```

**Recommendation for this PR**:
- ✅ Implement RepaintBoundary (easy win)
- ⏸ Defer SliverGrid refactor to later PR (larger change, needs QA)

#### Issue 3: Reloading on Every Resume

**User Requirement**: "Always reload" - fresh data on resume

**Performance Impact**:
- API call on every resume (network cost)
- Image cache invalidation (re-download images)
- BLoC state rebuild (UI re-render)

**Mitigation**:
1. **Smart Caching** (only reload if data is stale):
```dart
void _handleAppResume() {
  final currentState = context.read<HomeBloc>().state;

  // Only reload if data is older than 5 minutes
  if (currentState.lastUpdated != null) {
    final age = DateTime.now().difference(currentState.lastUpdated!);
    if (age.inMinutes < 5) {
      debugPrint('>>> Data is fresh, skipping reload');
      return;
    }
  }

  // Reload stale data
  context.read<HomeBloc>().add(LoadHomeData());
}
```

2. **Keep image cache on resume**:
```dart
// DON'T call these on resume:
// CachedNetworkImage.evictFromCache(url);
// UtilImage.clearSvgCache();
```

**Recommendation for this PR**:
- ✅ Implement debouncing (already planned)
- ✅ Keep image cache (don't clear on resume)
- ⏸ Defer smart caching to later PR (requires HomeState changes)

### Performance Measurement

**Before Release, Measure**:
```dart
import 'package:flutter/scheduler.dart';

void _measurePerformance() {
  final start = SchedulerBinding.instance.currentFrameTimeStamp;

  // Trigger reload
  context.read<HomeBloc>().add(LoadHomeData());

  SchedulerBinding.instance.addPostFrameCallback((_) {
    final end = SchedulerBinding.instance.currentFrameTimeStamp;
    final duration = end - start;
    debugPrint('>>> Reload took: ${duration.inMilliseconds}ms');
  });
}
```

**Performance Targets**:
- First frame after resume: < 100ms
- Full menu load: < 2 seconds (on good network)
- No frame drops during image loading (60 FPS)

### Optimization Recommendations Summary

**Implement in this PR**:
1. ✅ RepaintBoundary for GridView items
2. ✅ Debouncing (2-second threshold)
3. ✅ Keep image cache on resume
4. ✅ Limit image cache size (already done)

**Defer to later**:
1. ⏸ SliverGrid refactor (remove shrinkWrap)
2. ⏸ Conditional BackdropFilter (based on device capability)
3. ⏸ Smart cache invalidation (age-based reload)

---

## 6. Flutter-Specific Gotchas and Pitfalls

### Gotcha 1: WidgetsBindingObserver Lifecycle

**Pitfall**: Forgetting to remove observer in `dispose()`

**Consequence**: Memory leak, observer keeps listening after widget is disposed

**Fix**:
```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this); // CRITICAL
  super.dispose();
}
```

**Detection**: Run app with `flutter run --track-widget-creation` and check memory profiler.

### Gotcha 2: Context Validity in Async Callbacks

**Pitfall**: Using `context` after `await` without checking `mounted`

**Example** (WRONG):
```dart
void _handleAppResume() async {
  await Future.delayed(Duration(seconds: 1));
  context.read<HomeBloc>().add(LoadHomeData()); // CRASH if widget disposed
}
```

**Fix** (CORRECT):
```dart
void _handleAppResume() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted && context.mounted) { // Check both
    context.read<HomeBloc>().add(LoadHomeData());
  }
}
```

### Gotcha 3: CachedNetworkImage with BuildContext

**Pitfall**: `CachedNetworkImage` needs `BuildContext` for `errorWidget`

**Problem**: Using `errorWidget` in static method without context

**Solution** (already implemented):
```dart
// Use Builder to get context
errorWidget: (context, url, error) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context); // Now safe
      return Container(...);
    },
  );
}
```

### Gotcha 4: Image Caching Across App Restarts

**Pitfall**: Cached images might become stale after app update

**Consequence**: Users see old menu icons after app update

**Mitigation**:
```dart
// In GetCombinedMenu use case, include cache-busting strategy
final imageUrl = menuItem.imageUrl;
final cacheBustedUrl = '$imageUrl?v=${appVersion}'; // Add version query param
```

**Recommendation**: Implement cache-busting if API doesn't set proper Cache-Control headers.

### Gotcha 5: SVG Caching Memory Pressure

**Pitfall**: In-memory SVG cache grows unbounded

**Consequence**: OutOfMemoryError on low-end devices

**Mitigation** (implement in UtilImage):
```dart
static const int maxSvgCacheSize = 50; // Limit cache size

static Future<String> _fetchSvgString(String url) async {
  // Check cache first
  if (_svgCache.containsKey(url)) {
    return _svgCache[url]!;
  }

  // Evict oldest entry if cache is full
  if (_svgCache.length >= maxSvgCacheSize) {
    final oldestKey = _svgCache.keys.first;
    _svgCache.remove(oldestKey);
    debugPrint('>>> Evicted SVG from cache: $oldestKey');
  }

  // ... fetch and cache ...
}
```

### Gotcha 6: AppLifecycleState Transitions

**Pitfall**: `resumed` might fire even when app never fully paused

**Example**: Notification drawer pulls down, then closes → `inactive` → `resumed` (no `paused`)

**Fix**: Only reload on transition from `paused` to `resumed`, not `inactive` to `resumed`:
```dart
AppLifecycleState? _previousState;

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (_previousState == AppLifecycleState.paused &&
      state == AppLifecycleState.resumed) {
    _handleAppResume(); // Only reload on full resume
  }
  _previousState = state;
}
```

**Recommendation**: Start simple (reload on any `resumed`), add this refinement if too many false positives.

### Gotcha 7: BLoC Event Duplication

**Pitfall**: Dispatching same event multiple times rapidly

**Example**: User taps "Retry" button multiple times → multiple LoadHomeData events

**Fix**: Add event transformer to BLoC:
```dart
on<LoadHomeData>(
  _onLoad,
  transformer: (events, mapper) => events.distinct().switchMap(mapper),
);
```

**Recommendation**: Implement if you observe duplicate API calls in logs.

### Gotcha 8: Hot Reload vs Hot Restart

**Pitfall**: WidgetsBindingObserver doesn't reset on hot reload

**Consequence**: During development, observer might be registered twice

**Fix**: Use `flutter run --hot` carefully. When testing lifecycle, do full restart:
```bash
flutter run --hot  # For UI changes
r  # Hot reload (keeps observer state)
R  # Hot restart (resets observer)
```

**Recommendation**: Always test lifecycle changes with hot restart (R), not hot reload (r).

---

## 7. Complete Implementation Checklist

### Phase 1: Add cached_network_image Package

**File**: `pubspec.yaml`

```yaml
dependencies:
  # ... existing dependencies ...
  cached_network_image: ^3.4.1  # Add this line
  # http already exists (used for SVG fetching)
```

**Command**:
```bash
flutter pub add cached_network_image
```

---

### Phase 2: Update UtilImage with Error Handling

**File**: `lib/utils/util_image.dart`

**Changes**:
1. Add imports: `cached_network_image`, `http`, `dart:async`, `dart:io`
2. Replace `buildIcon` method with enhanced version (see Section 1)
3. Add private helper methods: `_buildNetworkImage`, `_buildNetworkSvg`, `_fetchSvgString`, `_buildLoadingPlaceholder`, `_buildErrorWidget`
4. Add SVG cache management: `_svgCache`, `clearSvgCache()`

**Full code**: See Section 1 "Complete Updated UtilImage.buildIcon Method"

---

### Phase 3: Add Lifecycle Observer to HomePage

**File**: `lib/features/home/presentation/pages/home_page.dart`

**Changes**:
1. Add `with WidgetsBindingObserver` to `_HomePageState`
2. Add field: `DateTime? _lastResumeTime;`
3. In `initState()`: Call `WidgetsBinding.instance.addObserver(this);`
4. Add `dispose()` override: Call `WidgetsBinding.instance.removeObserver(this);`
5. Add `didChangeAppLifecycleState()` override: Handle `resumed` and `paused`
6. Add helper method: `_handleAppResume()` with debouncing logic
7. Add helper method: `_handleAppPause()` (optional, placeholder for now)

**Full code**: See Section 2 "Recommended Implementation Pattern"

---

### Phase 4: Enhance HomePage Error UI

**File**: `lib/features/home/presentation/pages/home_page.dart`

**Changes**:
1. Replace error state UI (lines 115-118) with enhanced version
2. Add retry button that dispatches `LoadHomeData()` event
3. Improve styling with Material Design 3 components

**Full code**: See Section 3 "Layer 3: Enhanced HomePage Error UI"

---

### Phase 5: Add Global ErrorWidget Override

**File**: `lib/main.dart`

**Changes**:
1. Before `runApp()`, set `ErrorWidget.builder = (details) { ... }`
2. Wrap `runApp()` in `runZonedGuarded()` for unhandled exceptions
3. Log errors to console (future: send to crash reporting)

**Full code**: See Section 3 "Layer 2: Global ErrorWidget Override (App-Level)"

---

### Phase 6: Add RepaintBoundary to GridView Items

**File**: `lib/features/home/presentation/pages/home_page.dart`

**Changes**:
1. In `GridView.builder` itemBuilder, wrap Card in RepaintBoundary
2. Use unique key based on menu item ID

**Code**:
```dart
itemBuilder: (BuildContext context, int index) {
  final m = menu[index];

  return RepaintBoundary(
    key: ValueKey(m.id ?? index), // Use ID or fallback to index
    child: Card(
      // ... existing Card implementation ...
    ),
  );
},
```

---

### Phase 7: Write Critical Tests

**Files to Create**:

1. `test/utils/util_image_test.dart` - See Section 4, Test 1
2. `test/features/home/presentation/pages/home_page_test.dart` - See Section 4, Test 2
3. `test/features/home/presentation/bloc/home_bloc_test.dart` - See Section 4, Test 3

**Test Dependencies** (add if not present):
```yaml
dev_dependencies:
  # ... existing ...
  bloc_test: ^9.1.7  # For testing BLoCs
```

**Command**:
```bash
flutter pub add --dev bloc_test
```

---

### Phase 8: Run Tests and Verify Coverage

**Commands**:
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# View coverage (Windows)
start coverage/html/index.html
```

**Success Criteria**:
- All tests pass
- `util_image.dart`: 80%+ coverage
- `home_page.dart`: 60%+ coverage
- `home_bloc.dart`: 80%+ coverage

---

### Phase 9: Manual Testing

**Test Scenarios**:

1. **Black Screen Regression Test**:
   - Open app on HomePage
   - Lock device
   - Wait 2 minutes
   - Unlock device
   - **Expected**: HomePage reloads, menu visible, NO black screen

2. **Network Image Error Test**:
   - Turn off WiFi/mobile data
   - Open HomePage
   - **Expected**: Error icons visible, app doesn't crash

3. **Rapid Resume Test**:
   - Open HomePage
   - Quickly toggle between apps 5 times
   - **Expected**: Only 2-3 reloads (debouncing works)

4. **Auth Flow Test**:
   - Log out
   - Resume app
   - **Expected**: Snackbar shows, local menu visible

5. **Performance Test**:
   - Open HomePage with 10+ menu items
   - Lock/unlock device
   - **Expected**: Smooth animation, no jank

---

## 8. Architectural Decisions Summary

### Decision 1: Package Choice

**Choice**: `cached_network_image` for PNG/JPG, manual caching for SVG

**Rationale**:
- Industry standard, battle-tested
- Built-in error handling and retry
- SVG requires custom solution anyway

**Alternatives Considered**:
- `flutter_cache_manager` alone: Too low-level, more boilerplate
- `extended_image`: More features but heavier, overkill for this use case

---

### Decision 2: Lifecycle Management

**Choice**: `WidgetsBindingObserver` in HomePage (not global)

**Rationale**:
- Only HomePage needs reload on resume
- Keeps logic localized and testable
- Other pages might have different resume behavior

**Alternatives Considered**:
- Global observer in `main.dart`: Overkill, harder to test
- RouteObserver: Doesn't detect app pause/resume, only route changes

---

### Decision 3: Debouncing Strategy

**Choice**: Timestamp-based debounce (2-second threshold)

**Rationale**:
- Simple, no timer management
- Predictable behavior
- Sufficient for preventing rapid reloads

**Alternatives Considered**:
- Timer-based debounce: More complex, harder to test
- No debouncing: Risk of excessive API calls

---

### Decision 4: Error Handling Architecture

**Choice**: Three-layer approach (BLoC, UI, Global ErrorWidget)

**Rationale**:
- Defense in depth
- Graceful degradation (best UX)
- Catches both expected and unexpected errors

**Alternatives Considered**:
- Only BLoC error states: Misses widget build errors
- Only global ErrorWidget: Poor UX, no retry option

---

### Decision 5: Testing Scope

**Choice**: Focus on critical paths, defer edge cases

**Rationale**:
- User wants "minimal tests now"
- Critical tests prevent regressions
- Can expand coverage later

**Alternatives Considered**:
- Comprehensive testing upfront: Time-consuming, delays fix
- No tests: Risk of breaking existing functionality

---

## 9. Risk Analysis and Mitigation

### Risk 1: Over-Reloading

**Probability**: Medium
**Impact**: Medium (battery drain, API costs)
**Mitigation**: Debouncing + state check before reload

---

### Risk 2: Image Loading Performance

**Probability**: Low
**Impact**: Medium (slow load times)
**Mitigation**:
- Cache size limits
- RepaintBoundary
- Future: Lazy loading with SliverGrid

---

### Risk 3: SVG Cache Memory Pressure

**Probability**: Low
**Impact**: High (OutOfMemoryError)
**Mitigation**:
- Cache size limit (50 items)
- Eviction policy (FIFO)
- Future: Disk caching with `path_provider`

---

### Risk 4: Breaking Existing Auth Flow

**Probability**: Low
**Impact**: High (users can't log in)
**Mitigation**:
- Comprehensive testing of auth flow
- No changes to AuthBloc
- Only UI-level changes in HomePage

---

### Risk 5: Network Errors Not Handled

**Probability**: Very Low
**Impact**: High (black screen regression)
**Mitigation**:
- Comprehensive error widgets
- Tests for all error scenarios
- Global ErrorWidget as last resort

---

## 10. Deployment Strategy

### Pre-Deployment Checklist

- [ ] All tests pass (`flutter test`)
- [ ] Coverage meets targets (80%+ critical files)
- [ ] Manual testing completed (all 5 scenarios)
- [ ] No new analyzer warnings (`flutter analyze`)
- [ ] Code formatted (`dart format lib/ test/`)
- [ ] Debouncing tested (rapid resume doesn't cause multiple reloads)
- [ ] Error widgets tested (turn off WiFi, verify graceful degradation)
- [ ] Performance measured (no frame drops during reload)

### Rollout Plan

1. **Merge to develop branch**
2. **QA Testing** (1-2 days):
   - Test on multiple Android devices (different OS versions)
   - Test on iOS (if applicable)
   - Test on low-end devices (performance)
3. **Beta Release** (TestFlight / Internal Testing):
   - Dogfood with internal users
   - Monitor crash reports (Firebase Crashlytics)
4. **Production Release**:
   - Gradual rollout (10% → 50% → 100%)
   - Monitor error rates in analytics

### Rollback Plan

If critical issues found:
1. Revert commit (git revert)
2. Emergency hotfix release
3. Root cause analysis

---

## 11. Future Enhancements (Post-MVP)

### Enhancement 1: Smart Cache Invalidation

**Goal**: Only reload if data is stale (> 5 minutes old)

**Implementation**:
- Add `lastUpdated` timestamp to HomeState
- Check age before reloading in `_handleAppResume()`

---

### Enhancement 2: Disk-Based SVG Caching

**Goal**: Persist SVG cache across app restarts

**Implementation**:
- Use `path_provider` to get cache directory
- Save SVG strings to files
- Load from disk on app start

---

### Enhancement 3: SliverGrid Refactor

**Goal**: Remove `shrinkWrap` for better scroll performance

**Implementation**:
- Replace SingleChildScrollView + GridView with CustomScrollView + SliverGrid
- Requires testing to ensure no layout regressions

---

### Enhancement 4: Prefetching Images

**Goal**: Preload images in background for faster display

**Implementation**:
- When HomeBloc loads menu, precache images
- Use `precacheImage()` for PNG/JPG
- Use custom SVG prefetch for SVG

---

### Enhancement 5: Offline Mode with Sync

**Goal**: Full offline support, sync when back online

**Implementation**:
- Cache menu items to local database (sqflite)
- Show cached menu when offline
- Sync with API when online

---

## Conclusion

David, this implementation plan provides a comprehensive architectural approach to fix the black screen issue on app resume. The solution is:

- **Minimal**: Only touches 5 files in main codebase
- **Robust**: Three layers of error handling
- **Testable**: Critical tests ensure no regressions
- **Performant**: Debouncing and caching prevent excessive loads
- **Flutter-idiomatic**: Follows best practices and official patterns

**Key Takeaways**:
1. **Use `cached_network_image`** for PNG/JPG with built-in error handling
2. **Manual FutureBuilder** for SVG network images with in-memory cache
3. **WidgetsBindingObserver** in HomePage for lifecycle awareness
4. **Timestamp-based debouncing** (2 seconds) to prevent rapid reloads
5. **Three-layer error handling** (BLoC, UI, Global ErrorWidget)
6. **Critical tests only** - focus on image errors and lifecycle
7. **RepaintBoundary** for GridView items to optimize rendering

The implementation follows Clean Architecture, uses classic BLoC pattern, and maintains consistency with your existing codebase. All changes are backward-compatible and low-risk.

**Next Steps**:
1. Review this plan
2. Approve or request modifications
3. I'll update the context session file
4. Begin implementation in phases

Let me know if you need clarification on any section or want to adjust the approach!
