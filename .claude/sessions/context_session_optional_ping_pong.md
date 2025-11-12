# Session: Optional Ping-Pong Connection Monitoring

**Feature Name**: `optional-ping-pong-settings`  
**Date Created**: November 9, 2025  
**Status**: Planning Phase  
**Branch**: `feat/optional-ping-pong-settings`  
**Target Branch**: `develop`

---

## Feature Request
Make ping-pong connection monitoring to Bluetooth devices an optional feature. Add a switch in settings where users can choose whether disconnection will happen if the device doesn't send/respond to ping-pong heartbeats.

---

## Exploration Summary

### Current Implementation
**Ping-Pong Mechanism** is implemented in multiple feature repositories/BLoCs:

1. **Temperature Feature** (`temperature_repository_impl.dart`)
   - Sends heartbeat every 5 seconds: `'P\n'`
   - Expects ACK response: `'K\n'`
   - Timeout: 45 seconds without data → disconnects
   - Status: ✅ ACTIVE

2. **Servo Feature** (`servo_bloc.dart`)
   - Sends heartbeat every 5 seconds: `'P\n'`
   - Timeout: 45 seconds → disconnects
   - Status: ✅ ACTIVE

3. **Light Control Feature** (`light_control_bloc.dart`)
   - Has timeout mechanism (45 seconds)
   - Status: ❌ NO HEARTBEAT (only timeout)

4. **Gamepad Feature** (`gamepad_repository_impl.dart`)
   - Heartbeat code present but COMMENTED OUT
   - Timeout: 45 seconds active
   - Status: ⚠️ PARTIAL (timeout only)

### Technology Stack
- **Framework**: Flutter 3.7.2+ with Dart SDK 3.5+
- **State Management**: BLoC pattern
- **DI**: GetIt
- **Storage**: SharedPreferences + FlutterSecureStorage
- **Architecture**: Clean Architecture (Domain/Data/Presentation)

### Current Storage Usage
- **SharedPreferences**: Used for local module caching (`home_modules_seed.dart`)
- **SecureStorage**: Used for auth tokens and user data
- **No settings/preferences layer exists yet**

---

## Team Selection

Based on technology stack analysis:

### Selected Subagents
- **Flutter Frontend Developer** (`flutter-frontend-developer`)
  - State management advice (BLoC pattern for settings)
  - UI/UX for settings toggle
  - SharedPreferences best practices
  - Feature flag pattern implementation

### Not Required
- ❌ Backend architects (no backend changes needed)
- ❌ Angular/NestJS/Laravel (Flutter-only feature)

---

## Implementation Plan (Draft - Awaiting Advice)

### Phase 1: Settings Infrastructure
1. Create settings domain layer
2. Create settings data layer (SharedPreferences)
3. Create settings BLoC
4. Create settings UI page

### Phase 2: Connection Monitoring Service
1. Create centralized connection settings service
2. Inject into all IoT feature repositories/BLoCs
3. Conditional heartbeat logic based on settings

### Phase 3: UI Integration
1. Add settings toggle to Profile page
2. Update all IoT features to respect setting
3. Add visual indicator when ping-pong is disabled

### Phase 4: Testing & Documentation
- Unit tests for settings logic
- Widget tests for settings UI
- Update Arduino script documentation
- User documentation

---

## Questions & Clarifications Needed

*Waiting for user responses before proceeding to advice phase...*

---

## Iterations

### Iteration 1 - Initial Planning
- Explored codebase structure
- Identified all ping-pong implementations
- Selected appropriate subagents
- Created draft implementation plan

---

## Notes
- Temperature and Servo have full ping-pong implementation
- Light Control and Gamepad need consistency fixes
- No existing settings infrastructure - needs to be created from scratch
- Follow Clean Architecture patterns established in the project
