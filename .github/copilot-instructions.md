# Makers Lab - AI Agent Instructions

## Project Overview
Flutter IoT application for educational Bluetooth device control (ESP32). Uses **Clean Architecture** with strict layer separation following refactored patterns documented in `ARCHITECTURE_IMPROVEMENT.md` and `BEFORE_AFTER_COMPARISON.md`.

**Target Platforms**: Android & iOS (primary), Windows/Linux/Web (rarely)  
**Flutter Version**: 3.7.2+ with Dart SDK 3.5+

## Code Writing Standards (CRITICAL)

### Universal Rules
- **Simplicity First**: Prefer clean, maintainable solutions over clever ones
- **ABOUTME Comments**: ALL Dart files MUST start with 2-line comment:
  ```dart
  // ABOUTME: This file contains the GetCombinedMenu use case
  // ABOUTME: It merges local and remote menu items based on auth status
  ```
- **Minimal Changes**: Make smallest reasonable changes to achieve desired outcome
- **Style Matching**: Follow `dart format` and official Dart style guide
- **Preserve Comments**: Never remove comments unless provably false
- **No Temporal Naming**: Avoid 'new', 'improved', 'enhanced' in names/comments
- **Immutability**: Prefer `const` constructors and `final` fields
- **Null Safety**: Leverage Dart's sound null safety properly

### Dart-Specific Patterns
```dart
// ✅ Good: Const constructors and final fields
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
}

class User {
  final String id;
  final String name;
  const User({required this.id, required this.name});
}

// ✅ Good: Named parameters with required
void createUser({
  required String name,
  required String email,
  String? phone,
}) {}

// ✅ Good: Extension methods for utilities
extension StringExtensions on String {
  bool get isValidEmail => contains('@') && contains('.');
}
```

## Architecture Fundamentals

### Layer Structure (CRITICAL - Never Violate)
```
Presentation (UI) → Domain (Business Logic) → Data (External Sources)
```

**Rule**: Business logic belongs in **Domain layer UseCases**, NOT in BLoCs or UI.

### Feature Module Organization
```
lib/features/{feature_name}/
├── data/
│   ├── datasources/     # Remote/local data access
│   ├── models/          # JSON serialization (extends entities)
│   └── repository/      # Repository implementations
├── domain/
│   ├── entities/        # Pure business objects (no toJson/fromJson)
│   ├── repositories/    # Abstract contracts
│   └── usecases/        # Single-responsibility business logic
└── presentation/
    ├── bloc/            # State management (delegates to UseCases)
    ├── pages/           # Screen widgets
    └── widgets/         # Reusable UI components
```

### Core Shared Components
- `lib/core/error/` - `Failure` hierarchy (Equatable-based), `Exception` types
- `lib/core/network/` - `DioClient` with auth/error interceptors
- `lib/core/router/` - `go_router` config with `ShellRoute` for bottom nav
- `lib/core/domain/repositories/base_repository.dart` - `safeCall()` for error handling
- `lib/core/presentation/bloc/bluetooth/` - Global Bluetooth state (BLE/Serial)
- `lib/di/service_locator.dart` - GetIt dependency injection setup

## Critical Patterns & Anti-Patterns

### ✅ DO: UseCase-Driven Architecture (See `GetCombinedMenu`)
**Example**: `lib/features/home/domain/usecases/get_combined_menu.dart`
```dart
class GetCombinedMenu {
  final HomeRepository homeRepository;
  final CheckSession checkSession;

  Future<Either<Failure, List<MainMenuItemModel>>> call() async {
    // 1. Business logic here (auth checks, data merging, etc.)
    final localMenuResult = await homeRepository.getMainMenu();
    final isAuthenticated = await checkSession();
    
    // 2. Graceful degradation on remote failures
    if (isAuthenticated) {
      final remoteResult = await homeRepository.getRemoteMenuItems();
      return remoteResult.fold(
        (failure) => Right(localMenu), // Fallback to local
        (remote) => Right([...localMenu, ...remote]),
      );
    }
    return Right(localMenu);
  }
}
```

**BLoC delegates to UseCase** (no business logic in presentation):
```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCombinedMenu getCombinedMenu;

  HomeBloc({required this.getCombinedMenu}) : super(HomeInitial());

  Future<void> _onLoad(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    final result = await getCombinedMenu();
    result.fold(
      (failure) => emit(HomeFailure(error: failure.message)),
      (items) => emit(HomeSuccess(items: items)),
    );
  }
}
```

### ❌ DON'T: Business Logic in Presentation
**NEVER do** (see `BEFORE_AFTER_COMPARISON.md` for anti-pattern examples):
- Check auth status in `initState()` or widgets
- Pass business flags like `isAuthenticated` in events
- Nest multiple async `fold()` operations in BLoCs
- Access other BLoCs via `context.read<AuthBloc>()` for business decisions

## Dependency Injection (GetIt)

### Registration Pattern (`lib/di/service_locator.dart`)
```dart
Future<void> setupLocator() async {
  // 1. External dependencies first
  getIt.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
  getIt.registerLazySingleton<Dio>(() => DioClient(...).dio);
  
  // 2. Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(dio: getIt()));
  
  // 3. Repositories
  getIt.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(
    localDatasource: getIt(),
    remoteDatasource: getIt(),
  ));
  
  // 4. UseCases
  getIt.registerLazySingleton(() => GetCombinedMenu(
    homeRepository: getIt(),
    checkSession: getIt(),
  ));
  
  // 5. BLoCs (Factory - new instance per request)
  getIt.registerFactory(() => HomeBloc(getCombinedMenu: getIt()));
}
```

### Global BLoCs in `main.dart`
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus()), lazy: false),
    BlocProvider(create: (_) => getIt<BluetoothBloc>()),
    BlocProvider(create: (_) => getIt<ChatBloc>()),
  ],
  child: const MyApp(),
)
```

### Per-Route BLoCs (GoRouter)
```dart
GoRoute(
  path: HomePage.routeName,
  pageBuilder: (context, state) => NoTransitionPage(
    child: BlocProvider<HomeBloc>(
      create: (_) => getIt<HomeBloc>(),
      child: const HomePage(),
    ),
  ),
)
```

## Data Layer Patterns

### Error Handling with `Either<Failure, T>` (dartz)
All repository methods return `Either<Failure, T>`. Use `BaseRepository.safeCall()`:
```dart
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> signIn(String email, String password) {
    return safeCall<User>(() async {
      final response = await remoteDataSource.signIn(email, password);
      await tokenLocalDataSource.cacheTokens(response.jwt);
      return response.data!;
    });
  }
}
```

### Model vs Entity Pattern
- **Entities** (`domain/entities/`): Simple classes with nullable fields, no JSON logic, no Equatable
  ```dart
  class User {
    String? id;
    String? name;
    String? email;
    
    User({this.id, this.name, this.email});
  }
  ```
- **Models** (`data/models/`): Extend entities, add `fromJson()`/`toJson()`, no Equatable
  ```dart
  class UserModel extends User {
    UserModel({super.id, super.name, super.email});
    
    factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
      id: json["id"],
      name: json["name"],
      email: json["email"],
    );
    
    Map<String, dynamic> toJson() => {
      "id": id,
      "name": name,
      "email": email,
    };
  }
  ```

Example: `MainMenuItemModel extends MainMenuItem`, `UserModel extends User`

### Secure Storage for Tokens
Use `ISecureStorageService` wrapper around `FlutterSecureStorage`:
```dart
await tokenLocalDataSource.cacheTokens(
  accessToken: jwt,
  refreshToken: jwt,
);
```

## State Management (BLoC)

### Event Naming
- `LoadHomeData`, `SendMessage`, `ConnectDevice` (imperative verbs)
- Keep events simple - no business logic flags

### State Pattern (Traditional State Classes)
```dart
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeSuccess extends HomeState {
  final List<MainMenuItemModel> items;
  HomeSuccess({required this.items});
}

class HomeFailure extends HomeState {
  final String error;
  HomeFailure({required this.error});
}
```

### Event Pattern (Simple Abstract Classes)
```dart
abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}

class UpdateItem extends HomeEvent {
  final String itemId;
  UpdateItem(this.itemId);
}
```

### UI Consumption
```dart
BlocBuilder<HomeBloc, HomeState>(
  builder: (context, state) {
    if (state is HomeLoading) return LoadingWidget();
    if (state is HomeFailure) return ErrorWidget(state.error);
    if (state is HomeSuccess) return SuccessView(state.items);
    return Container();
  },
)
```

## Navigation (GoRouter)

### Route Definition
- Paths in `lib/core/router/router_paths.dart`
- Routes in `lib/features/{feature}/presentation/routes/`
- Shell route for bottom nav: `main_shell.dart`

### Navigation Commands
```dart
context.go(HomePage.routeName);
context.push(ProfilePage.routeName);
context.pop();
```

## Bluetooth Architecture (Critical for IoT Features)

### Global Bluetooth State
- `BluetoothBloc` registered globally in `main.dart`
- Access via `context.read<BluetoothBloc>()`
- Events: `DiscoverDevices`, `ConnectToDevice`, `DisconnectDevice`, `SendData`

### Feature-Specific Bluetooth Integration
IoT features (temperature, servo, gamepad, light_control) use:
1. `BluetoothRepository` for device I/O
2. Feature-specific repository (e.g., `ServoRepository`) wraps Bluetooth calls
3. BLoC listens to Bluetooth data streams

Example pattern:
```dart
class ServoBloc extends Bloc<ServoEvent, ServoState> {
  final GetBluetoothDataStream getDataStream;
  final SendServoPosition sendPosition;
  
  StreamSubscription? _subscription;
  
  Future<void> _onListen(ListenToData event, Emitter emit) async {
    _subscription = (await getDataStream()).listen((data) {
      add(UpdateServoPosition(parsePosition(data)));
    });
  }
}
```

## Testing & Development

### Testing Requirements (NO EXCEPTIONS)
**CRITICAL**: All features MUST have tests unless David explicitly states: "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME."

Required test coverage:
- **Unit tests**: Domain layer (UseCases, entities) - 100% for business logic
- **BLoC tests**: State transitions and event handling - use `bloc_test`
- **Widget tests**: UI components with `flutter_test`
- **Minimum coverage**: 80% across all layers

### Test Structure Examples
```dart
// BLoC Test
blocTest<UserBloc, UserState>(
  'emits [UserLoading, UserLoaded] when LoadUsersEvent is added',
  build: () {
    when(mockGetUsersUseCase(any))
        .thenAnswer((_) async => Right([user]));
    return bloc;
  },
  act: (bloc) => bloc.add(const LoadUsersEvent()),
  expect: () => [const UserLoading(), UserLoaded(users: [user])],
  verify: (_) => verify(mockGetUsersUseCase(NoParams())).called(1),
);

// Widget Test
testWidgets('UserCard displays user information', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: UserCard(user: testUser)),
  ));
  expect(find.text('John Doe'), findsOneWidget);
  expect(find.text('john@example.com'), findsOneWidget);
});
```

### Running Tests
```powershell
flutter test                                    # Run all tests
flutter test --coverage                         # Generate coverage
flutter test test/features/auth/               # Test specific feature
flutter test --name "BLoC"                     # Filter by name
```

### No Unit Tests Currently
Tests should follow feature structure when added:
```
test/features/{feature}/
├── data/models/          # Model serialization tests
├── domain/usecases/      # UseCase logic tests
└── presentation/bloc/    # BLoC state transition tests
```

## Mobile UI/UX Best Practices

### Material Design 3 Guidelines
1. **Responsive Design**: Support phones and tablets
   ```dart
   final size = MediaQuery.of(context).size;
   final isTablet = size.width > 600;
   ```

2. **Safe Areas**: Handle notches and system UI
   ```dart
   Scaffold(body: SafeArea(child: YourContent()))
   ```

3. **Touch Targets**: Minimum 48x48 dp for interactive elements

4. **Loading States**: Show feedback for async operations
   ```dart
   BlocBuilder<HomeBloc, HomeState>(
     builder: (context, state) {
       if (state is HomeLoading) return CircularProgressIndicator();
       if (state is HomeFailure) return ErrorWidget(state.error);
       if (state is HomeSuccess) return SuccessView(state.items);
       return Container();
     },
   )
   ```

5. **Platform Integration**: Use platform channels when needed
   ```dart
   import 'dart:io' show Platform;
   if (Platform.isIOS) {
     return CupertinoButton(...);
   }
   return ElevatedButton(...);
   ```

### Running the App
```powershell
flutter pub get
flutter run
# For specific platforms:
flutter run -d windows
flutter run -d chrome
flutter run -d <android-device-id>
```

### Build & Generate
```powershell
flutter pub run flutter_launcher_icons  # Update app icons
flutter gen-l10n                        # Generate localizations
flutter build apk --release
flutter pub run build_runner build      # Code generation (json_serializable, etc.)
dart format lib/ test/                  # Format code
flutter analyze                         # Check for issues
```

## Code Quality & Analysis

### Pre-Commit Checklist
```powershell
dart format .                           # Format all Dart files
flutter analyze --fatal-infos           # Zero warnings policy
flutter test --coverage                 # Run tests with coverage
```

### ABOUTME Comments Required
Every Dart file MUST start with:
```dart
// ABOUTME: This file contains the User authentication BLoC
// ABOUTME: It handles login, logout, and session management events
```

## Localization
- ARB files: `lib/l10n/app_*.arb`
- Generated: `AppLocalizations.of(context)!.welcomeMessage`
- Default: Spanish Mexico (`es_MX`)

## Common Tasks

### Adding a New Feature Module
1. Create folder: `lib/features/{feature_name}/`
2. Add `data/`, `domain/`, `presentation/` subdirectories
3. Define entity in `domain/entities/`
4. Create UseCase in `domain/usecases/`
5. Implement repository in `data/repository/`
6. Create BLoC in `presentation/bloc/`
7. Register in `service_locator.dart`
8. Add routes to `app_router.dart`

### Adding API Endpoint
1. Define method in remote datasource interface
2. Implement in datasource `_impl` with Dio (auto-handles auth via interceptors)
3. Add repository method calling datasource via `safeCall()`
4. Create/update UseCase consuming repository
5. Call UseCase from BLoC

### Debugging BLoC Issues
- Enable `SimpleBlocObserver` in `main.dart` (already active)
- Check for "emit after completion" errors → avoid nested async `fold()` calls
- Verify UseCase returns `Either<Failure, T>`, not plain `Future`

## Style Conventions
- Material Symbols Icons preferred (`material_symbols_icons`)
- Custom colors in `lib/theme/app_color.dart`
- Roboto font family (configured in `pubspec.yaml`)
- Spanish UI text by default
- Use `debugPrint()` in development, `logger` for production

## Key Dependencies
- **flutter_bloc**: State management
- **get_it**: Dependency injection
- **go_router**: Navigation
- **dartz**: Functional error handling (`Either`)
- **dio**: HTTP client with interceptors
- **flutter_secure_storage**: Token storage
- **equatable**: Value equality for Failures (error handling only)
- **flutter_bluetooth_serial** + **flutter_reactive_ble**: Bluetooth communication
- **syncfusion_flutter_gauges**: IoT data visualization

## Resources
- Architecture rationale: `ARCHITECTURE_IMPROVEMENT.md`
- Before/after anti-patterns: `BEFORE_AFTER_COMPARISON.md`
- Dependency injection: `lib/di/service_locator.dart`
- Base error handling: `lib/core/domain/repositories/base_repository.dart`
- Detailed patterns: `CLAUDE.md` (comprehensive architecture guide)

## Version Control & Workflow

### Branch Naming Convention
- **Features**: `feat/user-authentication`
- **Fixes**: `fix/bluetooth-connection-error`
- **Refactors**: `refactor/clean-architecture-home`

### Commit Message Format (Conventional Commits)
```bash
feat: add user authentication flow
fix: resolve null safety issue in user bloc
refactor: extract user validation logic
test: add unit tests for user repository
docs: update architecture documentation
```

### Development Workflow
1. Create feature branch from `develop`
2. Implement feature following Clean Architecture
3. Write tests (unit, widget, BLoC) - **MANDATORY**
4. Run `dart format .` and `flutter analyze`
5. Commit with conventional commits
6. Create PR with reference to issue/requirements

## Communication Standards

- **Address David by name** in all communications
- **Ask for clarification** rather than making assumptions
- **Stop and ask for help** when stuck - human input is valuable
- **Get explicit permission** before making architectural changes
- **Never throw away implementations** without permission

## Architecture Compliance Checklist

Before submitting code, verify:
- [ ] Clean Architecture layers properly separated
- [ ] Business logic in Domain UseCases, not BLoCs
- [ ] All dependencies injected via GetIt
- [ ] `Either<Failure, T>` pattern used for error handling
- [ ] ABOUTME comments added to all new files
- [ ] Tests written (unit, widget, BLoC) with >80% coverage
- [ ] `dart format .` applied
- [ ] `flutter analyze` passes with zero warnings
- [ ] No business logic in presentation layer
- [ ] Material Design 3 guidelines followed
- [ ] Responsive design for mobile screens
- [ ] Entities and Models are simple classes (no Equatable)
- [ ] Only Failures use Equatable for error handling
