# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application (Android/iOS) implementing Clean Architecture with separation of concerns across Domain, Data, and Presentation layers. The application demonstrates best practices in Flutter development with SOLID principles, modern state management patterns (BLoC), and comprehensive Material Design UI/UX standards optimized for mobile devices.

## Architecture

### Tech Stack
- **Framework**: Flutter 3.24+ with Dart 3.5+
- **Target Platforms**: Android & iOS (primary), Windows/Linux/Web (rarely)
- **Architecture**: Clean Architecture (Domain, Data, Presentation)
- **State Management**: BLoC Pattern (classic Bloc<Event, State>) with flutter_bloc
- **Dependency Injection**: get_it with injectable for service locator pattern
- **Navigation**: GoRouter or Auto Route for type-safe declarative routing
- **Testing**: flutter_test, mockito, bloc_test, integration_test
- **UI Components**: Material Design 3 with custom theming and responsive layouts
- **Networking**: dio with retrofit for type-safe REST API calls
- **Local Storage**: sqflite (SQLite), hive (NoSQL), shared_preferences (key-value)
- **Form Validation**: reactive_forms or form_builder_validators
- **Image Handling**: cached_network_image with image optimization
- **Animations**: Built-in Flutter animations and lottie for complex animations

### Clean Architecture Layers

The codebase follows strict Clean Architecture with clear separation of concerns:

#### Project Structure
```
lib/
  core/                    # Shared utilities and base classes
    constants/             # App-wide constants (colors, strings, endpoints)
    error/                 # Error handling (failures, exceptions)
    usecases/              # Base UseCase interface
    utils/                 # Helper functions and extensions
    network/               # Network info and connectivity
    theme/                 # Material Design 3 theme configuration
    
  features/                # Feature-based organization
    {feature_name}/
      domain/              # Core business logic (framework-agnostic)
        entities/          # Business objects with identity
        repositories/      # Repository interfaces (contracts)
        usecases/          # Business use cases
        
      data/                # Data layer (external concerns)
        models/            # Data models extending entities
        datasources/       # Remote (API) and Local (DB) data sources
        repositories/      # Repository implementations
        
      presentation/        # UI layer
        bloc/              # BLoC state management
          {feature}_bloc.dart
          {feature}_event.dart
          {feature}_state.dart
        pages/             # Screen-level widgets
        widgets/           # Reusable feature-specific widgets
        
  injection_container.dart # Dependency injection setup (get_it)
  main.dart                # App entry point
  app.dart                 # MaterialApp configuration

assets/
  images/                  # Image assets (PNG, JPG, SVG)
  fonts/                   # Custom fonts
  animations/              # Lottie animations

test/
  features/                # Feature tests (unit, widget, bloc)
  integration_test/        # End-to-end integration tests
```

### Key Architectural Principles

1. **Dependency Rule**: All dependencies point inward. Domain has zero dependencies on infrastructure or Flutter.
2. **Single Responsibility**: Each class has one reason to change
3. **Dependency Injection**: All dependencies injected via constructors using get_it
4. **Repository Pattern**: Domain defines interfaces, Data implements them
5. **Either Pattern**: Use dartz package for functional error handling (Either<Failure, Success>)
6. **BLoC Pattern**: Strict separation of business logic from UI using classic Bloc<Event, State>

### Path Structure (pubspec.yaml)

No path aliases in Flutter - use relative imports or package imports:
```dart
// Core imports
import 'package:app_name/core/error/failures.dart';
import 'package:app_name/core/usecases/usecase.dart';

// Feature imports
import 'package:app_name/features/user/domain/entities/user.dart';
import 'package:app_name/features/user/data/models/user_model.dart';
import 'package:app_name/features/user/presentation/bloc/user_bloc.dart';
```

## Development Commands

### Running the Application

```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run with flavor (dev/staging/prod)
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart

# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android - recommended for Play Store)
flutter build appbundle --release

# Build IPA (iOS - requires Mac)
flutter build ios --release

# Clean build artifacts
flutter clean
```

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/user/domain/usecases/get_users_test.dart

# Run integration tests
flutter test integration_test/app_test.dart

# Run widget tests
flutter test --name widget

# Generate test coverage report (HTML)
genhtml coverage/lcov.info -o coverage/html
```

### Code Quality & Analysis

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/ test/

# Fix formatting issues automatically
dart fix --apply

# Run custom lint rules (if using flutter_lints)
flutter analyze --fatal-infos --fatal-warnings
```

### Code Generation

```bash
# Generate code for json_serializable, freezed, etc.
flutter pub run build_runner build

# Watch mode for continuous generation
flutter pub run build_runner watch

# Delete conflicting outputs and rebuild
flutter pub run build_runner build --delete-conflicting-outputs
```

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

## Environment Variables

Configuration in `lib/core/config/env_config.dart`:
```dart
class EnvConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
  
  static const String apiKey = String.fromEnvironment('API_KEY');
}
```

Run with environment variables:
```bash
flutter run --dart-define=API_BASE_URL=https://api.dev.com --dart-define=API_KEY=your_key
```

## Mobile-Specific Architecture Patterns

### 1. BLoC State Management Pattern

**Event Definition**:
```dart
// presentation/bloc/user/user_event.dart
abstract class UserEvent {}

class LoadUsersEvent extends UserEvent {
  const LoadUsersEvent();
}

class CreateUserEvent extends UserEvent {
  final CreateUserRequest request;
  
  const CreateUserEvent({required this.request});
}
```

**State Definition**:
```dart
// presentation/bloc/user/user_state.dart
abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<User> users;
  
  UserLoaded({required this.users});
}

class UserError extends UserState {
  final String message;
  
  UserError({required this.message});
}
```

**BLoC Implementation**:
```dart
// presentation/bloc/user/user_bloc.dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUsersUseCase getUsersUseCase;
  final CreateUserUseCase createUserUseCase;

  UserBloc({
    required this.getUsersUseCase,
    required this.createUserUseCase,
  }) : super(UserInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<CreateUserEvent>(_onCreateUser);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    
    final result = await getUsersUseCase(NoParams());
    
    result.fold(
      (failure) => emit(UserError(message: _mapFailureToMessage(failure))),
      (users) => emit(UserLoaded(users: users)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Error. Please try again later.';
      case NetworkFailure:
        return 'No Internet Connection';
      default:
        return 'Unexpected Error';
    }
  }
}
```

### 2. Domain Layer (Business Logic)

**Entity**:
```dart
// domain/entities/user.dart
class User {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  bool? isActive;

  User({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.isActive,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
```

**Repository Interface**:
```dart
// domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<Either<Failure, List<User>>> getUsers();
  Future<Either<Failure, User>> getUserById(String id);
  Future<Either<Failure, User>> createUser(CreateUserRequest request);
  Future<Either<Failure, void>> deleteUser(String id);
}
```

**Use Case**:
```dart
// domain/usecases/get_users_usecase.dart
class GetUsersUseCase implements UseCase<List<User>, NoParams> {
  final UserRepository repository;

  GetUsersUseCase({required this.repository});

  @override
  Future<Either<Failure, List<User>>> call(NoParams params) async {
    return await repository.getUsers();
  }
}
```

### 3. Data Layer (Infrastructure)

**Data Model**:
```dart
// data/models/user_model.dart
class UserModel extends User {
  UserModel({
    super.id,
    super.firstName,
    super.lastName,
    super.email,
    super.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    firstName: json['first_name'],
    lastName: json['last_name'],
    email: json['email'],
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'is_active': isActive,
  };
}
```

**Repository Implementation**:
```dart
// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<User>>> getUsers() async {
    if (await networkInfo.isConnected) {
      try {
        final users = await remoteDataSource.getUsers();
        await localDataSource.cacheUsers(users);
        return Right(users);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final cachedUsers = await localDataSource.getCachedUsers();
        return Right(cachedUsers);
      } on CacheException {
        return const Left(CacheFailure(message: 'No cached data'));
      }
    }
  }
}
```

### 4. Presentation Layer (UI)

**Page Widget**:
```dart
// presentation/pages/users_page.dart
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateUserDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserInitial) return const _EmptyStateWidget();
          if (state is UserLoading) return const Center(child: CircularProgressIndicator());
          if (state is UserLoaded) return _UserListWidget(users: state.users);
          if (state is UserError) return _ErrorWidget(message: state.message);
          return Container();
        },
      ),
    );
  }
}
```

## Mobile UI/UX Best Practices

### Material Design 3 Guidelines

1. **Theme Configuration**:
```dart
// core/theme/app_theme.dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
```

2. **Responsive Design**:
```dart
// Use MediaQuery for responsive layouts
class ResponsiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return isTablet ? TabletLayout() : MobileLayout();
  }
}
```

3. **Safe Area Handling**:
```dart
// Always wrap content in SafeArea for notch/status bar
Scaffold(
  body: SafeArea(
    child: YourContent(),
  ),
);
```

4. **Touch Target Sizes**:
- Minimum 48x48 dp for interactive elements
- Use `MaterialButton`, `IconButton`, `FloatingActionButton`
- Provide adequate spacing between touch targets

5. **Loading States**:
```dart
// Show loading indicators for async operations
if (state is Loading)
  const Center(child: CircularProgressIndicator())
else if (state is Loaded)
  YourContent()
```

6. **Error Handling UI**:
```dart
// Display user-friendly error messages
if (state is Error)
  ErrorWidget(
    message: state.message,
    onRetry: () => context.read<Bloc>().add(RetryEvent()),
  )
```

7. **Navigation Patterns**:
```dart
// Use proper navigation for mobile
// Bottom navigation for 3-5 primary destinations
// Drawer for 5+ destinations or settings
// Tabs for related content groupings
```

8. **Form Validation**:
```dart
// Provide immediate, inline validation feedback
TextFormField(
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Required field';
    if (!value!.contains('@')) return 'Invalid email';
    return null;
  },
  decoration: InputDecoration(
    labelText: 'Email',
    helperText: 'Enter your email address',
    errorMaxLines: 2,
  ),
);
```

### Platform-Specific Considerations

**Android**:
- Material Design 3 components
- Back button navigation support
- Navigation drawer for menus
- Bottom navigation bar
- Floating action buttons (FAB)

**iOS**:
- Cupertino widgets when appropriate
- Swipe-back gesture support
- Bottom tab bar navigation
- Use `CupertinoPageScaffold` for iOS-specific screens

**Cross-platform**:
```dart
// Use Platform.isIOS / Platform.isAndroid for platform-specific behavior
import 'dart:io';

Widget buildButton() {
  if (Platform.isIOS) {
    return CupertinoButton(child: Text('Button'), onPressed: () {});
  }
  return ElevatedButton(child: Text('Button'), onPressed: () {});
}
```

## Key Technical Details

### Dependency Injection Setup

```dart
// injection_container.dart
final sl = GetIt.instance;

Future<void> init() async {
  //! Features - User
  // Bloc
  sl.registerFactory(() => UserBloc(
    getUsersUseCase: sl(),
    createUserUseCase: sl(),
  ));
  
  // Use cases
  sl.registerLazySingleton(() => GetUsersUseCase(repository: sl()));
  sl.registerLazySingleton(() => CreateUserUseCase(repository: sl()));
  
  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  
  // Data sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sharedPreferences: sl()),
  );
  
  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  
  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
}
```

### Main Entry Point

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init(); // Initialize dependency injection
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Clean Architecture',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: BlocProvider(
        create: (_) => sl<UserBloc>()..add(const LoadUsersEvent()),
        child: const UsersPage(),
      ),
    );
  }
}
```

## Adding New Features

### Adding a New Feature

1. Create feature folder structure in `lib/features/{feature_name}/`
2. Define domain entities and repository interfaces
3. Implement use cases in domain layer
4. Create data models and repository implementations
5. Implement BLoC for state management
6. Build UI pages and widgets
7. Register dependencies in `injection_container.dart`
8. Write comprehensive tests

### Adding New Packages

```bash
# Add package to pubspec.yaml
flutter pub add package_name

# Add dev dependency (testing)
flutter pub add --dev package_name

# Update dependencies
flutter pub upgrade
```

Common packages:
- `flutter_bloc`: State management
- `get_it`: Dependency injection
- `dartz`: Functional programming (Either)
- `equatable`: Value equality for Failures only
- `dio`: HTTP client
- `shared_preferences`: Simple storage
- `sqflite`: SQLite database
- `cached_network_image`: Image caching
- `go_router`: Navigation

## Sub-Agent Workflow

### Rules
- After a plan mode phase you should create a `.claude/sessions/context_session_{feature_name}.md` with the definition of the plan
- Before you do any work, MUST view files in `.claude/sessions/context_session_{feature_name}.md` file and `.claude/doc/{feature_name}/*` files to get the full context
- `.claude/sessions/context_session_{feature_name}.md` should contain most of context of what we did, overall plan, and sub agents will continuously add context to the file
- After you finish the work, MUST update the `.claude/sessions/context_session_{feature_name}.md` file to make sure others can get full context of what you did
- After you finish each phase, MUST update the `.claude/sessions/context_session_{feature_name}.md` file to make sure others can get full context of what you did

### Sub-Agent Workflow
This project uses specialized sub-agents for different concerns. Always consult the appropriate agent:

- **flutter-frontend-developer**: Flutter feature development, Clean Architecture implementation, BLoC patterns
- **ui-ux-analyzer**: Mobile UI review, Material Design compliance, responsive design validation
- **qa-criteria-validator**: Acceptance criteria definition, feature validation, testing strategy
- **backend-architect**: API design, backend integration patterns (when applicable)

Sub agents will do research about the implementation and report feedback, but you will do the actual implementation.
When passing task to sub agent, make sure you pass the context file, e.g. `.claude/sessions/context_session_{feature_name}.md`.
After each sub agent finishes the work, make sure you read the related documentation they created to get full context of the plan before you start executing.

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

**NO EXCEPTIONS POLICY**: All projects MUST have:
- Unit tests for domain layer (use cases, entities)
- Widget tests for UI components
- BLoC tests for state management
- Integration tests for critical user flows

The only way to skip tests: David EXPLICITLY states "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME."

### Test Structure

```dart
// Unit Test Example
void main() {
  late GetUsersUseCase usecase;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    usecase = GetUsersUseCase(repository: mockRepository);
  });

  group('GetUsersUseCase', () {
    test('should return list of users from repository', () async {
      // arrange
      final users = [
        User(
          id: '1',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          isActive: true,
        )
      ];
      when(mockRepository.getUsers())
          .thenAnswer((_) async => Right(users));
      
      // act
      final result = await usecase(NoParams());
      
      // assert
      expect(result, Right(users));
      verify(mockRepository.getUsers());
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

```dart
// Widget Test Example
void main() {
  testWidgets('UserCard displays user information', (tester) async {
    // arrange
    final user = User(
      id: '1',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      isActive: true,
    );
    
    // act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserCard(user: user),
        ),
      ),
    );
    
    // assert
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john@example.com'), findsOneWidget);
  });
}
```

```dart
// BLoC Test Example
void main() {
  late UserBloc bloc;
  late MockGetUsersUseCase mockGetUsersUseCase;

  setUp(() {
    mockGetUsersUseCase = MockGetUsersUseCase();
    bloc = UserBloc(getUsersUseCase: mockGetUsersUseCase);
  });

  blocTest<UserBloc, UserState>(
    'emits [UserLoading, UserLoaded] when LoadUsersEvent is added',
    build: () {
      when(mockGetUsersUseCase(any))
          .thenAnswer((_) async => Right([user]));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadUsersEvent()),
    expect: () => [
      UserLoading(),
      UserLoaded(users: [user]),
    ],
  );
}
```

### Test Coverage Requirements

- Tests must comprehensively cover ALL functionality
- Test output must be pristine to pass
- Minimum 80% code coverage for all layers
- 100% coverage for critical business logic
- Mock all external dependencies
- Never ignore test failures or warnings

## Architecture Compliance

When writing Flutter code:

1. **Keep Domain Pure**: Zero Flutter/framework dependencies in `domain/`
2. **Define Interfaces First**: Repository interfaces in domain before implementations
3. **Use Either Pattern**: All repository methods return `Either<Failure, Success>`
4. **BLoC Pattern**: All business logic in BLoCs, not in widgets
5. **Dependency Injection**: All dependencies injected via constructors using get_it
6. **Immutability**: Use final fields where appropriate (especially in models/states)
7. **Simple Classes**: Entities and Models are simple classes with nullable fields (no Equatable)
8. **Equatable for Failures**: Only use Equatable for Failure classes in error handling
9. **Single Responsibility**: Each widget, class, and function has one purpose

When writing mobile UI:

1. **Material Design 3**: Follow Material Design guidelines for Android
2. **Responsive Design**: Support multiple screen sizes (phones, tablets)
3. **Safe Areas**: Always handle notches and system UI
4. **Touch Targets**: Minimum 48x48 dp for all interactive elements
5. **Loading States**: Show appropriate feedback for async operations
6. **Error Handling**: Display user-friendly error messages with retry options
7. **Accessibility**: Support screen readers and dynamic font sizes
8. **Platform Conventions**: Follow Android and iOS platform guidelines

## Mobile-Specific Guidelines

### Performance Optimization

1. **Use const widgets** whenever possible
2. **Implement keys** for ListView/GridView items
3. **Cache images** with cached_network_image
4. **Lazy load data** with pagination
5. **Optimize build methods** - keep them pure and fast
6. **Use RepaintBoundary** for complex animations
7. **Profile with DevTools** to identify bottlenecks

### Platform Integration

```dart
// Platform channels for native functionality
import 'package:flutter/services.dart';

const platform = MethodChannel('com.example.app/battery');

Future<String> getBatteryLevel() async {
  try {
    final int result = await platform.invokeMethod('getBatteryLevel');
    return 'Battery level: $result%';
  } on PlatformException catch (e) {
    return "Failed to get battery level: '${e.message}'.";
  }
}
```

### Offline-First Architecture

```dart
// Implement offline-first with local caching
@override
Future<Either<Failure, List<User>>> getUsers() async {
  if (await networkInfo.isConnected) {
    try {
      final users = await remoteDataSource.getUsers();
      await localDataSource.cacheUsers(users); // Cache for offline
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  } else {
    // Return cached data when offline
    try {
      final cachedUsers = await localDataSource.getCachedUsers();
      return Right(cachedUsers);
    } on CacheException {
      return const Left(CacheFailure(message: 'No cached data available'));
    }
  }
}
```

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

## Compliance Check

Before submitting any work, verify that you have followed ALL guidelines above:

- [ ] Clean Architecture layers properly separated
- [ ] BLoC pattern correctly implemented
- [ ] All dependencies injected via get_it
- [ ] Either pattern used for error handling
- [ ] Unit tests for domain layer written
- [ ] Widget tests for UI components written
- [ ] BLoC tests for state management written
- [ ] Test coverage >80%
- [ ] ABOUTME comments added to all files
- [ ] Dart format applied: `dart format .`
- [ ] No analysis errors: `flutter analyze`
- [ ] Material Design 3 guidelines followed
- [ ] Responsive design for mobile screens
- [ ] Safe areas properly handled
- [ ] Accessibility considerations included

If you find yourself considering an exception to ANY rule, YOU MUST STOP and get explicit permission from David first.

## Mobile Development Best Practices Summary

1. **Architecture**: Clean Architecture with clear layer separation
2. **State Management**: Classic BLoC pattern (Bloc<Event, State>)
3. **Dependency Injection**: get_it with injectable
4. **Error Handling**: Either<Failure, Success> pattern with dartz
5. **Testing**: Comprehensive unit, widget, and BLoC tests (>80% coverage)
6. **UI/UX**: Material Design 3 for Android, Cupertino for iOS when appropriate
7. **Performance**: Const widgets, efficient builds, image caching
8. **Offline-First**: Local caching with sqflite or hive
9. **Platform Integration**: Platform channels for native functionality
10. **Code Quality**: dart analyze, dart format, sound null safety
