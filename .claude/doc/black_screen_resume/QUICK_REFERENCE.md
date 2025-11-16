# Quick Reference: Black Screen Fix Implementation

## TL;DR - Key Decisions

### 1. Image Error Handling

**Package**: Add `cached_network_image: ^3.4.1`

**For PNG/JPG Images**:
- Use `CachedNetworkImage` widget (NOT provider)
- Built-in `placeholder`, `errorWidget`, and caching
- Automatic retry and disk caching

**For SVG Images**:
- Use `FutureBuilder` + `http` to fetch SVG string
- Manual in-memory cache (simple Map)
- Render with `SvgPicture.string()`
- Show error icon on failure

**Why Not One Solution?**:
- `cached_network_image` doesn't support SVG
- Manual SVG handling is simple enough for menu icons
- Future: Can upgrade to disk-based SVG cache if needed

---

### 2. HomePage Lifecycle

**Pattern**: `WidgetsBindingObserver` in `_HomePageState`

**Implementation**:
```dart
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  DateTime? _lastResumeTime;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // ...
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // CRITICAL!
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }
}
```

**Debouncing**: 2-second threshold (timestamp-based)

**Why Debounce?**:
- Prevents rapid reloads when user swipes through apps
- Reduces API calls and battery drain
- Simple implementation (no timer management)

---

### 3. Error Handling

**Three-Layer Approach**:

1. **BLoC Layer**: Handle domain errors → emit error states
2. **UI Layer**: Show error states with retry button
3. **Global Layer**: Override `ErrorWidget.builder` for catastrophic failures

**Never Do**:
- ❌ try-catch in build() method
- ❌ Suppress errors without logging
- ❌ Generic errors without retry option

**Always Do**:
- ✅ Explicit error state handling in BLoCs
- ✅ User-friendly error UI with retry
- ✅ Logging for debugging
- ✅ Prevent errors at source (image error handlers)

---

### 4. Critical Tests

**Must Implement**:
1. `test/utils/util_image_test.dart` - Image error handling
2. `test/features/home/presentation/pages/home_page_test.dart` - Lifecycle observer
3. `test/features/home/presentation/bloc/home_bloc_test.dart` - BLoC error scenarios

**Coverage Targets**:
- `util_image.dart`: 80%+
- `home_page.dart`: 60%+
- `home_bloc.dart`: 80%+

**Edge Cases**: Defer to later (focus on critical paths now)

---

### 5. Performance

**Implement Now**:
- ✅ RepaintBoundary for GridView items
- ✅ Debouncing (2-second threshold)
- ✅ Keep image cache on resume (don't clear)
- ✅ Limit image cache size (400x400px)

**Defer to Later**:
- ⏸ SliverGrid refactor (remove shrinkWrap)
- ⏸ Conditional BackdropFilter (device capability)
- ⏸ Smart cache invalidation (age-based)

**Targets**:
- First frame after resume: < 100ms
- Full menu load: < 2s (good network)
- No frame drops (60 FPS)

---

## Flutter Gotchas to Avoid

1. **Always remove WidgetsBindingObserver in dispose()** → Memory leak
2. **Check `mounted && context.mounted` after async calls** → Crash
3. **Use `Builder` in static methods needing context** → Null error
4. **Limit SVG cache size** → OutOfMemoryError
5. **Test lifecycle with hot restart (R), not reload (r)** → Observer state issues

---

## Implementation Order

1. Add `cached_network_image` package
2. Update `UtilImage.buildIcon` with error handling
3. Add lifecycle observer to HomePage
4. Enhance HomePage error UI
5. Add global ErrorWidget override
6. Add RepaintBoundary to GridView
7. Write critical tests
8. Manual testing (5 scenarios)

---

## Files Changed

**Modified** (5 files):
1. `pubspec.yaml` - Add dependencies
2. `lib/utils/util_image.dart` - Error handling
3. `lib/features/home/presentation/pages/home_page.dart` - Lifecycle observer
4. `lib/main.dart` - Global ErrorWidget
5. Test files - Critical test coverage

**No Changes to**:
- AuthBloc (low risk of breaking auth flow)
- HomeBloc (only UI-level changes)
- Other pages (scoped to HomePage only)

---

## Success Criteria

**Functional**:
- [ ] No black screen after locking device for 2+ minutes
- [ ] Error icons show when network fails (no crash)
- [ ] Debouncing prevents excessive reloads
- [ ] Retry button works in error states

**Technical**:
- [ ] All tests pass
- [ ] Coverage targets met
- [ ] No analyzer warnings
- [ ] Performance targets met

**QA**:
- [ ] Manual testing completed (5 scenarios)
- [ ] Works on Android (multiple OS versions)
- [ ] Works on iOS (if applicable)
- [ ] No regressions in auth flow

---

## Questions Answered

1. **Image error handling**: Use `CachedNetworkImage` for PNG/JPG, manual FutureBuilder for SVG
2. **Lifecycle management**: `WidgetsBindingObserver` with 2-second debouncing
3. **Error handling**: Three-layer approach (BLoC + UI + Global), NO try-catch in build()
4. **Critical tests**: Image errors, lifecycle observer, BLoC error scenarios
5. **Performance**: RepaintBoundary + debouncing, defer SliverGrid refactor

---

## Next Steps

1. Review full implementation plan in `flutter-frontend.md`
2. Approve or request modifications
3. Begin implementation in phases
4. Run tests and manual QA
5. Merge to develop branch

---

**Full Details**: See `flutter-frontend.md` for complete code examples, architectural rationale, and test cases.
