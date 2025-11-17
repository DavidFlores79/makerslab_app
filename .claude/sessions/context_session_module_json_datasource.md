# Module JSON Datasource Refactoring - Session Context

## Feature Overview
Refactor the current hardcoded module system (Gamepad, Temperature, Servo, Light Control) to use JSON datasources with enhanced support for:
- Instructions (step-by-step guides with images)
- Materials (required components with quantities and images)
- Video tutorials (YouTube integration)
- INO files for both ESP32 and Arduino UNO platforms

## Current State Analysis

### Existing Architecture
The app currently has **two separate module systems**:

#### 1. Home Menu System (lib/features/home)
- **Purpose**: Main menu cards displayed on HomePage
- **Entity**: `MainMenuItem` (id, title, route, colorHex, assetPath, imageUrl, isStatic, priority)
- **Datasource**: Hardcoded mock in `lib/core/mocks/main_menu_mock.dart`
- **Features**:
  - Local caching with SharedPreferences
  - Remote fetching from API (for authenticated users)
  - Combines local static modules + remote dynamic modules
  - Clean Architecture: Domain → Data → Presentation with BLoC

#### 2. Module Detail System (per-feature hardcoded)
- **Purpose**: Module details page with instructions, materials, video, INO files
- **Entity**: `MainModule` (title, description, moduleRoute, interfaceRoute, image, videoId, inoFile, instructions, materials)
- **Current Implementation**: **Hardcoded inside each module's page**
  - Example: `TemperaturePage` has `final MainModule mainModule = MainModule(...)`
  - Each module (Gamepad, Servo, Light Control, Temperature) duplicates this pattern
- **Sub-entities**:
  - `InstructionItem`: title, description, imagePath, actionType, actionValue
  - `MaterialItem`: title, description, qty, imagePath, actionType, actionValue

### Existing Assets
- **Module Icons**: `assets/images/modules/` (gamepad.png, servo.png, thermometer.png, etc.)
- **Static Images**: `assets/images/static/{module}/` (module-specific images)
- **Instructions**: `assets/images/static/{module}/instructions/` (step1.png, instruction1.png)
- **Materials**: `assets/images/static/materials/` (esp32.png, arduino-uno.png, dht-11.png, breadboard.png, etc.)
- **INO Files**: `assets/files/` (esp32_bt_temp, esp32_bt_servo, esp32_bt_light, UNO_bt_gamepad)

### Current Flow
1. User lands on `HomePage` → shows menu cards from `mainMenuMock`
2. User taps "Temperatura" → navigates to `/temperature`
3. `TemperaturePage` displays hardcoded `MainModule` instance with instructions, materials, video, INO file
4. User can view instructions, materials, watch video, or download INO file

## Problem Statement
David correctly identified that the current approach has issues:
1. **Hardcoded Data**: Each module page has hardcoded `MainModule` instances (not scalable)
2. **No Centralized Datasource**: Module details are not stored in JSON
3. **Duplication**: Similar data structure repeated across 4 modules
4. **No Multi-Platform INO Support**: Currently only one INO file per module (need ESP32 + Arduino UNO variants)
5. **Not Dynamic**: Cannot add/update modules without recompiling the app
6. **Inconsistent Architecture**: Home menu uses Clean Architecture with datasources, but module details are hardcoded

## ⚠️ CRITICAL UPDATE: Hybrid Module System (David's Clarification)

The app already has a **HYBRID MODULE SYSTEM**:
- **Local (Static) Modules**: 4 fixed modules (Temperature, Servo, Gamepad, Light Control) - **free for all users**
- **Remote (Dynamic) Modules**: Fetched from API (`/api/modules`) - **only for authenticated/subscribed users**
- **Current API**: `https://makerslab-backend.onrender.com/api/modules`
- **Flow**: HomePage combines `mainMenuMock` (local) + remote modules when user signs in

### Implications for This Refactoring:
1. **Scope**: Focus ONLY on the 4 static local modules (Temperature, Servo, Gamepad, Light Control)
2. **Separate Systems**: Remote modules will have different pages/repositories (NOT part of this refactoring)
3. **Backend Changes**: API will need updates to support module details (instructions, materials, INO files) - separate task
4. **No Breaking Changes**: Remote module fetching must continue working as-is

### David's Decisions (Answered 2025-11-16):
- **A) Performance**: Lazy Load per module (load on-demand)
- **B) Platform Default**: Remember last selection (save in SharedPreferences)
- **C) Error Handling**: Snackbar with retry (modules shouldn't have errors - fixed data)
- **D) Analytics**: Yes, track platform selection
- **E) Future API**: Yes, already have API for remote modules (will need backend updates)

## Solution Approach

### Architecture Decision
Create a **unified module system** that extends the existing Home architecture with module detail datasources:

1. **Extend Domain Layer**: Add `ModuleDetail` entity to include instructions, materials, video, INO files
2. **Create JSON Datasource**: Local JSON files in `assets/data/modules/`
3. **Repository Pattern**: ModuleDetailRepository for fetching module details
4. **BLoC Integration**: Extend existing HomeBloc or create ModuleDetailBloc
5. **Multi-Platform INO Support**: Support both ESP32 and Arduino UNO INO files per module

### Data Structure (JSON Schema)
```json
{
  "modules": [
    {
      "id": "temperature",
      "title": "Sensor Temperatura",
      "description": "Módulo de temperatura y humedad con DHT11",
      "route": "/temperature",
      "interfaceRoute": "/temperature-interface",
      "colorHex": "#FF2196F3",
      "image": "assets/images/static/temperature/esp32DHT11.png",
      "iconPath": "assets/images/brand/humidity.png",
      "videoId": "kJpdoBLSmHs",
      "chatModuleKey": "temperature_sensor",
      "priority": 2,
      "isStatic": true,
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
          "description": "Código para Arduino UNO con HC-05"
        }
      ],
      "instructions": [
        {
          "title": "1. Conectar el sensor DHT11 y el módulo Bluetooth HC-05 al Protoboard",
          "description": "Descripción detallada del paso 1...",
          "imagePath": "assets/images/static/temperature/instructions/instruction1.png",
          "actionType": "modalBottomSheet",
          "actionValue": null
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
        }
      ]
    }
  ]
}
```

## Team Selection

### Subagents to Involve
- **flutter-frontend-developer**:
  - Clean Architecture implementation for module datasource
  - JSON parsing and model creation
  - BLoC pattern for module detail state management
  - Widget refactoring for dynamic module rendering
  - File structure organization

### Why Flutter Agent?
This is a pure Flutter/Dart refactoring task involving:
- Domain/Data/Presentation layer modifications
- JSON datasource implementation
- BLoC state management
- Widget architecture refactoring
- No backend API changes needed (local JSON assets)

## Implementation Plan (High-Level)

### Phase 1: Domain Layer Extension
1. Create `ModuleDetail` entity with instructions, materials, video, INO files
2. Create `InoFile` entity for multi-platform support
3. Update repository interfaces

### Phase 2: Data Layer Implementation
4. Create JSON files in `assets/data/modules/` for all 4 modules
5. Create `ModuleDetailLocalDataSource` to parse JSON
6. Implement `ModuleDetailRepository`
7. Register in DI (`service_locator.dart`)

### Phase 3: BLoC Integration
8. Create `ModuleDetailBloc` or extend existing `HomeBloc`
9. Add events/states for module detail fetching
10. Use cases: `GetModuleDetail`, `GetModuleByRoute`

### Phase 4: Presentation Refactoring
11. Refactor module pages (Temperature, Servo, Gamepad, Light Control)
12. Remove hardcoded `MainModule` instances
13. Use BlocBuilder to render module details dynamically
14. Update shared widgets to accept dynamic data

### Phase 5: Multi-Platform INO Support
15. Add UI selector for ESP32 vs Arduino UNO
16. Implement file download/share for selected platform
17. Update existing share functionality

### Phase 6: Testing & Documentation
18. Unit tests for JSON parsing
19. Widget tests for module pages
20. BLoC tests for state management
21. Update documentation

## Branch Strategy
- **Branch Name**: `feat/module-json-datasource-refactor` ✅ CREATED
- **GitHub Issue**: #15 (https://github.com/DavidFlores79/makerslab_app/issues/15) ✅
- **Base Branch**: `develop`
- **Target Branch**: `develop`
- **Review Requirements**: 1 reviewer required
- **Created**: 2025-11-16

## Technology Stack
- **Flutter**: 3.7.2+
- **Dart**: 3.7.2+
- **State Management**: BLoC (flutter_bloc 9.1.1)
- **DI**: get_it 8.0.3 (manual registration)
- **JSON Parsing**: dart:convert (built-in)
- **File Sharing**: share_plus (existing in project)

## Open Questions for David

### ✅ ANSWERED (2025-11-16)
- **A) Performance**: Lazy Load per module (load on-demand) ✅
- **B) Platform Default**: Remember last selection (save in SharedPreferences) ✅
- **C) Error Handling**: Snackbar with retry (modules shouldn't have errors - fixed data) ✅
- **D) Analytics**: Yes, track platform selection ✅
- **E) Future API**: Yes, already have API for remote modules (will need backend updates) ✅

### ⏳ PENDING DECISION
- **Platform Selection UI Pattern**: Dropdown vs Tabs (Segmented Button)?
  - UI/UX Analysis completed → See `.claude/doc/module_json_datasource/ui_analysis.md`
  - **Recommendation**: TABS (Segmented Button) ✅ 95% confidence
  - **Awaiting**: David's approval to proceed with tabs implementation

## Iteration Log
- **Iteration 1**: Initial exploration and architecture analysis (flutter-frontend-developer)
- **Iteration 2**: UI/UX analysis for platform selection pattern (ui-ux-analyzer, 2025-11-16)
  - Analyzed Dropdown vs Tabs patterns
  - Evaluated Material Design 3 guidelines
  - Assessed mobile UX best practices
  - Provided implementation code for both options
  - **Output**: `.claude/doc/module_json_datasource/ui_analysis.md`
- **Iteration 3**: Detailed implementation plan creation (flutter-frontend-developer, 2025-11-16)
  - Created comprehensive step-by-step implementation guide
  - Defined 10 implementation phases with timelines
  - Provided complete code examples for all layers
  - Specified testing requirements (>80% coverage)
  - Created file structure summary (35 new files, 12 modified, 3 deleted)
  - **Output**: `.claude/doc/module_json_datasource/flutter-frontend-implementation-plan.md`

## Sub-Agent Feedback

### Flutter Frontend Developer (Iteration 1)
- Created comprehensive implementation plan
- Recommended extending `HomeBloc` (not creating separate ModuleDetailBloc)
- Proposed lazy loading strategy for module details
- Designed JSON schema with multi-platform INO support
- **Output**: `.claude/doc/module_json_datasource/flutter-frontend.md`

### UI/UX Analyzer (Iteration 2 - 2025-11-16)
- **Task**: Analyze best UI pattern for ESP32 vs Arduino UNO selection
- **Analysis**: Comprehensive 22-section evaluation
- **Recommendation**: TABS (Segmented Button) over Dropdown
- **Key Findings**:
  - Material Design 3 explicitly recommends segmented buttons for 2-5 options
  - Mobile-first pattern (used by Circuit.io, Blynk IoT apps)
  - 33% faster interaction (1 tap vs 2 taps)
  - Better accessibility (larger tap targets, clearer visual states)
  - Higher discoverability (no hidden states)
  - Tabs: 11 wins vs Dropdown: 2 wins in feature comparison
- **Trade-offs**: Uses 10-20px more vertical space (acceptable)
- **Implementation**: Provided Flutter code for both patterns
- **Next Steps**: Awaiting David's approval
- **Output**: `.claude/doc/module_json_datasource/ui_analysis.md`
