# Implementation Plan: Fix INO File Sharing Error Handling

**Feature**: Fix "Error desconocido" when sharing INO files
**Branch**: `feat/fix-ino-file-sharing`
**Date**: 2025-11-15
**Status**: Implementation Plan (NOT YET IMPLEMENTED)

---

## Problem Analysis

### Current Issue
David reports: **"muestra Error al compartir archivo: Error desconocido"** (shows unknown error when sharing file)

### Root Cause Hypothesis
The current implementation is hitting the `UnknownFailure` catch-all block instead of providing specific error information. Analysis of the code reveals:

1. **Service Layer** (`FileSharingService`):
   - Uses `rethrow` in catch block (line 60)
   - Only has `debugPrint` logging - no structured logging
   - Catches all errors generically with `catch (e, stackTrace)`
   - May be rethrowing `Error` objects (not `Exception`), which aren't caught by `on Exception`

2. **Repository Layer** (`FileSharingRepositoryImpl`):
   - Has specific exception handlers for:
     - `FileSystemException` → `FileSystemFailure`
     - `PlatformException` → `FileNotFoundFailure` or `ShareFailure`
     - `Exception` → `ShareFailure`
     - `catch (e)` → `UnknownFailure` ← **THIS IS WHERE IT'S FAILING**

3. **Missing Exception Types**:
   - No handling for `StateError`, `ArgumentError`, `TypeError`
   - No handling for Dart `Error` class (different from `Exception`)
   - No handling for share_plus specific errors (if they exist)
   - Generic `catch` is too broad

4. **Logging Gaps**:
   - Service uses `debugPrint` instead of `LoggerService`
   - Repository doesn't log before converting to Failure
   - No error type information in logs
   - Can't diagnose what actual error occurred

### Why This Matters
The error message "Error desconocido" gives no diagnostic information. We need to:
1. Catch the actual error that's occurring
2. Log comprehensive error details
3. Provide specific user-facing messages
4. Maintain >80% test coverage

---

## Architecture Context

### Current Architecture (Clean Architecture)
```
lib/
  core/
    data/
      services/
        file_sharing_service.dart          ← Service throws exceptions
        logger_service.dart                 ← Available for logging
      repositories/
        file_sharing_repository_impl.dart  ← Converts exceptions → Failures
    domain/
      repositories/
        file_sharing_repository.dart       ← Interface (no changes needed)
      usecases/
        share_file_usecase.dart            ← Use case (no changes needed)
    error/
      failure.dart                          ← Failure classes (no changes needed)
  shared/
    widgets/
      modules/
        build_main_content.dart            ← UI layer (no changes needed)

test/
  core/
    data/
      services/
        file_sharing_service_test.dart     ← Needs expansion
      repositories/
        file_sharing_repository_impl_test.dart ← Needs new tests
```

### Dependency Flow
```
UI (build_main_content.dart)
  → UseCase (ShareFileUseCase)
    → Repository Interface (FileSharingRepository)
      → Repository Impl (FileSharingRepositoryImpl)  ← FIX HERE
        → Service (FileSharingService)  ← FIX HERE
          → External (share_plus, path_provider, rootBundle)
```

---

## Implementation Plan

### 1. Update `FileSharingService` - Enhanced Logging

**File**: `lib/core/data/services/file_sharing_service.dart`

#### Changes Required

**A. Add LoggerService Injection**
```dart
// Add to constructor
class FileSharingService {
  final LoggerService logger;  // NEW

  FileSharingService({required this.logger});  // UPDATED

  // ... rest of class
}
```

**B. Replace All `debugPrint` with `logger` Calls**
```dart
Future<ShareResult> shareAssetFile({...}) async {
  try {
    // Load asset file from bundle
    final byteData = await rootBundle.load(assetPath);
    logger.info('File loaded from assets: $assetPath');  // CHANGED from debugPrint

    // Get temporary directory and write file
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    logger.info('File written to temp directory: $filePath');  // CHANGED

    // Share using share_plus API
    final result = await SharePlus.instance.share(...);

    logger.info('Share result status: ${result.status}');  // CHANGED
    return result;
  } catch (e, stackTrace) {
    // Enhanced logging with error type and full details
    logger.error(
      'Error sharing file - Type: ${e.runtimeType}, AssetPath: $assetPath, FileName: $fileName',
      e,
      stackTrace,
    );  // CHANGED - comprehensive error info
    rethrow;
  }
}
```

**C. ABOUTME Comments Update**
No changes to ABOUTME comments - they're still accurate.

**Why This Approach**:
- Service layer should NOT handle errors, only log them
- Use structured logging with `LoggerService` (already exists in project)
- Include error type (`e.runtimeType`) for diagnosis
- Keep `rethrow` - let repository handle conversion to Failures

---

### 2. Update `FileSharingRepositoryImpl` - Comprehensive Exception Handling

**File**: `lib/core/data/repositories/file_sharing_repository_impl.dart`

#### Changes Required

**A. Add LoggerService Injection**
```dart
class FileSharingRepositoryImpl implements FileSharingRepository {
  final FileSharingService service;
  final LoggerService logger;  // NEW

  FileSharingRepositoryImpl({
    required this.service,
    required this.logger,  // NEW
  });
```

**B. Replace Entire `shareAssetFile` Method with Enhanced Error Handling**

**BEFORE** (current implementation):
```dart
@override
Future<Either<Failure, void>> shareAssetFile({...}) async {
  try {
    await service.shareAssetFile(...);
    return const Right(null);
  } on FileSystemException catch (e, stackTrace) {
    return Left(FileSystemFailure(...));
  } on PlatformException catch (e, stackTrace) {
    // Check for asset not found
    if (e.message?.contains('Unable to load asset') ?? false) {
      return Left(FileNotFoundFailure(...));
    }
    return Left(ShareFailure(...));
  } on Exception catch (e, stackTrace) {
    return Left(ShareFailure(...));
  } catch (e, stackTrace) {  // ← THIS IS WHERE IT'S FAILING
    return Left(UnknownFailure(...));
  }
}
```

**AFTER** (enhanced implementation):
```dart
@override
Future<Either<Failure, void>> shareAssetFile({
  required String assetPath,
  required String fileName,
  String? text,
  String? subject,
}) async {
  try {
    // Call the service to share the file
    await service.shareAssetFile(
      assetPath: assetPath,
      fileName: fileName,
      text: text,
      subject: subject,
    );

    // All share results are treated as success (even user dismissal)
    return const Right(null);

  } on FileSystemException catch (e, stackTrace) {
    // Error writing to temporary directory
    logger.error(
      'FileSystemException in shareAssetFile - Path: $assetPath',
      e,
      stackTrace,
    );
    return Left(
      FileSystemFailure(
        'No se pudo guardar el archivo temporalmente',
        stackTrace,
      ),
    );

  } on PlatformException catch (e, stackTrace) {
    // Asset not found in bundle or platform-specific errors
    logger.error(
      'PlatformException in shareAssetFile - Code: ${e.code}, Message: ${e.message}',
      e,
      stackTrace,
    );

    if (e.message?.contains('Unable to load asset') ?? false) {
      return Left(
        FileNotFoundFailure(
          'Archivo no encontrado en los recursos de la aplicación',
          stackTrace,
        ),
      );
    }
    return Left(
      ShareFailure(
        'Error de la plataforma: ${e.message ?? e.toString()}',
        stackTrace,
      ),
    );

  } on StateError catch (e, stackTrace) {
    // NEW: Handle StateError (e.g., share sheet not available)
    logger.error(
      'StateError in shareAssetFile - Type: ${e.runtimeType}',
      e,
      stackTrace,
    );
    return Left(
      ShareFailure(
        'Error de estado al compartir: ${e.message}',
        stackTrace,
      ),
    );

  } on ArgumentError catch (e, stackTrace) {
    // NEW: Handle ArgumentError (e.g., invalid file path)
    logger.error(
      'ArgumentError in shareAssetFile - Name: ${e.name}, Message: ${e.message}',
      e,
      stackTrace,
    );
    return Left(
      ShareFailure(
        'Argumento inválido: ${e.message ?? e.toString()}',
        stackTrace,
      ),
    );

  } on TypeError catch (e, stackTrace) {
    // NEW: Handle TypeError (e.g., null reference)
    logger.error(
      'TypeError in shareAssetFile - Type: ${e.runtimeType}',
      e,
      stackTrace,
    );
    return Left(
      ShareFailure(
        'Error de tipo al compartir archivo',
        stackTrace,
      ),
    );

  } on Exception catch (e, stackTrace) {
    // Generic exceptions (includes custom exceptions from share_plus)
    logger.error(
      'Exception in shareAssetFile - Type: ${e.runtimeType}, Details: ${e.toString()}',
      e,
      stackTrace,
    );
    return Left(
      ShareFailure(
        'Error al compartir el archivo: ${e.toString()}',
        stackTrace,
      ),
    );

  } on Error catch (e, stackTrace) {
    // NEW: Handle Dart Error class (different from Exception)
    // This catches errors like NoSuchMethodError, AssertionError, etc.
    logger.error(
      'Error in shareAssetFile - Type: ${e.runtimeType}, Details: ${e.toString()}',
      e,
      stackTrace,
    );
    return Left(
      ShareFailure(
        'Error del sistema al compartir: ${e.toString()}',
        stackTrace,
      ),
    );

  } catch (e, stackTrace) {
    // Unknown errors - should rarely hit this now
    logger.error(
      'Unknown error in shareAssetFile - Type: ${e.runtimeType}, Details: ${e.toString()}',
      e,
      stackTrace,
    );
    return Left(
      UnknownFailure(
        'Error desconocido al compartir el archivo: ${e.toString()} (Tipo: ${e.runtimeType})',
        stackTrace,
      ),
    );
  }
}
```

**Why This Approach**:
- **More Specific Exception Types**: Added `StateError`, `ArgumentError`, `TypeError`, `Error`
- **Better Logging**: Every catch block logs with error type and details
- **Better Error Messages**: Include actual error details in user message
- **Preserve Architecture**: Still returns `Either<Failure, void>`, no business logic
- **Diagnostic Info**: Final catch includes `e.runtimeType` so we can see what we missed

**Key Differences**:
1. `on Error catch (e, stackTrace)` - NEW - catches Dart Error class
2. `on StateError`, `on ArgumentError`, `on TypeError` - NEW - specific error types
3. All catch blocks now log with `logger.error()`
4. Last catch block includes `e.runtimeType` for diagnosis

---

### 3. Update Dependency Injection

**File**: `lib/di/service_locator.dart`

#### Changes Required

**BEFORE**:
```dart
// File Sharing Service (around line 190)
getIt.registerLazySingleton<FileSharingService>(
  () => FileSharingService(),
);

// File Sharing Repository (around line 195)
getIt.registerLazySingleton<FileSharingRepository>(
  () => FileSharingRepositoryImpl(service: getIt<FileSharingService>()),
);
```

**AFTER**:
```dart
// File Sharing Service (around line 190)
getIt.registerLazySingleton<FileSharingService>(
  () => FileSharingService(logger: getIt<LoggerService>()),  // CHANGED: add logger
);

// File Sharing Repository (around line 195)
getIt.registerLazySingleton<FileSharingRepository>(
  () => FileSharingRepositoryImpl(
    service: getIt<FileSharingService>(),
    logger: getIt<LoggerService>(),  // CHANGED: add logger
  ),
);
```

**Important**: Verify that `LoggerService` is already registered earlier in the file. Based on the project structure, it should be registered around line 30-40 in the "Core Services" section.

---

### 4. Update Repository Tests

**File**: `test/core/data/repositories/file_sharing_repository_impl_test.dart`

#### Changes Required

**A. Update Mock Generation**
```dart
@GenerateMocks([FileSharingService, LoggerService])  // ADD LoggerService
void main() {
  late FileSharingRepositoryImpl repository;
  late MockFileSharingService mockService;
  late MockLoggerService mockLogger;  // NEW

  setUp(() {
    mockService = MockFileSharingService();
    mockLogger = MockLoggerService();  // NEW
    repository = FileSharingRepositoryImpl(
      service: mockService,
      logger: mockLogger,  // NEW
    );
  });
```

**B. Add New Test Cases**

Add these tests after the existing tests (around line 249):

```dart
group('Enhanced error handling tests', () {
  test('should return ShareFailure and log when StateError is thrown', () async {
    // Arrange
    final error = StateError('Share sheet not available');
    when(mockService.shareAssetFile(
      assetPath: anyNamed('assetPath'),
      fileName: anyNamed('fileName'),
      text: anyNamed('text'),
      subject: anyNamed('subject'),
    )).thenThrow(error);

    // Act
    final result = await repository.shareAssetFile(
      assetPath: tAssetPath,
      fileName: tFileName,
      text: tText,
      subject: tSubject,
    );

    // Assert
    expect(result, isA<Left>());
    result.fold(
      (failure) {
        expect(failure, isA<ShareFailure>());
        expect(failure.message, contains('Error de estado'));
      },
      (_) => fail('Should return Left'),
    );

    // Verify logging occurred
    verify(mockLogger.error(
      argThat(contains('StateError')),
      argThat(isA<StateError>()),
      argThat(isA<StackTrace>()),
    )).called(1);
  });

  test('should return ShareFailure and log when ArgumentError is thrown', () async {
    // Arrange
    final error = ArgumentError('Invalid file path');
    when(mockService.shareAssetFile(
      assetPath: anyNamed('assetPath'),
      fileName: anyNamed('fileName'),
      text: anyNamed('text'),
      subject: anyNamed('subject'),
    )).thenThrow(error);

    // Act
    final result = await repository.shareAssetFile(
      assetPath: tAssetPath,
      fileName: tFileName,
      text: tText,
      subject: tSubject,
    );

    // Assert
    expect(result, isA<Left>());
    result.fold(
      (failure) {
        expect(failure, isA<ShareFailure>());
        expect(failure.message, contains('Argumento inválido'));
      },
      (_) => fail('Should return Left'),
    );

    verify(mockLogger.error(
      argThat(contains('ArgumentError')),
      argThat(isA<ArgumentError>()),
      argThat(isA<StackTrace>()),
    )).called(1);
  });

  test('should return ShareFailure and log when TypeError is thrown', () async {
    // Arrange
    final error = TypeError();
    when(mockService.shareAssetFile(
      assetPath: anyNamed('assetPath'),
      fileName: anyNamed('fileName'),
      text: anyNamed('text'),
      subject: anyNamed('subject'),
    )).thenThrow(error);

    // Act
    final result = await repository.shareAssetFile(
      assetPath: tAssetPath,
      fileName: tFileName,
      text: tText,
      subject: tSubject,
    );

    // Assert
    expect(result, isA<Left>());
    result.fold(
      (failure) {
        expect(failure, isA<ShareFailure>());
        expect(failure.message, contains('Error de tipo'));
      },
      (_) => fail('Should return Left'),
    );

    verify(mockLogger.error(
      argThat(contains('TypeError')),
      argThat(isA<TypeError>()),
      argThat(isA<StackTrace>()),
    )).called(1);
  });

  test('should return ShareFailure and log when Dart Error is thrown', () async {
    // Arrange
    // Using NoSuchMethodError as a representative Error class
    final error = NoSuchMethodError.withInvocation(
      null,
      Invocation.method(#missingMethod, []),
    );
    when(mockService.shareAssetFile(
      assetPath: anyNamed('assetPath'),
      fileName: anyNamed('fileName'),
      text: anyNamed('text'),
      subject: anyNamed('subject'),
    )).thenThrow(error);

    // Act
    final result = await repository.shareAssetFile(
      assetPath: tAssetPath,
      fileName: tFileName,
      text: tText,
      subject: tSubject,
    );

    // Assert
    expect(result, isA<Left>());
    result.fold(
      (failure) {
        expect(failure, isA<ShareFailure>());
        expect(failure.message, contains('Error del sistema'));
      },
      (_) => fail('Should return Left'),
    );

    verify(mockLogger.error(
      argThat(contains('Error in shareAssetFile')),
      argThat(isA<Error>()),
      argThat(isA<StackTrace>()),
    )).called(1);
  });

  test('should include error type in UnknownFailure message for diagnosis', () async {
    // Arrange - use a custom object to test the catch-all
    final customError = {'type': 'custom', 'message': 'something weird'};
    when(mockService.shareAssetFile(
      assetPath: anyNamed('assetPath'),
      fileName: anyNamed('fileName'),
      text: anyNamed('text'),
      subject: anyNamed('subject'),
    )).thenThrow(customError);

    // Act
    final result = await repository.shareAssetFile(
      assetPath: tAssetPath,
      fileName: tFileName,
      text: tText,
      subject: tSubject,
    );

    // Assert
    expect(result, isA<Left>());
    result.fold(
      (failure) {
        expect(failure, isA<UnknownFailure>());
        expect(failure.message, contains('Error desconocido'));
        // Verify it includes the runtime type for diagnosis
        expect(failure.message, contains('Tipo:'));
      },
      (_) => fail('Should return Left'),
    );

    verify(mockLogger.error(
      argThat(contains('Unknown error')),
      customError,
      argThat(isA<StackTrace>()),
    )).called(1);
  });
});

group('Logging verification for existing tests', () {
  test('should log FileSystemException details', () async {
    // Arrange
    when(mockService.shareAssetFile(
      assetPath: anyNamed('assetPath'),
      fileName: anyNamed('fileName'),
      text: anyNamed('text'),
      subject: anyNamed('subject'),
    )).thenThrow(const FileSystemException('Write failed'));

    // Act
    await repository.shareAssetFile(
      assetPath: tAssetPath,
      fileName: tFileName,
      text: tText,
      subject: tSubject,
    );

    // Assert logging
    verify(mockLogger.error(
      argThat(contains('FileSystemException')),
      argThat(isA<FileSystemException>()),
      argThat(isA<StackTrace>()),
    )).called(1);
  });

  test('should log PlatformException details', () async {
    // Arrange
    when(mockService.shareAssetFile(
      assetPath: anyNamed('assetPath'),
      fileName: anyNamed('fileName'),
      text: anyNamed('text'),
      subject: anyNamed('subject'),
    )).thenThrow(PlatformException(
      code: 'ShareError',
      message: 'Share failed',
    ));

    // Act
    await repository.shareAssetFile(
      assetPath: tAssetPath,
      fileName: tFileName,
      text: tText,
      subject: tSubject,
    );

    // Assert logging
    verify(mockLogger.error(
      argThat(contains('PlatformException')),
      argThat(isA<PlatformException>()),
      argThat(isA<StackTrace>()),
    )).called(1);
  });
});
```

**C. Update Test Expectations**

All existing tests will still pass because:
- We're not changing the Failure types returned
- We're just adding logging (which we verify with `verify()`)
- The Either pattern remains the same

**Why These Tests**:
- Test each new exception type (`StateError`, `ArgumentError`, `TypeError`, `Error`)
- Verify logging occurs for ALL error cases
- Verify error messages are user-friendly in Spanish
- Verify diagnostic info is included in UnknownFailure
- Maintain >80% coverage requirement

---

### 5. Update Service Tests (Optional but Recommended)

**File**: `test/core/data/services/file_sharing_service_test.dart`

Current tests are minimal. Consider adding integration-style tests:

```dart
@GenerateMocks([LoggerService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileSharingService', () {
    late FileSharingService service;
    late MockLoggerService mockLogger;

    setUp(() {
      mockLogger = MockLoggerService();
      service = FileSharingService(logger: mockLogger);
    });

    // ... existing tests ...

    group('Error logging', () {
      test('should log error details when asset not found', () async {
        // Arrange
        const invalidAssetPath = 'assets/files/nonexistent.ino';
        const fileName = 'nonexistent.ino';

        // Act & Assert
        expect(
          () => service.shareAssetFile(
            assetPath: invalidAssetPath,
            fileName: fileName,
          ),
          throwsA(isA<FlutterError>()),
        );

        // Verify logging
        verify(mockLogger.error(
          argThat(contains('Error sharing file')),
          argThat(anything),
          argThat(isA<StackTrace>()),
        )).called(1);
      });
    });
  });
}
```

**Note**: These are harder to test because they require mocking Flutter's rootBundle and platform channels. Focus on repository tests first.

---

## Testing Strategy

### Test Coverage Requirements
- Minimum 80% code coverage
- All new exception handlers must be tested
- All logging calls must be verified

### Test Execution Plan
1. Run existing tests: `flutter test test/core/data/repositories/file_sharing_repository_impl_test.dart`
2. Verify all existing tests still pass
3. Add new tests for new exception types
4. Run with coverage: `flutter test --coverage`
5. Verify >80% coverage on both files

### Manual Testing Plan
1. **Test Asset Not Found**:
   - Modify `mainModule.inoFile` to invalid path
   - Expected: "Archivo no encontrado" error

2. **Test File System Error**:
   - Run on device with no storage space (if possible)
   - Expected: "No se pudo guardar el archivo temporalmente"

3. **Test Platform Error**:
   - Run on emulator without share capability
   - Expected: Specific platform error message

4. **Test Success**:
   - Share a valid INO file
   - Expected: Share sheet opens, no error on dismiss or success

---

## Expected Behavior After Fix

### Before Fix
- User sees: **"Error al compartir archivo: Error desconocido"**
- No diagnostic information in logs
- Can't determine what went wrong

### After Fix
- User sees specific error based on failure type:
  - "Archivo no encontrado" - Asset missing
  - "No se pudo guardar el archivo temporalmente" - FileSystem error
  - "Error de la plataforma: [details]" - Platform error
  - "Error de estado al compartir: [details]" - StateError
  - "Argumento inválido: [details]" - ArgumentError
  - "Error de tipo al compartir archivo" - TypeError
  - "Error del sistema al compartir: [details]" - Dart Error
  - "Error al compartir el archivo: [details]" - Generic Exception
  - "Error desconocido al compartir el archivo: [details] (Tipo: [type])" - True unknown (rare)

- Logs contain:
  - Error type (`StateError`, `ArgumentError`, etc.)
  - Full error message
  - Stack trace
  - Context (assetPath, fileName)

### Diagnosis Path
1. User reports error
2. Check logs for error type
3. See specific error class and message
4. Fix actual underlying issue

---

## What Likely Caused "Error desconocido"

Based on the code analysis, the most likely causes are:

### Hypothesis 1: Dart Error Class (Most Likely)
**Issue**: share_plus or one of its dependencies threw a Dart `Error` object (not `Exception`)
- Examples: `NoSuchMethodError`, `AssertionError`, `CastError`
- Current code: `on Exception catch` doesn't catch `Error` class
- Result: Falls through to generic `catch` → `UnknownFailure`

**Evidence**:
- Service's `rethrow` would preserve the Error type
- Repository's `on Exception` wouldn't catch it
- Would hit final `catch` block

**Fix**: Add `on Error catch` handler

### Hypothesis 2: StateError from share_plus
**Issue**: share_plus might throw `StateError` when share sheet is not available
- Example: Emulator without Google Play Services
- Current code: Not caught by `on Exception`
- Result: Falls through to generic `catch`

**Fix**: Add `on StateError catch` handler

### Hypothesis 3: ArgumentError from File Path
**Issue**: Invalid file path format passed to XFile
- Example: Path with special characters, null bytes
- Current code: Not caught specifically
- Result: Falls through to generic `catch`

**Fix**: Add `on ArgumentError catch` handler

### Hypothesis 4: Custom Exception from share_plus
**Issue**: share_plus throws a custom exception we don't handle
- Would be caught by `on Exception`
- But error message doesn't match our string checks
- UI mapping would show "Error desconocido"

**Fix**: Better error message in `on Exception` handler

**Most Likely**: Hypothesis 1 (Dart Error class) because it's the only one that would bypass `on Exception` and hit the generic `catch` block.

---

## Files to Change

### Core Implementation
1. **lib/core/data/services/file_sharing_service.dart**
   - Add LoggerService injection
   - Replace debugPrint with logger calls
   - Enhanced error logging with error type

2. **lib/core/data/repositories/file_sharing_repository_impl.dart**
   - Add LoggerService injection
   - Add `on StateError catch` handler
   - Add `on ArgumentError catch` handler
   - Add `on TypeError catch` handler
   - Add `on Error catch` handler
   - Add logging to all catch blocks
   - Enhance UnknownFailure message with error type

3. **lib/di/service_locator.dart**
   - Inject LoggerService into FileSharingService
   - Inject LoggerService into FileSharingRepositoryImpl

### Tests
4. **test/core/data/repositories/file_sharing_repository_impl_test.dart**
   - Add LoggerService mock
   - Add tests for StateError
   - Add tests for ArgumentError
   - Add tests for TypeError
   - Add tests for Error class
   - Add tests verifying logging
   - Add test for UnknownFailure with error type

5. **test/core/data/services/file_sharing_service_test.dart** (optional)
   - Add LoggerService mock
   - Add error logging verification tests

### No Changes Required
- `lib/core/domain/repositories/file_sharing_repository.dart` - Interface unchanged
- `lib/core/domain/usecases/share_file_usecase.dart` - Use case unchanged
- `lib/core/error/failure.dart` - Failure classes unchanged
- `lib/shared/widgets/modules/build_main_content.dart` - UI logic unchanged

---

## Implementation Checklist

### Pre-Implementation
- [ ] Read this plan thoroughly
- [ ] Verify LoggerService is registered in DI
- [ ] Review current test coverage
- [ ] Understand current error flow

### Implementation Phase
- [ ] Update FileSharingService with LoggerService
- [ ] Update FileSharingRepositoryImpl with new exception handlers
- [ ] Update DI registration for both classes
- [ ] Run `dart format lib/` to format code
- [ ] Run `flutter analyze` to check for issues

### Testing Phase
- [ ] Generate mocks: `flutter pub run build_runner build`
- [ ] Update repository tests with LoggerService mock
- [ ] Add tests for StateError
- [ ] Add tests for ArgumentError
- [ ] Add tests for TypeError
- [ ] Add tests for Error class
- [ ] Add logging verification tests
- [ ] Run all tests: `flutter test`
- [ ] Verify all tests pass
- [ ] Run with coverage: `flutter test --coverage`
- [ ] Verify >80% coverage

### Manual Testing
- [ ] Test with valid INO file - should share successfully
- [ ] Test with invalid asset path - should show specific error
- [ ] Test on different devices/emulators
- [ ] Verify Spanish error messages display correctly
- [ ] Check logs for comprehensive error details

### Code Review
- [ ] All ABOUTME comments still accurate
- [ ] All imports use package: format
- [ ] No analysis warnings
- [ ] Code formatted with dart format
- [ ] Tests cover all new code paths
- [ ] Spanish error messages are user-friendly
- [ ] Logging doesn't expose sensitive data

### Git Workflow
- [ ] Commit changes: `git add .`
- [ ] Create commit with message:
  ```
  fix: enhance file sharing error handling with comprehensive logging

  - Add LoggerService to FileSharingService and FileSharingRepositoryImpl
  - Add specific exception handlers for StateError, ArgumentError, TypeError, Error
  - Add comprehensive logging to all error cases with error type and context
  - Include error type in UnknownFailure message for better diagnosis
  - Add unit tests for all new exception handlers
  - Verify logging calls in tests

  This fixes the "Error desconocido" issue by catching more specific error types
  and providing detailed diagnostic information in logs.

  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
- [ ] Push to branch: `git push origin feat/fix-ino-file-sharing`
- [ ] Update PR description with fix details

---

## Important Notes for Implementation

### 1. LoggerService Availability
The LoggerService exists at `lib/core/data/services/logger_service.dart` and should already be registered in DI. Verify this before implementation.

### 2. Error vs Exception in Dart
**Critical Distinction**:
- `Exception`: Expected errors that should be caught and handled
  - Examples: `FileSystemException`, `PlatformException`, `FormatException`
  - Caught by: `on Exception catch`

- `Error`: Programming errors that indicate bugs
  - Examples: `NoSuchMethodError`, `StateError`, `AssertionError`, `TypeError`
  - NOT caught by: `on Exception catch`
  - Caught by: `on Error catch` or generic `catch`

**Why This Matters**:
- Current code only has `on Exception catch`
- If share_plus throws an `Error`, it bypasses this handler
- Falls through to generic `catch` → `UnknownFailure`

**Solution**: Add `on Error catch` handler AFTER `on Exception catch`

### 3. Exception Handler Order
**CRITICAL**: Order matters in try-catch blocks!

**Correct Order** (specific → general):
```dart
try {
  // code
} on FileSystemException catch (e, s) {  // Most specific
} on PlatformException catch (e, s) {
} on StateError catch (e, s) {
} on ArgumentError catch (e, s) {
} on TypeError catch (e, s) {
} on Exception catch (e, s) {  // General exceptions
} on Error catch (e, s) {      // General errors
} catch (e, s) {               // Catch-all (unknown types)
}
```

**Wrong Order** (would bypass specific handlers):
```dart
try {
  // code
} on Exception catch (e, s) {  // TOO GENERAL - catches everything below
} on FileSystemException catch (e, s) {  // NEVER REACHED!
} on PlatformException catch (e, s) {    // NEVER REACHED!
}
```

### 4. Spanish Error Messages
All user-facing error messages must be in Spanish:
- ✅ "Error de estado al compartir"
- ✅ "Argumento inválido"
- ✅ "Error de tipo al compartir archivo"
- ✅ "Error del sistema al compartir"
- ❌ "State error when sharing" (wrong - English)

### 5. Don't Log Sensitive Data
**DO**:
- Log error types, file paths, error messages
- Log stack traces for debugging

**DON'T**:
- Log user personal information
- Log authentication tokens
- Log full file contents

### 6. Test Coverage Strategy
- Mock LoggerService in all tests
- Use `verify()` to ensure logging occurs
- Test each exception type separately
- Test that correct Failure type is returned
- Test that error messages are in Spanish

### 7. Preserve Existing Behavior
**Must Not Change**:
- Return type: `Either<Failure, void>`
- Success behavior: All ShareResult statuses return `Right(null)`
- Failure types: Same Failure classes as before
- UI layer: No changes to build_main_content.dart

**Can Change**:
- Error messages can be more detailed
- Logging is new functionality
- Internal exception handling flow

---

## Success Criteria

### Functional Requirements
✅ User sees specific error messages, not "Error desconocido"
✅ Logs contain comprehensive error information
✅ All existing functionality still works
✅ Spanish error messages maintained
✅ Either pattern preserved

### Technical Requirements
✅ >80% test coverage
✅ All tests pass
✅ No flutter analyze warnings
✅ Code formatted with dart format
✅ Clean Architecture maintained
✅ DI properly configured

### Testing Requirements
✅ Unit tests for all exception types
✅ Logging verification in tests
✅ Manual testing on real device
✅ Error messages user-friendly

---

## Post-Implementation

### Next Steps
1. Monitor logs in production to identify actual error types
2. If "Error desconocido" still appears, check logs for error type
3. Add specific handler for that type if needed
4. Update tests to cover the new case

### Future Improvements
1. Add telemetry/analytics for error tracking
2. Consider retry mechanism for transient errors
3. Add offline detection before attempting share
4. Consider caching shared files for faster re-sharing

---

## Summary

This implementation plan addresses the "Error desconocido" issue by:

1. **Adding Comprehensive Exception Handling**: Catching `StateError`, `ArgumentError`, `TypeError`, and `Error` class in addition to existing handlers

2. **Enhanced Logging**: Using `LoggerService` instead of `debugPrint` with error type, context, and stack traces

3. **Better Error Messages**: Including error details and type information for diagnosis

4. **Maintaining Architecture**: No changes to Clean Architecture, Either pattern, or UI layer

5. **Test Coverage**: Adding tests for all new exception types with >80% coverage

6. **Diagnostic Information**: Including error type in UnknownFailure message so we can identify missed cases

**Key Insight**: The issue is likely that share_plus or its dependencies are throwing Dart `Error` objects instead of `Exception` objects, which bypass the `on Exception catch` handler and hit the generic `catch` block. Adding `on Error catch` should catch most of these cases.

**Expected Outcome**: After implementation, users will see specific, actionable error messages, and logs will contain the information needed to diagnose and fix the actual underlying issue.

---

**DO NOT IMPLEMENT THIS PLAN YET - This is a proposal for David's review.**

When ready to implement, follow the checklist above and ensure all tests pass before committing.
