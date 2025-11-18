# Legal Documents Feature Implementation Session

**Feature Name**: legal-documents  
**Created**: 2025-11-17  
**Status**: Planning Phase

## Feature Overview
Implement privacy policy and terms and conditions fetching from backend API with support for multiple languages (English and Spanish).

## API Endpoint
- **GET** `/api/legal/active`
- **Query Parameters**: `type` (terms_and_conditions|privacy_policy), `language` (en|es)

## Technology Stack Detected
- **Frontend**: Flutter/Dart 3.7.2+
- **State Management**: flutter_bloc (BLoC pattern)
- **Architecture**: Clean Architecture (Data/Domain/Presentation layers)
- **HTTP Client**: Dio with interceptors
- **Functional Programming**: dartz (Either<Failure, T>)
- **Dependency Injection**: get_it
- **Secure Storage**: flutter_secure_storage
- **Localization**: flutter_localizations (es_MX default)

## Existing Patterns Identified
1. **Remote Data Sources**: Use Dio with `_safeGet()` helper for error handling
2. **Repository Pattern**: Extend `BaseRepository` with `safeCall()` wrapper
3. **Entities**: Simple classes with nullable fields (no Equatable, no JSON logic)
4. **Models**: Extend entities, add `fromJson()`/`toJson()` serialization
5. **UseCases**: Single-responsibility business logic in domain layer
6. **BLoC**: State management with event/state pattern, delegates to UseCases
7. **Error Handling**: `Either<Failure, T>` with `CacheFailure`, `ServerFailure`, `ApiException`

## Similar Features as Reference
- **Catalogs Feature**: GET request with query parameters (`/api/countries`)
- **Home Feature**: Remote/local data sources, combined menu pattern
- **Auth Feature**: Complex remote datasource with multiple endpoints

## User Requirements Confirmed
- **A3)** Content Rendering: Markdown format (requires `flutter_markdown` package)
- **B1)** Caching: No caching - always fetch from backend
- **C5)** Navigation: Multiple entry points (already separated in profile)
- **D1)** Language: Auto-detect from app locale, backend accepts 'es' and 'en'
- **E2)** Display: Separate pages (already separated in profile)
- **F2)** Version Tracking: No tracking - just display current version

## Iterations Log
### Iteration 1 - Initial Exploration (2025-11-17)
- ✅ Created session file
- ✅ Explored repository structure
- ✅ Identified technology stack (Flutter with Clean Architecture)
- ✅ Analyzed existing patterns (Catalogs, Home, Auth features)
- ✅ Located API config, DI setup, and base repository

### Iteration 2 - Requirements Clarification (2025-11-17)
- ✅ User confirmed Markdown rendering (A3)
- ✅ User confirmed no caching (B1)
- ✅ User confirmed multiple entry points in profile (C5)
- ✅ User confirmed auto-detect locale, backend supports 'es'/'en' (D1)
- ✅ User confirmed separate pages in profile (E2)
- ✅ User confirmed no version tracking (F2)
- ✅ Identified existing UI placeholders in `profile_page.dart` (lines 144-159)

### Iteration 3 - Final Plan Created (2025-11-17)
- ✅ Complete implementation plan documented in session file
- ✅ 7 phases defined: Dependencies → Domain → Data → Presentation → Config → Testing → Checklist
- ✅ File structure and implementation order specified
- ✅ Ready for implementation approval
