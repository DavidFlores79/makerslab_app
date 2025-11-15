## 📋 Problem Statement

The 'Descargar INO' button in IoT module pages no longer works correctly. When users tap this button to share Arduino INO files, the sharing functionality fails because the current implementation uses the deprecated `SharePlus.instance.share()` API from share_plus 11.1.0.

**Current limitations:**
- Using deprecated share_plus API that will be removed in future versions
- Architecture violation: FileSharingService implements repository interface directly
- Missing proper error handling for file sharing operations
- No tests for file sharing functionality

**Why this is important:**
- INO files are critical educational resources for students learning IoT with Arduino
- Users cannot share their module code with peers, teachers, or other platforms
- Technical debt from deprecated API usage
- Architecture violation makes code harder to maintain

## 🎯 User Value

**Primary Benefits:**
- Students can share Arduino code files via WhatsApp, email, Telegram, or any app
- Teachers can distribute module code to students easily
- Users can backup their code files to cloud storage apps
- Native platform share sheet provides familiar UX

**Concrete Example:**
> Maria is learning to program Arduino gamepad controls. She wants to share the `UNO_bt_gamepad.ino` file with her study group via WhatsApp. She taps 'Descargar INO', selects WhatsApp from the share sheet, chooses her study group chat, and the .ino file is sent. Her classmates can now open it in their Arduino IDE.

**UX Improvements:**
- One-tap sharing to any installed app
- No confusing error messages when dismissed
- Works offline (no network required)
- Files correctly named with module context

## 🔧 Technical Requirements

### Architecture Changes (Clean Architecture)

**Current (Incorrect):**
```
FileSharingService implements FileSharingRepository ❌ VIOLATION
  └─> UI calls service directly
```

**Target (Correct):**
```
Domain Layer:
  - FileSharingRepository (interface)
  - ShareFileUseCase

Data Layer:
  - FileSharingService (pure service, throws exceptions)
  - FileSharingRepositoryImpl (implements interface, converts exceptions → Failures)

Presentation Layer:
  - BuildMainContent widget (handles Either<Failure, void>)
```

### Technology Stack
- **Flutter**: 3.7.2+ with Dart 3.7.2+
- **Package Update**: share_plus 11.1.0 (use `Share.shareXFiles()` API)
- **Pattern**: Either<Failure, Success> for error handling (dartz)
- **Architecture**: Clean Architecture with Domain/Data/Presentation separation
- **DI**: get_it 8.0.3 (manual registration)

### API Changes Needed

**Domain Layer:**
- Add `subject` parameter to `FileSharingRepository.shareAssetFile()`
- Add `subject` parameter to `ShareFileUseCase`
- Return type already correct: `Future<Either<Failure, void>>`

**Data Layer:**
- Replace deprecated API:
  ```dart
  // OLD (deprecated)
  SharePlus.instance.share(ShareParams(...))

  // NEW (correct)
  Share.shareXFiles([XFile(filePath, mimeType: 'text/plain')],
    text: 'Código Arduino para ${moduleName}',
    subject: 'Archivo INO - ${moduleName}')
  ```

**Error Handling:**
- Add `FileNotFoundFailure` class
- Add `FileSystemFailure` class
- Add `ShareFailure` class
- All exceptions converted to Failures in repository layer

### Database Changes
- None (feature uses asset files and temp directory)

### Files Involved

**4 INO Files (Assets):**
- `assets/files/UNO_bt_gamepad/UNO_bt_gamepad.ino`
- `assets/files/esp32_bt_temp/esp32_bt_temp.ino`
- `assets/files/esp32_bt_servo/esp32_bt_servo.ino`
- `assets/files/esp32_bt_light/esp32_bt_light.ino`

**6 Files to MODIFY:**
1. `lib/core/error/failure.dart` - Add 3 failure types
2. `lib/core/data/services/file_sharing_service.dart` - **COMPLETE REWRITE**
3. `lib/core/domain/usecases/share_file_usecase.dart` - Add subject param
4. `lib/core/domain/repositories/file_sharing_repository.dart` - Add subject param
5. `lib/di/service_locator.dart` - Register service + repository
6. `lib/shared/widgets/modules/build_main_content.dart` - Handle Either

**3 Files to CREATE:**
1. `lib/core/data/repositories/file_sharing_repository_impl.dart`
2. `test/core/data/services/file_sharing_service_test.dart`
3. `test/core/data/repositories/file_sharing_repository_impl_test.dart`

## ✅ Definition of Done

### Implementation
- [ ] Domain layer updated (repository interface, use case)
- [ ] Error types added (FileNotFoundFailure, FileSystemFailure, ShareFailure)
- [ ] FileSharingService rewritten (remove interface, use new API)
- [ ] FileSharingRepositoryImpl created (exception → Failure conversion)
- [ ] DI registration updated (service + repository)
- [ ] UI updated to handle Either<Failure, void>
- [ ] MIME type explicitly set to `text/plain`
- [ ] Subject parameter added for better UX
- [ ] User dismissal treated as success (no error shown)

### Testing
- [ ] Unit tests for FileSharingService (>80% coverage)
- [ ] Unit tests for FileSharingRepositoryImpl (>80% coverage)
- [ ] Unit tests for ShareFileUseCase (100% coverage)
- [ ] Manual testing on Android device (all 4 .ino files)
- [ ] Manual testing on iOS device (all 4 .ino files)
- [ ] Share to WhatsApp, email, Files app tested
- [ ] User dismissal tested (no error shown)
- [ ] Asset not found error tested

### Code Quality
- [ ] All new files have ABOUTME comments
- [ ] Spanish error messages for user-facing text
- [ ] `flutter analyze` passes with no warnings
- [ ] `dart format lib/ test/` applied
- [ ] No deprecated API usage
- [ ] Follows Clean Architecture principles
- [ ] SOLID principles followed
- [ ] No code duplication

### Documentation
- [ ] Session file updated with implementation status
- [ ] Code comments explain architecture decisions
- [ ] Error handling documented in code

### CI/CD
- [ ] All tests pass locally
- [ ] Build succeeds: `flutter build apk --release`
- [ ] No linting errors

## 🧪 Manual Testing Checklist

### Basic Flow (Happy Path)
**Temperature Module:**
- [ ] Open Temperature module page
- [ ] Tap 'Descargar INO' button
- [ ] Native share sheet appears
- [ ] Select WhatsApp
- [ ] File `esp32_bt_temp.ino` appears in chat input
- [ ] Send to contact
- [ ] Contact receives file successfully
- [ ] Repeat for email, Telegram, Google Drive

**All Modules:**
- [ ] Gamepad: Share `UNO_bt_gamepad.ino`
- [ ] Servo: Share `esp32_bt_servo.ino`
- [ ] Light Control: Share `esp32_bt_light.ino`

### Edge Cases
**User Dismissal:**
- [ ] Tap 'Descargar INO'
- [ ] Share sheet appears
- [ ] Tap outside sheet or press back
- [ ] No error message shown ✅
- [ ] No crash occurs ✅

**Network Offline:**
- [ ] Turn off WiFi and mobile data
- [ ] Tap 'Descargar INO'
- [ ] Share sheet still appears (no network needed)
- [ ] Can share to local apps (Files, Notes)

**Low Storage:**
- [ ] Device with <10MB free space
- [ ] Tap 'Descargar INO'
- [ ] Should work (files are <50KB)

### Error Handling
**Asset Not Found (Simulated):**
- [ ] Modify code to use non-existent asset path
- [ ] Tap button
- [ ] Spanish error shown: 'Error al compartir archivo: Archivo no encontrado'
- [ ] Error logged for debugging

**Permissions:**
- [ ] No special permissions required
- [ ] Share sheet uses system permissions
- [ ] Works without granting additional permissions

### Integration Testing
**With Existing Features:**
- [ ] Bluetooth connection still works during sharing
- [ ] Can share file while connected to Arduino
- [ ] Can share file while disconnected
- [ ] Other module buttons (temperature control, servo slider) unaffected

**Cross-Platform:**
- [ ] Android 9+ devices (Pixel, Samsung, Xiaomi)
- [ ] iOS 13+ devices (iPhone 8+, iPad)
- [ ] Share to email clients (Gmail, Outlook)
- [ ] Share to messaging apps (WhatsApp, Telegram, Signal)
- [ ] Share to cloud storage (Google Drive, Dropbox)
- [ ] Share to file managers (Files app, Mi Explorer)

**Performance:**
- [ ] Share action completes in <1 second
- [ ] No UI freezing during file copy
- [ ] No memory leaks (test multiple shares)

## 🏗️ Implementation Strategy

### Branch Information
- **Branch Name**: `feat/fix-ino-file-sharing`
- **Base Branch**: `develop`
- **Target Branch**: `develop`
- **Estimated Effort**: M (Medium - 4-6 hours)

### Commit Strategy
1. `feat: add failure types for file sharing errors`
2. `refactor: fix file sharing service architecture violation`
3. `feat: create file sharing repository implementation`
4. `feat: update file sharing use case with Either pattern`
5. `feat: update UI to handle file sharing errors`
6. `test: add unit tests for file sharing service`
7. `test: add unit tests for file sharing repository`
8. `docs: update ABOUTME comments in file sharing files`

### Dependencies
- None (all changes within file sharing feature)
- No blocking issues

### Review Requirements
- 1 reviewer approval required
- All CI/CD checks must pass
- Manual testing on at least 1 Android device
- All test coverage >80%

## 📚 Related Documentation

### Architectural Decisions
- **Clean Architecture**: Domain → Data → Presentation separation
- **Error Handling**: Either<Failure, Success> pattern from dartz
- **DI Pattern**: Manual get_it registration in `di/service_locator.dart`
- **share_plus Migration**: Official migration guide for 10.x → 11.x

### Existing Patterns to Follow
- **Error Handling**: See `BluetoothRepositoryImpl` for exception → Failure conversion
- **Use Case Pattern**: See `ConnectDeviceUseCase` for single responsibility pattern
- **UI Error Display**: See `SnackbarService` for consistent error messaging

### Design Specifications
- **Share Text**: 'Código Arduino para {moduleTitle}'
- **Subject Line**: 'Archivo INO - {moduleTitle}'
- **Error Messages**: Spanish, specific (e.g., 'Error al compartir archivo: Archivo no encontrado')
- **UX Decision**: Silent on dismissal (no success/cancel message)

### Reference Documentation
- Session File: `.claude/sessions/context_session_ino_file_sharing.md`
- Expert Advice: `.claude/doc/ino_file_sharing/flutter-frontend.md`
- CLAUDE.md: Project-wide architecture and testing requirements

## ⚠️ Important Implementation Notes

1. **User dismissal is NOT an error**: All `ShareResult` statuses return `Right(null)`
2. **Don't show success message**: User might have just dismissed the sheet
3. **MIME type matters**: Use `text/plain` for maximum app compatibility
4. **No permissions needed**: Temp directory and share sheet don't require special permissions
5. **Architecture fix is critical**: Service must NOT implement repository interface
6. **Spanish error messages**: "Error al compartir archivo: ..."
7. **All .ino files are small**: <50KB, no performance concerns
8. **Test on real devices**: Share sheet behavior varies by platform

## 🎯 Success Metrics

**User-Facing:**
- Zero errors when sharing INO files
- Share sheet appears in <1 second
- Files correctly named and formatted
- Works on 100% of tested devices/platforms

**Technical:**
- No deprecated API warnings
- Test coverage >80%
- Zero architecture violations
- Clean flutter analyze output

---

**Labels**: `type: feature`, `priority: high`, `area: file-sharing`, `platform: android`, `platform: ios`
**Assignee**: @davidrealdev
**Milestone**: v1.1.0
