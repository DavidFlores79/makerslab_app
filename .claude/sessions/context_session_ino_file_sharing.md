# Session: INO File Sharing Fix

## Feature Request
Fix the `_onDownloadAndShare` functionality that no longer works. When users tap the 'Descargar INO' button, it should show options to share the INO file via social media, email, or other sharing methods.

## Status
Planning phase - exploration complete

## Technology Stack
- Flutter 3.7.2+ with Dart 3.7.2+
- Target: Android/iOS
- Packages: share_plus 11.1.0, path_provider 2.1.5
- Clean Architecture pattern
- Dependency Injection: get_it 8.0.3

## Current Implementation Analysis

### Files Involved
1. **UI Layer**: `lib/shared/widgets/modules/build_main_content.dart` (line 37 - "Descargar INO" button)
2. **Use Case**: `lib/core/domain/usecases/share_file_usecase.dart`
3. **Repository Interface**: `lib/core/domain/repositories/file_sharing_repository.dart`
4. **Service Implementation**: `lib/core/data/services/file_sharing_service.dart`
5. **Module Entity**: `lib/core/domain/entities/module.dart` (contains inoFile path)

### Current Flow
```
BuildMainContent (UI)
  └─> _onDownloadAndShare()
      └─> ShareFileUseCase (get from DI)
          └─> FileSharingRepository.shareAssetFile()
              └─> FileSharingService.shareAssetFile()
                  └─> Uses share_plus package (SharePlus.instance.share)
```

### Current Implementation (FileSharingService)
- Loads asset file from bundle using `rootBundle.load(assetPath)`
- Writes file to temporary directory
- Shares using `SharePlus.instance.share()` with `ShareParams`
- Checks for `ShareResultStatus.success`

### Problem Identified
The code uses `SharePlus.instance.share()` API which is **deprecated** in share_plus 11.1.0. The correct API is:
```dart
// Old (deprecated)
SharePlus.instance.share(ShareParams(...))

// New (correct)
Share.shareXFiles([XFile(...)], text: '...', subject: '...')
```

### INO Files Available
- `assets/files/UNO_bt_gamepad/UNO_bt_gamepad.ino` - Gamepad module
- `assets/files/esp32_bt_temp/esp32_bt_temp.ino` - Temperature module
- `assets/files/esp32_bt_servo/esp32_bt_servo.ino` - Servo module
- `assets/files/esp32_bt_light/esp32_bt_light.ino` - Light control module

### Module Pages with INO Files
Each module page defines its own `MainModule` instance with `inoFile` field pointing to the asset path.

## Plan Updates
- Exploration complete ✅
- Root cause identified: Using deprecated share_plus API ✅
- Team selection: flutter-frontend-developer ✅
- Expert advice received ✅
- Final plan created ✅

## Expert Advice Summary (flutter-frontend-developer)

Full details in: `.claude/doc/ino_file_sharing/flutter-frontend.md`

### Key Findings
1. **share_plus 11.1.0 Correct API**: Use `Share.shareXFiles([XFile(...)], text: '...', subject: '...')` instead of deprecated `SharePlus.instance.share(ShareParams(...))`
2. **Architecture Violation**: Current code has `FileSharingService implements FileSharingRepository` which violates Clean Architecture
3. **Error Handling**: User dismissing share sheet is NOT an error - all ShareResult statuses return `Right(null)`
4. **MIME Type**: Explicitly set `mimeType: 'text/plain'` for maximum app compatibility
5. **No Permissions Needed**: Temp directory and share sheet don't require special permissions

### Correct Architecture
```
FileSharingService (throws exceptions)
  ↓
FileSharingRepositoryImpl (catches → Failures)
  ↓
ShareFileUseCase (passes Either through)
  ↓
UI (handles Either - show errors only)
```

## Final Implementation Plan

### Phase 1: Update Domain Layer
1. Update `lib/core/domain/repositories/file_sharing_repository.dart`
   - Add `subject` parameter to `shareAssetFile()` method
   - Return type already correct: `Future<Either<Failure, void>>`

2. Update `lib/core/domain/usecases/share_file_usecase.dart`
   - Add `subject` parameter
   - Update return type to `Future<Either<Failure, void>>`

### Phase 2: Update Error Handling
3. Update `lib/core/error/failure.dart`
   - Add `FileNotFoundFailure` class
   - Add `FileSystemFailure` class
   - Add `ShareFailure` class

### Phase 3: Fix Data Layer (CRITICAL)
4. **REWRITE** `lib/core/data/services/file_sharing_service.dart`
   - Remove `implements FileSharingRepository` (architecture violation!)
   - Change to standalone service
   - Update to use `Share.shareXFiles()` API (not SharePlus.instance)
   - Add `subject` parameter
   - Return `ShareResult` instead of void
   - Throw exceptions (repository will handle conversion to Failures)
   - Explicitly set `mimeType: 'text/plain'` for XFile

5. **CREATE** `lib/core/data/repositories/file_sharing_repository_impl.dart`
   - Implement `FileSharingRepository` interface
   - Inject `FileSharingService` via constructor
   - Catch all exceptions → convert to appropriate Failures
   - Return `Right(null)` for all ShareResult statuses (user dismissal is not error)

### Phase 4: Update Dependency Injection
6. Update `lib/di/service_locator.dart`
   - Register `FileSharingService` as singleton
   - Register `FileSharingRepositoryImpl` as singleton
   - Verify `ShareFileUseCase` registration

### Phase 5: Update UI
7. Update `lib/shared/widgets/modules/build_main_content.dart`
   - Update `_onDownloadAndShare()` to handle Either result
   - Add BuildContext parameter
   - Use `result.fold()` for error handling
   - Show error snackbar only on Left (failure)
   - Don't show success message (user might have dismissed)

### Phase 6: Testing
8. **CREATE** `test/core/data/services/file_sharing_service_test.dart`
   - Mock rootBundle, getTemporaryDirectory, Share.shareXFiles
   - Test success path
   - Test asset not found error
   - Test temp directory write failure
   - Test user dismissal (treat as success)

9. **CREATE** `test/core/data/repositories/file_sharing_repository_impl_test.dart`
   - Mock FileSharingService
   - Test all error → Failure conversions
   - Test success scenarios

10. **CREATE** `test/core/domain/usecases/share_file_usecase_test.dart`
    - Mock repository
    - Test Either pass-through

### Phase 7: Code Quality
11. Run `flutter analyze` - fix all warnings
12. Run `dart format lib/ test/` - format all code
13. Add ABOUTME comments to all new/modified files
14. Verify test coverage >80%

## Files Summary

### Files to CREATE (3)
1. `lib/core/data/repositories/file_sharing_repository_impl.dart` - Repository with error handling
2. `test/core/data/services/file_sharing_service_test.dart` - Service unit tests
3. `test/core/data/repositories/file_sharing_repository_impl_test.dart` - Repository unit tests

### Files to MODIFY (6)
1. `lib/core/error/failure.dart` - Add 3 new Failure types
2. `lib/core/data/services/file_sharing_service.dart` - **COMPLETE REWRITE**
3. `lib/core/domain/usecases/share_file_usecase.dart` - Add subject param, return Either
4. `lib/core/domain/repositories/file_sharing_repository.dart` - Add subject param
5. `lib/di/service_locator.dart` - Register service + repository
6. `lib/shared/widgets/modules/build_main_content.dart` - Handle Either in UI

## Branch Strategy

**Branch Name**: `feat/fix-ino-file-sharing`
**Base Branch**: `develop` (current)
**Target Branch**: `develop`
**Review Requirements**: 1 reviewer

### Commit Strategy
1. `feat: add failure types for file sharing errors`
2. `refactor: fix file sharing service architecture violation`
3. `feat: create file sharing repository implementation`
4. `feat: update file sharing use case with Either pattern`
5. `feat: update UI to handle file sharing errors`
6. `test: add unit tests for file sharing service`
7. `test: add unit tests for file sharing repository`
8. `docs: update ABOUTME comments in file sharing files`

## Acceptance Criteria

### Functional ✅
- [ ] User taps "Descargar INO" button
- [ ] Native share sheet appears with app options
- [ ] User can share to email, messaging, social media, file managers
- [ ] File is correctly named (e.g., `UNO_bt_gamepad.ino`)
- [ ] Works on Android 9+ and iOS 13+
- [ ] User can dismiss share sheet without errors

### Technical ✅
- [ ] Uses `Share.shareXFiles()` (not deprecated API)
- [ ] Follows Clean Architecture (service → repository → use case → UI)
- [ ] Returns `Either<Failure, void>` from repository/use case
- [ ] All exceptions converted to appropriate Failures
- [ ] MIME type explicitly set to `text/plain`
- [ ] No deprecated API warnings
- [ ] All tests pass

### Testing ✅
- [ ] Unit tests for FileSharingService (>80% coverage)
- [ ] Unit tests for FileSharingRepositoryImpl (>80% coverage)
- [ ] Unit tests for ShareFileUseCase (100% coverage)
- [ ] Manual testing on Android device
- [ ] Manual testing on iOS device
- [ ] All 4 .ino files tested (gamepad, temp, servo, light)

### Code Quality ✅
- [ ] All new files have ABOUTME comments
- [ ] Error messages are user-friendly and in Spanish
- [ ] No code duplication
- [ ] Follows Dart style guide
- [ ] `flutter analyze` passes with no warnings
- [ ] `dart format` applied to all files

## Important Implementation Notes

1. **User dismissal is NOT an error**: All ShareResult statuses return `Right(null)`
2. **Don't show success message**: User might have just dismissed the sheet
3. **MIME type matters**: Use `text/plain` for maximum app compatibility
4. **No permissions needed**: Temp directory and share sheet don't require special permissions
5. **Architecture fix is critical**: Service must NOT implement repository interface
6. **Spanish error messages**: "Error al compartir archivo: ..."
7. **All .ino files are small**: <50KB, no performance concerns
8. **Test on real devices**: Share sheet behavior varies by platform

## Estimated Time

**Total**: 4-6 hours
- Core Implementation (Phases 1-4): 2-3 hours
- UI Updates (Phase 5): 30 minutes
- Testing (Phase 6): 2-3 hours
- Code Quality (Phase 7): 30 minutes

## David's Decisions (Received)

**A) Test Coverage**: A1 - 80% coverage for new code (standard practice)
**B) Share Dismissal UX**: B1 - Show nothing (user knows they cancelled)
**C) Error Message Detail**: C2 - Specific errors (e.g., "Error al compartir archivo: Archivo no encontrado")
**D) Share Text Content**: D2 - Module-specific (e.g., "Código Arduino para Temperatura")

## Implementation Details (Based on Decisions)

### Share Text Format
```dart
text: 'Código Arduino para ${mainModule.title}',
subject: 'Archivo INO - ${mainModule.title}',
```

### Error Message Mapping
- **FileNotFoundFailure**: "Error al compartir archivo: Archivo no encontrado"
- **FileSystemFailure**: "Error al compartir archivo: No se pudo guardar el archivo"
- **ShareFailure**: "Error al compartir archivo: Error de la plataforma"
- **UnknownFailure**: "Error al compartir archivo: Error desconocido"

### User Feedback Strategy
- **Success/Dismissal**: Silent (no message shown)
- **Error**: Red snackbar with specific error message using SnackbarService
- **Loading**: No loading indicator (operations are instant with small files)

## Status

✅ Planning phase complete
✅ David's decisions received and documented
✅ Implementation plan finalized
✅ GitHub issue created: #9
✅ Feature branch created: `feat/fix-ino-file-sharing`
⏳ **Ready to start implementation**

**Note**: Per CLAUDE.md requirements, tests MUST be written unless David explicitly states: "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME."

## GitHub Information

**Issue**: [#9 Fix INO File Sharing - Replace Deprecated share_plus API](https://github.com/DavidFlores79/makerslab_app/issues/9)
**Branch**: `feat/fix-ino-file-sharing`
**Base Branch**: `develop`
**Created**: 2025-11-15

## Next Steps

Use the command: `/start-working-on-branch-new feat/fix-ino-file-sharing` to begin implementation.
