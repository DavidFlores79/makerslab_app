# Flutter Frontend Implementation Plan: INO File Sharing Fix

## Feature Overview
Fix the broken "Descargar INO" (Download INO) functionality that allows users to share Arduino .ino files from the app to external apps (email, social media, messaging, etc.) on Android and iOS devices.

**Root Cause**: Using deprecated `SharePlus.instance.share()` API from share_plus package. Need to migrate to the current `Share.shareXFiles()` API.

---

## 1. share_plus 11.1.0 API Best Practices

### Correct API Usage

**DEPRECATED (Current Implementation)**:
```dart
final result = await SharePlus.instance.share(
  ShareParams(files: [XFile(file.path)], text: text, title: text),
);
```

**CORRECT (New Implementation)**:
```dart
final result = await Share.shareXFiles(
  [XFile(file.path)],
  text: text,
  subject: subject,  // Use subject instead of title
);
```

### Key Differences in share_plus 11.1.0

1. **Static Method vs Instance**: Use `Share.shareXFiles()` directly (static method), not `SharePlus.instance.share()`
2. **No ShareParams**: Pass arguments directly to `shareXFiles()`
3. **title → subject**: The `title` parameter is now `subject` (appears in email subject line on compatible apps)
4. **Return Type**: Returns `ShareResult` with status and action information

### Platform-Specific Behavior

**Android**:
- `ShareResult.status` will be `ShareResultStatus.unavailable` on Android < 10 (API 29)
- On Android 10+, returns `dismissed` if user cancels, `success` if shared
- MIME type is auto-detected from file extension (.ino → text/plain)

**iOS**:
- Always returns proper `ShareResultStatus` (success/dismissed)
- Subject appears in compatible apps (Mail, Messages)
- Share sheet shows all compatible apps for text files

### Common Pitfalls to Avoid

1. **Don't use ShareParams** - This is from the old API
2. **Don't rely on ShareResult on Android < 10** - Always treat as success if no exception thrown
3. **File must exist** - XFile path must point to an actual file on disk (not an asset path directly)
4. **Temporary files need cleanup** - Files in temp directory should be managed, though OS will eventually clean them

---

## 2. Error Handling Strategy

### Exception Types to Handle

#### A. Asset Loading Errors (rootBundle.load)
```dart
try {
  final byteData = await rootBundle.load(assetPath);
} on FlutterError catch (e, stackTrace) {
  // Asset not found or not in pubspec.yaml
  return Left(FileNotFoundFailure('Asset not found: $assetPath', stackTrace));
}
```

**When it occurs**: Asset path is incorrect, asset not declared in pubspec.yaml, or asset deleted

#### B. File System Errors (writeAsBytes, getTemporaryDirectory)
```dart
try {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(byteData.buffer.asUint8List());
} on FileSystemException catch (e, stackTrace) {
  // No storage permission, disk full, path too long
  return Left(FileSystemFailure('Failed to write file: ${e.message}', stackTrace));
} on PathAccessException catch (e, stackTrace) {
  // Permission denied
  return Left(PermissionFailure('Storage access denied: ${e.message}', stackTrace));
}
```

**When it occurs**:
- Disk space full
- Permissions denied (rare on temp directory)
- Invalid file name characters

#### C. Share Operation Errors (Share.shareXFiles)
```dart
try {
  final result = await Share.shareXFiles([XFile(file.path)], text: text, subject: subject);
} on PlatformException catch (e, stackTrace) {
  // Platform-specific error (extremely rare)
  return Left(ShareFailure('Failed to share file: ${e.message}', stackTrace));
}
```

**When it occurs**: Platform-level issues (very rare in share_plus)

### User Cancellation Handling

**Important**: User dismissing the share sheet is **NOT an error** - it's a valid user action.

```dart
if (result.status == ShareResultStatus.dismissed) {
  // User cancelled - treat as success, just don't show "shared successfully"
  return const Right(null);
}

if (result.status == ShareResultStatus.success) {
  // Actually shared to an app
  return const Right(null);
}

if (result.status == ShareResultStatus.unavailable) {
  // Android < 10 - can't determine result, assume success
  return const Right(null);
}
```

### Either Pattern Implementation

The repository should return `Either<Failure, void>` since there's no meaningful data to return on success.

```dart
// Repository method signature
Future<Either<Failure, void>> shareAssetFile({
  required String assetPath,
  required String fileName,
  String? text,
  String? subject,
});
```

---

## 3. Recommended Error Handling Pattern

### Complete Implementation Example

```dart
@override
Future<Either<Failure, void>> shareAssetFile({
  required String assetPath,
  required String fileName,
  String? text,
  String? subject,
}) async {
  try {
    // Step 1: Load asset file
    final ByteData byteData;
    try {
      byteData = await rootBundle.load(assetPath);
    } on FlutterError catch (e, stackTrace) {
      return Left(FileNotFoundFailure(
        'Asset file not found: $assetPath',
        stackTrace,
      ));
    }

    // Step 2: Get temporary directory and write file
    final Directory tempDir;
    try {
      tempDir = await getTemporaryDirectory();
    } catch (e, stackTrace) {
      return Left(FileSystemFailure(
        'Failed to access temporary directory: ${e.toString()}',
        stackTrace as StackTrace?,
      ));
    }

    // Step 3: Write file to temp directory
    final file = File('${tempDir.path}/$fileName');
    try {
      await file.writeAsBytes(byteData.buffer.asUint8List());
    } on FileSystemException catch (e, stackTrace) {
      return Left(FileSystemFailure(
        'Failed to write temporary file: ${e.message}',
        stackTrace,
      ));
    }

    // Step 4: Share the file
    final ShareResult result;
    try {
      result = await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: subject,
      );
    } on PlatformException catch (e, stackTrace) {
      return Left(ShareFailure(
        'Failed to share file: ${e.message}',
        stackTrace,
      ));
    } catch (e, stackTrace) {
      return Left(UnknownFailure(
        'Unexpected error while sharing: ${e.toString()}',
        stackTrace as StackTrace?,
      ));
    }

    // Step 5: Handle result (all statuses are treated as success)
    // User cancelling is not an error, just a valid user action
    debugPrint('Share result: ${result.status}');
    return const Right(null);

  } catch (e, stackTrace) {
    // Catch-all for unexpected errors
    return Left(UnknownFailure(
      'Unexpected error in shareAssetFile: ${e.toString()}',
      stackTrace as StackTrace?,
    ));
  }
}
```

### New Failure Types Needed

Add these to `lib/core/error/failure.dart`:

```dart
class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure(super.message, [super.stackTrace]);
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message, [super.stackTrace]);
}

class ShareFailure extends Failure {
  const ShareFailure(super.message, [super.stackTrace]);
}
```

**Note**: `PermissionFailure` and `UnknownFailure` already exist in the codebase.

---

## 4. Testing Strategy for File Sharing

### A. Unit Tests for Repository Implementation

**Location**: `test/core/data/services/file_sharing_service_test.dart`

**Required Mocks**:
1. Mock `rootBundle` using `TestAssetBundle`
2. Mock `getTemporaryDirectory()` using `MethodChannel`
3. Mock `Share.shareXFiles()` using `MethodChannel`

**Test Setup Example**:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FileSharingService service;
  late MockPathProviderPlatform mockPathProvider;

  setUp(() {
    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;
    service = FileSharingService();
  });

  // Tests go here...
}
```

### B. Test Cases to Implement

#### 1. Success Path Tests
```dart
test('should successfully share asset file when all operations succeed', () async {
  // Arrange
  const assetPath = 'assets/files/test.ino';
  const fileName = 'test.ino';
  final mockAssetBundle = _createMockAssetBundle('// Arduino code');

  when(mockPathProvider.getTemporaryPath())
      .thenAnswer((_) async => '/tmp');

  // Mock share_plus MethodChannel
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/share'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'shareFiles') {
        return 'success';  // ShareResultStatus.success
      }
      return null;
    },
  );

  // Act
  final result = await service.shareAssetFile(
    assetPath: assetPath,
    fileName: fileName,
  );

  // Assert
  expect(result.isRight(), true);
});
```

#### 2. Error Path Tests
```dart
test('should return FileNotFoundFailure when asset does not exist', () async {
  // Arrange
  const assetPath = 'assets/files/nonexistent.ino';
  const fileName = 'nonexistent.ino';

  // Act
  final result = await service.shareAssetFile(
    assetPath: assetPath,
    fileName: fileName,
  );

  // Assert
  expect(result.isLeft(), true);
  result.fold(
    (failure) => expect(failure, isA<FileNotFoundFailure>()),
    (_) => fail('Should have returned failure'),
  );
});

test('should return FileSystemFailure when temp directory is inaccessible', () async {
  // Arrange
  const assetPath = 'assets/files/test.ino';
  const fileName = 'test.ino';
  final mockAssetBundle = _createMockAssetBundle('// Arduino code');

  when(mockPathProvider.getTemporaryPath())
      .thenThrow(FileSystemException('Access denied'));

  // Act
  final result = await service.shareAssetFile(
    assetPath: assetPath,
    fileName: fileName,
  );

  // Assert
  expect(result.isLeft(), true);
  result.fold(
    (failure) => expect(failure, isA<FileSystemFailure>()),
    (_) => fail('Should have returned failure'),
  );
});

test('should treat user dismissal as success (not an error)', () async {
  // Arrange
  const assetPath = 'assets/files/test.ino';
  const fileName = 'test.ino';
  final mockAssetBundle = _createMockAssetBundle('// Arduino code');

  when(mockPathProvider.getTemporaryPath())
      .thenAnswer((_) async => '/tmp');

  // Mock share_plus returning dismissed status
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/share'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'shareFiles') {
        return 'dismissed';  // ShareResultStatus.dismissed
      }
      return null;
    },
  );

  // Act
  final result = await service.shareAssetFile(
    assetPath: assetPath,
    fileName: fileName,
  );

  // Assert
  expect(result.isRight(), true);
});
```

#### 3. Edge Cases
```dart
test('should handle file names with special characters', () async {
  // Test with fileName containing spaces, dashes, underscores
  const fileName = 'UNO_bt_gamepad (v2).ino';
  // Implementation...
});

test('should handle large asset files (>1MB)', () async {
  // Test with large file to ensure buffer handling works
  final largeContent = '// Comment\n' * 100000;  // ~1.2MB
  // Implementation...
});

test('should handle empty asset files', () async {
  // Test with 0-byte file
  final mockAssetBundle = _createMockAssetBundle('');
  // Implementation...
});
```

### C. Integration Test (Optional but Recommended)

**Location**: `integration_test/file_sharing_test.dart`

```dart
void main() {
  testWidgets('should open share sheet when tapping Descargar INO button', (tester) async {
    // This requires a real device/emulator
    // Launch app
    app.main();
    await tester.pumpAndSettle();

    // Navigate to Temperature module (or any module with INO file)
    await tester.tap(find.text('Temperatura'));
    await tester.pumpAndSettle();

    // Tap "Descargar INO" button
    await tester.tap(find.text('Descargar INO'));
    await tester.pumpAndSettle();

    // Verify share sheet appeared (platform-specific)
    // On Android: Look for system share dialog
    // On iOS: Look for UIActivityViewController
    // Note: Hard to verify programmatically, mainly for manual testing
  });
}
```

### D. Helper Functions for Tests

```dart
TestAssetBundle _createMockAssetBundle(String content) {
  return TestAssetBundle({
    'assets/files/test.ino': ByteData.view(
      Uint8List.fromList(utf8.encode(content)).buffer,
    ),
  });
}

class TestAssetBundle extends CachingAssetBundle {
  final Map<String, ByteData> _assets;

  TestAssetBundle(this._assets);

  @override
  Future<ByteData> load(String key) async {
    if (_assets.containsKey(key)) {
      return _assets[key]!;
    }
    throw FlutterError('Asset not found: $key');
  }
}
```

---

## 5. Clean Architecture Compliance

### Current Architecture Issues

**Problem 1**: Service directly implements Repository interface
```dart
// Current (INCORRECT)
class FileSharingService implements FileSharingRepository {
  // Service should not implement repository interface directly
}
```

**Problem 2**: No separation between repository and service layers

### Recommended Architecture Fix

Create proper layer separation following Clean Architecture:

```
Domain Layer (lib/core/domain/)
  └─ repositories/
     └─ file_sharing_repository.dart  [Interface]

Data Layer (lib/core/data/)
  ├─ repositories/
  │  └─ file_sharing_repository_impl.dart  [Repository Implementation]
  └─ services/
     └─ file_sharing_service.dart  [Platform Service]
```

### Correct Implementation Structure

#### A. Domain Layer - Repository Interface
**File**: `lib/core/domain/repositories/file_sharing_repository.dart`
```dart
// ABOUTME: Repository interface for file sharing operations following Clean Architecture
// ABOUTME: Returns Either<Failure, T> for functional error handling

import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/error/failure.dart';

abstract class FileSharingRepository {
  /// Shares an asset file (e.g., .ino Arduino file) via platform share sheet
  ///
  /// [assetPath]: Path to asset file (e.g., 'assets/files/UNO_bt_gamepad/UNO_bt_gamepad.ino')
  /// [fileName]: Name for the shared file (e.g., 'UNO_bt_gamepad.ino')
  /// [text]: Optional text message to share alongside file
  /// [subject]: Optional subject line (appears in email apps)
  ///
  /// Returns [Right(null)] on success (including user dismissal)
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> shareAssetFile({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
  });
}
```

#### B. Data Layer - Service (Platform Abstraction)
**File**: `lib/core/data/services/file_sharing_service.dart`
```dart
// ABOUTME: Platform service for file sharing operations using share_plus package
// ABOUTME: Handles low-level file operations and platform share sheet invocation

import 'dart:io';
import 'package:flutter/services.dart' show rootBundle, ByteData, FlutterError, PlatformException;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart' show debugPrint;

class FileSharingService {
  /// Shares a file from app assets via platform share sheet
  ///
  /// Steps:
  /// 1. Load asset file from bundle
  /// 2. Write to temporary directory (required for sharing)
  /// 3. Share via Share.shareXFiles()
  ///
  /// Throws [FlutterError] if asset not found
  /// Throws [FileSystemException] if file write fails
  /// Throws [PlatformException] if share operation fails (rare)
  Future<ShareResult> shareAssetFile({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    // Load asset from bundle
    final byteData = await rootBundle.load(assetPath);

    // Write to temporary directory
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    // Share using share_plus
    final result = await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
      subject: subject,
    );

    debugPrint('File sharing result: ${result.status}');
    return result;
  }
}
```

#### C. Data Layer - Repository Implementation
**File**: `lib/core/data/repositories/file_sharing_repository_impl.dart`
```dart
// ABOUTME: Implementation of FileSharingRepository using FileSharingService
// ABOUTME: Handles error conversion from exceptions to Failure types

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart' show FlutterError, PlatformException;
import 'package:makerslab_app/core/domain/repositories/file_sharing_repository.dart';
import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/core/data/services/file_sharing_service.dart';

class FileSharingRepositoryImpl implements FileSharingRepository {
  final FileSharingService _service;

  FileSharingRepositoryImpl({required FileSharingService service})
      : _service = service;

  @override
  Future<Either<Failure, void>> shareAssetFile({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    try {
      await _service.shareAssetFile(
        assetPath: assetPath,
        fileName: fileName,
        text: text,
        subject: subject,
      );

      // All share results (success, dismissed, unavailable) are treated as success
      // User dismissing the share sheet is a valid action, not an error
      return const Right(null);

    } on FlutterError catch (e, stackTrace) {
      // Asset not found or not in pubspec.yaml
      return Left(FileNotFoundFailure(
        'Asset file not found: $assetPath - ${e.message}',
        stackTrace,
      ));

    } on FileSystemException catch (e, stackTrace) {
      // Failed to write to temp directory
      return Left(FileSystemFailure(
        'Failed to save file for sharing: ${e.message}',
        stackTrace,
      ));

    } on PathAccessException catch (e, stackTrace) {
      // Permission denied (rare for temp directory)
      return Left(PermissionFailure(
        'Storage access denied: ${e.message}',
        stackTrace,
      ));

    } on PlatformException catch (e, stackTrace) {
      // Platform-level share error (extremely rare)
      return Left(ShareFailure(
        'Platform error while sharing: ${e.message}',
        stackTrace,
      ));

    } catch (e, stackTrace) {
      // Unexpected error
      return Left(UnknownFailure(
        'Unexpected error while sharing file: ${e.toString()}',
        stackTrace as StackTrace?,
      ));
    }
  }
}
```

### Dependency Injection Updates

**File**: `lib/di/service_locator.dart`

Add registrations:
```dart
// Service (singleton)
getIt.registerLazySingleton<FileSharingService>(() => FileSharingService());

// Repository (singleton)
getIt.registerLazySingleton<FileSharingRepository>(
  () => FileSharingRepositoryImpl(service: getIt()),
);

// Use case (singleton)
getIt.registerLazySingleton(() => ShareFileUseCase(getIt()));
```

### Use Case Layer (Already Exists)

**File**: `lib/core/domain/usecases/share_file_usecase.dart`

Update to use Either pattern:
```dart
// ABOUTME: Use case for sharing asset files via platform share sheet
// ABOUTME: Orchestrates file sharing operation through repository layer

import 'package:dartz/dartz.dart';
import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/core/domain/repositories/file_sharing_repository.dart';

class ShareFileUseCase {
  final FileSharingRepository _repository;

  ShareFileUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String assetPath,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    return await _repository.shareAssetFile(
      assetPath: assetPath,
      fileName: fileName,
      text: text,
      subject: subject,
    );
  }
}
```

### Why This Architecture is Correct

1. **Domain Layer Independence**: Repository interface has no Flutter/platform dependencies
2. **Single Responsibility**:
   - Service = Platform interaction (rootBundle, Share.shareXFiles)
   - Repository = Error handling and domain logic
   - Use Case = Application-specific orchestration
3. **Testability**: Each layer can be tested independently with mocks
4. **Dependency Inversion**: Domain defines interface, data layer implements it

---

## 6. Mobile Platform Considerations

### Android Permissions

**No special permissions required** for file sharing in this implementation:
- ✅ Temporary directory access is always granted (app-private storage)
- ✅ Share sheet is a system-provided UI, no permissions needed
- ✅ .ino files are text files, no restricted content

**Note**: If implementation changes to save to Downloads folder, would need:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
```
But this is **NOT needed** for current implementation.

### Android-Specific Considerations

1. **MIME Type Handling**:
   - .ino files → auto-detected as `text/plain`
   - Can explicitly set: `XFile(file.path, mimeType: 'text/plain')`
   - Not necessary but can be added for clarity

2. **Share Sheet Behavior**:
   - On Android 10+ (API 29): User can see which app they shared to
   - On Android < 10: Share result is always "unavailable"
   - Bottom sheet shows all apps that accept text files (WhatsApp, Gmail, Drive, etc.)

3. **File Size Limits**:
   - No enforced limit in share_plus
   - Some receiving apps may have limits (e.g., email attachments)
   - Current .ino files are small (<50KB), no issues expected

4. **compileSdk 35 Compatibility**:
   - share_plus 11.1.0 supports Android SDK 35 ✅
   - No additional configuration needed

### iOS-Specific Considerations

1. **UIActivityViewController**:
   - share_plus uses UIActivityViewController under the hood
   - Shows all apps that can handle text/plain files
   - Subject appears in Mail and Messages apps
   - User can also AirDrop, save to Files, etc.

2. **Permissions**:
   - No special permissions needed ✅
   - Photo library permission only needed if sharing images (not our case)

3. **Temporary Directory**:
   - iOS automatically cleans temp directory when space is low
   - Files persist until app is terminated or OS cleans them
   - No manual cleanup needed

4. **Share Sheet Appearance**:
   - Native iOS share sheet (white modal from bottom)
   - Shows app icons in color
   - Text appears as preview if provided

### File MIME Type Handling for .ino Files

**Current Behavior**:
- `XFile` auto-detects MIME type from file extension
- `.ino` → defaults to `text/plain` or `application/octet-stream`

**Recommended**: Explicitly set MIME type for clarity
```dart
final xFile = XFile(
  file.path,
  mimeType: 'text/plain',  // Explicit MIME type
);
```

**Why text/plain?**
- .ino files are plain text Arduino source code
- Compatible with text editors, email, messaging apps
- If set to `application/octet-stream`, some apps won't recognize it

**Alternative (More Specific)**:
```dart
final xFile = XFile(
  file.path,
  mimeType: 'text/x-arduino',  // Arduino-specific MIME type
);
```
**Warning**: `text/x-arduino` is not widely recognized. Stick with `text/plain` for maximum compatibility.

### Platform-Specific Testing

**Android Testing**:
1. Test on Android 9 (API 28) - ShareResult unavailable
2. Test on Android 10+ (API 29+) - ShareResult available
3. Verify share sheet shows expected apps (Gmail, WhatsApp, Drive)
4. Test with large files (simulated 1MB+ .ino file)

**iOS Testing**:
1. Test on iOS 13+ (minimum supported by share_plus)
2. Verify subject appears in Mail app
3. Test AirDrop functionality
4. Test "Save to Files" option

---

## 7. Files to Create/Modify

### Files to CREATE

1. **lib/core/data/repositories/file_sharing_repository_impl.dart**
   - New file: Repository implementation with error handling
   - Implements `FileSharingRepository` interface
   - Uses `FileSharingService` for platform operations
   - Converts exceptions to `Either<Failure, void>`

2. **test/core/data/repositories/file_sharing_repository_impl_test.dart**
   - New file: Unit tests for repository implementation
   - Mock `FileSharingService`
   - Test all error paths and success scenarios

3. **test/core/data/services/file_sharing_service_test.dart**
   - New file: Unit tests for platform service
   - Mock `rootBundle`, `getTemporaryDirectory`, `Share.shareXFiles`
   - Test file operations and share invocation

### Files to MODIFY

1. **lib/core/error/failure.dart**
   - Add new Failure types:
     ```dart
     class FileNotFoundFailure extends Failure {
       const FileNotFoundFailure(super.message, [super.stackTrace]);
     }

     class FileSystemFailure extends Failure {
       const FileSystemFailure(super.message, [super.stackTrace]);
     }

     class ShareFailure extends Failure {
       const ShareFailure(super.message, [super.stackTrace]);
     }
     ```

2. **lib/core/data/services/file_sharing_service.dart**
   - **REPLACE entire implementation** (service should NOT implement repository interface)
   - Change from implementing `FileSharingRepository` to standalone service
   - Update `shareAssetFile()` to:
     - Return `ShareResult` instead of `void`
     - Remove `Either` pattern (just throw exceptions, repository will handle)
     - Use `Share.shareXFiles()` instead of `SharePlus.instance.share()`
     - Add `subject` parameter support

3. **lib/core/domain/usecases/share_file_usecase.dart**
   - Update return type: `Future<Either<Failure, void>>`
   - Add `subject` parameter
   - Update implementation to handle Either result

4. **lib/core/domain/repositories/file_sharing_repository.dart**
   - Already exists and is correct
   - Just add `subject` parameter:
     ```dart
     Future<Either<Failure, void>> shareAssetFile({
       required String assetPath,
       required String fileName,
       String? text,
       String? subject,  // ADD THIS
     });
     ```

5. **lib/di/service_locator.dart**
   - Add `FileSharingService` registration:
     ```dart
     getIt.registerLazySingleton<FileSharingService>(() => FileSharingService());
     ```
   - Add `FileSharingRepositoryImpl` registration:
     ```dart
     getIt.registerLazySingleton<FileSharingRepository>(
       () => FileSharingRepositoryImpl(service: getIt()),
     );
     ```
   - `ShareFileUseCase` registration should already exist

6. **lib/shared/widgets/modules/build_main_content.dart**
   - Update `_onDownloadAndShare()` to handle Either result:
     ```dart
     Future<void> _onDownloadAndShare(BuildContext context) async {
       final useCase = getIt<ShareFileUseCase>();

       final result = await useCase(
         assetPath: module.inoFile!,
         fileName: module.inoFile!.split('/').last,
         text: 'Código Arduino para ${module.title}',
         subject: 'Archivo INO - ${module.title}',
       );

       result.fold(
         (failure) {
           // Show error snackbar
           getIt<SnackbarService>().showError(
             context: context,
             message: 'Error al compartir archivo: ${failure.message}',
           );
         },
         (_) {
           // Success - optionally show success message
           // Note: Don't show "shared successfully" since user might have dismissed
           debugPrint('File share completed');
         },
       );
     }
     ```

### Files to DELETE

**None** - All existing files should be kept, just modified.

---

## 8. Implementation Checklist

### Phase 1: Update Domain Layer
- [ ] Update `lib/core/domain/repositories/file_sharing_repository.dart` - add `subject` parameter
- [ ] Update `lib/core/domain/usecases/share_file_usecase.dart` - return Either, add subject parameter

### Phase 2: Update Error Handling
- [ ] Add new Failure types to `lib/core/error/failure.dart` (FileNotFoundFailure, FileSystemFailure, ShareFailure)

### Phase 3: Fix Data Layer
- [ ] Rewrite `lib/core/data/services/file_sharing_service.dart` to NOT implement repository interface
- [ ] Update service to use `Share.shareXFiles()` API (remove SharePlus.instance)
- [ ] Create `lib/core/data/repositories/file_sharing_repository_impl.dart` with proper error handling

### Phase 4: Update Dependency Injection
- [ ] Register `FileSharingService` in `lib/di/service_locator.dart`
- [ ] Register `FileSharingRepositoryImpl` in service locator
- [ ] Verify `ShareFileUseCase` registration

### Phase 5: Update UI
- [ ] Update `lib/shared/widgets/modules/build_main_content.dart` to handle Either result
- [ ] Add error handling UI (snackbar on failure)
- [ ] Test on device (Android/iOS)

### Phase 6: Testing
- [ ] Write unit tests for `FileSharingRepositoryImpl`
- [ ] Write unit tests for `FileSharingService`
- [ ] Write unit tests for `ShareFileUseCase`
- [ ] Manual testing on Android device
- [ ] Manual testing on iOS device (if available)
- [ ] Test all 4 INO files (gamepad, temperature, servo, light_control)

### Phase 7: Code Quality
- [ ] Run `flutter analyze` - ensure no errors
- [ ] Run `dart format lib/ test/` - format all code
- [ ] Add ABOUTME comments to all new files
- [ ] Verify test coverage >80% for new code
- [ ] Review all error messages for user-friendliness

---

## 9. Important Implementation Notes

### Critical Notes for Implementation

1. **Don't Make Service Implement Repository**:
   - Current code has `FileSharingService implements FileSharingRepository` - this violates Clean Architecture
   - Service should be a standalone class with no knowledge of repository interfaces
   - Repository implementation should wrap the service

2. **share_plus API Changes**:
   - `SharePlus.instance.share(ShareParams(...))` → `Share.shareXFiles([...], text: ..., subject: ...)`
   - No more `ShareParams` class
   - `title` parameter renamed to `subject`
   - Import: `import 'package:share_plus/share_plus.dart';` (same package, different API)

3. **Error Handling Philosophy**:
   - Service throws exceptions (platform errors)
   - Repository catches exceptions → converts to Failures
   - Use case passes through Either from repository
   - UI handles Either (show errors, hide success)

4. **User Dismissal is NOT an Error**:
   - All `ShareResultStatus` values (success, dismissed, unavailable) should return `Right(null)`
   - Don't show "shared successfully" message (user might have dismissed)
   - Only show error messages for actual failures

5. **MIME Type for .ino Files**:
   - Explicitly set `mimeType: 'text/plain'` in XFile
   - Ensures maximum app compatibility (Gmail, WhatsApp, Drive, etc.)

6. **No Permissions Needed**:
   - Temporary directory is app-private, no permissions required
   - Share sheet is system-provided, no permissions required
   - Don't add storage permissions unless explicitly moving to Downloads folder

7. **Testing with Real Devices**:
   - share_plus cannot be fully tested in simulators (share sheet is platform-specific)
   - Must test on physical Android device (preferably Android 10+)
   - Must test on physical iOS device (or iOS simulator for basic functionality)

8. **File Cleanup**:
   - No manual cleanup needed for temp directory files
   - OS will clean temp directory when needed
   - Files persist until app terminates or OS reclaims space

9. **Existing Assets**:
   - All .ino files already exist in `assets/files/`
   - Already declared in `pubspec.yaml` under `assets:`
   - Paths are correct in `Module` entities
   - No asset changes needed

10. **Spanish Localization**:
    - Error messages should be in Spanish (primary language)
    - Example: `'Error al compartir archivo: ...'`
    - Success messages: Use AppLocalizations if needed

---

## 10. Edge Cases to Handle

### Edge Cases and Solutions

1. **Asset File Not Declared in pubspec.yaml**:
   - Error: `FlutterError: Unable to load asset`
   - Solution: Return `FileNotFoundFailure` with helpful message
   - Prevention: All .ino files already in pubspec.yaml

2. **Disk Space Full (Temp Directory)**:
   - Error: `FileSystemException: No space left on device`
   - Solution: Return `FileSystemFailure` with message about disk space
   - Mitigation: .ino files are small (<50KB), unlikely to fail

3. **File Name with Special Characters**:
   - Current files use underscores and letters (safe)
   - Test with: `UNO_bt_gamepad.ino` (already exists)
   - No sanitization needed

4. **Share Sheet Dismissed Immediately**:
   - Android < 10: `ShareResultStatus.unavailable` (can't detect dismissal)
   - Android 10+: `ShareResultStatus.dismissed`
   - iOS: `ShareResultStatus.dismissed`
   - Solution: Treat all as success, don't show confirmation

5. **App in Background During Share**:
   - Share sheet is modal, keeps app in foreground
   - No special handling needed

6. **Rapid Repeated Taps on "Descargar INO"**:
   - Multiple share sheets could open
   - Solution: Disable button while share is in progress (optional enhancement)
   - Current behavior: Multiple sheets is harmless but annoying

7. **Large .ino File (Hypothetical)**:
   - Current files are small, but if adding >10MB file:
   - Loading asset into memory could cause lag
   - Solution: Use streaming if file >5MB (not needed for current files)

8. **Platform Exception from share_plus**:
   - Extremely rare (library is stable)
   - Solution: Catch `PlatformException` → return `ShareFailure`
   - Log stack trace for debugging

---

## 11. Success Criteria

### Definition of Done

The feature is complete when:

1. **Functional Requirements**:
   - [ ] User can tap "Descargar INO" button on any module page
   - [ ] Share sheet appears with all compatible apps (email, messaging, social, file managers)
   - [ ] .ino file is successfully shared to selected app
   - [ ] User can dismiss share sheet without errors
   - [ ] Works on Android 9+ and iOS 13+

2. **Technical Requirements**:
   - [ ] Uses `Share.shareXFiles()` API (not deprecated SharePlus.instance)
   - [ ] Follows Clean Architecture (service → repository → use case → UI)
   - [ ] Returns `Either<Failure, void>` from all layers
   - [ ] All exceptions converted to appropriate Failure types
   - [ ] MIME type explicitly set to `text/plain`
   - [ ] No analysis warnings from `flutter analyze`
   - [ ] Code formatted with `dart format`

3. **Testing Requirements**:
   - [ ] Unit tests for `FileSharingRepositoryImpl` (>80% coverage)
   - [ ] Unit tests for `FileSharingService` (>80% coverage)
   - [ ] Unit tests for `ShareFileUseCase` (100% coverage)
   - [ ] Manual testing on Android device (API 29+)
   - [ ] Manual testing on iOS device or simulator
   - [ ] All 4 .ino files tested (gamepad, temp, servo, light)

4. **Code Quality Requirements**:
   - [ ] All new files have ABOUTME comments
   - [ ] Error messages are user-friendly and in Spanish
   - [ ] No code duplication
   - [ ] Follows Dart style guide
   - [ ] No TODOs or FIXMEs in code

5. **Documentation Requirements**:
   - [ ] This implementation plan reviewed and approved
   - [ ] Session context file updated with results
   - [ ] Any deviations from plan documented with rationale

---

## 12. Post-Implementation Verification

### Manual Testing Script

1. **Open App**:
   ```
   flutter run -d <device-id>
   ```

2. **Navigate to Temperature Module**:
   - Tap "Temperatura" from home screen
   - Wait for page to load
   - Scroll to "Descargar INO" button

3. **Test Share Functionality**:
   - Tap "Descargar INO" button
   - Verify share sheet appears
   - Select Gmail (or any email app)
   - Verify file is attached with correct name: `esp32_bt_temp.ino`
   - Verify text appears: "Código Arduino para Temperatura"
   - Cancel/send email

4. **Test User Dismissal**:
   - Tap "Descargar INO" again
   - Dismiss share sheet without selecting app
   - Verify no error shown
   - Verify app remains functional

5. **Test Other Modules**:
   - Repeat steps 2-4 for:
     - Servo motor module (`esp32_bt_servo.ino`)
     - Light control module (`esp32_bt_light.ino`)
     - Gamepad module (`UNO_bt_gamepad.ino`)

6. **Test Error Handling** (if possible):
   - Temporarily rename asset in pubspec.yaml to cause error
   - Tap "Descargar INO"
   - Verify error snackbar appears with helpful message
   - Revert pubspec.yaml change

### Automated Test Execution

```bash
# Run all unit tests with coverage
flutter test --coverage

# Generate coverage report (HTML)
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
open coverage/html/index.html  # macOS
start coverage/html/index.html  # Windows

# Verify coverage >80% for new files
```

### Analysis and Formatting Checks

```bash
# Check for analysis errors
flutter analyze

# Format all code
dart format lib/ test/

# Verify no changes after format
git diff
```

---

## 13. Known Limitations

1. **ShareResult Unavailable on Android < 10**:
   - Cannot determine if user dismissed or shared
   - Acceptable: These are older devices, share still works

2. **No Progress Indicator**:
   - File operations are synchronous (no progress UI)
   - Acceptable: .ino files are small (<50KB), instant operation

3. **No File Cleanup**:
   - Temp files persist until OS cleans them
   - Acceptable: Files are small, OS manages temp directory

4. **MIME Type Not Universally Recognized**:
   - `text/plain` means some apps may not show syntax highlighting
   - Acceptable: Sharing is for transfer, not editing

5. **No Offline Indicator**:
   - Share works offline (file is local)
   - Some receiving apps (email) may fail to send without network
   - Acceptable: That's the receiving app's responsibility

---

## 14. Future Enhancements (Out of Scope)

These are NOT part of this implementation but could be added later:

1. **Save to Downloads Folder**:
   - Add "Save to Downloads" button alongside "Share"
   - Requires storage permissions on Android
   - Better for users who want to keep the file

2. **QR Code Sharing**:
   - Generate QR code of .ino file content
   - Users can scan to get code on another device
   - Useful for workshops/classrooms

3. **Direct Upload to Arduino Cloud**:
   - Integrate with Arduino Cloud API
   - Share file directly to user's Arduino projects
   - Requires Arduino account integration

4. **Share as GitHub Gist**:
   - Upload .ino file as public/private gist
   - Generate shareable link
   - Requires GitHub OAuth

5. **Custom Share Text per Module**:
   - Localized descriptions for each module
   - Include circuit diagram link in share text
   - Stored in module metadata

---

## Conclusion

This implementation plan provides a comprehensive guide to fixing the INO file sharing feature using the current share_plus 11.1.0 API while maintaining Clean Architecture principles. The plan covers:

- ✅ Correct share_plus API usage
- ✅ Comprehensive error handling with Either pattern
- ✅ Clean Architecture compliance (service → repository → use case)
- ✅ Testing strategy with specific test cases
- ✅ Platform-specific considerations (Android/iOS)
- ✅ No additional permissions required
- ✅ User-friendly error messages in Spanish
- ✅ Edge case handling
- ✅ Clear success criteria

**Next Steps for David**:
1. Review this implementation plan
2. Approve or request changes
3. Confirm test coverage requirements (currently 80%)
4. Authorize actual implementation phase

**Estimated Implementation Time**: 4-6 hours
- Phase 1-4 (Core Implementation): 2-3 hours
- Phase 5 (UI Updates): 30 minutes
- Phase 6 (Testing): 2-3 hours
- Phase 7 (Code Quality): 30 minutes
