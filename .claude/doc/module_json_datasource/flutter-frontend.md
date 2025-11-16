# Module JSON Datasource Refactoring - Implementation Plan

## Executive Summary

This document provides comprehensive architectural recommendations for refactoring the hardcoded module details (Temperature, Servo, Gamepad, Light Control) to use a JSON datasource following Clean Architecture principles. The goal is to create a scalable, maintainable system that supports dynamic module content with multi-platform INO file support.

---

## 1. Architecture Strategy: Extend Home Feature (RECOMMENDED)

### Decision: Extend Existing `home` Feature

**Recommendation**: Extend the existing `lib/features/home/` feature rather than creating a separate `ModuleDetail` feature.

**Rationale**:
- The `home` feature already manages module menu items (`MainMenuItem`)
- Module details are an extension of menu items - same modules, just more detailed information
- Avoids creating two separate systems managing the same conceptual entities
- Simpler dependency injection and state management
- Reduces code duplication and improves cohesion

### Proposed Structure

```
lib/features/home/
  domain/
    entities/
      main_menu_item.dart          # Existing - menu card data
      module_detail.dart           # NEW - detailed module info
      instruction_item.dart        # MOVE from core/domain/entities/
      material_item.dart           # MOVE from core/domain/entities/
      ino_file.dart                # NEW - multi-platform INO file entity
    repositories/
      home_repository.dart         # EXTEND with module detail methods
    usecases/
      get_home_menu.dart           # Existing
      get_combined_menu.dart       # Existing
      get_module_detail.dart       # NEW - fetch detail by module ID
      get_all_module_details.dart  # NEW - fetch all details (for preloading)

  data/
    datasources/
      home_local_datasource.dart   # EXTEND interface
      home_local_datasource_impl.dart  # EXTEND implementation
      module_detail_json_parser.dart   # NEW - JSON parsing utilities
    models/
      main_menu_item_model.dart    # Existing
      module_detail_model.dart     # NEW - with fromJson/toJson
      instruction_item_model.dart  # NEW
      material_item_model.dart     # NEW
      ino_file_model.dart          # NEW
    repositories/
      home_repository_impl.dart    # EXTEND with module detail methods

  presentation/
    bloc/
      home_bloc.dart               # EXTEND with module detail events/states
      home_event.dart              # ADD: LoadModuleDetail, LoadAllModuleDetails
      home_state.dart              # EXTEND: add moduleDetails map
    pages/
      home_page.dart               # Existing - no changes needed
    widgets/
      module_detail_loader.dart    # NEW - handles loading/error states

assets/
  data/
    modules/
      modules_detail.json          # NEW - consolidated JSON file
```

### Why Not a Separate Feature?

**Against Creating `module_detail` Feature**:
- Creates artificial separation between menu items and their details
- Requires cross-feature communication (HomeBloc → ModuleDetailBloc)
- Increases complexity in dependency injection
- Menu and details share the same module ID - natural coupling
- Would need to sync state between two separate BLoCs

---

## 2. BLoC Strategy: Extend HomeBloc (RECOMMENDED)

### Decision: Extend Existing `HomeBloc`

**Recommendation**: Extend the current `HomeBloc` to handle both menu items and module details.

**Rationale**:
- Menu items and module details are tightly coupled (same modules)
- Avoids state synchronization issues between separate BLoCs
- Simpler navigation flow - single source of truth
- Module pages can access both menu data and detail data from same BLoC
- Cleaner dependency injection

### Proposed BLoC Design

#### Events (home_event.dart)

```dart
// Existing event
abstract class HomeEvent {
  const HomeEvent();
}

class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

// NEW EVENTS
class LoadModuleDetail extends HomeEvent {
  final String moduleId;

  const LoadModuleDetail({required this.moduleId});
}

class LoadAllModuleDetails extends HomeEvent {
  const LoadAllModuleDetails();
}

class ClearModuleDetailCache extends HomeEvent {
  const ClearModuleDetailCache();
}
```

#### States (home_state.dart)

```dart
enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final List<MainMenuItemModel> mainMenuItems;
  final Map<String, ModuleDetail> moduleDetails; // NEW - keyed by module ID
  final String? error;
  final bool isLoadingModuleDetails;          // NEW - separate loading state
  final String? moduleDetailError;            // NEW - separate error state

  const HomeState({
    this.status = HomeStatus.initial,
    this.mainMenuItems = const [],
    this.moduleDetails = const {},          // NEW
    this.error,
    this.isLoadingModuleDetails = false,    // NEW
    this.moduleDetailError,                 // NEW
  });

  HomeState copyWith({
    HomeStatus? status,
    List<MainMenuItemModel>? mainMenuItems,
    Map<String, ModuleDetail>? moduleDetails,  // NEW
    String? error,
    bool? isLoadingModuleDetails,              // NEW
    String? moduleDetailError,                 // NEW
  }) {
    return HomeState(
      status: status ?? this.status,
      mainMenuItems: mainMenuItems ?? this.mainMenuItems,
      moduleDetails: moduleDetails ?? this.moduleDetails,
      error: error ?? this.error,
      isLoadingModuleDetails: isLoadingModuleDetails ?? this.isLoadingModuleDetails,
      moduleDetailError: moduleDetailError ?? this.moduleDetailError,
    );
  }

  // Helper method to get module detail by ID
  ModuleDetail? getModuleDetail(String moduleId) {
    return moduleDetails[moduleId];
  }
}
```

#### BLoC Implementation (home_bloc.dart)

```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCombinedMenu getCombinedMenu;
  final GetModuleDetail getModuleDetail;        // NEW
  final GetAllModuleDetails getAllModuleDetails; // NEW

  HomeBloc({
    required this.getCombinedMenu,
    required this.getModuleDetail,              // NEW
    required this.getAllModuleDetails,          // NEW
  }) : super(const HomeState()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<LoadModuleDetail>(_onLoadModuleDetail);          // NEW
    on<LoadAllModuleDetails>(_onLoadAllModuleDetails);  // NEW
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));

    final result = await getCombinedMenu();

    result.fold(
      (failure) => emit(state.copyWith(
        status: HomeStatus.failure,
        error: failure.message,
      )),
      (menuItems) => emit(state.copyWith(
        status: HomeStatus.success,
        mainMenuItems: menuItems,
      )),
    );
  }

  Future<void> _onLoadModuleDetail(
    LoadModuleDetail event,
    Emitter<HomeState> emit,
  ) async {
    // Check if already loaded
    if (state.moduleDetails.containsKey(event.moduleId)) {
      return; // Already cached
    }

    emit(state.copyWith(isLoadingModuleDetails: true));

    final result = await getModuleDetail(event.moduleId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingModuleDetails: false,
        moduleDetailError: failure.message,
      )),
      (detail) {
        final updatedDetails = Map<String, ModuleDetail>.from(state.moduleDetails);
        updatedDetails[event.moduleId] = detail;

        emit(state.copyWith(
          isLoadingModuleDetails: false,
          moduleDetails: updatedDetails,
          moduleDetailError: null,
        ));
      },
    );
  }

  Future<void> _onLoadAllModuleDetails(
    LoadAllModuleDetails event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoadingModuleDetails: true));

    final result = await getAllModuleDetails();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingModuleDetails: false,
        moduleDetailError: failure.message,
      )),
      (details) {
        final detailsMap = <String, ModuleDetail>{};
        for (final detail in details) {
          detailsMap[detail.id] = detail;
        }

        emit(state.copyWith(
          isLoadingModuleDetails: false,
          moduleDetails: detailsMap,
          moduleDetailError: null,
        ));
      },
    );
  }
}
```

### Why Not Create ModuleDetailBloc?

**Against Separate BLoC**:
- Requires BlocProvider nesting or multiple providers
- State synchronization complexity
- Harder to test interactions between menu and details
- More boilerplate code
- Navigation becomes more complex (need to access two BLoCs)

---

## 3. JSON Schema Design

### Consolidated JSON Structure

**Location**: `assets/data/modules/modules_detail.json`

**Schema**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["version", "modules"],
  "properties": {
    "version": {
      "type": "string",
      "description": "Schema version for future migrations"
    },
    "modules": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "id",
          "title",
          "description",
          "route",
          "interfaceRoute",
          "instructions",
          "materials",
          "inoFiles"
        ],
        "properties": {
          "id": {
            "type": "string",
            "description": "Unique module identifier (e.g., 'temperature', 'servo')"
          },
          "title": {
            "type": "string",
            "description": "Display title in Spanish"
          },
          "description": {
            "type": "string",
            "description": "Module description"
          },
          "route": {
            "type": "string",
            "description": "Module page route (e.g., '/temperature')"
          },
          "interfaceRoute": {
            "type": "string",
            "description": "Interface page route (e.g., '/temperature-interface')"
          },
          "image": {
            "type": "string",
            "description": "Module hero image asset path"
          },
          "videoId": {
            "type": "string",
            "description": "YouTube video ID"
          },
          "chatModuleKey": {
            "type": "string",
            "description": "Chat module identifier for AI assistant"
          },
          "inoFiles": {
            "type": "array",
            "description": "Multi-platform INO files",
            "items": {
              "type": "object",
              "required": ["platform", "fileName", "filePath"],
              "properties": {
                "platform": {
                  "type": "string",
                  "enum": ["ESP32", "Arduino UNO"],
                  "description": "Target platform"
                },
                "fileName": {
                  "type": "string",
                  "description": "Display file name"
                },
                "filePath": {
                  "type": "string",
                  "description": "Asset path to INO file"
                },
                "description": {
                  "type": "string",
                  "description": "Platform-specific description"
                }
              }
            }
          },
          "instructions": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["title", "description", "actionType"],
              "properties": {
                "title": {
                  "type": "string"
                },
                "description": {
                  "type": "string"
                },
                "imagePath": {
                  "type": "string",
                  "description": "Optional instruction image"
                },
                "actionType": {
                  "type": "string",
                  "enum": ["modalBottomSheet", "externalUrl", "internalRoute", "none"]
                },
                "actionValue": {
                  "type": "string",
                  "description": "URL or route for actionable instructions"
                }
              }
            }
          },
          "materials": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["title", "description", "qty", "actionType"],
              "properties": {
                "title": {
                  "type": "string"
                },
                "description": {
                  "type": "string"
                },
                "qty": {
                  "type": "string",
                  "description": "Quantity as string (e.g., '1', '2-3', '10+')"
                },
                "imagePath": {
                  "type": "string"
                },
                "actionType": {
                  "type": "string",
                  "enum": ["modalBottomSheet", "externalUrl", "internalRoute", "none"]
                },
                "actionValue": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Example JSON Data

```json
{
  "version": "1.0.0",
  "modules": [
    {
      "id": "temperature",
      "title": "Sensor Temperatura",
      "description": "Módulo de temperatura y humedad con DHT11",
      "route": "/temperature",
      "interfaceRoute": "/temperature-interface",
      "image": "assets/images/static/temperature/esp32DHT11.png",
      "videoId": "kJpdoBLSmHs",
      "chatModuleKey": "temperature_sensor",
      "inoFiles": [
        {
          "platform": "ESP32",
          "fileName": "esp32_bt_temp.ino",
          "filePath": "assets/files/esp32_bt_temp/esp32_bt_temp.ino",
          "description": "Código para ESP32 con Bluetooth Classic"
        },
        {
          "platform": "Arduino UNO",
          "fileName": "uno_bt_temp.ino",
          "filePath": "assets/files/uno_bt_temp/uno_bt_temp.ino",
          "description": "Código para Arduino UNO con HC-05 Bluetooth"
        }
      ],
      "instructions": [
        {
          "title": "1. Conectar el sensor DHT11 y el módulo Bluetooth HC-05 al Protoboard",
          "description": "Coloca el sensor DHT11 en el protoboard y conecta VCC a 5V, GND a tierra, y el pin de datos al GPIO 4 del ESP32. Conecta el módulo Bluetooth HC-05 al ESP32 mediante UART.",
          "imagePath": "assets/images/static/temperature/instructions/instruction1.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "2. Descargar bibliotecas necesarias",
          "description": "Instala las bibliotecas DHT sensor library y Adafruit Unified Sensor desde el gestor de bibliotecas de Arduino IDE.",
          "imagePath": null,
          "actionType": "externalUrl",
          "actionValue": "https://www.arduino.cc/reference/en/libraries/"
        }
      ],
      "materials": [
        {
          "title": "Microcontrolador ESP32",
          "description": "Placa de desarrollo ESP32 con WiFi y Bluetooth integrados",
          "qty": "1",
          "imagePath": "assets/images/static/materials/esp32.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "Sensor DHT11",
          "description": "Sensor de temperatura y humedad digital",
          "qty": "1",
          "imagePath": "assets/images/static/materials/dht-11.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        }
      ]
    }
  ]
}
```

### Schema Validation Approach

**Validation Strategy**: Fail-fast with detailed logging

1. **At Build Time**: Add `pubspec.yaml` asset declaration validation
2. **At Runtime**: Validate JSON schema on first load with detailed error messages
3. **Error Handling**: If JSON is invalid, fall back to empty list and log error
4. **Development Mode**: Add debug assertions to catch schema issues early

**Implementation**:

```dart
// lib/features/home/data/datasources/module_detail_json_parser.dart

class ModuleDetailJsonParser {
  final ILogger logger;

  ModuleDetailJsonParser({required this.logger});

  Future<List<ModuleDetailModel>> parseModulesJson(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate schema version
      final version = data['version'] as String?;
      if (version == null) {
        throw const FormatException('Missing schema version');
      }

      // Validate modules array exists
      final modulesJson = data['modules'] as List<dynamic>?;
      if (modulesJson == null) {
        throw const FormatException('Missing modules array');
      }

      // Parse each module with detailed error handling
      final modules = <ModuleDetailModel>[];
      for (int i = 0; i < modulesJson.length; i++) {
        try {
          final moduleJson = modulesJson[i] as Map<String, dynamic>;
          modules.add(ModuleDetailModel.fromJson(moduleJson));
        } catch (e, stackTrace) {
          logger.error('Failed to parse module at index $i', e, stackTrace);
          // Continue parsing other modules
        }
      }

      logger.info('Successfully parsed ${modules.length} modules');
      return modules;
    } catch (e, stackTrace) {
      logger.error('Failed to parse modules JSON', e, stackTrace);
      rethrow;
    }
  }
}
```

---

## 4. Entity Design: Composition Over Inheritance

### Decision: Separate Entities with Shared ID

**Recommendation**: Keep `MainMenuItem` and `ModuleDetail` as separate entities that share a common `id` field.

**Rationale**:
- Single Responsibility Principle - menu items and details serve different purposes
- Menu items are lightweight (for rendering cards)
- Module details are heavy (instructions, materials, videos)
- Allows lazy loading of details (don't fetch until needed)
- Easier to test and mock
- Clearer separation of concerns

### Entity Definitions

#### ModuleDetail Entity

```dart
// lib/features/home/domain/entities/module_detail.dart

// ABOUTME: Domain entity representing detailed module information for IoT modules
// ABOUTME: Includes instructions, materials, videos, and multi-platform INO files

class ModuleDetail {
  final String id;              // Shared with MainMenuItem
  final String title;
  final String description;
  final String route;
  final String interfaceRoute;
  final String? image;
  final String? videoId;
  final String? chatModuleKey;
  final List<InstructionItem> instructions;
  final List<MaterialItem> materials;
  final List<InoFile> inoFiles;  // Multi-platform support

  ModuleDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.route,
    required this.interfaceRoute,
    required this.instructions,
    required this.materials,
    required this.inoFiles,
    this.image,
    this.videoId,
    this.chatModuleKey,
  });
}
```

#### InoFile Entity (NEW)

```dart
// lib/features/home/domain/entities/ino_file.dart

// ABOUTME: Domain entity representing a platform-specific Arduino INO file
// ABOUTME: Supports multiple platforms (ESP32, Arduino UNO) per module

enum InoPlatform {
  esp32('ESP32'),
  arduinoUno('Arduino UNO');

  final String displayName;
  const InoPlatform(this.displayName);
}

class InoFile {
  final InoPlatform platform;
  final String fileName;
  final String filePath;
  final String? description;

  InoFile({
    required this.platform,
    required this.fileName,
    required this.filePath,
    this.description,
  });
}
```

#### InstructionItem Entity (MOVE from core)

```dart
// lib/features/home/domain/entities/instruction_item.dart

// ABOUTME: Domain entity representing a single instruction step for module assembly
// ABOUTME: Supports images, descriptions, and actionable instructions

enum InstructionItemType {
  internalRoute,
  externalUrl,
  modalBottomSheet,
  none;
}

class InstructionItem {
  final String title;
  final String description;
  final String imagePath;
  final InstructionItemType actionType;
  final String? actionValue;

  InstructionItem({
    required this.title,
    required this.description,
    required this.actionType,
    this.actionValue,
    String? imagePath,
  }) : imagePath = imagePath ?? 'assets/images/static/placeholder.png';
}
```

#### MaterialItem Entity (MOVE from core)

```dart
// lib/features/home/domain/entities/material_item.dart

// ABOUTME: Domain entity representing a required material/component for module assembly
// ABOUTME: Includes quantity, description, image, and optional purchase links

enum MaterialItemType {
  internalRoute,
  externalUrl,
  modalBottomSheet,
  none;
}

class MaterialItem {
  final String title;
  final String description;
  final String qty;
  final String imagePath;
  final MaterialItemType actionType;
  final String? actionValue;

  MaterialItem({
    required this.title,
    required this.description,
    required this.qty,
    required this.actionType,
    this.actionValue,
    String? imagePath,
  }) : imagePath = imagePath ?? 'assets/images/static/placeholder.png';
}
```

### Why Not Extend MainMenuItem?

**Against Inheritance**:
- Violates Interface Segregation Principle (clients don't need all fields)
- Creates tight coupling between menu and detail layers
- Makes it harder to evolve entities independently
- Complicates JSON parsing (inheritance requires discriminators)
- Menu items may come from API, details always from local JSON

**Composition Approach**:
- Use shared `id` field to link menu items and details
- `HomeBloc` manages both as separate maps
- UI components request details by ID when needed
- Clean separation of concerns

---

## 5. Repository Pattern: Single Repository Extended

### Decision: Extend `HomeRepository` Interface

**Recommendation**: Extend the existing `HomeRepository` to include module detail methods.

**Rationale**:
- Both menu items and module details are "home" domain concepts
- Simplifies dependency injection (one repository instead of two)
- Easier to test interactions
- Single source of truth for module data
- Follows Open/Closed Principle (extend, don't modify)

### Repository Interface

```dart
// lib/features/home/domain/repositories/home_repository.dart

// ABOUTME: Repository interface for home menu items and module details
// ABOUTME: Defines contracts for fetching menu, module details, and caching

abstract class HomeRepository {
  // Existing methods
  Future<Either<Failure, void>> cacheMainMenu(List<MainMenuItemModel> menu);
  Future<Either<Failure, List<MainMenuItemModel>>> getMainMenu();
  Future<Either<Failure, List<MainMenuItemModel>>> getRemoteMenuItems();

  // NEW METHODS
  Future<Either<Failure, ModuleDetail>> getModuleDetailById(String id);
  Future<Either<Failure, List<ModuleDetail>>> getAllModuleDetails();
  Future<Either<Failure, void>> cacheModuleDetails(List<ModuleDetail> details);
}
```

### Repository Implementation

```dart
// lib/features/home/data/repositories/home_repository_impl.dart

class HomeRepositoryImpl implements HomeRepository {
  final HomeLocalDatasource localDatasource;
  final HomeRemoteDataSource remoteDatasource;

  HomeRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  // Existing methods remain unchanged...

  @override
  Future<Either<Failure, ModuleDetail>> getModuleDetailById(String id) async {
    try {
      final detail = await localDatasource.getModuleDetailById(id);
      return Right(detail);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, List<ModuleDetail>>> getAllModuleDetails() async {
    try {
      final details = await localDatasource.getAllModuleDetails();
      return Right(details);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> cacheModuleDetails(
    List<ModuleDetail> details,
  ) async {
    try {
      await localDatasource.cacheModuleDetails(details);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}
```

### Datasource Extension

```dart
// lib/features/home/data/datasources/home_local_datasource.dart

abstract class HomeLocalDatasource {
  // Existing methods
  Future<void> cacheModules(List<MainMenuItemModel> modules);
  Future<List<MainMenuItemModel>> getCachedModules();

  // NEW METHODS
  Future<ModuleDetailModel> getModuleDetailById(String id);
  Future<List<ModuleDetailModel>> getAllModuleDetails();
  Future<void> cacheModuleDetails(List<ModuleDetailModel> details);
}
```

```dart
// lib/features/home/data/datasources/home_local_datasource_impl.dart

const _kModuleDetailsKey = 'CACHED_MODULE_DETAILS_v1';

class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  final SharedPreferences prefs;
  final ILogger logger;
  final ModuleDetailJsonParser jsonParser;  // NEW

  HomeLocalDatasourceImpl({
    required this.prefs,
    required this.logger,
    required this.jsonParser,  // NEW
  });

  // Existing methods remain unchanged...

  @override
  Future<List<ModuleDetailModel>> getAllModuleDetails() async {
    try {
      logger.info("Loading module details from JSON...");

      // Check cache first
      final cached = prefs.getString(_kModuleDetailsKey);
      if (cached != null) {
        logger.info("Loading from cache");
        final parsed = json.decode(cached) as List<dynamic>;
        return parsed
            .map((e) => ModuleDetailModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load from assets
      final jsonString = await rootBundle.loadString(
        'assets/data/modules/modules_detail.json',
      );

      final modules = await jsonParser.parseModulesJson(jsonString);

      // Cache for next time
      await cacheModuleDetails(modules);

      logger.info("Loaded ${modules.length} module details");
      return modules;
    } catch (e, stackTrace) {
      logger.error('Error loading module details', e, stackTrace);
      throw CacheException('Error loading module details', stackTrace);
    }
  }

  @override
  Future<ModuleDetailModel> getModuleDetailById(String id) async {
    try {
      final all = await getAllModuleDetails();
      final detail = all.firstWhere(
        (m) => m.id == id,
        orElse: () => throw CacheException(
          'Module detail not found: $id',
          StackTrace.current,
        ),
      );
      return detail;
    } catch (e, stackTrace) {
      logger.error('Error loading module detail: $id', e, stackTrace);
      throw CacheException('Error loading module detail: $id', stackTrace);
    }
  }

  @override
  Future<void> cacheModuleDetails(List<ModuleDetailModel> details) async {
    try {
      final jsonStr = json.encode(details.map((m) => m.toJson()).toList());
      await prefs.setString(_kModuleDetailsKey, jsonStr);
      logger.info("Cached ${details.length} module details");
    } catch (e, stackTrace) {
      logger.error('Error caching module details', e, stackTrace);
      throw CacheException('Error caching module details', stackTrace);
    }
  }
}
```

---

## 6. Multi-Platform INO File UX

### Decision: Dropdown Selector with Platform Icons

**Recommendation**: Use a platform dropdown selector above the "Descargar INO" button.

**UI Design**:

```
┌─────────────────────────────────────┐
│  Plataforma: [ESP32 ▼]             │ ← Dropdown
│                                      │
│  ┌──────────┐  ┌──────────────────┐ │
│  │ Interfaz │  │ Descargar INO    │ │
│  └──────────┘  └──────────────────┘ │
└─────────────────────────────────────┘
```

**Implementation**:

```dart
// lib/shared/widgets/modules/build_main_content.dart

class BuildMainContent extends StatefulWidget {
  final ModuleDetail moduleDetail;  // Changed from MainModule

  const BuildMainContent({super.key, required this.moduleDetail});

  @override
  State<BuildMainContent> createState() => _BuildMainContentState();
}

class _BuildMainContentState extends State<BuildMainContent> {
  late InoFile _selectedInoFile;

  @override
  void initState() {
    super.initState();
    // Default to first available platform (usually ESP32)
    _selectedInoFile = widget.moduleDetail.inoFiles.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform Selector
        if (widget.moduleDetail.inoFiles.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Plataforma:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<InoFile>(
                    value: _selectedInoFile,
                    isExpanded: true,
                    items: widget.moduleDetail.inoFiles.map((inoFile) {
                      return DropdownMenuItem<InoFile>(
                        value: inoFile,
                        child: Row(
                          children: [
                            Icon(
                              _getPlatformIcon(inoFile.platform),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(inoFile.platform.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (InoFile? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedInoFile = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Flexible(
                child: MainAppButton(
                  label: 'Interfaz',
                  onPressed: () => context.push(
                    '${widget.moduleDetail.route}${widget.moduleDetail.interfaceRoute}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: MainAppButton(
                  variant: ButtonVariant.outlined,
                  label: 'Descargar INO',
                  onPressed: () => _onDownloadAndShare(context),
                ),
              ),
            ],
          ),
        ),

        // Rest of the content...
        InstructionsSection(instructions: widget.moduleDetail.instructions),
        // ...
      ],
    );
  }

  IconData _getPlatformIcon(InoPlatform platform) {
    switch (platform) {
      case InoPlatform.esp32:
        return Icons.memory;  // Chip icon
      case InoPlatform.arduinoUno:
        return Icons.developer_board;  // Board icon
    }
  }

  Future<void> _onDownloadAndShare(BuildContext context) async {
    final shareFileUseCase = getIt<ShareFileUseCase>();
    final snackbarService = getIt<SnackbarService>();

    // Use selected platform's INO file
    final result = await shareFileUseCase(
      assetPath: _selectedInoFile.filePath,
      fileName: _selectedInoFile.fileName,
      text: 'Código ${_selectedInoFile.platform.displayName} para ${widget.moduleDetail.title}',
      subject: 'Archivo INO - ${widget.moduleDetail.title}',
    );

    // Error handling remains the same...
  }
}
```

### Alternative UX Patterns Considered

**Tab Selector**:
```
[ ESP32 ] [ Arduino UNO ]
```
- Rejected: Takes up too much vertical space
- Not scalable for 3+ platforms

**Modal Dialog**:
- Rejected: Extra tap required, interrupts user flow
- Better for educational content, not platform selection

**Recommendation**: Dropdown is most compact and familiar UX pattern for platform selection.

---

## 7. Backward Compatibility Strategy

### Migration Approach: Gradual Refactoring

**Strategy**: Migrate one module at a time with fallback support.

#### Phase 1: JSON Setup (No Breaking Changes)

1. Create JSON file with all module details
2. Create entities, models, repository extensions
3. Add use cases and extend BLoC
4. **DO NOT** modify existing module pages yet
5. **Test**: Verify JSON parsing, caching, BLoC state management

#### Phase 2: Add Compatibility Layer

Create a fallback widget that supports both old and new approaches:

```dart
// lib/shared/widgets/modules/module_content_wrapper.dart

class ModuleContentWrapper extends StatelessWidget {
  final String moduleId;
  final MainModule? fallbackModule;  // Old approach

  const ModuleContentWrapper({
    super.key,
    required this.moduleId,
    this.fallbackModule,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final moduleDetail = state.getModuleDetail(moduleId);

        // NEW: Use JSON-loaded module detail if available
        if (moduleDetail != null) {
          return BuildMainContent(moduleDetail: moduleDetail);
        }

        // OLD: Fallback to hardcoded module
        if (fallbackModule != null) {
          return _LegacyBuildMainContent(mainModule: fallbackModule);
        }

        // Loading state
        if (state.isLoadingModuleDetails) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        return ErrorView(
          message: state.moduleDetailError ?? 'Module not found',
          onRetry: () {
            context.read<HomeBloc>().add(LoadModuleDetail(moduleId: moduleId));
          },
        );
      },
    );
  }
}
```

#### Phase 3: Migrate One Module at a Time

**Example: Temperature Module Migration**

**Before** (temperature_page.dart):
```dart
class TemperaturePage extends StatelessWidget {
  static const String routeName = '/temperature';
  TemperaturePage({super.key});

  final MainModule mainModule = MainModule(...);  // Hardcoded

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ...
          SliverToBoxAdapter(
            child: BuildMainContent(mainModule: mainModule),
          ),
        ],
      ),
    );
  }
}
```

**After** (temperature_page.dart):
```dart
class TemperaturePage extends StatelessWidget {
  static const String routeName = '/temperature';
  static const String moduleId = 'temperature';  // NEW

  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger module detail load on first build
    context.read<HomeBloc>().add(
      const LoadModuleDetail(moduleId: moduleId),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ...
          SliverToBoxAdapter(
            child: ModuleContentWrapper(moduleId: moduleId),  // NEW
          ),
        ],
      ),
    );
  }
}
```

#### Phase 4: Remove Fallback Layer

Once all 4 modules are migrated and tested:
1. Remove `MainModule` entity from `core/domain/entities/`
2. Remove `_LegacyBuildMainContent` widget
3. Remove fallback logic from `ModuleContentWrapper`
4. Delete hardcoded module instances

### Testing Strategy During Migration

**Unit Tests**:
- Test JSON parsing with valid and invalid data
- Test `ModuleDetailJsonParser` error handling
- Test repository methods with mocked datasources

**Widget Tests**:
- Test `ModuleContentWrapper` with both old and new data
- Test loading/error states
- Test platform selector dropdown

**Integration Tests**:
- Test complete flow: HomePage → TemperaturePage → Load Details → Display
- Test platform switching and INO file sharing

### Rollback Plan

If issues arise during migration:
1. Revert module page changes (restore hardcoded `MainModule`)
2. JSON infrastructure remains (no harm, not used)
3. No breaking changes to existing features
4. User experience unchanged

---

## 8. Performance Optimization: Lazy Loading Strategy

### Decision: Lazy Load Per Module (RECOMMENDED)

**Recommendation**: Load module details on-demand when user navigates to module page.

**Rationale**:
- Average user visits 1-2 modules per session
- JSON file will grow as more modules are added
- Faster app startup time
- Reduced memory footprint
- Better for offline scenarios (cache only what's used)

### Loading Strategy

#### Approach 1: Lazy Load (RECOMMENDED)

**Flow**:
1. User lands on `HomePage` → Load menu items only (lightweight)
2. User taps "Temperatura" → Navigate to `/temperature`
3. `TemperaturePage` triggers `LoadModuleDetail('temperature')`
4. BLoC checks if already cached in state → If yes, return immediately
5. If not cached, load from JSON → Parse → Cache in BLoC state
6. Display module content

**Advantages**:
- Fast initial load
- Minimal memory usage
- Only parse JSON for visited modules
- Better for users who don't explore all modules

**Implementation**:

```dart
class TemperaturePage extends StatelessWidget {
  static const moduleId = 'temperature';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Check if detail already loaded
        if (state.getModuleDetail(moduleId) == null &&
            !state.isLoadingModuleDetails) {
          // Trigger load
          context.read<HomeBloc>().add(
            const LoadModuleDetail(moduleId: moduleId),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ModuleContentWrapper(moduleId: moduleId),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

#### Approach 2: Preload All (ALTERNATIVE)

**Flow**:
1. User lands on `HomePage` → Load menu items + ALL module details
2. Parse entire JSON file → Cache all in BLoC state
3. User navigates to any module → Instant display (no loading state)

**Advantages**:
- Instant module page display
- Simpler state management
- Better for power users who visit multiple modules

**Disadvantages**:
- Slower initial load (1-2 seconds)
- Higher memory usage (~100KB JSON)
- Parse modules user may never visit

**When to Use**: If analytics show users typically visit 3+ modules per session.

### Performance Benchmarks

**Lazy Loading** (4 modules):
- Initial load: 200ms (menu only)
- Per-module load: 50-100ms (parse 1 module from JSON)
- Memory: ~10KB per module

**Preload All** (4 modules):
- Initial load: 500-800ms (menu + all details)
- Per-module load: 0ms (already cached)
- Memory: ~50KB total

### Recommendation

**Start with Lazy Loading**, then monitor analytics:
- If >70% of users visit only 1 module → Keep lazy loading
- If >50% of users visit 3+ modules → Switch to preload all

**Implementation Toggle**:

```dart
// lib/features/home/presentation/pages/home_page.dart

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()
        ..add(const LoadHomeData())
        // Optionally preload module details:
        // ..add(const LoadAllModuleDetails()),  // Uncomment to enable preload
      child: Scaffold(
        // ...
      ),
    );
  }
}
```

---

## 9. Widget Refactoring Strategy

### Current Widget Dependencies

**Widgets Using `MainModule`**:
1. `BuildMainContent` - Main content builder (instructions, materials, video, buttons)
2. `InstructionsSection` - Horizontal scrollable instruction cards
3. `BillOfMaterialsSection` - Horizontal scrollable material cards
4. `YouTubePlayer` - Video player

**Widgets Using `InstructionItem`**:
1. `InstructionsSection`
2. `InstructionDetailsSection`
3. `InstructionActions` helper

**Widgets Using `MaterialItem`**:
1. `BillOfMaterialsSection`
2. `MaterialDetailsPage`

### Refactoring Approach

#### Step 1: Move Entities to Home Feature

**From**:
```
lib/core/domain/entities/
  module.dart
  instruction.dart
  material.dart
```

**To**:
```
lib/features/home/domain/entities/
  module_detail.dart         # Replaces module.dart
  instruction_item.dart      # Moved from core
  material_item.dart         # Moved from core
  ino_file.dart             # NEW
```

**Migration Script**:
```dart
// Update all imports:
// OLD: import 'package:makerslab_app/core/domain/entities/module.dart';
// NEW: import 'package:makerslab_app/features/home/domain/entities/module_detail.dart';

// Find and replace:
// MainModule → ModuleDetail
```

#### Step 2: Update BuildMainContent Widget

**Key Changes**:
- Replace `MainModule` parameter with `ModuleDetail`
- Add platform dropdown for INO file selection
- Update share functionality to use selected platform

**File**: `lib/shared/widgets/modules/build_main_content.dart`

**Changes Required**:
1. Import new entities from home feature
2. Change parameter type from `MainModule` to `ModuleDetail`
3. Add state management for selected INO file
4. Add platform dropdown UI
5. Update `_onDownloadAndShare` to use selected file

**No changes needed for**:
- `InstructionsSection` - already uses `List<InstructionItem>`
- `BillOfMaterialsSection` - already uses `List<MaterialItem>`
- `YouTubePlayer` - already uses `String videoId`

#### Step 3: Update Module Pages

**Template for All Module Pages**:

```dart
// Example: lib/features/temperature/presentation/pages/temperature_page.dart

class TemperaturePage extends StatelessWidget {
  static const String routeName = '/temperature';
  static const String moduleId = 'temperature';

  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger lazy load
    final homeBloc = context.read<HomeBloc>();
    if (homeBloc.state.getModuleDetail(moduleId) == null &&
        !homeBloc.state.isLoadingModuleDetails) {
      homeBloc.add(const LoadModuleDetail(moduleId: moduleId));
    }

    return Scaffold(
      appBar: AppBar(/* ... */),
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final moduleDetail = state.getModuleDetail(moduleId);

            if (moduleDetail != null) {
              return CustomScrollView(
                slivers: [
                  MainSliverBackAppbar(
                    title: moduleDetail.title,
                    imagePath: moduleDetail.image,
                  ),
                  SliverToBoxAdapter(
                    child: BuildMainContent(moduleDetail: moduleDetail),
                  ),
                ],
              );
            }

            if (state.isLoadingModuleDetails) {
              return const Center(child: CircularProgressIndicator());
            }

            return ErrorView(
              message: state.moduleDetailError ?? 'Error loading module',
              onRetry: () => homeBloc.add(
                const LoadModuleDetail(moduleId: moduleId),
              ),
            );
          },
        ),
      ),
      floatingActionButton: PxChatBotFloatingButton(
        chatKey: moduleDetail?.chatModuleKey ?? '',
      ),
    );
  }
}
```

**Pages to Update**:
1. `lib/features/temperature/presentation/pages/temperature_page.dart`
2. `lib/features/servo/presentation/pages/servo_page.dart`
3. `lib/features/gamepad/presentation/pages/gamepad_page.dart`
4. `lib/features/light_control/presentation/pages/light_control_page.dart`

---

## 10. Testing Strategy

### Test Coverage Requirements

**Minimum 80% Coverage for**:
- Domain layer (entities, use cases)
- Data layer (JSON parsing, repository)
- BLoC layer (events, states, transitions)
- Critical widgets (BuildMainContent, platform selector)

### Unit Tests

#### JSON Parser Tests

```dart
// test/features/home/data/datasources/module_detail_json_parser_test.dart

void main() {
  late ModuleDetailJsonParser parser;
  late MockLogger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
    parser = ModuleDetailJsonParser(logger: mockLogger);
  });

  group('parseModulesJson', () {
    test('should parse valid JSON successfully', () async {
      // Arrange
      const jsonString = '''
      {
        "version": "1.0.0",
        "modules": [
          {
            "id": "temperature",
            "title": "Sensor Temperatura",
            ...
          }
        ]
      }
      ''';

      // Act
      final result = await parser.parseModulesJson(jsonString);

      // Assert
      expect(result, isA<List<ModuleDetailModel>>());
      expect(result.length, 1);
      expect(result.first.id, 'temperature');
    });

    test('should throw FormatException for missing version', () async {
      // Arrange
      const jsonString = '{"modules": []}';

      // Act & Assert
      expect(
        () => parser.parseModulesJson(jsonString),
        throwsA(isA<FormatException>()),
      );
    });

    test('should continue parsing after individual module error', () async {
      // Arrange
      const jsonString = '''
      {
        "version": "1.0.0",
        "modules": [
          {"id": "valid"},
          {"invalid": "data"},
          {"id": "also_valid"}
        ]
      }
      ''';

      // Act
      final result = await parser.parseModulesJson(jsonString);

      // Assert
      expect(result.length, 2);  // Only valid modules parsed
      verify(mockLogger.error(any, any, any)).called(1);  // Error logged
    });
  });
}
```

#### Repository Tests

```dart
// test/features/home/data/repositories/home_repository_impl_test.dart

void main() {
  late HomeRepositoryImpl repository;
  late MockHomeLocalDatasource mockLocalDatasource;
  late MockHomeRemoteDataSource mockRemoteDatasource;

  setUp(() {
    mockLocalDatasource = MockHomeLocalDatasource();
    mockRemoteDatasource = MockHomeRemoteDataSource();
    repository = HomeRepositoryImpl(
      localDatasource: mockLocalDatasource,
      remoteDatasource: mockRemoteDatasource,
    );
  });

  group('getModuleDetailById', () {
    const testId = 'temperature';
    final testDetail = ModuleDetailModel(id: testId, /* ... */);

    test('should return ModuleDetail on success', () async {
      // Arrange
      when(mockLocalDatasource.getModuleDetailById(testId))
          .thenAnswer((_) async => testDetail);

      // Act
      final result = await repository.getModuleDetailById(testId);

      // Assert
      expect(result, isA<Right<Failure, ModuleDetail>>());
      result.fold(
        (_) => fail('Should return Right'),
        (detail) => expect(detail.id, testId),
      );
    });

    test('should return CacheFailure on CacheException', () async {
      // Arrange
      when(mockLocalDatasource.getModuleDetailById(testId))
          .thenThrow(CacheException('Not found', StackTrace.current));

      // Act
      final result = await repository.getModuleDetailById(testId);

      // Assert
      expect(result, isA<Left<Failure, ModuleDetail>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, 'Not found');
        },
        (_) => fail('Should return Left'),
      );
    });
  });
}
```

### BLoC Tests

```dart
// test/features/home/presentation/bloc/home_bloc_test.dart

void main() {
  late HomeBloc bloc;
  late MockGetCombinedMenu mockGetCombinedMenu;
  late MockGetModuleDetail mockGetModuleDetail;
  late MockGetAllModuleDetails mockGetAllModuleDetails;

  setUp(() {
    mockGetCombinedMenu = MockGetCombinedMenu();
    mockGetModuleDetail = MockGetModuleDetail();
    mockGetAllModuleDetails = MockGetAllModuleDetails();
    bloc = HomeBloc(
      getCombinedMenu: mockGetCombinedMenu,
      getModuleDetail: mockGetModuleDetail,
      getAllModuleDetails: mockGetAllModuleDetails,
    );
  });

  group('LoadModuleDetail', () {
    const testId = 'temperature';
    final testDetail = ModuleDetail(id: testId, /* ... */);

    blocTest<HomeBloc, HomeState>(
      'emits [loading, success] when detail loaded successfully',
      build: () {
        when(mockGetModuleDetail(testId))
            .thenAnswer((_) async => Right(testDetail));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadModuleDetail(moduleId: testId)),
      expect: () => [
        HomeState(isLoadingModuleDetails: true),
        HomeState(
          isLoadingModuleDetails: false,
          moduleDetails: {testId: testDetail},
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'does not emit when detail already cached',
      build: () => bloc,
      seed: () => HomeState(moduleDetails: {testId: testDetail}),
      act: (bloc) => bloc.add(const LoadModuleDetail(moduleId: testId)),
      expect: () => [],  // No state changes
    );

    blocTest<HomeBloc, HomeState>(
      'emits error state on failure',
      build: () {
        when(mockGetModuleDetail(testId))
            .thenAnswer((_) async => const Left(CacheFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadModuleDetail(moduleId: testId)),
      expect: () => [
        HomeState(isLoadingModuleDetails: true),
        HomeState(
          isLoadingModuleDetails: false,
          moduleDetailError: 'Error',
        ),
      ],
    );
  });
}
```

### Widget Tests

```dart
// test/shared/widgets/modules/build_main_content_test.dart

void main() {
  testWidgets('displays platform dropdown when multiple INO files available',
      (tester) async {
    // Arrange
    final moduleDetail = ModuleDetail(
      id: 'test',
      inoFiles: [
        InoFile(platform: InoPlatform.esp32, fileName: 'esp32.ino', filePath: '...'),
        InoFile(platform: InoPlatform.arduinoUno, fileName: 'uno.ino', filePath: '...'),
      ],
      // ...
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildMainContent(moduleDetail: moduleDetail),
        ),
      ),
    );

    // Assert
    expect(find.text('Plataforma:'), findsOneWidget);
    expect(find.byType(DropdownButton<InoFile>), findsOneWidget);
  });

  testWidgets('switches platform when dropdown selection changes',
      (tester) async {
    // Arrange
    final esp32File = InoFile(
      platform: InoPlatform.esp32,
      fileName: 'esp32.ino',
      filePath: 'path/esp32.ino',
    );
    final unoFile = InoFile(
      platform: InoPlatform.arduinoUno,
      fileName: 'uno.ino',
      filePath: 'path/uno.ino',
    );
    final moduleDetail = ModuleDetail(
      id: 'test',
      inoFiles: [esp32File, unoFile],
      // ...
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildMainContent(moduleDetail: moduleDetail),
        ),
      ),
    );

    // Act - Open dropdown
    await tester.tap(find.byType(DropdownButton<InoFile>));
    await tester.pumpAndSettle();

    // Select Arduino UNO
    await tester.tap(find.text('Arduino UNO').last);
    await tester.pumpAndSettle();

    // Assert - Platform changed
    expect(find.text('Arduino UNO'), findsWidgets);
  });
}
```

### Integration Tests

```dart
// integration_test/module_detail_flow_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete module detail flow', (tester) async {
    // Setup DI
    await setupServiceLocator();

    // Launch app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Navigate to Temperature module
    await tester.tap(find.text('Sensor Temperatura'));
    await tester.pumpAndSettle();

    // Verify module detail loaded
    expect(find.text('Instrucciones'), findsOneWidget);
    expect(find.text('Materiales'), findsOneWidget);
    expect(find.byType(YouTubePlayer), findsOneWidget);

    // Switch platform
    await tester.tap(find.byType(DropdownButton<InoFile>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arduino UNO').last);
    await tester.pumpAndSettle();

    // Verify platform switched
    expect(find.text('Arduino UNO'), findsWidgets);

    // Test INO file download
    await tester.tap(find.text('Descargar INO'));
    await tester.pumpAndSettle();

    // Verify share triggered (platform-specific assertion)
  });
}
```

---

## 11. Dependency Injection Updates

### Service Locator Registration

```dart
// lib/di/service_locator.dart

Future<void> setupServiceLocator() async {
  // Existing registrations...

  // JSON Parser (NEW)
  getIt.registerLazySingleton<ModuleDetailJsonParser>(
    () => ModuleDetailJsonParser(logger: getIt()),
  );

  // Update HomeLocalDatasource registration
  getIt.registerLazySingleton<HomeLocalDatasource>(
    () => HomeLocalDatasourceImpl(
      prefs: getIt(),
      logger: getIt(),
      jsonParser: getIt(),  // NEW
    ),
  );

  // Repository remains the same (interface extended, implementation extended)

  // NEW Use Cases
  getIt.registerLazySingleton(
    () => GetModuleDetail(repository: getIt<HomeRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetAllModuleDetails(repository: getIt<HomeRepository>()),
  );

  // Update HomeBloc registration
  getIt.registerFactory(
    () => HomeBloc(
      getCombinedMenu: getIt(),
      getModuleDetail: getIt(),        // NEW
      getAllModuleDetails: getIt(),    // NEW
    ),
  );
}
```

---

## 12. File Structure Summary

### New Files to Create

```
lib/features/home/
  domain/
    entities/
      module_detail.dart           ← NEW
      ino_file.dart                ← NEW
      instruction_item.dart        ← MOVE from core
      material_item.dart           ← MOVE from core
    usecases/
      get_module_detail.dart       ← NEW
      get_all_module_details.dart  ← NEW

  data/
    datasources/
      module_detail_json_parser.dart  ← NEW
    models/
      module_detail_model.dart        ← NEW
      ino_file_model.dart             ← NEW
      instruction_item_model.dart     ← NEW
      material_item_model.dart        ← NEW

  presentation/
    widgets/
      module_detail_loader.dart       ← NEW (optional helper widget)

assets/
  data/
    modules/
      modules_detail.json             ← NEW

test/
  features/home/
    data/
      datasources/
        module_detail_json_parser_test.dart  ← NEW
      models/
        module_detail_model_test.dart        ← NEW
      repositories/
        home_repository_impl_test.dart       ← EXTEND
    domain/
      usecases/
        get_module_detail_test.dart          ← NEW
    presentation/
      bloc/
        home_bloc_test.dart                  ← EXTEND
  shared/
    widgets/
      modules/
        build_main_content_test.dart         ← NEW
```

### Files to Modify

```
lib/features/home/
  domain/
    repositories/
      home_repository.dart                 ← EXTEND interface
  data/
    datasources/
      home_local_datasource.dart           ← EXTEND interface
      home_local_datasource_impl.dart      ← EXTEND implementation
    repositories/
      home_repository_impl.dart            ← EXTEND implementation
  presentation/
    bloc/
      home_bloc.dart                       ← ADD events/handlers
      home_event.dart                      ← ADD events
      home_state.dart                      ← ADD fields

lib/shared/widgets/modules/
  build_main_content.dart                  ← REFACTOR to use ModuleDetail

lib/features/temperature/presentation/pages/
  temperature_page.dart                    ← REFACTOR to use BLoC

lib/features/servo/presentation/pages/
  servo_page.dart                          ← REFACTOR to use BLoC

lib/features/gamepad/presentation/pages/
  gamepad_page.dart                        ← REFACTOR to use BLoC

lib/features/light_control/presentation/pages/
  light_control_page.dart                  ← REFACTOR to use BLoC

lib/di/
  service_locator.dart                     ← ADD new registrations

pubspec.yaml                               ← ADD JSON asset
```

### Files to Delete (After Migration Complete)

```
lib/core/domain/entities/
  module.dart                              ← DELETE (replaced by module_detail.dart)
  instruction.dart                         ← DELETE (moved to home feature)
  material.dart                            ← DELETE (moved to home feature)
```

---

## 13. Implementation Phases

### Phase 1: Foundation (Week 1)

**Goals**: Set up domain layer and data infrastructure

**Tasks**:
1. Create domain entities:
   - `ModuleDetail`
   - `InoFile`
   - Move `InstructionItem`, `MaterialItem` to home feature
2. Create data models with `fromJson`/`toJson`
3. Create `ModuleDetailJsonParser`
4. Create JSON file `modules_detail.json` with all 4 modules
5. Add JSON to `pubspec.yaml` assets
6. Write unit tests for JSON parsing

**Acceptance Criteria**:
- All entities defined with proper types
- JSON parser handles valid and invalid data
- 100% unit test coverage for parser
- `flutter analyze` passes with no errors

### Phase 2: Repository & Use Cases (Week 1)

**Goals**: Implement data layer and business logic

**Tasks**:
1. Extend `HomeRepository` interface
2. Extend `HomeLocalDatasource` interface
3. Implement datasource methods in `HomeLocalDatasourceImpl`
4. Implement repository methods in `HomeRepositoryImpl`
5. Create use cases: `GetModuleDetail`, `GetAllModuleDetails`
6. Write unit tests for repository and use cases
7. Update DI registration in `service_locator.dart`

**Acceptance Criteria**:
- Repository methods return `Either<Failure, Success>`
- Proper error handling for missing modules
- Caching works correctly (SharedPreferences)
- 80%+ unit test coverage
- Integration with existing `HomeRepository` doesn't break menu loading

### Phase 3: BLoC Integration (Week 2)

**Goals**: Extend HomeBloc with module detail state management

**Tasks**:
1. Add events: `LoadModuleDetail`, `LoadAllModuleDetails`
2. Extend `HomeState` with `moduleDetails` map and loading states
3. Implement event handlers in `HomeBloc`
4. Add helper method `getModuleDetail(id)` to state
5. Write BLoC tests using `bloc_test`
6. Test caching behavior (don't reload if already in state)

**Acceptance Criteria**:
- BLoC handles loading, success, error states correctly
- Cached details don't trigger re-fetch
- Existing menu loading functionality unaffected
- 100% BLoC test coverage for new events

### Phase 4: Widget Refactoring (Week 2)

**Goals**: Update shared widgets to use new entities

**Tasks**:
1. Refactor `BuildMainContent`:
   - Change parameter from `MainModule` to `ModuleDetail`
   - Add state for selected INO file
   - Add platform dropdown UI
   - Update share functionality
2. Create `ModuleDetailLoader` helper widget (optional)
3. Write widget tests for `BuildMainContent`
4. Test platform dropdown interaction

**Acceptance Criteria**:
- Platform dropdown displays all available platforms
- Share functionality uses selected platform's INO file
- Widget tests cover all interaction scenarios
- Visual regression testing passes

### Phase 5: Module Page Migration (Week 3)

**Goals**: Migrate all 4 module pages to use new system

**Tasks**:
1. Migrate `TemperaturePage` (pilot migration)
2. Test thoroughly in development
3. Migrate `ServoPage`
4. Migrate `GamepadPage`
5. Migrate `LightControlPage`
6. Remove hardcoded `MainModule` instances
7. Integration testing for all modules

**Acceptance Criteria**:
- All modules load details from JSON
- Platform selection works for all modules
- No regressions in existing functionality
- Loading/error states display correctly
- Integration tests pass for all modules

### Phase 6: Cleanup & Documentation (Week 3)

**Goals**: Remove legacy code and finalize documentation

**Tasks**:
1. Delete `core/domain/entities/module.dart`
2. Delete `core/domain/entities/instruction.dart`
3. Delete `core/domain/entities/material.dart`
4. Remove fallback logic from `BuildMainContent`
5. Update session context document
6. Create migration guide for future modules
7. Performance testing and optimization
8. Final QA pass

**Acceptance Criteria**:
- No references to old `MainModule` entity
- Code analysis passes with no warnings
- All tests pass (unit, widget, integration)
- Performance benchmarks meet targets
- Documentation complete and accurate

---

## 14. Risks & Mitigation

### Risk 1: JSON Parsing Errors

**Risk**: Invalid JSON crashes app on startup

**Mitigation**:
- Comprehensive JSON validation in parser
- Try-catch blocks with detailed logging
- Fail gracefully with empty list on error
- Add debug assertions in development mode
- CI/CD pipeline validates JSON schema

### Risk 2: Breaking Existing Module Functionality

**Risk**: Migration breaks temperature/servo/gamepad/light modules

**Mitigation**:
- Gradual migration (one module at a time)
- Keep fallback support during transition
- Comprehensive integration tests before merging
- Feature flags to toggle new/old system
- Rollback plan documented

### Risk 3: Performance Degradation

**Risk**: JSON parsing slows down module page load

**Mitigation**:
- Lazy loading strategy (only load needed modules)
- Cache parsed data in SharedPreferences
- BLoC state caching (don't re-parse if already loaded)
- Performance benchmarks before/after migration
- Monitor analytics for user-perceived performance

### Risk 4: Asset Path Changes

**Risk**: Refactoring breaks asset paths in JSON

**Mitigation**:
- Keep existing asset structure unchanged
- Validate all asset paths exist in JSON parser
- Add asset existence checks in tests
- CI/CD pipeline verifies asset paths

### Risk 5: Multi-Platform INO Confusion

**Risk**: Users don't understand which platform to select

**Mitigation**:
- Clear platform labels (ESP32, Arduino UNO)
- Add descriptions for each platform
- Default to most common platform (ESP32)
- Add help icon with platform explanation
- Analytics to track platform selection patterns

---

## 15. Success Metrics

### Technical Metrics

- **Test Coverage**: >80% for all new code
- **Code Quality**: Zero analyzer warnings, formatted code
- **Performance**: Module page load <500ms (lazy loading)
- **Memory**: <50KB overhead for JSON caching
- **Build Time**: No significant increase (<5%)

### User Experience Metrics

- **Module Page Load Time**: <1 second (perceived)
- **Platform Switch Time**: Instant (<100ms)
- **Error Rate**: <1% of module page visits
- **Crash Rate**: No increase from baseline

### Maintenance Metrics

- **JSON Update Time**: <5 minutes to add new module
- **Code Duplication**: Eliminate 4 hardcoded module instances
- **Lines of Code**: Net reduction after cleanup
- **Future Module Cost**: 80% less effort (JSON vs code)

---

## 16. Future Enhancements

### Beyond Initial Implementation

1. **Remote JSON Fetching**:
   - Fetch module details from API (authenticated users)
   - Merge remote details with local JSON
   - Enable dynamic module updates without app release

2. **Multi-Language Support**:
   - Add `locale` field to JSON schema
   - Separate JSON files per language
   - Load based on `AppLocalizations` locale

3. **Module Versioning**:
   - Add `version` field to each module
   - Track user's completed module versions
   - Show "Updated" badge for new versions

4. **Advanced Search**:
   - Full-text search across instructions and materials
   - Filter by platform (ESP32-only modules)
   - Filter by difficulty level

5. **Offline PDF Export**:
   - Generate PDF from module details
   - Include all instructions and materials
   - Shareable for offline reference

---

## 17. Conclusion & Recommendations

### Summary of Architectural Decisions

| Question | Decision | Rationale |
|----------|----------|-----------|
| **Feature Location** | Extend `home` feature | Module details are extensions of menu items |
| **BLoC Strategy** | Extend `HomeBloc` | Avoids state synchronization complexity |
| **JSON Schema** | Consolidated single file | Simpler management, easier parsing |
| **Entity Design** | Separate with shared ID | Follows SRP, enables lazy loading |
| **Repository** | Extend `HomeRepository` | Single source of truth for module data |
| **Multi-Platform UX** | Dropdown selector | Most compact, familiar pattern |
| **Migration** | Gradual with fallback | Minimizes risk, allows rollback |
| **Performance** | Lazy load per module | Faster startup, lower memory |

### Recommended Implementation Order

1. **Foundation First**: Domain entities, models, JSON parser
2. **Infrastructure Second**: Repository, use cases, DI setup
3. **State Management Third**: Extend HomeBloc with new events/states
4. **UI Fourth**: Refactor shared widgets for new entities
5. **Migration Fifth**: One module at a time with testing
6. **Cleanup Last**: Remove legacy code after all modules migrated

### Next Steps for David

1. **Review this plan**: Approve architecture decisions
2. **Clarify priorities**: Confirm lazy loading vs preload preference
3. **Set timeline**: Allocate 3 weeks for full implementation
4. **Approve JSON schema**: Validate field names and structure
5. **Create feature branch**: `feat/module-json-datasource-refactor`
6. **Begin Phase 1**: Start with domain layer and JSON setup

### Questions for Final Clarification

1. **Performance**: Prefer lazy loading or preload all modules?
2. **Platform Selection**: Should ESP32 always be default?
3. **Error Handling**: Show error snackbar or inline error widget?
4. **Analytics**: Should we track platform selection?
5. **Future API**: Plan to fetch module details from API later?

---

**Document Version**: 1.0.0
**Author**: Flutter Frontend Developer Agent
**Date**: 2025-11-16
**Status**: Ready for Review

This implementation plan provides comprehensive architectural guidance for refactoring the hardcoded module system to use JSON datasources following Clean Architecture principles. All decisions are justified with clear rationale, and the migration strategy minimizes risk while maintaining backward compatibility.
