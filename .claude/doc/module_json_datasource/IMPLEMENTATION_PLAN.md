# Module JSON Datasource Refactoring - Final Implementation Plan

**Project**: Makers Lab Mobile App - Static Module Refactoring
**Owner**: David
**Date**: 2025-11-16
**Status**: READY FOR IMPLEMENTATION ✅
**Estimated Duration**: 3 Weeks (15 working days)

---

## Executive Summary

This plan refactors the 4 static IoT modules (Temperature, Servo, Gamepad, Light Control) from **hardcoded** `MainModule` instances to a **JSON datasource** with multi-platform INO file support (ESP32 + Arduino UNO).

### Key Decisions (All Approved by David):
- ✅ **Architecture**: Extend `home` feature with JSON datasource
- ✅ **Performance**: Lazy loading (load per module on-demand)
- ✅ **Platform UI**: Tabs (SegmentedButton) - NOT dropdown
- ✅ **Platform Default**: Arduino UNO (save last selection to SharedPreferences)
- ✅ **Error Handling**: Snackbar with retry (static modules shouldn't fail)
- ✅ **Analytics**: Track platform selection (ESP32 vs Arduino UNO)
- ✅ **Future API**: Plan for backend integration (separate task)

### Scope:
- ✅ **In Scope**: 4 static local modules (Temperature, Servo, Gamepad, Light Control)
- ❌ **Out of Scope**: Remote modules (API-based, paid content) - different architecture

---

## Table of Contents

1. [Phase 1: Foundation (Week 1)](#phase-1-foundation-week-1)
2. [Phase 2: BLoC & Widgets (Week 2)](#phase-2-bloc--widgets-week-2)
3. [Phase 3: Migration & Cleanup (Week 3)](#phase-3-migration--cleanup-week-3)
4. [Testing Requirements](#testing-requirements)
5. [File Structure](#file-structure)
6. [Backend Coordination](#backend-coordination)
7. [Risk Mitigation](#risk-mitigation)
8. [Success Metrics](#success-metrics)

---

## Phase 1: Foundation (Week 1)

**Duration**: 5 days
**Goal**: Set up domain layer, data infrastructure, and JSON datasource

### Day 1: Domain Layer Setup

#### Tasks:
1. **Create Entity Files** (4 new entities)

```dart
// lib/features/home/domain/entities/module_detail.dart
class ModuleDetail {
  final String id;
  final String title;
  final String description;
  final String route;
  final String interfaceRoute;
  final String? image;
  final String? videoId;
  final String? chatModuleKey;
  final List<InstructionItem> instructions;
  final List<MaterialItem> materials;
  final List<InoFile> inoFiles;

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

```dart
// lib/features/home/domain/entities/ino_file.dart
enum InoPlatform {
  esp32('ESP32'),
  arduinoUno('Arduino UNO');

  final String apiValue;
  const InoPlatform(this.apiValue);
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

2. **Move Existing Entities** (from core to home feature)

```bash
# Move instruction_item.dart
git mv lib/core/domain/entities/instruction.dart \
       lib/features/home/domain/entities/instruction_item.dart

# Move material_item.dart
git mv lib/core/domain/entities/material.dart \
       lib/features/home/domain/entities/material_item.dart
```

3. **Update Imports** (find and replace across codebase)

```bash
# Find all imports of old paths
rg "import.*core/domain/entities/instruction" -l
rg "import.*core/domain/entities/material" -l

# Replace with new paths (manual or script)
```

**Deliverables**:
- ✅ 4 new entity files created
- ✅ Old entities moved to home feature
- ✅ All imports updated
- ✅ `flutter analyze` passes with 0 errors

**Acceptance Criteria**:
- All domain entities have proper ABOUTME comments
- No dependencies on Flutter (pure Dart)
- Entities follow existing patterns (simple classes, no Equatable)

---

### Day 2: Data Models & JSON Parser

#### Tasks:

1. **Create Data Models** (with fromJson/toJson)

```dart
// lib/features/home/data/models/module_detail_model.dart
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
      inoFiles: (json['inoFiles'] as List<dynamic>)
          .map((e) => InoFileModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => InstructionItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      materials: (json['materials'] as List<dynamic>)
          .map((e) => MaterialItemModel.fromJson(e as Map<String, dynamic>))
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
      'inoFiles': inoFiles.map((e) => InoFileModel.fromEntity(e).toJson()).toList(),
      'instructions': instructions.map((e) => InstructionItemModel.fromEntity(e).toJson()).toList(),
      'materials': materials.map((e) => MaterialItemModel.fromEntity(e).toJson()).toList(),
    };
  }
}
```

2. **Create JSON Parser** (with validation and error handling)

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

      // Validate modules array
      final modulesJson = data['modules'] as List<dynamic>?;
      if (modulesJson == null) {
        throw const FormatException('Missing modules array');
      }

      // Parse each module with error recovery
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

**Deliverables**:
- ✅ 4 model classes with fromJson/toJson
- ✅ JSON parser with validation
- ✅ Error recovery for partial JSON failures

**Acceptance Criteria**:
- Models extend domain entities
- JSON parsing handles all edge cases (null, missing fields, invalid types)
- Unit tests for models (fromJson/toJson round-trip)

---

### Day 3: Create JSON File & Unit Tests

#### Tasks:

1. **Create Complete JSON File** (all 4 modules)

**File**: `assets/data/modules/modules_detail.json`

```json
{
  "version": "1.0.0",
  "modules": [
    {
      "id": "temperature",
      "title": "Sensor Temperatura",
      "description": "Módulo de temperatura y humedad con sensor DHT11. Aprende a leer datos ambientales y enviarlos por Bluetooth.",
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
          "description": "Código para ESP32 con Bluetooth Classic y sensor DHT11"
        },
        {
          "platform": "Arduino UNO",
          "fileName": "uno_bt_temp.ino",
          "filePath": "assets/files/uno_bt_temp/uno_bt_temp.ino",
          "description": "Código para Arduino UNO con HC-05 Bluetooth y sensor DHT11"
        }
      ],
      "instructions": [
        {
          "title": "1. Conectar el sensor DHT11 y el módulo Bluetooth HC-05 al Protoboard",
          "description": "Coloca el sensor DHT11 en el protoboard. Conecta VCC a 5V, GND a tierra, y el pin de datos al GPIO 4 del ESP32. Para Arduino UNO, conecta el HC-05 con divisor de voltaje.",
          "imagePath": "assets/images/static/temperature/instructions/instruction1.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "2. Descargar bibliotecas necesarias",
          "description": "Instala las bibliotecas 'DHT sensor library' y 'Adafruit Unified Sensor' desde el gestor de bibliotecas de Arduino IDE.",
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
        },
        {
          "title": "Resistencia 10kΩ",
          "description": "Resistencia pull-up para el sensor DHT11",
          "qty": "1",
          "imagePath": "assets/images/static/materials/resistance10k.png",
          "actionType": "none",
          "actionValue": null
        },
        {
          "title": "Cables Dupont",
          "description": "Cables de conexión macho-macho y macho-hembra",
          "qty": "10",
          "imagePath": "assets/images/static/materials/dupont-cables.png",
          "actionType": "none",
          "actionValue": null
        },
        {
          "title": "Protoboard",
          "description": "Placa de pruebas para prototipos",
          "qty": "1",
          "imagePath": "assets/images/static/materials/breadboard.png",
          "actionType": "none",
          "actionValue": null
        }
      ]
    },
    {
      "id": "servo",
      "title": "Servo Motor",
      "description": "Control de servo motor SG90 con precisión de 0-180 grados mediante Bluetooth.",
      "route": "/servo",
      "interfaceRoute": "/servo-interface",
      "image": "assets/images/static/servo/servo2.png",
      "videoId": "YOUR_SERVO_VIDEO_ID",
      "chatModuleKey": "servo_motor",
      "inoFiles": [
        {
          "platform": "ESP32",
          "fileName": "esp32_bt_servo.ino",
          "filePath": "assets/files/esp32_bt_servo/esp32_bt_servo.ino",
          "description": "Código para ESP32 con Bluetooth Classic y servo SG90"
        },
        {
          "platform": "Arduino UNO",
          "fileName": "uno_bt_servo.ino",
          "filePath": "assets/files/uno_bt_servo/uno_bt_servo.ino",
          "description": "Código para Arduino UNO con HC-05 Bluetooth y servo SG90"
        }
      ],
      "instructions": [
        {
          "title": "1. Conectar el servo SG90 al microcontrolador",
          "description": "Conecta el cable naranja (señal) al pin GPIO 13 del ESP32 o pin 9 del Arduino UNO. Cable rojo a 5V, cable marrón a GND.",
          "imagePath": "assets/images/static/servo/instructions/instruction1.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "2. Instalar biblioteca ESP32Servo",
          "description": "Para ESP32, instala la biblioteca 'ESP32Servo' desde el gestor de bibliotecas. Para Arduino UNO, usa la biblioteca 'Servo' incluida.",
          "imagePath": null,
          "actionType": "externalUrl",
          "actionValue": "https://www.arduino.cc/reference/en/libraries/esp32servo/"
        }
      ],
      "materials": [
        {
          "title": "Servo Motor SG90",
          "description": "Servo de 180 grados, torque 1.8 kg/cm",
          "qty": "1",
          "imagePath": "assets/images/static/materials/servo-sg90.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "Microcontrolador ESP32 o Arduino UNO",
          "description": "Elige entre ESP32 (Bluetooth integrado) o Arduino UNO (requiere HC-05)",
          "qty": "1",
          "imagePath": "assets/images/static/materials/esp32.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "Fuente de alimentación 5V",
          "description": "Fuente externa para alimentar el servo (USB o batería)",
          "qty": "1",
          "imagePath": "assets/images/static/materials/powersupply.png",
          "actionType": "none",
          "actionValue": null
        }
      ]
    },
    {
      "id": "gamepad",
      "title": "Gamepad",
      "description": "Robot controlado por gamepad virtual con motores DC, servos y pinza mecánica.",
      "route": "/gamepad",
      "interfaceRoute": "/gamepad-interface",
      "image": "assets/images/static/gamepad/gamepad.png",
      "videoId": "YOUR_GAMEPAD_VIDEO_ID",
      "chatModuleKey": "gamepad_robot",
      "inoFiles": [
        {
          "platform": "ESP32",
          "fileName": "esp32_bt_gamepad.ino",
          "filePath": "assets/files/esp32_bt_gamepad/esp32_bt_gamepad.ino",
          "description": "Código para ESP32 con Bluetooth Classic, motores L298N y servos"
        },
        {
          "platform": "Arduino UNO",
          "fileName": "UNO_bt_gamepad.ino",
          "filePath": "assets/files/UNO_bt_gamepad/UNO_bt_gamepad.ino",
          "description": "Código para Arduino UNO con HC-05 Bluetooth, motores L298N y servos"
        }
      ],
      "instructions": [
        {
          "title": "1. Ensamblar chasis del robot con motores DC",
          "description": "Monta los 2 motores DC con reductora en el chasis. Conecta los motores al driver L298N.",
          "imagePath": "assets/images/static/gamepad/instructions/instruction1.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "2. Conectar servos y pinza mecánica",
          "description": "Instala los servos para el brazo robótico y la pinza. Conecta servos a pines GPIO del microcontrolador.",
          "imagePath": null,
          "actionType": "none",
          "actionValue": null
        }
      ],
      "materials": [
        {
          "title": "Motor DC con reductora",
          "description": "Motores de 6V con caja reductora y ruedas incluidas",
          "qty": "2",
          "imagePath": "assets/images/static/materials/esp32.png",
          "actionType": "none",
          "actionValue": null
        },
        {
          "title": "Driver de motores L298N",
          "description": "Controlador de motores DC dual para hasta 2A por canal",
          "qty": "1",
          "imagePath": "assets/images/static/materials/esp32.png",
          "actionType": "none",
          "actionValue": null
        },
        {
          "title": "Servo SG90",
          "description": "Servos para brazo robótico y pinza",
          "qty": "5",
          "imagePath": "assets/images/static/materials/servo-sg90.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        }
      ]
    },
    {
      "id": "light",
      "title": "Control de LED",
      "description": "Enciende y apaga un LED remotamente mediante Bluetooth desde tu smartphone.",
      "route": "/light-control",
      "interfaceRoute": "/light-control-interface",
      "image": "assets/images/static/light_control/light_control.png",
      "videoId": "YOUR_LIGHT_VIDEO_ID",
      "chatModuleKey": "light_control",
      "inoFiles": [
        {
          "platform": "ESP32",
          "fileName": "esp32_bt_light.ino",
          "filePath": "assets/files/esp32_bt_light/esp32_bt_light.ino",
          "description": "Código para ESP32 con Bluetooth Classic y LED"
        },
        {
          "platform": "Arduino UNO",
          "fileName": "uno_bt_light.ino",
          "filePath": "assets/files/uno_bt_light/uno_bt_light.ino",
          "description": "Código para Arduino UNO con HC-05 Bluetooth y LED"
        }
      ],
      "instructions": [
        {
          "title": "1. Conectar LED con resistencia al microcontrolador",
          "description": "Conecta el ánodo del LED (+) al pin GPIO 2 del ESP32 o pin 13 del Arduino UNO a través de una resistencia de 220Ω. Conecta el cátodo (-) a GND.",
          "imagePath": "assets/images/static/light_control/instructions/instruction1.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "2. Opcional: Añadir botón físico",
          "description": "Conecta un botón táctil entre el pin GPIO 4 y GND para control manual local.",
          "imagePath": null,
          "actionType": "none",
          "actionValue": null
        }
      ],
      "materials": [
        {
          "title": "LED de 5mm",
          "description": "LED de cualquier color (rojo, verde, azul, blanco)",
          "qty": "1",
          "imagePath": "assets/images/static/materials/led.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        },
        {
          "title": "Resistencia 220Ω",
          "description": "Resistencia limitadora de corriente para el LED",
          "qty": "1",
          "imagePath": "assets/images/static/materials/resistance10k.png",
          "actionType": "none",
          "actionValue": null
        },
        {
          "title": "Microcontrolador ESP32 o Arduino UNO",
          "description": "Elige tu plataforma preferida",
          "qty": "1",
          "imagePath": "assets/images/static/materials/esp32.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
        }
      ]
    }
  ]
}
```

2. **Add to pubspec.yaml**

```yaml
flutter:
  assets:
    - assets/data/modules/modules_detail.json
    - assets/files/
    - assets/files/esp32_bt_temp/
    - assets/files/esp32_bt_servo/
    - assets/files/esp32_bt_light/
    - assets/files/esp32_bt_gamepad/
    - assets/files/uno_bt_temp/
    - assets/files/uno_bt_servo/
    - assets/files/uno_bt_light/
    - assets/files/UNO_bt_gamepad/
```

3. **Write Unit Tests**

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
      const jsonString = '''
      {
        "version": "1.0.0",
        "modules": [
          {
            "id": "temperature",
            "title": "Sensor Temperatura",
            "description": "Test description",
            "route": "/temperature",
            "interfaceRoute": "/temperature-interface",
            "inoFiles": [],
            "instructions": [],
            "materials": []
          }
        ]
      }
      ''';

      final result = await parser.parseModulesJson(jsonString);

      expect(result, isA<List<ModuleDetailModel>>());
      expect(result.length, 1);
      expect(result.first.id, 'temperature');
    });

    test('should throw FormatException for missing version', () async {
      const jsonString = '{"modules": []}';

      expect(
        () => parser.parseModulesJson(jsonString),
        throwsA(isA<FormatException>()),
      );
    });

    test('should continue parsing after individual module error', () async {
      const jsonString = '''
      {
        "version": "1.0.0",
        "modules": [
          {"id": "valid1", "title": "Valid", "description": "Test", "route": "/test", "interfaceRoute": "/test-interface", "inoFiles": [], "instructions": [], "materials": []},
          {"invalid": "data"},
          {"id": "valid2", "title": "Valid", "description": "Test", "route": "/test2", "interfaceRoute": "/test2-interface", "inoFiles": [], "instructions": [], "materials": []}
        ]
      }
      ''';

      final result = await parser.parseModulesJson(jsonString);

      expect(result.length, 2);
      verify(mockLogger.error(any, any, any)).called(1);
    });
  });
}
```

**Deliverables**:
- ✅ Complete JSON file with all 4 modules
- ✅ All INO files referenced exist
- ✅ JSON validates against schema
- ✅ Unit tests for JSON parser (100% coverage)

**Acceptance Criteria**:
- JSON file loads without errors
- All asset paths are valid
- Parser handles malformed JSON gracefully
- Unit tests achieve 100% line coverage

---

### Day 4-5: Repository Layer & Use Cases

#### Tasks:

1. **Extend Repository Interface**

```dart
// lib/features/home/domain/repositories/home_repository.dart

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

2. **Extend Datasource Interface**

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

3. **Implement Datasource Methods**

```dart
// lib/features/home/data/datasources/home_local_datasource_impl.dart

const _kModuleDetailsKey = 'CACHED_MODULE_DETAILS_v1';

class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  final SharedPreferences prefs;
  final ILogger logger;
  final ModuleDetailJsonParser jsonParser;

  HomeLocalDatasourceImpl({
    required this.prefs,
    required this.logger,
    required this.jsonParser,
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

4. **Implement Repository Methods**

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
      final models = details.map((d) => ModuleDetailModel.fromEntity(d)).toList();
      await localDatasource.cacheModuleDetails(models);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}
```

5. **Create Use Cases**

```dart
// lib/features/home/domain/usecases/get_module_detail.dart

class GetModuleDetail {
  final HomeRepository repository;

  GetModuleDetail({required this.repository});

  Future<Either<Failure, ModuleDetail>> call(String id) async {
    return await repository.getModuleDetailById(id);
  }
}
```

```dart
// lib/features/home/domain/usecases/get_all_module_details.dart

class GetAllModuleDetails {
  final HomeRepository repository;

  GetAllModuleDetails({required this.repository});

  Future<Either<Failure, List<ModuleDetail>>> call() async {
    return await repository.getAllModuleDetails();
  }
}
```

6. **Update Dependency Injection**

```dart
// lib/di/service_locator.dart

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

  // HomeBloc will be updated in Phase 2
}
```

7. **Write Repository & Use Case Tests**

```dart
// test/features/home/data/repositories/home_repository_impl_test.dart

void main() {
  late HomeRepositoryImpl repository;
  late MockHomeLocalDatasource mockLocalDatasource;

  setUp(() {
    mockLocalDatasource = MockHomeLocalDatasource();
    repository = HomeRepositoryImpl(
      localDatasource: mockLocalDatasource,
      remoteDatasource: MockHomeRemoteDataSource(),
    );
  });

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
      when(mockLocalDatasource.getModuleDetailById(testId))
          .thenAnswer((_) async => testDetail);

      final result = await repository.getModuleDetailById(testId);

      expect(result, isA<Right<Failure, ModuleDetail>>());
      result.fold(
        (_) => fail('Should return Right'),
        (detail) => expect(detail.id, testId),
      );
    });

    test('should return CacheFailure on CacheException', () async {
      when(mockLocalDatasource.getModuleDetailById(testId))
          .thenThrow(CacheException('Not found', StackTrace.current));

      final result = await repository.getModuleDetailById(testId);

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

**Deliverables**:
- ✅ Extended repository interface
- ✅ Extended datasource interface
- ✅ Implemented datasource methods
- ✅ Implemented repository methods
- ✅ 2 new use cases
- ✅ DI registrations updated
- ✅ Unit tests (80%+ coverage)

**Acceptance Criteria**:
- All methods return `Either<Failure, Success>`
- Proper error handling for missing modules
- Caching works correctly (SharedPreferences)
- Integration with existing HomeRepository doesn't break menu loading
- All tests pass

---

## Phase 2: BLoC & Widgets (Week 2)

**Duration**: 5 days
**Goal**: Extend HomeBloc, refactor shared widgets, implement tabs UI

### Day 6-7: BLoC Extension

#### Tasks:

1. **Add New Events**

```dart
// lib/features/home/presentation/bloc/home_event.dart

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

2. **Extend State**

```dart
// lib/features/home/presentation/bloc/home_state.dart

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final List<MainMenuItemModel> mainMenuItems;
  final Map<String, ModuleDetail> moduleDetails; // NEW
  final String? error;
  final bool isLoadingModuleDetails;          // NEW
  final String? moduleDetailError;            // NEW

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
      error: error,
      isLoadingModuleDetails: isLoadingModuleDetails ?? this.isLoadingModuleDetails,
      moduleDetailError: moduleDetailError,
    );
  }

  // Helper method
  ModuleDetail? getModuleDetail(String moduleId) {
    return moduleDetails[moduleId];
  }
}
```

3. **Implement Event Handlers**

```dart
// lib/features/home/presentation/bloc/home_bloc.dart

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
    on<ClearModuleDetailCache>(_onClearModuleDetailCache); // NEW
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
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
    // Check if already loaded (caching)
    if (state.moduleDetails.containsKey(event.moduleId)) {
      return; // Already cached in BLoC state
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
    emit(state.copyWith(moduleDetails: {}));
  }
}
```

4. **Update DI Registration**

```dart
// lib/di/service_locator.dart

getIt.registerFactory(
  () => HomeBloc(
    getCombinedMenu: getIt(),
    getModuleDetail: getIt(),        // NEW
    getAllModuleDetails: getIt(),    // NEW
  ),
);
```

5. **Write BLoC Tests**

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
        when(() => mockGetModuleDetail(testId))
            .thenAnswer((_) async => Right(testDetail));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadModuleDetail(moduleId: testId)),
      expect: () => [
        const HomeState(isLoadingModuleDetails: true),
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
        when(() => mockGetModuleDetail(testId))
            .thenAnswer((_) async => const Left(CacheFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadModuleDetail(moduleId: testId)),
      expect: () => [
        const HomeState(isLoadingModuleDetails: true),
        const HomeState(
          isLoadingModuleDetails: false,
          moduleDetailError: 'Error',
        ),
      ],
    );
  });
}
```

**Deliverables**:
- ✅ 3 new events added
- ✅ State extended with module details
- ✅ Event handlers implemented
- ✅ DI updated
- ✅ BLoC tests (100% coverage for new events)

**Acceptance Criteria**:
- BLoC handles loading, success, error states correctly
- Cached details don't trigger re-fetch
- Existing menu loading functionality unaffected
- All tests pass

---

### Day 8-9: Widget Refactoring

#### Tasks:

1. **Refactor BuildMainContent Widget**

**CRITICAL**: This is the main shared widget that all 4 module pages use.

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
  late InoPlatform _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _loadPlatformPreference();
  }

  Future<void> _loadPlatformPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlatform = prefs.getString('preferred_platform');

    InoPlatform defaultPlatform = InoPlatform.arduinoUno; // David's request

    if (savedPlatform != null) {
      // Try to find saved platform
      try {
        defaultPlatform = InoPlatform.values.firstWhere(
          (p) => p.apiValue == savedPlatform,
        );
      } catch (_) {
        // If saved platform not found, use default
      }
    }

    setState(() {
      _selectedPlatform = defaultPlatform;
      _selectedInoFile = _getInoFileForPlatform(_selectedPlatform);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform Selector (TABS - Segmented Button)
        if (widget.moduleDetail.inoFiles.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plataforma:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<InoPlatform>(
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
                  onSelectionChanged: (Set<InoPlatform> newSelection) {
                    setState(() {
                      _selectedPlatform = newSelection.first;
                      _selectedInoFile = _getInoFileForPlatform(_selectedPlatform);
                      _savePlatformPreference(_selectedPlatform);
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return AppColors.primary;
                    }),
                    side: MaterialStateProperty.all(
                      BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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

        // Video Section
        if (widget.moduleDetail.videoId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: YoutubePlayerWidget(videoId: widget.moduleDetail.videoId!),
          ),

        // Instructions Section
        if (widget.moduleDetail.instructions.isNotEmpty)
          InstructionsSection(instructions: widget.moduleDetail.instructions),

        // Materials Section
        if (widget.moduleDetail.materials.isNotEmpty)
          BillOfMaterialsSection(materials: widget.moduleDetail.materials),
      ],
    );
  }

  InoFile _getInoFileForPlatform(InoPlatform platform) {
    return widget.moduleDetail.inoFiles.firstWhere(
      (file) => file.platform == platform,
      orElse: () => widget.moduleDetail.inoFiles.first,
    );
  }

  Future<void> _savePlatformPreference(InoPlatform platform) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_platform', platform.apiValue);

    // Analytics tracking (David's request)
    // TODO: Implement analytics event
    debugPrint('Platform selected: ${platform.apiValue}');
  }

  Future<void> _onDownloadAndShare(BuildContext context) async {
    final shareFileUseCase = getIt<ShareFileUseCase>();

    // Use selected platform's INO file
    final result = await shareFileUseCase(
      assetPath: _selectedInoFile.filePath,
      fileName: _selectedInoFile.fileName,
      text: 'Código ${_selectedPlatform.apiValue} para ${widget.moduleDetail.title}',
      subject: 'Archivo INO - ${widget.moduleDetail.title}',
    );

    result.fold(
      (failure) {
        if (context.mounted) {
          SnackbarService().show(
            message: 'Error al compartir archivo: ${failure.message}',
            style: SnackbarStyle.error,
          );
        }
      },
      (_) {
        if (context.mounted) {
          SnackbarService().show(
            message: 'Archivo compartido exitosamente',
            style: SnackbarStyle.success,
          );
        }
      },
    );
  }
}
```

**Deliverables**:
- ✅ BuildMainContent refactored to use ModuleDetail
- ✅ Tabs (SegmentedButton) implementation
- ✅ Platform preference persistence (SharedPreferences)
- ✅ Analytics tracking placeholder

**Acceptance Criteria**:
- Widget accepts ModuleDetail instead of MainModule
- Tabs UI matches Material Design 3 spec
- Platform selection persists across app restarts
- Share functionality uses selected platform

---

### Day 10: Widget Testing

#### Tasks:

1. **Write Widget Tests**

```dart
// test/shared/widgets/modules/build_main_content_test.dart

void main() {
  testWidgets('displays platform tabs when multiple INO files available',
      (tester) async {
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
          filePath: 'assets/files/esp32.ino',
        ),
        InoFile(
          platform: InoPlatform.arduinoUno,
          fileName: 'uno.ino',
          filePath: 'assets/files/uno.ino',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildMainContent(moduleDetail: moduleDetail),
        ),
      ),
    );

    expect(find.text('Plataforma:'), findsOneWidget);
    expect(find.byType(SegmentedButton<InoPlatform>), findsOneWidget);
    expect(find.text('ESP32'), findsOneWidget);
    expect(find.text('Arduino UNO'), findsOneWidget);
  });

  testWidgets('switches platform when tab is tapped', (tester) async {
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
          filePath: 'assets/files/esp32.ino',
        ),
        InoFile(
          platform: InoPlatform.arduinoUno,
          fileName: 'uno.ino',
          filePath: 'assets/files/uno.ino',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildMainContent(moduleDetail: moduleDetail),
        ),
      ),
    );

    // Initial state: Arduino UNO selected (default)
    final segmentedButton = tester.widget<SegmentedButton<InoPlatform>>(
      find.byType(SegmentedButton<InoPlatform>),
    );
    expect(segmentedButton.selected.first, InoPlatform.arduinoUno);

    // Tap ESP32 tab
    await tester.tap(find.text('ESP32'));
    await tester.pumpAndSettle();

    // Verify platform changed
    final updatedSegmentedButton = tester.widget<SegmentedButton<InoPlatform>>(
      find.byType(SegmentedButton<InoPlatform>),
    );
    expect(updatedSegmentedButton.selected.first, InoPlatform.esp32);
  });
}
```

**Deliverables**:
- ✅ Widget tests for BuildMainContent
- ✅ Test platform tab rendering
- ✅ Test platform switching interaction
- ✅ Test "Descargar INO" button

**Acceptance Criteria**:
- All widget tests pass
- Coverage >80% for BuildMainContent
- Interactions are properly tested

---

## Phase 3: Migration & Cleanup (Week 3)

**Duration**: 5 days
**Goal**: Migrate all 4 module pages, integration testing, cleanup

### Day 11-13: Module Page Migration

#### Tasks:

**Migrate all 4 module pages ONE AT A TIME** (test each before moving to next)

**Migration Order**:
1. TemperaturePage (pilot migration, most critical)
2. ServoPage
3. LightControlPage
4. GamepadPage

**Template for Each Module Page**:

```dart
// lib/features/temperature/presentation/pages/temperature_page.dart

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
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final moduleDetail = state.getModuleDetail(moduleId);

            if (moduleDetail != null) {
              return CustomScrollView(
                slivers: [
                  MainSliverBackAppBar(
                    assetImagePath: moduleDetail.image ??
                        'assets/images/static/placeholder.png',
                    centerTitle: true,
                    backLabel: moduleDetail.title,
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      BuildMainContent(moduleDetail: moduleDetail),
                    ]),
                  ),
                ],
              );
            }

            if (state.isLoadingModuleDetails) {
              return const Center(child: CircularProgressIndicator());
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.moduleDetailError ?? 'Error al cargar módulo',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => homeBloc.add(
                      const LoadModuleDetail(moduleId: moduleId),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: PxChatBotFloatingButton(
        moduleKey: moduleDetail?.chatModuleKey ?? moduleId,
      ),
    );
  }
}
```

**Migration Checklist (per module)**:
- ✅ Remove hardcoded `final MainModule mainModule = ...`
- ✅ Add `const String moduleId = 'xxx'`
- ✅ Wrap body with `BlocBuilder<HomeBloc, HomeState>`
- ✅ Trigger `LoadModuleDetail` on first build
- ✅ Handle loading/error/success states
- ✅ Pass `moduleDetail` to BuildMainContent
- ✅ Test manually in emulator
- ✅ Verify INO download works for both platforms
- ✅ Verify video player works
- ✅ Verify instructions/materials display correctly

**Deliverables (per day)**:
- Day 11: ✅ TemperaturePage + ServoPage migrated
- Day 12: ✅ LightControlPage + GamepadPage migrated
- Day 13: ✅ All integration tests passing

**Acceptance Criteria**:
- All 4 modules load details from JSON
- Platform selection works for all modules
- No regressions in existing functionality
- Loading/error states display correctly

---

### Day 14: Cleanup & Final Testing

#### Tasks:

1. **Delete Legacy Code**

```bash
# Delete old entity files
rm lib/core/domain/entities/module.dart
rm lib/core/domain/entities/instruction.dart  # Already moved
rm lib/core/domain/entities/material.dart     # Already moved

# Remove unused imports
# Search for "import.*core/domain/entities/module" and remove
```

2. **Run Full Test Suite**

```bash
flutter test --coverage
flutter analyze
dart format lib/ test/
```

3. **Integration Testing**

- ✅ Test complete flow: HomePage → Module → Load Details → Switch Platform → Download INO
- ✅ Test offline behavior (airplane mode)
- ✅ Test SharedPreferences persistence
- ✅ Test error recovery

4. **Performance Testing**

```bash
# Measure JSON parsing time
# Measure module detail load time
# Measure app startup time
```

5. **Update Documentation**

- ✅ Update `.claude/sessions/context_session_module_json_datasource.md`
- ✅ Create migration guide for future modules
- ✅ Update CLAUDE.md if needed

**Deliverables**:
- ✅ All legacy code removed
- ✅ Zero analyzer warnings
- ✅ All tests passing (unit, widget, integration)
- ✅ Performance benchmarks documented
- ✅ Documentation updated

**Acceptance Criteria**:
- `flutter analyze` passes with 0 errors
- Test coverage >80%
- No references to old MainModule entity
- Performance meets targets (module load <500ms)

---

### Day 15: Final QA & Handoff

#### Tasks:

1. **Manual QA Checklist**

- ✅ Test all 4 modules on Android emulator
- ✅ Test all 4 modules on iOS simulator (if available)
- ✅ Test platform switching (ESP32 ↔ Arduino UNO)
- ✅ Test INO file download/share
- ✅ Test video playback
- ✅ Test instructions modal
- ✅ Test materials modal
- ✅ Test offline mode
- ✅ Test error states

2. **Create Git Commit**

```bash
git add .
git commit -m "feat: refactor static modules to JSON datasource with multi-platform INO support

- Add JSON datasource for 4 static modules (Temperature, Servo, Gamepad, Light)
- Implement multi-platform INO file support (ESP32 + Arduino UNO)
- Add tabs (SegmentedButton) UI for platform selection
- Extend HomeBloc with module detail state management
- Refactor BuildMainContent widget to accept ModuleDetail
- Create all missing INO files (Arduino UNO variants)
- Add platform preference persistence (SharedPreferences)
- Remove legacy hardcoded MainModule instances
- Add comprehensive unit/widget/integration tests (80%+ coverage)

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

3. **Create Feature Branch PR**

```bash
git checkout -b feat/module-json-datasource-refactor
git push -u origin feat/module-json-datasource-refactor

# Create PR via GitHub CLI or web UI
gh pr create --title "feat: Module JSON Datasource Refactoring" \
  --body "$(cat .claude/doc/module_json_datasource/IMPLEMENTATION_PLAN.md)" \
  --base develop
```

**Deliverables**:
- ✅ QA checklist completed
- ✅ Git commit created
- ✅ PR created targeting develop branch
- ✅ Screenshots/recordings for PR review

---

## Testing Requirements

### David's Mandate: NO EXCEPTIONS

**THE ONLY WAY TO SKIP TESTS:**
> "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME." - David

**Otherwise, ALL new code MUST have tests.**

### Test Coverage Targets:

| Layer | Minimum Coverage | Target Coverage |
|-------|-----------------|-----------------|
| **Domain** (entities, use cases) | 80% | 100% |
| **Data** (models, repositories, datasources) | 80% | 90% |
| **BLoC** (events, states, handlers) | 100% | 100% |
| **Widgets** (BuildMainContent, tabs) | 70% | 80% |
| **Overall Project** | 80% | 85% |

### Test Files to Create:

```
test/
  features/home/
    domain/
      usecases/
        get_module_detail_test.dart
        get_all_module_details_test.dart
    data/
      datasources/
        module_detail_json_parser_test.dart
        home_local_datasource_impl_test.dart
      models/
        module_detail_model_test.dart
        ino_file_model_test.dart
        instruction_item_model_test.dart
        material_item_model_test.dart
      repositories/
        home_repository_impl_test.dart (extend existing)
    presentation/
      bloc/
        home_bloc_test.dart (extend existing)
  shared/
    widgets/
      modules/
        build_main_content_test.dart
```

### Test Types:

1. **Unit Tests**: Entities, models, use cases, repositories
2. **Widget Tests**: BuildMainContent, platform tabs
3. **BLoC Tests**: All new events and states
4. **Integration Tests**: End-to-end flow (HomePage → Module → Details)

---

## File Structure

### New Files Created:

```
lib/features/home/
  domain/
    entities/
      module_detail.dart           ← NEW
      ino_file.dart                ← NEW
      instruction_item.dart        ← MOVED from core
      material_item.dart           ← MOVED from core
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

assets/
  data/
    modules/
      modules_detail.json             ← NEW
  files/
    uno_bt_temp/
      uno_bt_temp.ino                 ← NEW
    uno_bt_servo/
      uno_bt_servo.ino                ← NEW
    uno_bt_light/
      uno_bt_light.ino                ← NEW
    esp32_bt_gamepad/
      esp32_bt_gamepad.ino            ← NEW
```

### Modified Files:

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
  build_main_content.dart                  ← REFACTOR to ModuleDetail

lib/features/temperature/presentation/pages/
  temperature_page.dart                    ← REFACTOR

lib/features/servo/presentation/pages/
  servo_page.dart                          ← REFACTOR

lib/features/gamepad/presentation/pages/
  gamepad_page.dart                        ← REFACTOR

lib/features/light_control/presentation/pages/
  light_control_page.dart                  ← REFACTOR

lib/di/
  service_locator.dart                     ← ADD registrations

pubspec.yaml                               ← ADD JSON asset
```

### Deleted Files (After Migration):

```
lib/core/domain/entities/
  module.dart                              ← DELETE
  instruction.dart                         ← DELETE (moved)
  material.dart                            ← DELETE (moved)
```

---

## Backend Coordination

### NOT Part of This Implementation

This refactoring focuses ONLY on the 4 static local modules. Backend changes for remote modules are a **separate task**.

### Future Backend Work (Separate Epic):

**Document**: `.claude/doc/module_json_datasource/backend_api_specification.md`

**Key Points**:
1. **Database Schema**: 4 new tables (instructions, materials, ino_files, extend modules)
2. **New Endpoint**: `GET /api/modules/:id/details`
3. **Extended Response**: Add `hasDetails` flag to `/api/modules`
4. **Cloud Storage**: Store INO files in AWS S3/Google Cloud Storage
5. **Authentication**: Bearer token validation, subscription checking

**Timeline**: Backend work can happen in parallel or after Flutter implementation.

---

## Risk Mitigation

### Risk 1: JSON Parsing Errors

**Risk**: Invalid JSON crashes app on startup

**Mitigation**:
- ✅ Comprehensive JSON validation in parser
- ✅ Try-catch blocks with detailed logging
- ✅ Fail gracefully with empty list on error
- ✅ Debug assertions in development mode
- ✅ Manual JSON validation before committing

### Risk 2: Breaking Existing Module Functionality

**Risk**: Migration breaks temperature/servo/gamepad/light modules

**Mitigation**:
- ✅ Migrate one module at a time
- ✅ Test each module thoroughly before moving to next
- ✅ Comprehensive integration tests
- ✅ Manual QA checklist

### Risk 3: Asset Path Errors

**Risk**: INO files or images not found

**Mitigation**:
- ✅ Validate all asset paths exist in JSON parser
- ✅ Add asset existence checks in tests
- ✅ Use constants for asset paths (avoid typos)

### Risk 4: SharedPreferences Conflicts

**Risk**: Platform preference conflicts with other app settings

**Mitigation**:
- ✅ Use unique key: `preferred_platform`
- ✅ Handle null/invalid values gracefully
- ✅ Test persistence across app restarts

### Risk 5: BLoC State Synchronization

**Risk**: Module detail state gets out of sync

**Mitigation**:
- ✅ Clear caching logic (check before fetching)
- ✅ Immutable state with copyWith
- ✅ Comprehensive BLoC tests
- ✅ Add ClearModuleDetailCache event for debugging

---

## Success Metrics

### Technical Metrics

- ✅ **Test Coverage**: >80% for all new code (mandate)
- ✅ **Code Quality**: Zero analyzer warnings
- ✅ **Performance**: Module page load <500ms (lazy loading)
- ✅ **Memory**: <50KB overhead for JSON caching
- ✅ **Build Time**: No significant increase (<5%)

### User Experience Metrics

- ✅ **Module Load Time**: <1 second perceived
- ✅ **Platform Switch Time**: Instant (<100ms)
- ✅ **Error Rate**: 0% (static modules shouldn't fail)
- ✅ **INO Download Success**: 100%

### Maintenance Metrics

- ✅ **JSON Update Time**: <5 minutes to add new module
- ✅ **Code Duplication**: Eliminated (4 hardcoded instances → 1 JSON file)
- ✅ **Lines of Code**: Net reduction after cleanup
- ✅ **Future Module Cost**: 80% less effort (JSON vs code)

---

## Rollout Strategy

### Soft Launch (Internal Testing)

**Week 3, Day 15**:
- ✅ Deploy to internal test track (Google Play Internal Testing)
- ✅ Invite 10 beta testers
- ✅ Monitor crash reports (Firebase Crashlytics)
- ✅ Collect feedback on platform selector UX

### Production Release

**Week 4** (after successful testing):
- ✅ Merge PR to develop
- ✅ Create release branch: `release/v1.x.x`
- ✅ Deploy to production (Google Play + App Store)
- ✅ Monitor analytics for platform selection usage

### Monitoring

**Track These Metrics**:
1. Platform selection ratio (ESP32 vs Arduino UNO)
2. INO download success rate
3. Module load time (Firestore Performance Monitoring)
4. Crash-free rate

---

## Communication Plan

### Stakeholders:

1. **David (Project Owner)** - Final approvals, decisions
2. **Backend Team** - Future API integration (separate task)
3. **QA Team** - Testing assistance
4. **Beta Testers** - User feedback

### Status Updates:

**Daily Standups** (async or sync):
- What was completed yesterday
- What's planned for today
- Any blockers

**Weekly Summary** (end of each week):
- Phase completion status
- Test coverage metrics
- Risks identified
- Next week plan

---

## Appendix

### Additional Resources:

1. **Architecture Validation**: `.claude/doc/module_json_datasource/architecture_validation.md`
2. **Backend API Spec**: `.claude/doc/module_json_datasource/backend_api_specification.md`
3. **UI/UX Analysis**: `.claude/doc/module_json_datasource/ui_analysis.md`
4. **Platform Selector Decision**: `.claude/doc/module_json_datasource/platform_selector_decision.md`
5. **Flutter Frontend Plan**: `.claude/doc/module_json_datasource/flutter-frontend.md`
6. **Session Context**: `.claude/sessions/context_session_module_json_datasource.md`

### Quick Commands:

```bash
# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Format code
dart format lib/ test/

# Analyze code
flutter analyze

# Build release APK
flutter build apk --release

# Run on device
flutter run -d <device-id>
```

---

**Status**: READY FOR IMPLEMENTATION ✅

**Next Steps**:
1. ✅ David approves plan
2. ✅ Create feature branch: `feat/module-json-datasource-refactor`
3. ✅ Start Phase 1, Day 1

**Estimated Completion**: 3 weeks from start date

---

**Document Version**: 1.0
**Author**: Claude Code Agent
**Approved By**: [Pending David's Approval]
**Last Updated**: 2025-11-16
