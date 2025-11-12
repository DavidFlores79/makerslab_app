# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Makers Lab** is a Flutter mobile application (Android/iOS) for IoT device control and educational purposes. The app enables users to interact with Arduino-based modules through Bluetooth, including temperature sensors, servo motors, LED control, and gamepad interfaces. It implements Clean Architecture with clear separation across Domain, Data, and Presentation layers, following SOLID principles and modern Flutter development patterns.

## Architecture

### Tech Stack
- **Framework**: Flutter 3.7.2+ with Dart 3.7.2+
- **Target Platforms**: Android & iOS (primary focus)
- **Architecture**: Clean Architecture (Domain, Data, Presentation)
- **State Management**: BLoC Pattern (classic Bloc<Event, State>) with flutter_bloc 9.1.1
- **Dependency Injection**: get_it 8.0.3 for service locator pattern (manual registration)
- **Navigation**: go_router 16.0.0 with ShellRoute for nested navigation
- **Testing**: flutter_test (minimal test coverage currently)
- **UI Components**: Material Design 3 with custom AppColors theme
- **Networking**: dio 5.9.0 with custom interceptors (auth, refresh token, error handling)
- **Local Storage**: flutter_secure_storage 9.2.4, shared_preferences 2.5.3
- **Bluetooth**: flutter_bluetooth_serial 0.4.0, flutter_reactive_ble 5.4.0
- **Form Validation**: pin_code_fields 8.0.1 for OTP verification
- **Media**: video_player 2.10.0, youtube_player_flutter 9.1.2, lottie 3.3.1
- **Localization**: intl 0.19.0, flutter_localizations (Spanish/English)
- **Chat**: flutter_chat_core 2.8.0, flutter_chat_ui 2.9.0
- **Other**: uuid 3.0.4, equatable 2.0.7, dartz 0.10.1, logger 2.6.0

### Clean Architecture Layers

The codebase follows Clean Architecture with feature-based organization:

#### Actual Project Structure
```
lib/
  core/                           # Shared cross-cutting concerns
    config/                       # API config, module seeds
    data/
      repositories/               # Bluetooth repository impl
      services/                   # File sharing, permissions, logger, Bluetooth service
    domain/
      entities/                   # Core entities (if any)
      repositories/               # Bluetooth, file sharing repository interfaces
      usecases/                   # Bluetooth usecases (connect, discover, send data)
        bluetooth/                # Connect, disconnect, discover, send, get stream
        share_file_usecase.dart
    error/                        # Failure classes (Equatable), exceptions
    mocks/                        # Mock data for development
    network/                      # DioClient, interceptors (auth, error), refresh token service, api_exceptions
    presentation/
      bloc/
        bluetooth/                # Bluetooth BLoC (global)
      pages/                      # Not found page
    router/                       # GoRouter configuration (app_router.dart)
    storage/                      # Secure storage service, keys
    ui/                           # Snackbar service, bluetooth dialogs
    validators/                   # Form validators
    app_keys.dart                 # Global app keys

  di/
    service_locator.dart          # Manual get_it registration (no @injectable)

  features/                       # Feature modules
    auth/                         # Authentication & user management
      data/
        datasources/              # Remote (API), local (token, user)
        repositories/             # Auth repository impl
      domain/
        entities/                 # User entity
        repositories/             # Auth repository interface
        usecases/                 # Login, register, logout, check session, OTP, etc.
      presentation/
        bloc/                     # AuthBloc, OtpBloc, RegisterCubit
        pages/                    # Login, signup, OTP, splash coordinator
        routes/                   # Auth routes configuration
        widgets/                  # Auth-specific widgets

    catalogs/                     # Country/catalog data
      data/, domain/, presentation/ (minimal)

    chat/                         # In-app chat functionality
      data/, domain/, presentation/
      usecases/                   # Send message, upload file, start session

    home/                         # Main home screen with module menu
      data/
        datasources/              # Local (menu cache), remote (API)
        repositories/             # Home repository impl
      domain/
        repositories/             # Home repository interface
        usecases/                 # Get menu, get remote menu, get combined menu
      presentation/
        bloc/                     # HomeBloc
        pages/                    # HomePage
        routes/                   # Static module routes

    gamepad/                      # Gamepad control module
      data/, domain/, presentation/

    light_control/                # LED light control module
      data/, domain/, presentation/

    onboarding/                   # First-time user onboarding
      data/, domain/, presentation/

    profile/                      # User profile management
      data/, domain/, presentation/
      pages/                      # ProfilePage, PersonalDataPage

    servo/                        # Servo motor control module
      data/, domain/, presentation/
      usecases/                   # Get/send servo position

    temperature/                  # Temperature sensor module
      data/
        datasources/              # Local temperature datasource
        repositories/             # Temperature repository impl
      domain/
        entities/                 # Temperature entity
        repositories/             # Temperature repository interface
      presentation/
        bloc/                     # TemperatureBloc
        pages/                    # Temperature control page

  l10n/                           # Localization files (Spanish, English)

  shared/                         # Shared widgets and utilities

  theme/                          # AppColors, theme configuration

  utils/                          # Helper utilities

  main.dart                       # App entry point with DI setup
  main_shell.dart                 # Shell route wrapper

assets/
  images/                         # Brand, modules, static instruction images
    brand/
    modules/
    static/
      temperature/, servo/, light_control/, gamepad/
        instructions/             # Step-by-step images
  fonts/                          # Roboto font family
  lotties/                        # Lottie animations
  files/                          # Static files

test/
  widget_test.dart                # Basic widget test (only test currently)
```

### Key Architectural Principles

1. **Dependency Rule**: All dependencies point inward. Domain layer has zero dependencies on Flutter/infrastructure.
2. **Single Responsibility**: Each class has one reason to change
3. **Dependency Injection**: Manual get_it registration in `lib/di/service_locator.dart` (no @injectable)
4. **Repository Pattern**: Domain defines interfaces, Data implements them
5. **Either Pattern**: Use dartz package for functional error handling (Either<Failure, Success>)
6. **BLoC Pattern**: Classic Bloc<Event, State> pattern for state management
7. **Equatable**: Used ONLY for Failure classes, not for entities or models
8. **Simple Entities**: Domain entities are simple classes with required/nullable fields

### Import Structure

Use package imports for all internal code:
```dart
// Core imports
import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/core/network/dio_client.dart';

// Feature imports
import 'package:makerslab_app/features/auth/domain/entities/user_entity.dart';
import 'package:makerslab_app/features/temperature/presentation/bloc/temperature_bloc.dart';

// DI import
import 'package:makerslab_app/di/service_locator.dart';
```

## Development Commands

### Running the Application

```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator (default: main.dart)
flutter run

# Run with device selection
flutter devices
flutter run -d <device-id>

# Build APK (Android) - current compileSdk: 35
flutter build apk --release

# Build App Bundle (Android - for Play Store)
flutter build appbundle --release

# Build IPA (iOS - requires Mac)
flutter build ios --release

# Clean build artifacts (fixes many build issues)
flutter clean && flutter pub get

# Check Flutter environment
flutter doctor
flutter doctor -v
```

**Note**: This project does NOT use flavors. There's only one entry point: `lib/main.dart`.

### Testing

```bash
# Run all tests (currently only widget_test.dart exists)
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart

# Generate test coverage report (HTML)
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
open coverage/html/index.html
```

**Current State**: Minimal test coverage. Only `test/widget_test.dart` exists. Tests MUST be added for all new features.

### Code Quality & Analysis

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/ test/

# Fix formatting issues automatically
dart fix --apply

# Run analysis with strict mode
flutter analyze --fatal-infos --fatal-warnings
```

**Note**: This project uses `flutter_lints 5.0.0` for linting rules.

### Code Generation

This project does NOT currently use code generation tools like `build_runner`, `json_serializable`, or `freezed`. All models are handwritten.

### Device Management

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on Chrome (for web testing)
flutter run -d chrome

# Launch Android emulator
flutter emulators --launch <emulator-id>

# List available emulators
flutter emulators
```

**Always use `flutter pub` instead of `dart pub` for Flutter projects.**

## Key Technical Configurations

### API Configuration

API configuration is in `lib/core/config/api_config.dart`. The DioClient in `lib/core/network/dio_client.dart` includes:
- **Auth Interceptor**: Adds Bearer token from secure storage
- **Error Interceptor**: Handles API errors and logs them
- **Refresh Token Service**: Automatically refreshes expired tokens

### Dependency Injection Setup

All DI is manually configured in `lib/di/service_locator.dart` using get_it. Registration includes:
- Services (logger, permissions, Bluetooth, secure storage)
- Data sources (local and remote)
- Repositories
- Use cases
- BLoCs (factory for feature BLoCs, singleton for global BluetoothBloc)

Example registration pattern:
```dart
// Singleton service
getIt.registerLazySingleton<BluetoothService>(() => BluetoothService());

// Repository
getIt.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(
    tokenLocalDataSource: getIt(),
    userLocalDataSource: getIt(),
    remoteDataSource: getIt(),
  ),
);

// Use case
getIt.registerLazySingleton(() => LoginUser(repository: getIt()));

// BLoC (factory for new instances)
getIt.registerFactory(() => AuthBloc(
  loginUser: getIt(),
  registerUser: getIt(),
  // ... other dependencies
));
```

### Navigation Configuration

GoRouter is configured in `lib/core/router/app_router.dart`:
- Initial route: `SplashCoordinator.routeName`
- Auth routes defined in `features/auth/presentation/routes/auth_routes.dart`
- Main app uses `ShellRoute` wrapper (`MainShell`) for persistent bottom navigation
- Module routes in `features/home/presentation/routes/main_static_routes.dart`

## Mobile-Specific Architecture Patterns

### 1. BLoC State Management Pattern

This project uses classic BLoC pattern. Here's a real example from the Temperature module:

**BLoC Implementation** (`features/temperature/presentation/bloc/temperature_bloc.dart`):
```dart
class TemperatureBloc extends Bloc<TemperatureEvent, TemperatureState> {
  final GetBluetoothDataStreamUseCase getDataStreamUseCase;
  final SendBluetoothStringUseCase sendStringUseCase;
  final TemperatureLocalDataSource localDataSource;
  final BluetoothBloc bluetoothBloc;

  TemperatureBloc({
    required this.getDataStreamUseCase,
    required this.sendStringUseCase,
    required this.localDataSource,
    required this.bluetoothBloc,
  }) : super(TemperatureInitial()) {
    on<StartTemperatureMonitoring>(_onStartMonitoring);
    on<StopTemperatureMonitoring>(_onStopMonitoring);
    on<UpdateTemperature>(_onUpdateTemperature);
  }

  Future<void> _onStartMonitoring(
    StartTemperatureMonitoring event,
    Emitter<TemperatureState> emit,
  ) async {
    emit(TemperatureLoading());

    // Subscribe to Bluetooth data stream
    final result = await getDataStreamUseCase(NoParams());

    result.fold(
      (failure) => emit(TemperatureError(message: _mapFailureToMessage(failure))),
      (stream) {
        // Process incoming data
        emit(TemperatureMonitoring(stream: stream));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is BluetoothFailure) {
      return 'Bluetooth Error: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'No Internet Connection';
    }
    return 'Unexpected Error';
  }
}
```

**Key BLoC Patterns in this Project**:
- All module BLoCs (Temperature, Servo, LightControl, Gamepad) depend on global `BluetoothBloc`
- BLoCs subscribe to Bluetooth data streams for real-time sensor updates
- Use `Either<Failure, Success>` from dartz for error handling
- Events trigger use case execution
- States represent UI states (Initial, Loading, Success, Error)

### 2. Domain Layer (Business Logic)

Real examples from the Temperature feature:

**Entity** (`features/temperature/domain/entities/temperature_entity.dart`):
```dart
class Temperature {
  final double celsius;
  final double humidity;
  final DateTime timestamp;

  Temperature({
    required this.celsius,
    required this.humidity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
```

**Repository Interface** (`features/temperature/domain/repositories/temperature_repository.dart`):
```dart
abstract class TemperatureRepository {
  Future<Either<Failure, Stream<String>>> getBluetoothDataStream();
  Future<Either<Failure, void>> sendCommand(String command);
  Future<Either<Failure, Temperature?>> getLastTemperature();
  Future<Either<Failure, void>> saveTemperature(Temperature temperature);
}
```

**Use Case Example** (`core/domain/usecases/bluetooth/connect_device.dart`):
```dart
class ConnectDeviceUseCase {
  final BluetoothRepository repository;

  ConnectDeviceUseCase({required this.repository});

  Future<Either<Failure, void>> call(String deviceId) async {
    return await repository.connectToDevice(deviceId);
  }
}
```

**Important Domain Rules**:
- Entities are simple classes (no Equatable, no immutability enforced)
- Some fields are nullable, some required - depends on use case
- Use cases follow single responsibility principle
- Repository interfaces define contracts, implementations live in data layer

### 3. Data Layer (Infrastructure)

**Repository Implementation Example** (`core/data/repositories/bluetooth_repository_impl.dart`):
```dart
class BluetoothRepositoryImpl implements BluetoothRepository {
  final BluetoothService btService;

  BluetoothRepositoryImpl({required this.btService});

  @override
  Future<Either<Failure, List<BluetoothDevice>>> discoverDevices() async {
    try {
      final devices = await btService.scanForDevices();
      return Right(devices);
    } on BluetoothException catch (e) {
      return Left(BluetoothFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> connectToDevice(String deviceId) async {
    try {
      await btService.connect(deviceId);
      return const Right(null);
    } on BluetoothException catch (e) {
      return Left(BluetoothFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stream<String>>> getDataStream() async {
    try {
      final stream = btService.dataStream;
      return Right(stream);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }
}
```

**Key Data Layer Patterns**:
- Repository implementations handle exceptions and convert them to Failures
- Use try-catch to handle exceptions from external sources (Bluetooth, API, storage)
- Return `Either<Failure, Success>` - Left for errors, Right for success
- Data sources are injected (remote API, local storage, Bluetooth service)
- No business logic in repository implementations - pure data operations

### 4. Presentation Layer (UI)

**Typical Page Structure**:
```dart
class TemperaturePage extends StatelessWidget {
  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TemperatureBloc>()..add(StartTemperatureMonitoring()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Temperature Monitor'),
          backgroundColor: AppColors.primary,
        ),
        body: SafeArea(
          child: BlocBuilder<TemperatureBloc, TemperatureState>(
            builder: (context, state) {
              if (state is TemperatureInitial) {
                return const _InitialStateWidget();
              }
              if (state is TemperatureLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is TemperatureMonitoring) {
                return _TemperatureDisplayWidget(data: state.temperature);
              }
              if (state is TemperatureError) {
                return _ErrorWidget(message: state.message);
              }
              return Container();
            },
          ),
        ),
      ),
    );
  }
}
```

**Key UI Patterns**:
- BlocProvider creates BLoC instance with getIt<T>()
- SafeArea handles notches/system UI
- BlocBuilder rebuilds UI based on state changes
- Material Design 3 with custom AppColors
- Spanish localization by default (AppLocalizations)

## Mobile UI/UX Best Practices

### Current Project Theme

Theme is configured in `main.dart` with Material Design 3:
- **Primary Color**: `AppColors.primary` (from `theme/app_color.dart`)
- **Font**: Roboto (regular, medium, bold, italic variants)
- **Localization**: Spanish (es_MX) primary, English (en_US) fallback
- **Material 3**: `useMaterial3: true`

### Key UI Patterns Used

1. **SafeArea**: Always used for handling notches/system UI
2. **BlocBuilder**: For reactive UI updates based on state
3. **Custom Dialogs**: Bluetooth dialogs in `core/ui/bluetooth_dialogs.dart`
4. **Snackbar Service**: Global snackbar service in `core/ui/snackbar_service.dart`
5. **ShellRoute**: Persistent navigation shell with `MainShell` widget
6. **NoTransitionPage**: Used for instant page transitions
7. **AppLocalizations**: Spanish/English translation support

## Project-Specific Features

### Bluetooth Integration

The app heavily relies on Bluetooth for IoT device communication:
- **Services Used**: `flutter_bluetooth_serial`, `flutter_reactive_ble`
- **Core Service**: `BluetoothService` in `core/data/services/bluetooth_service.dart`
- **Global BLoC**: `BluetoothBloc` is a singleton (lazy) for managing connection state
- **Module BLoCs**: Temperature, Servo, LightControl, Gamepad all depend on BluetoothBloc
- **Permissions**: Handled by `PermissionService` in `core/data/services/permission_handler.dart`

### Authentication Flow

- **OTP Verification**: Pin code fields for SMS/email verification
- **Secure Storage**: Tokens stored in flutter_secure_storage
- **Token Refresh**: Automatic token refresh via interceptor
- **Session Check**: `CheckSession` use case validates token on app start
- **User Cache**: Local user data caching for offline access

### IoT Module Structure

Each IoT module (Temperature, Servo, LightControl, Gamepad) follows the same pattern:
1. **Domain**: Entity, Repository interface, Use cases (optional)
2. **Data**: Repository implementation (uses BluetoothRepository)
3. **Presentation**: BLoC, Page, Widgets
4. **Instructions**: Static images in `assets/images/static/{module}/instructions/`

## Adding New Features

### Adding a New IoT Module

1. Create feature folder: `lib/features/{module_name}/`
2. Create domain layer:
   - Entity (if needed): `domain/entities/{module}_entity.dart`
   - Repository interface: `domain/repositories/{module}_repository.dart`
   - Use cases (if complex logic): `domain/usecases/...`
3. Create data layer:
   - Repository implementation: `data/repositories/{module}_repository_impl.dart`
   - Use `BluetoothRepository` for device communication
4. Create presentation layer:
   - BLoC: `presentation/bloc/{module}_bloc.dart`, `{module}_event.dart`, `{module}_state.dart`
   - Page: `presentation/pages/{module}_page.dart`
   - Widgets: `presentation/widgets/...`
5. Register in DI (`lib/di/service_locator.dart`):
   ```dart
   // Repository
   getIt.registerLazySingleton<YourRepository>(
     () => YourRepositoryImpl(bluetoothRepository: getIt()),
   );

   // Use cases (if any)
   getIt.registerLazySingleton(() => YourUseCase(repository: getIt()));

   // BLoC (factory for new instances)
   getIt.registerFactory(() => YourBloc(
     getDataStreamUseCase: getIt(),
     sendStringUseCase: getIt(),
     bluetoothBloc: getIt(),
   ));
   ```
6. Add route in `features/home/presentation/routes/main_static_routes.dart`
7. Add module icon/card to Home menu
8. Add instruction images to `assets/images/static/{module}/instructions/`
9. Write tests (domain, data, presentation)

### Adding New Packages

```bash
# Add runtime dependency
flutter pub add package_name

# Add dev dependency
flutter pub add --dev package_name

# Update all dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## Sub-Agent Workflow

### Rules
- After a plan mode phase, create `.claude/sessions/context_session_{feature_name}.md` with plan definition
- Before working, MUST read `.claude/sessions/context_session_{feature_name}.md` and `.claude/docs/{feature_name}/*` for full context
- Session files contain overall plan and context - sub-agents continuously add to them
- After finishing work or each phase, MUST update session file so others get full context

### Sub-Agent Workflow
This project uses specialized sub-agents:

- **flutter-frontend-developer**: Flutter development, Clean Architecture, BLoC patterns, IoT module implementation
- **ui-ux-analyzer**: Mobile UI review, Material Design compliance, responsive design
- **qa-criteria-validator**: Acceptance criteria definition, feature validation, testing strategy

Sub-agents research and report feedback, but you do the actual implementation.
When delegating to sub-agent, pass the context file (`.claude/sessions/context_session_{feature_name}.md`).
After sub-agent finishes, read their documentation to get full context before executing.

## Code Writing Standards

- **Simplicity First**: Prefer simple, clean, maintainable solutions over clever ones
- **ABOUTME Comments**: All Dart files must start with 2-line comment with "ABOUTME: " prefix
  ```dart
  // ABOUTME: This file contains the User entity representing a user in the system
  // ABOUTME: It includes basic user information and validation logic
  ```
- **Minimal Changes**: Make smallest reasonable changes to achieve desired outcome
- **Style Matching**: Follow official Dart style guide and `dart format` standards
- **Preserve Comments**: Never remove comments unless provably false
- **No Temporal Naming**: Avoid 'new', 'improved', 'enhanced', 'recently' in names/comments
- **Evergreen Documentation**: Comments describe code as it is, not its history
- **Immutability**: Prefer const constructors and final fields
- **Null Safety**: Leverage Dart's sound null safety properly
- **Extensions**: Use extension methods for utility functions
- **Widget Keys**: Use keys for widget testing and performance optimization

### Dart-Specific Standards

```dart
// Good: Const constructors
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
}

// Good: Final fields
class User {
  final String id;
  final String name;
  
  const User({required this.id, required this.name});
}

// Good: Named parameters with required
void createUser({
  required String name,
  required String email,
  String? phone,
}) {}

// Good: Proper null safety
String? nullableValue;
String nonNullValue = nullableValue ?? 'default';

// Good: Extension methods
extension StringExtensions on String {
  bool get isValidEmail => contains('@') && contains('.');
}
```

## Version Control

- Non-trivial edits must be tracked in git
- Create feature branches for new work: `git checkout -b feat/user-authentication`
- Commit frequently throughout development with conventional commits:
  - `feat: add user authentication flow`
  - `fix: resolve null safety issue in user bloc`
  - `refactor: extract user validation logic`
  - `test: add unit tests for user repository`
- Never throw away implementations without explicit permission

## Testing Requirements

**IMPORTANT**: David requires comprehensive testing for ALL new features.

**NO EXCEPTIONS POLICY**: The only way to skip tests is if David EXPLICITLY states:
> "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME."

### Required Tests for New Features

1. **Unit Tests**: Domain layer (use cases, repositories with mocked dependencies)
2. **Widget Tests**: UI components and pages
3. **BLoC Tests**: State management logic (using `bloc_test` package)
4. **Integration Tests**: Critical user flows (when applicable)

### Test Structure Pattern

Create test files mirroring source structure:
```
test/
  features/
    {feature_name}/
      domain/
        usecases/
          {usecase}_test.dart
      data/
        repositories/
          {repository}_test.dart
      presentation/
        bloc/
          {bloc}_test.dart
        widgets/
          {widget}_test.dart
```

### Test Coverage Requirements

- Minimum 80% code coverage for all new code
- 100% coverage for critical business logic (auth, Bluetooth, payments)
- Mock all external dependencies (Bluetooth, API, storage)
- Test both success and failure scenarios
- Never ignore test failures or warnings

## Architecture Compliance Checklist

### Domain Layer Rules
- ✅ Zero Flutter/framework dependencies
- ✅ Repository interfaces defined before implementations
- ✅ All repository methods return `Either<Failure, Success>`
- ✅ Entities are simple classes (no Equatable, nullable/required fields as needed)
- ✅ Use cases have single responsibility

### Data Layer Rules
- ✅ Repository implementations handle exceptions → convert to Failures
- ✅ Use try-catch for external sources (Bluetooth, API, storage)
- ✅ No business logic in repositories
- ✅ Data sources injected via constructor

### Presentation Layer Rules
- ✅ All business logic in BLoCs, NOT in widgets
- ✅ BLoCs registered in `di/service_locator.dart`
- ✅ Use BlocProvider to create BLoC instances
- ✅ BlocBuilder for reactive UI updates
- ✅ SafeArea for handling notches/system UI
- ✅ Material Design 3 components
- ✅ Spanish localization (AppLocalizations)

### Dependency Injection Rules
- ✅ Manual registration in `lib/di/service_locator.dart` (NO @injectable)
- ✅ Singleton services: `registerLazySingleton`
- ✅ Feature BLoCs: `registerFactory` (new instance each time)
- ✅ Global BLoCs: `registerLazySingleton` (BluetoothBloc, AuthBloc, ChatBloc)
- ✅ All dependencies injected via constructor

### Error Handling Rules
- ✅ Use Equatable ONLY for Failure classes
- ✅ Define specific Failure types (BluetoothFailure, ServerFailure, etc.)
- ✅ Map Failures to user-friendly messages in BLoCs
- ✅ Display errors in UI with retry options

## Code Writing

- YOU MUST ALWAYS address me as "David" in all communications.
- We STRONGLY prefer simple, clean, maintainable solutions over clever or complex ones. Readability and maintainability are PRIMARY CONCERNS.
- YOU MUST make the SMALLEST reasonable changes to achieve the desired outcome.
- YOU MUST MATCH the Dart style guide and existing code formatting patterns.
- YOU MUST NEVER make code changes unrelated to your current task.
- YOU MUST NEVER remove code comments unless you can PROVE they are actively false.
- All Dart files MUST start with a brief 2-line comment explaining what the file does. Each line MUST start with "ABOUTME: "
- YOU MUST NEVER refer to temporal context in comments (like "recently refactored").
- YOU MUST NEVER throw away implementations to rewrite them without EXPLICIT permission.
- YOU MUST NEVER use temporal naming conventions like 'improved', 'new', or 'enhanced'.
- YOU MUST follow Dart formatting: `dart format lib/ test/`

## Getting Help

- Always ask for clarification rather than making assumptions
- Stop and ask for help when stuck, especially when human input would be valuable
- If considering an exception to any rule, stop and get explicit permission from David first
- Use `flutter doctor` to diagnose setup issues
- Check `flutter doctor -v` for detailed environment information

## Pre-Submission Compliance Check

Before submitting any work, verify ALL guidelines:

- [ ] Clean Architecture layers properly separated (domain, data, presentation)
- [ ] BLoC pattern correctly implemented (classic Bloc<Event, State>)
- [ ] Dependencies registered in `lib/di/service_locator.dart` with get_it
- [ ] Either pattern used for error handling (dartz)
- [ ] Unit tests for domain layer written
- [ ] Widget tests for UI components written
- [ ] BLoC tests for state management written
- [ ] Test coverage >80% for new code
- [ ] ABOUTME comments added to all new Dart files
- [ ] Code formatted: `dart format lib/ test/`
- [ ] No analysis errors: `flutter analyze`
- [ ] Material Design 3 guidelines followed
- [ ] SafeArea properly used
- [ ] Spanish/English localization supported
- [ ] Bluetooth integration follows existing patterns (if applicable)

**If you consider ANY exception to these rules, STOP and get explicit permission from David first.**

## Quick Reference Summary

### Project Characteristics
- **Type**: Flutter IoT education app (Temperature, Servo, LED, Gamepad modules)
- **Architecture**: Clean Architecture (Domain, Data, Presentation)
- **State**: BLoC pattern with flutter_bloc
- **DI**: Manual get_it registration in `di/service_locator.dart`
- **Bluetooth**: Core feature using flutter_bluetooth_serial + flutter_reactive_ble
- **Auth**: JWT tokens, OTP verification, secure storage
- **Navigation**: GoRouter with ShellRoute
- **Localization**: Spanish (primary), English (fallback)
- **Theme**: Material Design 3, custom AppColors
- **Target**: Android/iOS (compileSdk 35)

### Key Files to Know
- `lib/main.dart` - App entry point, DI initialization
- `lib/di/service_locator.dart` - Dependency injection registry
- `lib/core/router/app_router.dart` - Navigation configuration
- `lib/core/network/dio_client.dart` - API client with interceptors
- `lib/core/data/services/bluetooth_service.dart` - Bluetooth core service
- `lib/core/error/failure.dart` - Failure types (Equatable)
- `lib/theme/app_color.dart` - App color palette

### Common Commands
```bash
flutter run                    # Run app
flutter test --coverage        # Run tests with coverage
flutter analyze               # Static analysis
dart format lib/ test/        # Format code
flutter clean && flutter pub get  # Clean rebuild
```
