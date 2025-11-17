# Module JSON Datasource Refactoring - Detailed Implementation Plan

**Project**: Makers Lab Mobile App
**Feature**: GitHub Issue #15 - Refactor hardcoded modules to JSON datasource
**Branch**: `feat/module-json-datasource-refactor`
**Author**: Flutter Frontend Developer Agent
**Date**: 2025-11-16
**Status**: Ready for Implementation

---

## Executive Summary

This document provides step-by-step implementation instructions for refactoring the 4 hardcoded IoT modules (Temperature, Servo, Gamepad, Light Control) to use a JSON datasource with multi-platform INO file support. The implementation follows Clean Architecture principles and extends the existing `home` feature.

**Key Decisions** (Approved by David):
- ✅ **Performance**: Lazy load per module (on-demand)
- ✅ **Platform Default**: Remember last selection (SharedPreferences)
- ✅ **Error Handling**: Snackbar with retry
- ✅ **Analytics**: Track platform selection
- ✅ **UI Pattern**: TABS (Segmented Button) for ESP32 vs Arduino UNO selection

**Estimated Timeline**: 3 weeks (60-80 hours)

---

## Phase 1: Domain Layer Foundation (Week 1, Days 1-2)

### 1.1 Create `InoFile` Entity

**File**: `lib/features/home/domain/entities/ino_file.dart`

```dart
// ABOUTME: Domain entity representing a platform-specific Arduino INO file
// ABOUTME: Supports multiple platforms (ESP32, Arduino UNO) per module

enum InoPlatform {
  esp32('ESP32'),
  arduinoUno('Arduino UNO');

  final String displayName;
  const InoPlatform(this.displayName);

  static InoPlatform fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ESP32':
        return InoPlatform.esp32;
      case 'ARDUINO UNO':
        return InoPlatform.arduinoUno;
      default:
        throw ArgumentError('Unknown platform: $value');
    }
  }
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

### 1.2 Create `ModuleDetail` Entity

**File**: `lib/features/home/domain/entities/module_detail.dart`

```dart
// ABOUTME: Domain entity representing detailed module information for IoT modules
// ABOUTME: Includes instructions, materials, videos, and multi-platform INO files

import 'instruction_item.dart';
import 'material_item.dart';
import 'ino_file.dart';

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

### 1.3 Move Entities from Core to Home Feature

**Action**: MOVE (not copy) these files:

**From**: `lib/core/domain/entities/instruction.dart`
**To**: `lib/features/home/domain/entities/instruction_item.dart`

**From**: `lib/core/domain/entities/material.dart`
**To**: `lib/features/home/domain/entities/material_item.dart`

**Important**: Update all import statements across the codebase after moving.

### 1.4 Create Use Cases

**File**: `lib/features/home/domain/usecases/get_module_detail.dart`

```dart
// ABOUTME: Use case for fetching a single module detail by ID
// ABOUTME: Returns Either with Failure or ModuleDetail entity

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/module_detail.dart';
import '../repositories/home_repository.dart';

class GetModuleDetail {
  final HomeRepository repository;

  GetModuleDetail({required this.repository});

  Future<Either<Failure, ModuleDetail>> call(String moduleId) async {
    return await repository.getModuleDetailById(moduleId);
  }
}
```

**File**: `lib/features/home/domain/usecases/get_all_module_details.dart`

```dart
// ABOUTME: Use case for fetching all module details from datasource
// ABOUTME: Used for preloading or cache warming scenarios

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/module_detail.dart';
import '../repositories/home_repository.dart';

class GetAllModuleDetails {
  final HomeRepository repository;

  GetAllModuleDetails({required this.repository});

  Future<Either<Failure, List<ModuleDetail>>> call() async {
    return await repository.getAllModuleDetails();
  }
}
```

### 1.5 Extend Repository Interface

**File**: `lib/features/home/domain/repositories/home_repository.dart`

**Action**: ADD these methods to the existing interface:

```dart
  // NEW METHODS - Module Detail Support
  Future<Either<Failure, ModuleDetail>> getModuleDetailById(String id);
  Future<Either<Failure, List<ModuleDetail>>> getAllModuleDetails();
  Future<Either<Failure, void>> cacheModuleDetails(List<ModuleDetail> details);
```

---

## Phase 2: Data Layer Implementation (Week 1, Days 3-5)

### 2.1 Create Data Models

**File**: `lib/features/home/data/models/ino_file_model.dart`

```dart
// ABOUTME: Data model for InoFile entity with JSON serialization
// ABOUTME: Maps between domain entity and JSON representation

import '../../domain/entities/ino_file.dart';

class InoFileModel extends InoFile {
  InoFileModel({
    required super.platform,
    required super.fileName,
    required super.filePath,
    super.description,
  });

  factory InoFileModel.fromJson(Map<String, dynamic> json) {
    return InoFileModel(
      platform: InoPlatform.fromString(json['platform'] as String),
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform.displayName,
      'fileName': fileName,
      'filePath': filePath,
      'description': description,
    };
  }
}
```

**File**: `lib/features/home/data/models/instruction_item_model.dart`

```dart
// ABOUTME: Data model for InstructionItem entity with JSON serialization
// ABOUTME: Handles instruction steps with images and actions

import '../../domain/entities/instruction_item.dart';

class InstructionItemModel extends InstructionItem {
  InstructionItemModel({
    required super.title,
    required super.description,
    required super.actionType,
    super.imagePath,
    super.actionValue,
  });

  factory InstructionItemModel.fromJson(Map<String, dynamic> json) {
    return InstructionItemModel(
      title: json['title'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?,
      actionType: _parseActionType(json['actionType'] as String),
      actionValue: json['actionValue'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'actionType': actionType.name,
      'actionValue': actionValue,
    };
  }

  static InstructionItemType _parseActionType(String value) {
    switch (value) {
      case 'internalRoute':
        return InstructionItemType.internalRoute;
      case 'externalUrl':
        return InstructionItemType.externalUrl;
      case 'modalBottomSheet':
        return InstructionItemType.modalBottomSheet;
      case 'none':
      default:
        return InstructionItemType.none;
    }
  }
}
```

**File**: `lib/features/home/data/models/material_item_model.dart`

```dart
// ABOUTME: Data model for MaterialItem entity with JSON serialization
// ABOUTME: Represents required components for module assembly

import '../../domain/entities/material_item.dart';

class MaterialItemModel extends MaterialItem {
  MaterialItemModel({
    required super.title,
    required super.description,
    required super.qty,
    required super.actionType,
    super.imagePath,
    super.actionValue,
  });

  factory MaterialItemModel.fromJson(Map<String, dynamic> json) {
    return MaterialItemModel(
      title: json['title'] as String,
      description: json['description'] as String,
      qty: json['qty'] as String,
      imagePath: json['imagePath'] as String?,
      actionType: _parseActionType(json['actionType'] as String),
      actionValue: json['actionValue'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'qty': qty,
      'imagePath': imagePath,
      'actionType': actionType.name,
      'actionValue': actionValue,
    };
  }

  static MaterialItemType _parseActionType(String value) {
    switch (value) {
      case 'internalRoute':
        return MaterialItemType.internalRoute;
      case 'externalUrl':
        return MaterialItemType.externalUrl;
      case 'modalBottomSheet':
        return MaterialItemType.modalBottomSheet;
      case 'none':
      default:
        return MaterialItemType.none;
    }
  }
}
```

**File**: `lib/features/home/data/models/module_detail_model.dart`

```dart
// ABOUTME: Data model for ModuleDetail entity with comprehensive JSON serialization
// ABOUTME: Aggregates instructions, materials, and multi-platform INO files

import '../../domain/entities/module_detail.dart';
import 'instruction_item_model.dart';
import 'material_item_model.dart';
import 'ino_file_model.dart';

class ModuleDetailModel extends ModuleDetail {
  ModuleDetailModel({
    required super.id,
    required super.title,
    required super.description,
    required super.route,
    required super.interfaceRoute,
    required super.instructions,
    required super.materials,
    required super.inoFiles,
    super.image,
    super.videoId,
    super.chatModuleKey,
  });

  factory ModuleDetailModel.fromJson(Map<String, dynamic> json) {
    return ModuleDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      route: json['route'] as String,
      interfaceRoute: json['interfaceRoute'] as String,
      image: json['image'] as String?,
      videoId: json['videoId'] as String?,
      chatModuleKey: json['chatModuleKey'] as String?,
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => InstructionItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      materials: (json['materials'] as List<dynamic>)
          .map((e) => MaterialItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      inoFiles: (json['inoFiles'] as List<dynamic>)
          .map((e) => InoFileModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'route': route,
      'interfaceRoute': interfaceRoute,
      'image': image,
      'videoId': videoId,
      'chatModuleKey': chatModuleKey,
      'instructions': instructions
          .map((e) => (e as InstructionItemModel).toJson())
          .toList(),
      'materials':
          materials.map((e) => (e as MaterialItemModel).toJson()).toList(),
      'inoFiles': inoFiles.map((e) => (e as InoFileModel).toJson()).toList(),
    };
  }
}
```

### 2.2 Create JSON Parser

**File**: `lib/features/home/data/datasources/module_detail_json_parser.dart`

```dart
// ABOUTME: Parses modules_detail.json file with comprehensive error handling
// ABOUTME: Validates schema and provides detailed logging for debugging

import 'dart:convert';
import '../../../../core/data/services/logger_service.dart';
import '../models/module_detail_model.dart';

class ModuleDetailJsonParser {
  final ILogger logger;

  ModuleDetailJsonParser({required this.logger});

  Future<List<ModuleDetailModel>> parseModulesJson(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate schema version
      final version = data['version'] as String?;
      if (version == null) {
        logger.warning('Missing schema version in modules JSON');
      } else {
        logger.info('Parsing modules JSON version: $version');
      }

      // Validate modules array exists
      final modulesJson = data['modules'] as List<dynamic>?;
      if (modulesJson == null || modulesJson.isEmpty) {
        logger.warning('No modules found in JSON');
        return [];
      }

      // Parse each module with detailed error handling
      final modules = <ModuleDetailModel>[];
      for (int i = 0; i < modulesJson.length; i++) {
        try {
          final moduleJson = modulesJson[i] as Map<String, dynamic>;
          final module = ModuleDetailModel.fromJson(moduleJson);
          modules.add(module);
          logger.info('Successfully parsed module: ${module.id}');
        } catch (e, stackTrace) {
          logger.error('Failed to parse module at index $i', e, stackTrace);
          // Continue parsing other modules instead of failing completely
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

### 2.3 Extend Local Datasource

**File**: `lib/features/home/data/datasources/home_local_datasource.dart`

**Action**: ADD these methods to the existing interface:

```dart
  // NEW METHODS - Module Detail Support
  Future<ModuleDetailModel> getModuleDetailById(String id);
  Future<List<ModuleDetailModel>> getAllModuleDetails();
  Future<void> cacheModuleDetails(List<ModuleDetailModel> details);
```

**File**: `lib/features/home/data/datasources/home_local_datasource_impl.dart`

**Action**: ADD constructor parameter and implement new methods:

```dart
// Add to constructor
  final ModuleDetailJsonParser jsonParser;

// Add cache key constant
const _kModuleDetailsKey = 'CACHED_MODULE_DETAILS_v1';

// Implement new methods
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
```

### 2.4 Extend Repository Implementation

**File**: `lib/features/home/data/repositories/home_repository_impl.dart`

**Action**: ADD implementation methods:

```dart
  @override
  Future<Either<Failure, ModuleDetail>> getModuleDetailById(String id) async {
    try {
      final detail = await localDatasource.getModuleDetailById(id);
      return Right(detail);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ModuleDetail>>> getAllModuleDetails() async {
    try {
      final details = await localDatasource.getAllModuleDetails();
      return Right(details);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheModuleDetails(
    List<ModuleDetail> details,
  ) async {
    try {
      final models = details
          .map((d) => ModuleDetailModel(
                id: d.id,
                title: d.title,
                description: d.description,
                route: d.route,
                interfaceRoute: d.interfaceRoute,
                instructions: d.instructions,
                materials: d.materials,
                inoFiles: d.inoFiles,
                image: d.image,
                videoId: d.videoId,
                chatModuleKey: d.chatModuleKey,
              ))
          .toList();
      await localDatasource.cacheModuleDetails(models);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Unexpected error: ${e.toString()}'));
    }
  }
```

---

## Phase 3: JSON Datasource Creation (Week 1, Day 5)

### 3.1 Extract Hardcoded Data

**IMPORTANT**: Before creating the JSON, you MUST extract the current hardcoded data from these module pages:

1. `lib/features/temperature/presentation/pages/temperature_page.dart`
2. `lib/features/servo/presentation/pages/servo_page.dart`
3. `lib/features/gamepad/presentation/pages/gamepad_page.dart`
4. `lib/features/light_control/presentation/pages/light_control_page.dart`

Look for the `MainModule` instances with instructions, materials, videoId, etc.

### 3.2 Create JSON File

**File**: `assets/data/modules/modules_detail.json`

**Structure**: (Example with Temperature module - repeat for all 4 modules)

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
          "description": "Código para Arduino UNO con módulo HC-05"
        }
      ],
      "instructions": [
        {
          "title": "1. Conectar el sensor DHT11",
          "description": "Coloca el sensor DHT11 en el protoboard...",
          "imagePath": "assets/images/static/temperature/instructions/instruction1.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        }
      ],
      "materials": [
        {
          "title": "Microcontrolador ESP32",
          "description": "Placa de desarrollo ESP32 con WiFi y Bluetooth",
          "qty": "1",
          "imagePath": "assets/images/static/materials/esp32.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        }
      ]
    }
    // ... repeat for servo, gamepad, light_control modules
  ]
}
```

**CRITICAL**: You MUST include ALL 4 modules: temperature, servo, gamepad, light_control

### 3.3 Update pubspec.yaml

**File**: `pubspec.yaml`

**Action**: ADD to assets section:

```yaml
  assets:
    # ... existing assets ...
    - assets/data/modules/
```

---

## Phase 4: BLoC Extension (Week 2, Days 1-2)

### 4.1 Add Events

**File**: `lib/features/home/presentation/bloc/home_event.dart`

**Action**: ADD these event classes:

```dart
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

### 4.2 Extend State

**File**: `lib/features/home/presentation/bloc/home_state.dart`

**Action**: ADD these fields and update copyWith:

```dart
class HomeState {
  // ... existing fields ...
  final Map<String, ModuleDetail> moduleDetails; // NEW
  final bool isLoadingModuleDetails;             // NEW
  final String? moduleDetailError;               // NEW

  const HomeState({
    // ... existing parameters ...
    this.moduleDetails = const {},
    this.isLoadingModuleDetails = false,
    this.moduleDetailError,
  });

  HomeState copyWith({
    // ... existing parameters ...
    Map<String, ModuleDetail>? moduleDetails,
    bool? isLoadingModuleDetails,
    String? moduleDetailError,
  }) {
    return HomeState(
      // ... existing assignments ...
      moduleDetails: moduleDetails ?? this.moduleDetails,
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

### 4.3 Extend BLoC

**File**: `lib/features/home/presentation/bloc/home_bloc.dart`

**Action**: ADD dependencies and event handlers:

```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  // ... existing fields ...
  final GetModuleDetail getModuleDetail;        // NEW
  final GetAllModuleDetails getAllModuleDetails; // NEW

  HomeBloc({
    // ... existing parameters ...
    required this.getModuleDetail,
    required this.getAllModuleDetails,
  }) : super(const HomeState()) {
    // ... existing event handlers ...
    on<LoadModuleDetail>(_onLoadModuleDetail);
    on<LoadAllModuleDetails>(_onLoadAllModuleDetails);
    on<ClearModuleDetailCache>(_onClearModuleDetailCache);
  }

  Future<void> _onLoadModuleDetail(
    LoadModuleDetail event,
    Emitter<HomeState> emit,
  ) async {
    // Check if already loaded (caching)
    if (state.moduleDetails.containsKey(event.moduleId)) {
      return; // Already cached, no need to reload
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

  Future<void> _onClearModuleDetailCache(
    ClearModuleDetailCache event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(moduleDetails: const {}));
  }
}
```

---

## Phase 5: Widget Refactoring (Week 2, Days 3-4)

### 5.1 Refactor BuildMainContent Widget

**File**: `lib/shared/widgets/modules/build_main_content.dart`

**CRITICAL CHANGES**:
1. Change parameter from `MainModule` to `ModuleDetail`
2. Add StatefulWidget for platform selection
3. Implement TABS (Segmented Button) for platform selection
4. Save selected platform to SharedPreferences
5. Update share functionality to use selected platform's INO file

**Full Implementation**:

```dart
// ABOUTME: Main content builder for module details pages with platform selection
// ABOUTME: Uses tabs (segmented button) for ESP32 vs Arduino UNO platform selection

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/domain/entities/module_detail.dart';
import '../../features/home/domain/entities/ino_file.dart';
import '../../core/domain/usecases/share_file_usecase.dart';
import '../../core/ui/snackbar_service.dart';
import '../../di/service_locator.dart';
import '../../theme/app_color.dart';
import 'index.dart';

class BuildMainContent extends StatefulWidget {
  final ModuleDetail moduleDetail;

  const BuildMainContent({super.key, required this.moduleDetail});

  @override
  State<BuildMainContent> createState() => _BuildMainContentState();
}

class _BuildMainContentState extends State<BuildMainContent> {
  late InoPlatform _selectedPlatform;
  static const String _kPlatformSelectionKey = 'LAST_SELECTED_PLATFORM';

  @override
  void initState() {
    super.initState();
    _loadLastSelectedPlatform();
  }

  Future<void> _loadLastSelectedPlatform() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlatform = prefs.getString(_kPlatformSelectionKey);

    setState(() {
      if (lastPlatform != null) {
        try {
          _selectedPlatform = InoPlatform.fromString(lastPlatform);
        } catch (e) {
          _selectedPlatform = InoPlatform.esp32; // Fallback
        }
      } else {
        _selectedPlatform = InoPlatform.esp32; // Default
      }
    });
  }

  Future<void> _saveSelectedPlatform(InoPlatform platform) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPlatformSelectionKey, platform.displayName);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform Selector (only show if multiple platforms available)
        if (widget.moduleDetail.inoFiles.length > 1)
          _buildPlatformSelector(),

        const SizedBox(height: 16),

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

        // Instructions Section
        InstructionsSection(instructions: widget.moduleDetail.instructions),
        const SizedBox(height: 30),

        // Video Player
        if (widget.moduleDetail.videoId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: YouTubePlayer(
                videoId: widget.moduleDetail.videoId!,
              ),
            ),
          ),

        const SizedBox(height: 30),

        // Materials Section
        BillOfMaterialsSection(materials: widget.moduleDetail.materials),
        const SizedBox(height: 200),
      ],
    );
  }

  /// Platform Selector Widget (Tabs/Segmented Button)
  Widget _buildPlatformSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Text(
            'Plataforma:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 8),

          // Segmented Button (Tabs)
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<InoPlatform>(
              segments: [
                ButtonSegment<InoPlatform>(
                  value: InoPlatform.esp32,
                  label: const Text('ESP32'),
                  icon: const Icon(Icons.memory, size: 18),
                ),
                ButtonSegment<InoPlatform>(
                  value: InoPlatform.arduinoUno,
                  label: const Text('Arduino UNO'),
                  icon: const Icon(Icons.developer_board, size: 18),
                ),
              ],
              selected: {_selectedPlatform},
              onSelectionChanged: (Set<InoPlatform> selected) {
                setState(() {
                  _selectedPlatform = selected.first;
                });
                _saveSelectedPlatform(selected.first);

                // Analytics tracking (if implemented)
                // AnalyticsService.logEvent(
                //   name: 'platform_selected',
                //   parameters: {
                //     'module_id': widget.moduleDetail.id,
                //     'platform': selected.first.name,
                //   },
                // );
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.white;
                  }
                  return AppColors.primary;
                }),
                side: WidgetStateProperty.all(
                  const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDownloadAndShare(BuildContext context) async {
    final shareFileUseCase = getIt<ShareFileUseCase>();
    final snackbarService = getIt<SnackbarService>();

    // Get selected platform's INO file
    final selectedInoFile = widget.moduleDetail.inoFiles.firstWhere(
      (file) => file.platform == _selectedPlatform,
      orElse: () => widget.moduleDetail.inoFiles.first, // Fallback
    );

    // Share file with platform-specific text
    final result = await shareFileUseCase(
      assetPath: selectedInoFile.filePath,
      fileName: selectedInoFile.fileName,
      text:
          'Código ${_selectedPlatform.displayName} para ${widget.moduleDetail.title}',
      subject: 'Archivo INO - ${widget.moduleDetail.title}',
    );

    // Error handling
    result.fold(
      (failure) {
        String errorMessage;
        if (failure.message.contains('no encontrado')) {
          errorMessage = 'Error al compartir archivo: Archivo no encontrado';
        } else if (failure.message.contains('guardar')) {
          errorMessage =
              'Error al compartir archivo: No se pudo guardar el archivo';
        } else if (failure.message.contains('plataforma')) {
          errorMessage = 'Error al compartir archivo: Error de la plataforma';
        } else {
          errorMessage = 'Error al compartir archivo: Error desconocido';
        }

        snackbarService.show(
          message: errorMessage,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          style: SnackbarStyle.withClose,
        );
      },
      (_) {
        // Success - no confirmation needed
      },
    );
  }
}
```

---

## Phase 6: Module Page Migration (Week 2, Day 5 - Week 3, Day 2)

### 6.1 Migration Pattern (Apply to All 4 Modules)

**Template for Module Page Refactoring**:

**BEFORE** (Example: temperature_page.dart):
```dart
class TemperaturePage extends StatelessWidget {
  TemperaturePage({super.key});

  final MainModule mainModule = MainModule(...); // HARDCODED

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

**AFTER**:
```dart
class TemperaturePage extends StatelessWidget {
  static const String routeName = '/temperature';
  static const String moduleId = 'temperature';

  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Trigger lazy load if not already loaded
        if (state.getModuleDetail(moduleId) == null &&
            !state.isLoadingModuleDetails) {
          context.read<HomeBloc>().add(
                const LoadModuleDetail(moduleId: moduleId),
              );
        }

        final moduleDetail = state.getModuleDetail(moduleId);

        return Scaffold(
          appBar: AppBar(/* ... */),
          body: SafeArea(
            child: _buildBody(context, state, moduleDetail),
          ),
          floatingActionButton: PxChatBotFloatingButton(
            chatKey: moduleDetail?.chatModuleKey ?? '',
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    HomeState state,
    ModuleDetail? moduleDetail,
  ) {
    // Loading state
    if (moduleDetail == null && state.isLoadingModuleDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (moduleDetail == null && state.moduleDetailError != null) {
      return ErrorView(
        message: state.moduleDetailError!,
        onRetry: () => context.read<HomeBloc>().add(
              const LoadModuleDetail(moduleId: moduleId),
            ),
      );
    }

    // Success state
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

    // Fallback
    return const Center(child: Text('No se pudo cargar el módulo'));
  }
}
```

### 6.2 Module Pages to Migrate

**CRITICAL**: Apply the above pattern to ALL 4 module pages:

1. **Temperature**: `lib/features/temperature/presentation/pages/temperature_page.dart`
   - moduleId: `'temperature'`
   - Remove hardcoded `MainModule` instance

2. **Servo**: `lib/features/servo/presentation/pages/servo_page.dart`
   - moduleId: `'servo'`
   - Remove hardcoded `MainModule` instance

3. **Gamepad**: `lib/features/gamepad/presentation/pages/gamepad_page.dart`
   - moduleId: `'gamepad'`
   - Remove hardcoded `MainModule` instance

4. **Light Control**: `lib/features/light_control/presentation/pages/light_control_page.dart`
   - moduleId: `'light_control'`
   - Remove hardcoded `MainModule` instance

---

## Phase 7: Dependency Injection (Week 3, Day 2)

### 7.1 Update Service Locator

**File**: `lib/di/service_locator.dart`

**Action**: ADD registrations in the appropriate sections:

```dart
Future<void> setupServiceLocator() async {
  // ... existing registrations ...

  // JSON Parser (NEW)
  getIt.registerLazySingleton<ModuleDetailJsonParser>(
    () => ModuleDetailJsonParser(logger: getIt()),
  );

  // Update HomeLocalDatasource registration
  getIt.registerLazySingleton<HomeLocalDatasource>(
    () => HomeLocalDatasourceImpl(
      prefs: getIt(),
      logger: getIt(),
      jsonParser: getIt(),  // NEW PARAMETER
    ),
  );

  // Repository remains the same (implementation extended)

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
      getModuleDetail: getIt(),        // NEW DEPENDENCY
      getAllModuleDetails: getIt(),    // NEW DEPENDENCY
    ),
  );
}
```

---

## Phase 8: Cleanup (Week 3, Day 3)

### 8.1 Delete Legacy Files

**CRITICAL**: Only delete these files AFTER successful migration and testing:

1. **Delete**: `lib/core/domain/entities/module.dart` (old MainModule)
2. **Delete**: `lib/core/domain/entities/instruction.dart` (moved to home)
3. **Delete**: `lib/core/domain/entities/material.dart` (moved to home)

### 8.2 Update Import Statements

**Action**: Find and replace all import statements:

**OLD**:
```dart
import 'package:makerslab_app/core/domain/entities/module.dart';
import 'package:makerslab_app/core/domain/entities/instruction.dart';
import 'package:makerslab_app/core/domain/entities/material.dart';
```

**NEW**:
```dart
import 'package:makerslab_app/features/home/domain/entities/module_detail.dart';
import 'package:makerslab_app/features/home/domain/entities/instruction_item.dart';
import 'package:makerslab_app/features/home/domain/entities/material_item.dart';
```

---

## Phase 9: Testing (Week 3, Days 3-5) - MANDATORY

### 9.1 Unit Tests - JSON Parser

**File**: `test/features/home/data/datasources/module_detail_json_parser_test.dart`

```dart
// ABOUTME: Unit tests for ModuleDetailJsonParser with valid/invalid JSON scenarios
// ABOUTME: Tests schema validation, error handling, and partial parsing

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:makerslab_app/core/data/services/logger_service.dart';
import 'package:makerslab_app/features/home/data/datasources/module_detail_json_parser.dart';
import 'package:makerslab_app/features/home/data/models/module_detail_model.dart';

class MockLogger extends Mock implements ILogger {}

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
            "description": "Test module",
            "route": "/temperature",
            "interfaceRoute": "/temperature-interface",
            "instructions": [],
            "materials": [],
            "inoFiles": [
              {
                "platform": "ESP32",
                "fileName": "test.ino",
                "filePath": "assets/test.ino"
              }
            ]
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

    test('should return empty list for empty modules array', () async {
      // Arrange
      const jsonString = '{"version": "1.0.0", "modules": []}';

      // Act
      final result = await parser.parseModulesJson(jsonString);

      // Assert
      expect(result, isEmpty);
    });

    test('should continue parsing after individual module error', () async {
      // Arrange
      const jsonString = '''
      {
        "version": "1.0.0",
        "modules": [
          {
            "id": "valid",
            "title": "Valid Module",
            "description": "Test",
            "route": "/test",
            "interfaceRoute": "/test-interface",
            "instructions": [],
            "materials": [],
            "inoFiles": []
          },
          {
            "invalid": "data"
          },
          {
            "id": "also_valid",
            "title": "Also Valid",
            "description": "Test",
            "route": "/test2",
            "interfaceRoute": "/test2-interface",
            "instructions": [],
            "materials": [],
            "inoFiles": []
          }
        ]
      }
      ''';

      // Act
      final result = await parser.parseModulesJson(jsonString);

      // Assert
      expect(result.length, 2); // Only valid modules parsed
      verify(mockLogger.error(any, any, any)).called(1); // Error logged
    });
  });
}
```

### 9.2 Unit Tests - Repository

**File**: `test/features/home/data/repositories/home_repository_impl_test.dart`

**Action**: EXTEND existing test file with new test cases:

```dart
  group('getModuleDetailById', () {
    const testId = 'temperature';
    final testDetail = ModuleDetailModel(
      id: testId,
      title: 'Test',
      description: 'Test',
      route: '/test',
      interfaceRoute: '/test-interface',
      instructions: [],
      materials: [],
      inoFiles: [],
    );

    test('should return ModuleDetail on success', () async {
      // Arrange
      when(mockLocalDatasource.getModuleDetailById(testId))
          .thenAnswer((_) async => testDetail);

      // Act
      final result = await repository.getModuleDetailById(testId);

      // Assert
      expect(result, isA<Right>());
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
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, 'Not found');
        },
        (_) => fail('Should return Left'),
      );
    });
  });
```

### 9.3 BLoC Tests

**File**: `test/features/home/presentation/bloc/home_bloc_test.dart`

**Action**: EXTEND with new event tests using `bloc_test`:

```dart
import 'package:bloc_test/bloc_test.dart';

  group('LoadModuleDetail', () {
    const testId = 'temperature';
    final testDetail = ModuleDetail(
      id: testId,
      title: 'Test',
      description: 'Test',
      route: '/test',
      interfaceRoute: '/test-interface',
      instructions: [],
      materials: [],
      inoFiles: [],
    );

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
      expect: () => [], // No state changes
    );

    blocTest<HomeBloc, HomeState>(
      'emits error state on failure',
      build: () {
        when(mockGetModuleDetail(testId))
            .thenAnswer((_) async => const Left(CacheFailure(message: 'Error')));
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
```

### 9.4 Widget Tests

**File**: `test/shared/widgets/modules/build_main_content_test.dart`

```dart
// ABOUTME: Widget tests for BuildMainContent with platform selector
// ABOUTME: Tests rendering, platform switching, and conditional display

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makerslab_app/shared/widgets/modules/build_main_content.dart';
import 'package:makerslab_app/features/home/domain/entities/module_detail.dart';
import 'package:makerslab_app/features/home/domain/entities/ino_file.dart';

void main() {
  testWidgets('displays platform selector when multiple platforms available',
      (tester) async {
    // Arrange
    final moduleDetail = ModuleDetail(
      id: 'test',
      title: 'Test Module',
      description: 'Test',
      route: '/test',
      interfaceRoute: '/test-interface',
      instructions: [],
      materials: [],
      inoFiles: [
        InoFile(
          platform: InoPlatform.esp32,
          fileName: 'esp32.ino',
          filePath: 'assets/esp32.ino',
        ),
        InoFile(
          platform: InoPlatform.arduinoUno,
          fileName: 'uno.ino',
          filePath: 'assets/uno.ino',
        ),
      ],
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
    expect(find.byType(SegmentedButton), findsOneWidget);
  });

  testWidgets('hides platform selector when only one platform',
      (tester) async {
    // Arrange
    final moduleDetail = ModuleDetail(
      id: 'test',
      title: 'Test Module',
      description: 'Test',
      route: '/test',
      interfaceRoute: '/test-interface',
      instructions: [],
      materials: [],
      inoFiles: [
        InoFile(
          platform: InoPlatform.esp32,
          fileName: 'esp32.ino',
          filePath: 'assets/esp32.ino',
        ),
      ],
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
    expect(find.text('Plataforma:'), findsNothing);
    expect(find.byType(SegmentedButton), findsNothing);
  });
}
```

### 9.5 Test Coverage Requirements

**Run Coverage**:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**MINIMUM REQUIREMENTS** (David's standard):
- Domain layer: **100%** coverage
- Data layer: **80%+** coverage
- BLoC layer: **100%** coverage
- Widget layer: **80%+** coverage

---

## Phase 10: Code Quality & Verification (Week 3, Day 5)

### 10.1 Code Formatting

```bash
dart format lib/ test/
```

### 10.2 Static Analysis

```bash
flutter analyze
```

**MUST pass with ZERO errors and ZERO warnings.**

### 10.3 ABOUTME Comments Verification

**CRITICAL**: ALL new Dart files MUST have 2-line ABOUTME comments at the top:

```dart
// ABOUTME: Brief description of what this file does
// ABOUTME: Additional context or key functionality
```

### 10.4 Manual Testing Checklist

David should manually test:

- [ ] Temperature module loads details from JSON
- [ ] Servo module loads details from JSON
- [ ] Gamepad module loads details from JSON
- [ ] Light Control module loads details from JSON
- [ ] Platform selector displays for all modules
- [ ] ESP32 tab can be selected
- [ ] Arduino UNO tab can be selected
- [ ] Selected platform is remembered (SharedPreferences)
- [ ] INO file download works for ESP32
- [ ] INO file download works for Arduino UNO
- [ ] Loading state displays correctly
- [ ] Error state displays with retry button
- [ ] Navigation to interface works
- [ ] YouTube video plays
- [ ] Instructions section displays
- [ ] Materials section displays
- [ ] App doesn't crash on resume
- [ ] No memory leaks (DevTools check)

---

## File Structure Summary

### New Files Created (35 files)

**Domain Layer**:
- `lib/features/home/domain/entities/module_detail.dart`
- `lib/features/home/domain/entities/ino_file.dart`
- `lib/features/home/domain/entities/instruction_item.dart` (moved)
- `lib/features/home/domain/entities/material_item.dart` (moved)
- `lib/features/home/domain/usecases/get_module_detail.dart`
- `lib/features/home/domain/usecases/get_all_module_details.dart`

**Data Layer**:
- `lib/features/home/data/models/module_detail_model.dart`
- `lib/features/home/data/models/ino_file_model.dart`
- `lib/features/home/data/models/instruction_item_model.dart`
- `lib/features/home/data/models/material_item_model.dart`
- `lib/features/home/data/datasources/module_detail_json_parser.dart`

**Assets**:
- `assets/data/modules/modules_detail.json`

**Tests** (9 test files):
- `test/features/home/data/datasources/module_detail_json_parser_test.dart`
- `test/features/home/data/models/module_detail_model_test.dart`
- `test/features/home/data/repositories/home_repository_impl_test.dart` (extended)
- `test/features/home/domain/usecases/get_module_detail_test.dart`
- `test/features/home/domain/usecases/get_all_module_details_test.dart`
- `test/features/home/presentation/bloc/home_bloc_test.dart` (extended)
- `test/shared/widgets/modules/build_main_content_test.dart`

### Files Modified (12 files)

**Domain Layer**:
- `lib/features/home/domain/repositories/home_repository.dart` (extended interface)

**Data Layer**:
- `lib/features/home/data/datasources/home_local_datasource.dart` (extended)
- `lib/features/home/data/datasources/home_local_datasource_impl.dart` (extended)
- `lib/features/home/data/repositories/home_repository_impl.dart` (extended)

**Presentation Layer**:
- `lib/features/home/presentation/bloc/home_bloc.dart` (extended)
- `lib/features/home/presentation/bloc/home_event.dart` (extended)
- `lib/features/home/presentation/bloc/home_state.dart` (extended)

**Shared Widgets**:
- `lib/shared/widgets/modules/build_main_content.dart` (refactored)

**Module Pages** (4 files):
- `lib/features/temperature/presentation/pages/temperature_page.dart`
- `lib/features/servo/presentation/pages/servo_page.dart`
- `lib/features/gamepad/presentation/pages/gamepad_page.dart`
- `lib/features/light_control/presentation/pages/light_control_page.dart`

**DI**:
- `lib/di/service_locator.dart` (extended)

**Config**:
- `pubspec.yaml` (added asset)

### Files Deleted (3 files)

**ONLY delete AFTER successful migration**:
- `lib/core/domain/entities/module.dart`
- `lib/core/domain/entities/instruction.dart`
- `lib/core/domain/entities/material.dart`

---

## Important Implementation Notes

### 1. Extract Hardcoded Data First

**CRITICAL**: Before creating the JSON file, you MUST:

1. Read all 4 module pages
2. Extract the hardcoded `MainModule` instances
3. Copy instructions, materials, videoId, routes, etc.
4. Verify all asset paths exist
5. Create JSON with EXACT same data

### 2. Multi-Platform INO Files

**Current State**: Some modules may only have one INO file (ESP32 or Arduino UNO).

**Action Required**:
- If Arduino UNO INO file doesn't exist, create it
- Ensure both platforms are supported for ALL 4 modules
- Verify file paths in `assets/files/` directory

### 3. Platform Selection Persistence

**Behavior**: App remembers last selected platform globally (not per module).

**Why**: Most users work with one platform type consistently.

**Future Enhancement**: Could be changed to per-module persistence if analytics show users switch platforms frequently.

### 4. Lazy Loading Strategy

**Implementation**: Module details load on-demand when user navigates to module page.

**Caching**: Once loaded, details stay in BLoC state (in-memory cache).

**Cache Invalidation**: Only cleared when:
- User logs out
- App restarts
- `ClearModuleDetailCache` event is dispatched

### 5. Error Handling

**Snackbar Pattern**: Used for non-critical errors (INO file download failed).

**Inline Error Widget**: Used for critical errors (module detail loading failed).

**Retry Functionality**: All error states include retry button.

### 6. Accessibility Compliance

**WCAG 2.1 AA Requirements**:
- ✅ Minimum 48dp tap targets (tabs)
- ✅ 4.5:1 text contrast ratio
- ✅ Screen reader support (SegmentedButton has native support)
- ✅ Keyboard navigation (Flutter handles automatically)

### 7. Analytics Tracking (Optional)

**Recommended Events**:
- `platform_selected`: When user switches platform
- `ino_download`: When user downloads INO file
- `module_viewed`: When module detail loads successfully
- `module_error`: When module detail fails to load

**Implementation**: Add after core functionality is working.

---

## Testing Strategy

### Unit Tests (30+ tests)

**JSON Parser**:
- Valid JSON parsing
- Invalid JSON handling
- Missing version field
- Empty modules array
- Partial parsing (some modules fail)
- Schema validation

**Repository**:
- Successful module detail fetch
- CacheException handling
- Module not found scenario
- All module details fetch
- Cache save/load

**Use Cases**:
- GetModuleDetail success
- GetModuleDetail failure
- GetAllModuleDetails success
- GetAllModuleDetails failure

### BLoC Tests (15+ tests)

**LoadModuleDetail Event**:
- Successful load
- Already cached (no reload)
- Failure scenario
- Multiple modules loaded sequentially

**LoadAllModuleDetails Event**:
- Successful preload
- Failure scenario

**State Transitions**:
- Loading → Success
- Loading → Error
- Cached → No state change

### Widget Tests (10+ tests)

**BuildMainContent**:
- Platform selector displays
- Platform selector hidden (single platform)
- Tab switching
- INO download button
- Interface button navigation
- Instructions section rendering
- Materials section rendering
- Video player rendering

### Integration Tests (5+ tests)

**Full Flow**:
- HomePage → Temperature module → Details loaded
- Platform switch → INO download → Share dialog
- Error state → Retry → Success
- Cached data → Instant load
- Multiple modules → Independent state

---

## Success Criteria

### Technical Metrics

- ✅ **Test Coverage**: >80% overall, 100% for critical paths
- ✅ **Code Quality**: Zero analyzer warnings
- ✅ **Performance**: Module page load <500ms
- ✅ **Memory**: <50KB overhead for JSON caching
- ✅ **Build Time**: No significant increase

### User Experience Metrics

- ✅ **Module Page Load**: <1 second perceived
- ✅ **Platform Switch**: Instant (<100ms)
- ✅ **Error Rate**: <1% of module page visits
- ✅ **Crash Rate**: No increase from baseline

### Functional Requirements

- ✅ All 4 modules load from JSON
- ✅ Platform selector works correctly
- ✅ INO download works for both platforms
- ✅ Platform selection persists across app sessions
- ✅ Loading/error states display properly
- ✅ Navigation to interfaces works
- ✅ No regressions in existing functionality
- ✅ Backward compatibility maintained (remote modules still work)

---

## Rollback Plan

If critical issues are found during testing:

1. **Revert module page changes**: Restore hardcoded `MainModule` instances
2. **Keep infrastructure**: JSON parsing, repository, BLoC extensions remain (no harm)
3. **No breaking changes**: Remote module fetching continues working
4. **User impact**: Zero (app behaves as before)

---

## Future Enhancements (Post-Implementation)

### 1. Remote JSON Fetching
- Fetch module details from API for authenticated users
- Merge remote details with local JSON
- Enable dynamic updates without app release

### 2. Multi-Language Support
- Separate JSON files per language (es, en)
- Load based on `AppLocalizations` locale
- Translate instructions, materials, descriptions

### 3. Module Versioning
- Add `version` field to each module
- Track completed module versions
- Show "Updated" badge for new versions

### 4. Offline PDF Export
- Generate PDF from module details
- Include all instructions and materials
- Shareable for offline reference

### 5. Advanced Search
- Full-text search across instructions/materials
- Filter by platform
- Filter by difficulty level

---

## Conclusion

This implementation plan provides comprehensive, step-by-step instructions for refactoring the hardcoded module system to use JSON datasources. The approach:

- ✅ Follows Clean Architecture principles strictly
- ✅ Extends existing `home` feature (no new feature module)
- ✅ Implements lazy loading for performance
- ✅ Uses Material Design 3 tabs for platform selection
- ✅ Maintains backward compatibility
- ✅ Includes comprehensive testing strategy
- ✅ Meets David's 80% test coverage requirement

**IMPORTANT**: This is an implementation plan, NOT actual implementation. David should review and approve before proceeding with actual code changes.

---

**Document Version**: 1.0.0
**Last Updated**: 2025-11-16
**Status**: Ready for Review & Implementation
**Estimated Effort**: 60-80 hours (3 weeks)

**Questions for David**:
1. Approve tabs (segmented button) for platform selection? ✅ (Recommended by UI/UX analysis)
2. Approve lazy loading strategy? ✅ (Confirmed in session context)
3. Approve ESP32 as default platform? (Needs confirmation)
4. Should analytics tracking be included in initial implementation? (Optional)
5. Are all Arduino UNO INO files ready in `assets/files/`? (Needs verification)

David, please review this plan carefully and provide approval or feedback before implementation begins.
