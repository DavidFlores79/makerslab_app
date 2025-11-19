# Legal Documents Feature - Complete Implementation Plan

**Feature**: Privacy Policy & Terms and Conditions  
**Branch**: `feat/legal-documents`  
**Base**: `develop`  
**Date**: 2025-11-17

---

## 📋 Requirements Summary

### API Specification
- **Endpoint**: `GET /api/legal/active`
- **Query Parameters**:
  - `type`: `'terms_and_conditions'` | `'privacy_policy'` (optional)
  - `language`: `'en'` | `'es'` (optional)

### Response Format
```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "type": "terms_and_conditions",
      "language": "en",
      "title": "Terms and Conditions",
      "content": "Markdown content here...",
      "version": "1.0",
      "isActive": true,
      "effectiveDate": "2025-01-01T00:00:00.000Z",
      "createdAt": "2025-01-01T00:00:00.000Z",
      "updatedAt": "2025-01-01T00:00:00.000Z"
    }
  ]
}
```

### User Decisions
- **A3)** Markdown content rendering (`flutter_markdown` package)
- **B1)** No local caching - always fetch from backend
- **C5)** Multiple entry points (already in profile section)
- **D1)** Auto-detect locale from app, backend accepts 'es'/'en'
- **E2)** Separate pages for Terms & Privacy (already in UI)
- **F2)** No version tracking - display current version only

---

## 🏗️ Architecture Overview

### Clean Architecture Layers
```
Presentation ─→ Domain ─→ Data
    ↓             ↓         ↓
  BLoC        UseCases   Repositories
   │             │           │
   │             │           ├─ Remote DataSource (API)
   │             │           └─ Models (JSON)
   │             │
   │             └─ Entities (Pure)
   │
   └─ Pages & Widgets
```

### Feature Structure
```
lib/features/legal/
├── data/
│   ├── datasources/legal_remote_datasource.dart
│   ├── models/legal_document_model.dart
│   └── repositories/legal_repository_impl.dart
├── domain/
│   ├── entities/legal_document.dart
│   ├── repositories/legal_repository.dart
│   └── usecases/get_active_legal_documents.dart
└── presentation/
    ├── bloc/
    │   ├── legal_bloc.dart
    │   ├── legal_event.dart
    │   └── legal_state.dart
    └── pages/
        └── legal_document_page.dart
```

---

## 📦 Phase 1: Dependencies

**File**: `pubspec.yaml`

Add under `dependencies`:
```yaml
flutter_markdown: ^0.7.4
```

**Command**: `flutter pub get`

---

## 🎯 Phase 2: Domain Layer

### 2.1 Entity - `lib/features/legal/domain/entities/legal_document.dart`

```dart
// ABOUTME: This file contains the LegalDocument entity
// ABOUTME: Pure domain object representing a legal document (Terms/Privacy Policy)

class LegalDocument {
  String? id;
  String? type;          // 'terms_and_conditions' | 'privacy_policy'
  String? language;      // 'en' | 'es'
  String? title;
  String? content;       // Markdown content
  String? version;
  bool? isActive;
  DateTime? effectiveDate;
  DateTime? createdAt;
  DateTime? updatedAt;

  LegalDocument({
    this.id,
    this.type,
    this.language,
    this.title,
    this.content,
    this.version,
    this.isActive,
    this.effectiveDate,
    this.createdAt,
    this.updatedAt,
  });
}
```

**Key Points**:
- Simple class with nullable fields
- NO Equatable
- NO JSON logic
- NO business logic

---

### 2.2 Repository Interface - `lib/features/legal/domain/repositories/legal_repository.dart`

```dart
// ABOUTME: This file contains the LegalRepository interface
// ABOUTME: Defines contract for fetching legal documents

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/legal_document.dart';

abstract class LegalRepository {
  Future<Either<Failure, List<LegalDocument>>> getActiveLegalDocuments({
    String? type,
    String? language,
  });
}
```

**Key Points**:
- Returns `Either<Failure, List<LegalDocument>>`
- Optional parameters for filtering
- Abstract interface only

---

### 2.3 UseCase - `lib/features/legal/domain/usecases/get_active_legal_documents.dart`

```dart
// ABOUTME: This file contains the GetActiveLegalDocuments use case
// ABOUTME: Fetches active legal documents with optional type and language filters

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/legal_document.dart';
import '../repositories/legal_repository.dart';

class GetActiveLegalDocuments {
  final LegalRepository repository;

  GetActiveLegalDocuments({required this.repository});

  Future<Either<Failure, List<LegalDocument>>> call({
    String? type,
    String? language,
  }) {
    return repository.getActiveLegalDocuments(
      type: type,
      language: language,
    );
  }
}
```

**Key Points**:
- Single responsibility: fetch documents
- Delegates to repository
- No business logic needed (simple pass-through)

---

## 💾 Phase 3: Data Layer

### 3.1 Model - `lib/features/legal/data/models/legal_document_model.dart`

```dart
// ABOUTME: This file contains the LegalDocumentModel
// ABOUTME: Extends LegalDocument entity with JSON serialization capabilities

import '../../domain/entities/legal_document.dart';

class LegalDocumentModel extends LegalDocument {
  LegalDocumentModel({
    super.id,
    super.type,
    super.language,
    super.title,
    super.content,
    super.version,
    super.isActive,
    super.effectiveDate,
    super.createdAt,
    super.updatedAt,
  });

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) =>
      LegalDocumentModel(
        id: json["_id"],
        type: json["type"],
        language: json["language"],
        title: json["title"],
        content: json["content"],
        version: json["version"],
        isActive: json["isActive"],
        effectiveDate: json["effectiveDate"] != null
            ? DateTime.parse(json["effectiveDate"])
            : null,
        createdAt: json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : null,
        updatedAt: json["updatedAt"] != null
            ? DateTime.parse(json["updatedAt"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "type": type,
        "language": language,
        "title": title,
        "content": content,
        "version": version,
        "isActive": isActive,
        "effectiveDate": effectiveDate?.toIso8601String(),
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}
```

**Key Points**:
- Extends entity
- Adds `fromJson()` and `toJson()`
- Handles ISO date parsing
- NO Equatable

---

### 3.2 Remote DataSource - `lib/features/legal/data/datasources/legal_remote_datasource.dart`

```dart
// ABOUTME: This file contains the LegalRemoteDataSource interface and implementation
// ABOUTME: Handles API calls for fetching legal documents

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/legal_document_model.dart';

abstract class LegalRemoteDataSource {
  Future<List<LegalDocumentModel>> getActiveLegalDocuments({
    String? type,
    String? language,
  });
}

class LegalRemoteDataSourceImpl implements LegalRemoteDataSource {
  final Dio dio;

  LegalRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<LegalDocumentModel>> getActiveLegalDocuments({
    String? type,
    String? language,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    if (language != null) queryParams['language'] = language;

    debugPrint('GET ${ApiConfig.legalDocumentsEndpoint} -> params: $queryParams');

    final response = await _safeGet(
      ApiConfig.legalDocumentsEndpoint,
      queryParameters: queryParams,
    );

    final data = _ensureMap(response.data);

    if (!data.containsKey('data') || data['data'] is! List) {
      throw ApiException('Invalid response format: missing data array');
    }

    final documentsList = data['data'] as List;
    return documentsList
        .map((json) => LegalDocumentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// --- Helpers (same pattern as CatalogsRemoteDataSource) ---

  Future<Response> _safeGet(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response;
      }

      final message = _extractMessageFromResponse(response);
      throw ApiException(message, statusCode: response.statusCode);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw ApiException('Tiempo de espera agotado. Verifica tu conexión.');
    }

    if (e.type == DioExceptionType.cancel) {
      throw ApiException('Solicitud cancelada.');
    }

    if (e.response != null) {
      final message = _extractMessageFromResponse(e.response!);
      throw ApiException(message, statusCode: e.response?.statusCode);
    }

    throw ApiException(e.message ?? 'Error de red desconocido');
  }

  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Response is not a valid JSON object');
  }

  String _extractMessageFromResponse(Response response) {
    try {
      final data = response.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      return 'Error: ${response.statusCode}';
    } catch (e) {
      return 'Error al procesar respuesta del servidor';
    }
  }
}
```

**Key Points**:
- Uses Dio with auth interceptors (auto-handled)
- `_safeGet()` helper for error handling
- Throws `ApiException` on errors
- Validates response structure

---

### 3.3 Repository Implementation - `lib/features/legal/data/repositories/legal_repository_impl.dart`

```dart
// ABOUTME: This file contains the LegalRepositoryImpl
// ABOUTME: Implements the LegalRepository interface with error handling

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/domain/repositories/base_repository.dart';
import '../../domain/entities/legal_document.dart';
import '../../domain/repositories/legal_repository.dart';
import '../datasources/legal_remote_datasource.dart';

class LegalRepositoryImpl extends BaseRepository implements LegalRepository {
  final LegalRemoteDataSource remoteDataSource;

  LegalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<LegalDocument>>> getActiveLegalDocuments({
    String? type,
    String? language,
  }) {
    return safeCall<List<LegalDocument>>(() async {
      return await remoteDataSource.getActiveLegalDocuments(
        type: type,
        language: language,
      );
    });
  }
}
```

**Key Points**:
- Extends `BaseRepository` for `safeCall()` wrapper
- Converts exceptions to `Failure` types
- Returns `Either<Failure, T>`

---

## 🎨 Phase 4: Presentation Layer

### 4.1 Events - `lib/features/legal/presentation/bloc/legal_event.dart`

```dart
// ABOUTME: This file contains the LegalBloc events
// ABOUTME: Defines events for loading legal documents

abstract class LegalEvent {}

class LoadLegalDocument extends LegalEvent {
  final String type;        // 'terms_and_conditions' | 'privacy_policy'
  final String? language;   // 'en' | 'es' (optional, auto-detected)

  LoadLegalDocument({
    required this.type,
    this.language,
  });
}
```

---

### 4.2 States - `lib/features/legal/presentation/bloc/legal_state.dart`

```dart
// ABOUTME: This file contains the LegalBloc states
// ABOUTME: Defines states for legal document loading and display

import '../../domain/entities/legal_document.dart';

enum LegalStatus { initial, loading, success, failure }

class LegalState {
  final LegalStatus status;
  final LegalDocument? document;
  final String? error;

  LegalState({
    this.status = LegalStatus.initial,
    this.document,
    this.error,
  });

  LegalState copyWith({
    LegalStatus? status,
    LegalDocument? document,
    String? error,
  }) =>
      LegalState(
        status: status ?? this.status,
        document: document ?? this.document,
        error: error ?? this.error,
      );
}
```

---

### 4.3 BLoC - `lib/features/legal/presentation/bloc/legal_bloc.dart`

```dart
// ABOUTME: This file contains the LegalBloc
// ABOUTME: Manages state for legal document fetching and display

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_active_legal_documents.dart';
import 'legal_event.dart';
import 'legal_state.dart';

class LegalBloc extends Bloc<LegalEvent, LegalState> {
  final GetActiveLegalDocuments getActiveLegalDocuments;

  LegalBloc({required this.getActiveLegalDocuments}) : super(LegalState()) {
    on<LoadLegalDocument>(_onLoad);
  }

  Future<void> _onLoad(
      LoadLegalDocument event, Emitter<LegalState> emit) async {
    debugPrint('Loading legal document: ${event.type}, language: ${event.language}');
    emit(state.copyWith(status: LegalStatus.loading));

    final result = await getActiveLegalDocuments(
      type: event.type,
      language: event.language,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: LegalStatus.failure, error: failure.message),
      ),
      (documents) {
        if (documents.isEmpty) {
          emit(state.copyWith(
            status: LegalStatus.failure,
            error: 'No se encontró el documento',
          ));
        } else {
          emit(state.copyWith(
            status: LegalStatus.success,
            document: documents.first, // Get first matching document
          ));
        }
      },
    );
  }
}
```

**Key Points**:
- Delegates to UseCase (NO business logic here)
- Emits loading → success/failure states
- Handles empty results gracefully

---

### 4.4 Page - `lib/features/legal/presentation/pages/legal_document_page.dart`

```dart
// ABOUTME: This file contains the LegalDocumentPage
// ABOUTME: Displays legal documents (Terms & Conditions or Privacy Policy) in Markdown format

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../di/service_locator.dart';
import '../bloc/legal_bloc.dart';
import '../bloc/legal_event.dart';
import '../bloc/legal_state.dart';

class LegalDocumentPage extends StatelessWidget {
  static const String routeName = "/legal";

  final String documentType; // 'terms_and_conditions' | 'privacy_policy'

  const LegalDocumentPage({
    super.key,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-detect language from app locale
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode == 'es' ? 'es' : 'en';

    return BlocProvider<LegalBloc>(
      create: (_) => getIt<LegalBloc>()
        ..add(LoadLegalDocument(
          type: documentType,
          language: language,
        )),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle(documentType)),
        ),
        body: BlocBuilder<LegalBloc, LegalState>(
          builder: (context, state) {
            if (state.status == LegalStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == LegalStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar el documento',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error ?? 'Intenta nuevamente más tarde',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.status == LegalStatus.success && state.document != null) {
              return Markdown(
                data: state.document!.content ?? '',
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  h1: Theme.of(context).textTheme.headlineMedium,
                  h2: Theme.of(context).textTheme.titleLarge,
                  h3: Theme.of(context).textTheme.titleMedium,
                  p: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return Container();
          },
        ),
      ),
    );
  }

  String _getTitle(String type) {
    switch (type) {
      case 'terms_and_conditions':
        return 'Términos y Condiciones';
      case 'privacy_policy':
        return 'Política de Privacidad';
      default:
        return 'Documento Legal';
    }
  }
}
```

**Key Points**:
- Auto-detects locale for language parameter
- BlocProvider creates new LegalBloc instance
- Shows loading/error/success states
- Renders Markdown with theme-aware styling
- Selectable text for copying

---

## ⚙️ Phase 5: Configuration & Integration

### 5.1 API Config - `lib/core/config/api_config.dart`

**Add after existing endpoints**:
```dart
// Endpoints de documentos legales
static const String legalDocumentsEndpoint = '/api/legal/active';
```

---

### 5.2 Dependency Injection - `lib/di/service_locator.dart`

**Add imports** (after existing imports):
```dart
import '../features/legal/data/datasources/legal_remote_datasource.dart';
import '../features/legal/data/repositories/legal_repository_impl.dart';
import '../features/legal/domain/repositories/legal_repository.dart';
import '../features/legal/domain/usecases/get_active_legal_documents.dart';
import '../features/legal/presentation/bloc/legal_bloc.dart';
```

**Add registrations** (after other remote data sources, around line 170):
```dart
// Legal remote datasource
getIt.registerLazySingleton<LegalRemoteDataSource>(
  () => LegalRemoteDataSourceImpl(dio: getIt()),
);
```

**Add after repositories** (around line 230):
```dart
// Legal repository
getIt.registerLazySingleton<LegalRepository>(
  () => LegalRepositoryImpl(remoteDataSource: getIt()),
);
```

**Add after use cases** (around line 250):
```dart
// Legal use case
getIt.registerLazySingleton(
  () => GetActiveLegalDocuments(repository: getIt()),
);
```

**Add after BLoCs** (around line 290):
```dart
// Legal BLoC
getIt.registerFactory(
  () => LegalBloc(getActiveLegalDocuments: getIt()),
);
```

---

### 5.3 Routing - `lib/core/router/app_router.dart`

**Add import**:
```dart
import '../../features/legal/presentation/pages/legal_document_page.dart';
```

**Add route** (in routes list, after other feature routes):
```dart
GoRoute(
  path: '${LegalDocumentPage.routeName}/:type',
  builder: (context, state) {
    final type = state.pathParameters['type'] ?? 'terms_and_conditions';
    return LegalDocumentPage(documentType: type);
  },
),
```

---

### 5.4 Profile Integration - `lib/features/profile/presentation/pages/profile_page.dart`

**Add import at top**:
```dart
import '../../../legal/presentation/pages/legal_document_page.dart';
```

**Update `_BuildLegalSection`** (replace lines 144-161):
```dart
class _BuildLegalSection extends StatelessWidget {
  const _BuildLegalSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileItemCard(
          title: 'Términos y condiciones',
          subtitle: 'Condiciones de uso',
          icon: Symbols.description,
          onTap: () {
            context.push('${LegalDocumentPage.routeName}/terms_and_conditions');
          },
        ),
        ProfileItemCard(
          title: 'Política de Privacidad',
          subtitle: 'Manejo de datos',
          icon: Symbols.privacy_tip,
          onTap: () {
            context.push('${LegalDocumentPage.routeName}/privacy_policy');
          },
        ),
      ],
    );
  }
}
```

---

## 🧪 Phase 6: Testing (MANDATORY)

### Test File Structure
```
test/features/legal/
├── data/
│   └── models/
│       └── legal_document_model_test.dart
├── domain/
│   └── usecases/
│       └── get_active_legal_documents_test.dart
└── presentation/
    ├── bloc/
    │   └── legal_bloc_test.dart
    └── pages/
        └── legal_document_page_test.dart
```

---

### 6.1 Unit Test - `test/features/legal/domain/usecases/get_active_legal_documents_test.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/features/legal/domain/entities/legal_document.dart';
import 'package:makerslab_app/features/legal/domain/repositories/legal_repository.dart';
import 'package:makerslab_app/features/legal/domain/usecases/get_active_legal_documents.dart';

@GenerateMocks([LegalRepository])
import 'get_active_legal_documents_test.mocks.dart';

void main() {
  late GetActiveLegalDocuments useCase;
  late MockLegalRepository mockRepository;

  setUp(() {
    mockRepository = MockLegalRepository();
    useCase = GetActiveLegalDocuments(repository: mockRepository);
  });

  final tDocument = LegalDocument(
    id: '1',
    type: 'privacy_policy',
    language: 'es',
    title: 'Privacy Policy',
    content: '# Privacy\nContent here',
  );

  test('should get legal documents from repository', () async {
    // Arrange
    when(mockRepository.getActiveLegalDocuments(
      type: any,
      language: any,
    )).thenAnswer((_) async => Right([tDocument]));

    // Act
    final result = await useCase(type: 'privacy_policy', language: 'es');

    // Assert
    expect(result, Right([tDocument]));
    verify(mockRepository.getActiveLegalDocuments(
      type: 'privacy_policy',
      language: 'es',
    ));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // Arrange
    final tFailure = ServerFailure('Server error', 500, StackTrace.current);
    when(mockRepository.getActiveLegalDocuments(
      type: any,
      language: any,
    )).thenAnswer((_) async => Left(tFailure));

    // Act
    final result = await useCase(type: 'privacy_policy');

    // Assert
    expect(result, Left(tFailure));
  });
}
```

---

### 6.2 Model Test - `test/features/legal/data/models/legal_document_model_test.dart`

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:makerslab_app/features/legal/data/models/legal_document_model.dart';

void main() {
  final tModel = LegalDocumentModel(
    id: '507f1f77bcf86cd799439011',
    type: 'terms_and_conditions',
    language: 'en',
    title: 'Terms and Conditions',
    content: '# Terms\nContent here...',
    version: '1.0',
    isActive: true,
    effectiveDate: DateTime.parse('2025-01-01T00:00:00.000Z'),
    createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
    updatedAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
  );

  final tJson = {
    "_id": "507f1f77bcf86cd799439011",
    "type": "terms_and_conditions",
    "language": "en",
    "title": "Terms and Conditions",
    "content": "# Terms\nContent here...",
    "version": "1.0",
    "isActive": true,
    "effectiveDate": "2025-01-01T00:00:00.000Z",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-01T00:00:00.000Z"
  };

  test('should deserialize from JSON', () {
    // Act
    final result = LegalDocumentModel.fromJson(tJson);

    // Assert
    expect(result.id, tModel.id);
    expect(result.type, tModel.type);
    expect(result.language, tModel.language);
    expect(result.title, tModel.title);
    expect(result.content, tModel.content);
    expect(result.version, tModel.version);
    expect(result.isActive, tModel.isActive);
    expect(result.effectiveDate, tModel.effectiveDate);
  });

  test('should serialize to JSON', () {
    // Act
    final result = tModel.toJson();

    // Assert
    expect(result, tJson);
  });

  test('should handle null dates gracefully', () {
    // Arrange
    final jsonWithNulls = {
      "_id": "123",
      "type": "privacy_policy",
      "language": "es",
      "title": "Privacy",
      "content": "Content",
      "version": "1.0",
      "isActive": true,
      "effectiveDate": null,
      "createdAt": null,
      "updatedAt": null,
    };

    // Act
    final result = LegalDocumentModel.fromJson(jsonWithNulls);

    // Assert
    expect(result.effectiveDate, isNull);
    expect(result.createdAt, isNull);
    expect(result.updatedAt, isNull);
  });
}
```

---

### 6.3 BLoC Test - `test/features/legal/presentation/bloc/legal_bloc_test.dart`

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:makerslab_app/core/error/failure.dart';
import 'package:makerslab_app/features/legal/domain/entities/legal_document.dart';
import 'package:makerslab_app/features/legal/domain/usecases/get_active_legal_documents.dart';
import 'package:makerslab_app/features/legal/presentation/bloc/legal_bloc.dart';
import 'package:makerslab_app/features/legal/presentation/bloc/legal_event.dart';
import 'package:makerslab_app/features/legal/presentation/bloc/legal_state.dart';

@GenerateMocks([GetActiveLegalDocuments])
import 'legal_bloc_test.mocks.dart';

void main() {
  late LegalBloc bloc;
  late MockGetActiveLegalDocuments mockGetActiveLegalDocuments;

  setUp(() {
    mockGetActiveLegalDocuments = MockGetActiveLegalDocuments();
    bloc = LegalBloc(getActiveLegalDocuments: mockGetActiveLegalDocuments);
  });

  final tDocument = LegalDocument(
    id: '1',
    type: 'privacy_policy',
    language: 'es',
    title: 'Privacy Policy',
    content: '# Privacy\nContent',
  );

  test('initial state should be LegalState with initial status', () {
    expect(bloc.state.status, LegalStatus.initial);
  });

  blocTest<LegalBloc, LegalState>(
    'emits [loading, success] when documents are fetched successfully',
    build: () {
      when(mockGetActiveLegalDocuments(
        type: any,
        language: any,
      )).thenAnswer((_) async => Right([tDocument]));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadLegalDocument(
      type: 'privacy_policy',
      language: 'es',
    )),
    expect: () => [
      LegalState(status: LegalStatus.loading),
      LegalState(status: LegalStatus.success, document: tDocument),
    ],
    verify: (_) {
      verify(mockGetActiveLegalDocuments(
        type: 'privacy_policy',
        language: 'es',
      )).called(1);
    },
  );

  blocTest<LegalBloc, LegalState>(
    'emits [loading, failure] when fetching documents fails',
    build: () {
      when(mockGetActiveLegalDocuments(
        type: any,
        language: any,
      )).thenAnswer((_) async => Left(
        ServerFailure('Server error', 500, StackTrace.current),
      ));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadLegalDocument(type: 'privacy_policy')),
    expect: () => [
      LegalState(status: LegalStatus.loading),
      LegalState(status: LegalStatus.failure, error: 'Server error'),
    ],
  );

  blocTest<LegalBloc, LegalState>(
    'emits [loading, failure] when no documents are returned',
    build: () {
      when(mockGetActiveLegalDocuments(
        type: any,
        language: any,
      )).thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadLegalDocument(type: 'privacy_policy')),
    expect: () => [
      LegalState(status: LegalStatus.loading),
      LegalState(
        status: LegalStatus.failure,
        error: 'No se encontró el documento',
      ),
    ],
  );
}
```

---

### 6.4 Widget Test - `test/features/legal/presentation/pages/legal_document_page_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:makerslab_app/features/legal/domain/entities/legal_document.dart';
import 'package:makerslab_app/features/legal/presentation/bloc/legal_bloc.dart';
import 'package:makerslab_app/features/legal/presentation/bloc/legal_state.dart';
import 'package:makerslab_app/features/legal/presentation/pages/legal_document_page.dart';

import '../bloc/legal_bloc_test.mocks.dart';

void main() {
  late MockGetActiveLegalDocuments mockUseCase;

  setUp(() {
    mockUseCase = MockGetActiveLegalDocuments();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<LegalBloc>(
        create: (_) => LegalBloc(getActiveLegalDocuments: mockUseCase),
        child: const LegalDocumentPage(documentType: 'privacy_policy'),
      ),
    );
  }

  testWidgets('displays loading indicator when state is loading',
      (tester) async {
    // Arrange
    await tester.pumpWidget(createWidgetUnderTest());

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays error message when state is failure', (tester) async {
    // Arrange
    await tester.pumpWidget(createWidgetUnderTest());
    final bloc = tester.element(find.byType(LegalDocumentPage)).read<LegalBloc>();

    // Act
    bloc.emit(LegalState(
      status: LegalStatus.failure,
      error: 'Error loading document',
    ));
    await tester.pump();

    // Assert
    expect(find.text('Error al cargar el documento'), findsOneWidget);
    expect(find.text('Error loading document'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('displays markdown content when state is success',
      (tester) async {
    // Arrange
    final tDocument = LegalDocument(
      id: '1',
      type: 'privacy_policy',
      language: 'es',
      title: 'Privacy Policy',
      content: '# Privacy Policy\nThis is the content',
    );

    await tester.pumpWidget(createWidgetUnderTest());
    final bloc = tester.element(find.byType(LegalDocumentPage)).read<LegalBloc>();

    // Act
    bloc.emit(LegalState(status: LegalStatus.success, document: tDocument));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Privacy Policy', skipOffstage: false), findsWidgets);
  });
}
```

---

## 📝 Phase 7: Implementation Checklist

### Pre-Implementation
- [ ] Current branch is `develop` or create it
- [ ] No uncommitted changes
- [ ] All tests passing

### Implementation Steps
1. [ ] Create feature branch: `git checkout -b feat/legal-documents`
2. [ ] Add `flutter_markdown` dependency to `pubspec.yaml`
3. [ ] Run `flutter pub get`
4. [ ] Create domain layer (entity → repository → usecase)
5. [ ] Create data layer (model → datasource → repository impl)
6. [ ] Create presentation layer (events → states → bloc → page)
7. [ ] Update API config
8. [ ] Register dependencies in service_locator
9. [ ] Add routing configuration
10. [ ] Integrate with profile page
11. [ ] Write unit tests (domain)
12. [ ] Write model tests (data)
13. [ ] Write BLoC tests (presentation)
14. [ ] Write widget tests (presentation)
15. [ ] Run tests: `flutter test --coverage`
16. [ ] Verify coverage >80%
17. [ ] Run `dart format .`
18. [ ] Run `flutter analyze` (zero warnings)
19. [ ] Manual testing on device/emulator
20. [ ] Commit with message: `feat: implement legal documents feature`
21. [ ] Push branch: `git push origin feat/legal-documents`
22. [ ] Create PR to `develop`

### Quality Gates (MUST PASS)
- [ ] All ABOUTME comments present
- [ ] Clean Architecture layers properly separated
- [ ] Business logic in UseCases, NOT in BLoC
- [ ] `Either<Failure, T>` pattern used
- [ ] No Equatable in entities/models
- [ ] GetIt dependency injection
- [ ] Test coverage ≥80%
- [ ] `dart format` applied
- [ ] `flutter analyze` passes with 0 warnings
- [ ] No hardcoded strings (use localization when needed)
- [ ] Material Design 3 guidelines followed
- [ ] Responsive for mobile screens

---

## 🎯 Success Criteria

### Functional
- ✅ Users can view Terms & Conditions from profile
- ✅ Users can view Privacy Policy from profile
- ✅ Content renders correctly in Markdown format
- ✅ Language auto-detects from app locale (es/en)
- ✅ Error states handled gracefully
- ✅ Loading states displayed properly

### Technical
- ✅ Follows Clean Architecture pattern
- ✅ Follows existing project conventions
- ✅ All tests passing (>80% coverage)
- ✅ Zero lint warnings
- ✅ Code formatted with `dart format`
- ✅ ABOUTME comments on all files
- ✅ Proper error handling with Either<Failure, T>

### Documentation
- ✅ Session file updated with final plan
- ✅ This implementation plan created
- ✅ Code comments clear and concise
- ✅ PR description documents changes

---

## 📚 Reference Files

### Existing Patterns to Follow
- **Remote DataSource**: `lib/features/catalogs/data/datasources/catalogs_remote_datasource.dart`
- **Repository Implementation**: `lib/features/catalogs/data/repositories/catalogs_repository_impl.dart`
- **UseCase**: `lib/features/home/domain/usecases/get_combined_menu.dart`
- **BLoC**: `lib/features/home/presentation/bloc/home_bloc.dart`
- **Page with BlocProvider**: `lib/features/home/presentation/pages/home_page.dart`

### Configuration Files
- API Config: `lib/core/config/api_config.dart`
- DI Setup: `lib/di/service_locator.dart`
- Routing: `lib/core/router/app_router.dart`
- Base Repository: `lib/core/domain/repositories/base_repository.dart`

---

## 🚀 Ready to Implement

David, this is the complete implementation plan for the Legal Documents feature. The plan follows your Clean Architecture guidelines and existing patterns from the codebase.

**Do you approve this plan and want me to proceed with implementation?**

If yes, I'll start implementing Phase 1 (Dependencies) and continue through all phases, creating all necessary files with proper ABOUTME comments, tests, and following your coding standards.
