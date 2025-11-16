# Backend API Specification - Module Details with Multi-Platform Support

**Project**: Makers Lab Backend
**Feature**: Remote Module Details with INO Files
**API Base**: `https://makerslab-backend.onrender.com`
**Date**: 2025-11-16
**Status**: Design Specification (Not Yet Implemented)

---

## Overview

This document specifies the backend API changes required to support **remote module details** with multi-platform INO file support (ESP32 + Arduino UNO). This is for **paid/subscribed users** who access dynamic modules beyond the 4 free static modules.

### Current State
- ✅ **Existing**: `GET /api/modules` - Returns menu items only (id, title, route, colorHex, etc.)
- ❌ **Missing**: Module details (instructions, materials, videos, INO files)

### Required Changes
- 🆕 **New Endpoint**: `GET /api/modules/:id/details` - Returns full module details
- 🔄 **Extended Response**: Add `hasDetails` flag to existing `/api/modules` response
- 🆕 **New Database Tables**: Store instructions, materials, INO files

---

## Database Schema Changes

### 1. Modules Table (Extend Existing)

```sql
ALTER TABLE modules ADD COLUMN has_details BOOLEAN DEFAULT FALSE;
ALTER TABLE modules ADD COLUMN description TEXT;
ALTER TABLE modules ADD COLUMN image_url VARCHAR(500);
ALTER TABLE modules ADD COLUMN video_id VARCHAR(100);
ALTER TABLE modules ADD COLUMN chat_module_key VARCHAR(100);
ALTER TABLE modules ADD COLUMN interface_route VARCHAR(100);

-- Example update for existing modules
UPDATE modules SET has_details = TRUE WHERE id IN ('advanced_robotics', 'iot_dashboard');
```

### 2. Instructions Table (NEW)

```sql
CREATE TABLE instructions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  image_path VARCHAR(500),
  action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('modalBottomSheet', 'externalUrl', 'internalRoute', 'none')),
  action_value VARCHAR(500),
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_instructions_module_id ON instructions(module_id);
CREATE INDEX idx_instructions_sort_order ON instructions(module_id, sort_order);
```

### 3. Materials Table (NEW)

```sql
CREATE TABLE materials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  qty VARCHAR(50) NOT NULL,
  image_path VARCHAR(500),
  action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('modalBottomSheet', 'externalUrl', 'internalRoute', 'none')),
  action_value VARCHAR(500),
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_materials_module_id ON materials(module_id);
CREATE INDEX idx_materials_sort_order ON materials(module_id, sort_order);
```

### 4. INO Files Table (NEW)

```sql
CREATE TABLE ino_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  platform VARCHAR(50) NOT NULL CHECK (platform IN ('ESP32', 'Arduino UNO')),
  file_name VARCHAR(255) NOT NULL,
  file_url VARCHAR(500) NOT NULL,
  description TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ino_files_module_id ON ino_files(module_id);
CREATE INDEX idx_ino_files_platform ON ino_files(module_id, platform);
CREATE UNIQUE INDEX idx_ino_files_unique_platform ON ino_files(module_id, platform);
```

---

## API Endpoints

### 1. Get Module Menu Items (EXISTING - Extend Response)

**Endpoint**: `GET /api/modules`

**Authentication**: Optional (returns different results for authenticated vs unauthenticated)

**Query Parameters**:
- `page` (optional): Page number (default: 1)
- `pageSize` (optional): Items per page (default: 10)

**Response** (EXTENDED):

```json
{
  "page": 1,
  "pageSize": 10,
  "totalItems": 15,
  "data": [
    {
      "id": "advanced_robotics",
      "title": "Robótica Avanzada",
      "route": "/advanced-robotics",
      "colorHex": "#FF5722",
      "assetPath": "",
      "imageUrl": "https://storage.example.com/modules/robotics.png",
      "isStatic": false,
      "priority": 10,
      "hasDetails": true  // 🆕 NEW FIELD - indicates if module has detailed content
    },
    {
      "id": "iot_dashboard",
      "title": "Dashboard IoT",
      "route": "/iot-dashboard",
      "colorHex": "#03A9F4",
      "assetPath": "",
      "imageUrl": "https://storage.example.com/modules/iot.png",
      "isStatic": false,
      "priority": 20,
      "hasDetails": true  // 🆕 NEW FIELD
    }
  ]
}
```

**Changes**:
- ✅ Add `hasDetails` boolean field to response
- ✅ Client checks `hasDetails` before fetching module details

---

### 2. Get Module Details by ID (NEW ENDPOINT)

**Endpoint**: `GET /api/modules/:id/details`

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `id` (string): Module ID (e.g., "advanced_robotics")

**Response**:

```json
{
  "success": true,
  "data": {
    "id": "advanced_robotics",
    "title": "Robótica Avanzada",
    "description": "Aprende a construir robots autónomos con sensores avanzados y control por IA",
    "route": "/advanced-robotics",
    "interfaceRoute": "/advanced-robotics-interface",
    "image": "https://storage.example.com/modules/robotics/hero.png",
    "videoId": "dQw4w9WgXcQ",
    "chatModuleKey": "advanced_robotics_assistant",
    "inoFiles": [
      {
        "platform": "ESP32",
        "fileName": "esp32_advanced_robot.ino",
        "fileUrl": "https://storage.example.com/ino-files/esp32_advanced_robot.ino",
        "description": "Código para ESP32 con sensores ultrasónicos y servos"
      },
      {
        "platform": "Arduino UNO",
        "fileName": "uno_advanced_robot.ino",
        "fileUrl": "https://storage.example.com/ino-files/uno_advanced_robot.ino",
        "description": "Código para Arduino UNO con HC-05 Bluetooth y L298N motor driver"
      }
    ],
    "instructions": [
      {
        "title": "1. Ensamblar el chasis del robot",
        "description": "Conecta las ruedas al motor driver L298N y asegura el chasis con tornillos M3",
        "imagePath": "https://storage.example.com/modules/robotics/instructions/step1.png",
        "actionType": "modalBottomSheet",
        "actionValue": null
      },
      {
        "title": "2. Instalar sensores ultrasónicos",
        "description": "Monta los sensores HC-SR04 en la parte frontal del robot",
        "imagePath": "https://storage.example.com/modules/robotics/instructions/step2.png",
        "actionType": "modalBottomSheet",
        "actionValue": null
      },
      {
        "title": "3. Descargar bibliotecas necesarias",
        "description": "Instala las bibliotecas NewPing y L298N desde Arduino IDE",
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
        "imagePath": "https://storage.example.com/materials/esp32.png",
        "actionType": "modalBottomSheet",
        "actionValue": null
      },
      {
        "title": "Motor Driver L298N",
        "description": "Controlador de motores DC dual para hasta 2A por canal",
        "qty": "1",
        "imagePath": "https://storage.example.com/materials/l298n.png",
        "actionType": "externalUrl",
        "actionValue": "https://www.amazon.com/L298N-Motor-Driver"
      },
      {
        "title": "Sensor Ultrasónico HC-SR04",
        "description": "Sensor de distancia por ultrasonido (2-400cm)",
        "qty": "2",
        "imagePath": "https://storage.example.com/materials/hc-sr04.png",
        "actionType": "modalBottomSheet",
        "actionValue": null
      },
      {
        "title": "Motores DC con reductora",
        "description": "Motores de 6V con caja reductora y ruedas incluidas",
        "qty": "2",
        "imagePath": "https://storage.example.com/materials/dc-motor.png",
        "actionType": "none",
        "actionValue": null
      },
      {
        "title": "Batería LiPo 7.4V 2200mAh",
        "description": "Batería recargable con conector XT60",
        "qty": "1",
        "imagePath": "https://storage.example.com/materials/lipo-battery.png",
        "actionType": "externalUrl",
        "actionValue": "https://www.amazon.com/LiPo-Battery"
      }
    ]
  }
}
```

**Error Responses**:

```json
// 401 Unauthorized (no token or invalid token)
{
  "success": false,
  "error": "Unauthorized",
  "message": "Authentication token required"
}

// 403 Forbidden (user not subscribed)
{
  "success": false,
  "error": "Forbidden",
  "message": "Subscription required to access this module"
}

// 404 Not Found (module doesn't exist or has no details)
{
  "success": false,
  "error": "Not Found",
  "message": "Module details not found for id: 'xyz'"
}

// 500 Internal Server Error
{
  "success": false,
  "error": "Internal Server Error",
  "message": "Failed to fetch module details"
}
```

---

### 3. Download INO File (NEW ENDPOINT - Optional)

**Endpoint**: `GET /api/modules/:id/ino-files/:platform/download`

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `id` (string): Module ID
- `platform` (string): Platform name ("ESP32" or "Arduino_UNO")

**Response**:
- Content-Type: `text/x-arduino` or `application/octet-stream`
- Content-Disposition: `attachment; filename="esp32_advanced_robot.ino"`
- Body: INO file contents

**Alternative**: Return direct download URL in `/api/modules/:id/details` response (current approach)

---

## Multi-Platform INO File Strategy

### Storage Options

#### Option 1: Cloud Storage (RECOMMENDED ✅)

**Implementation**:
- Store INO files in AWS S3, Google Cloud Storage, or similar
- Generate signed URLs with expiration (30 minutes)
- Return URL in API response
- Client downloads directly from cloud storage

**Pros**:
- ✅ Scalable (no backend bandwidth usage)
- ✅ Fast downloads (CDN support)
- ✅ Secure (signed URLs with expiration)
- ✅ Low backend load

**Cons**:
- ❌ Requires cloud storage setup
- ❌ Slightly more complex URL generation

**Example URL**:
```
https://storage.example.com/ino-files/esp32_advanced_robot.ino?signature=xyz&expires=1234567890
```

---

#### Option 2: Database BLOB Storage (NOT RECOMMENDED ❌)

**Implementation**:
- Store INO file contents in PostgreSQL BYTEA or TEXT column
- Return file contents in API response

**Pros**:
- ✅ Simple implementation
- ✅ No external dependencies

**Cons**:
- ❌ Database bloat (INO files can be 10-50KB each)
- ❌ Slow queries (BLOB retrieval)
- ❌ High memory usage
- ❌ Not scalable

**Verdict**: Avoid for production.

---

### Platform Naming Convention

**Database Values**:
- `ESP32` (exact match, case-sensitive)
- `Arduino UNO` (with space, case-sensitive)

**URL Parameters** (use underscores for URL safety):
- `ESP32`
- `Arduino_UNO`

**Client Enum** (Flutter):
```dart
enum InoPlatform {
  esp32('ESP32'),
  arduinoUno('Arduino UNO');

  final String apiValue;
  const InoPlatform(this.apiValue);
}
```

---

## Authentication & Authorization

### Access Control Rules

| User Type | Static Modules (JSON) | Remote Modules (API) | Module Details |
|-----------|----------------------|---------------------|----------------|
| **Unauthenticated** | ✅ Full access | ❌ No access | ❌ No access |
| **Authenticated (Free)** | ✅ Full access | ❌ No access | ❌ No access |
| **Authenticated (Subscribed)** | ✅ Full access | ✅ Full access | ✅ Full access |

### Token Validation

**Required Headers**:
```http
Authorization: Bearer <jwt_token>
```

**Token Claims**:
```json
{
  "userId": "user-uuid",
  "email": "user@example.com",
  "subscription": {
    "plan": "premium",
    "status": "active",
    "expiresAt": "2025-12-31T23:59:59Z"
  },
  "iat": 1700000000,
  "exp": 1700086400
}
```

**Validation Logic**:
```typescript
// Backend validation (NestJS example)
if (!user.subscription || user.subscription.status !== 'active') {
  throw new ForbiddenException('Subscription required');
}

if (new Date(user.subscription.expiresAt) < new Date()) {
  throw new ForbiddenException('Subscription expired');
}
```

---

## File Upload & Management (Admin API)

### Admin Endpoint: Upload INO File

**Endpoint**: `POST /api/admin/modules/:id/ino-files`

**Authentication**: Admin token required

**Request** (multipart/form-data):
```http
POST /api/admin/modules/advanced_robotics/ino-files
Content-Type: multipart/form-data
Authorization: Bearer <admin_token>

{
  "platform": "ESP32",
  "description": "Código para ESP32 con sensores ultrasónicos",
  "file": <binary data>
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "ino-file-uuid",
    "moduleId": "advanced_robotics",
    "platform": "ESP32",
    "fileName": "esp32_advanced_robot.ino",
    "fileUrl": "https://storage.example.com/ino-files/esp32_advanced_robot.ino",
    "description": "Código para ESP32 con sensores ultrasónicos",
    "uploadedAt": "2025-11-16T10:30:00Z"
  }
}
```

---

## Example API Calls (cURL)

### 1. Get Module Menu (Unauthenticated)

```bash
curl -X GET "https://makerslab-backend.onrender.com/api/modules?page=1&pageSize=10"
```

### 2. Get Module Details (Authenticated)

```bash
curl -X GET "https://makerslab-backend.onrender.com/api/modules/advanced_robotics/details" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 3. Download INO File (Direct URL)

```bash
curl -X GET "https://storage.example.com/ino-files/esp32_advanced_robot.ino?signature=xyz" \
  -o esp32_advanced_robot.ino
```

---

## Flutter Client Integration

### Data Models

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
}
```

### API Client

```dart
// lib/features/home/data/datasources/home_remote_datasource.dart

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  @override
  Future<ModuleDetailModel> getRemoteModuleDetail(String id) async {
    final response = await dio.get(
      '/api/modules/$id/details',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
        },
      ),
    );

    if (response.statusCode == 200) {
      return ModuleDetailModel.fromJson(response.data['data']);
    } else if (response.statusCode == 403) {
      throw SubscriptionRequiredException();
    } else {
      throw ServerException('Failed to fetch module details');
    }
  }
}
```

---

## Migration Strategy

### Phase 1: Database Setup
1. ✅ Create new tables (instructions, materials, ino_files)
2. ✅ Add columns to modules table
3. ✅ Create indexes for performance

### Phase 2: Admin Panel
1. ✅ Build admin UI for uploading module details
2. ✅ File upload for INO files to cloud storage
3. ✅ CRUD operations for instructions and materials

### Phase 3: API Implementation
1. ✅ Implement `GET /api/modules/:id/details` endpoint
2. ✅ Add authentication/authorization middleware
3. ✅ Add `hasDetails` field to existing `/api/modules` response

### Phase 4: Testing
1. ✅ Unit tests for API endpoints
2. ✅ Integration tests with mock data
3. ✅ Load testing for file downloads

### Phase 5: Flutter Integration
1. ✅ Create models and datasources
2. ✅ Extend repository with remote module details
3. ✅ UI for displaying remote module content

---

## Performance Considerations

### Caching Strategy

**Backend**:
- Cache module details in Redis (TTL: 1 hour)
- Cache signed URLs in Redis (TTL: 30 minutes)

**Flutter Client**:
- Cache remote module details in SharedPreferences
- Clear cache on logout
- Refresh cache if older than 24 hours

### Rate Limiting

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1700000000
```

**Limits**:
- `/api/modules`: 100 requests/hour per user
- `/api/modules/:id/details`: 50 requests/hour per user
- File downloads: 20 downloads/hour per user

---

## Security Considerations

### 1. SQL Injection Prevention
- ✅ Use parameterized queries
- ✅ Validate all input IDs (UUID format)

### 2. File Upload Security
- ✅ Validate file extension (.ino only)
- ✅ Scan files for malicious content
- ✅ Limit file size (max 500KB per INO file)

### 3. URL Signing
- ✅ Generate signed URLs with expiration
- ✅ Validate signatures on download

### 4. Access Control
- ✅ Verify subscription status on every request
- ✅ Log unauthorized access attempts

---

## Monitoring & Analytics

### Metrics to Track

1. **API Performance**:
   - Response time for `/api/modules/:id/details`
   - Cache hit rate for module details
   - File download success rate

2. **User Behavior**:
   - Most accessed modules
   - Platform preference (ESP32 vs Arduino UNO)
   - Average time spent on module pages

3. **Errors**:
   - 403 errors (subscription required)
   - 404 errors (module not found)
   - Failed file downloads

---

## Documentation for Frontend Team

### Quick Reference

**Static Modules** (Temperature, Servo, Gamepad, Light):
- Source: `assets/data/modules/modules_detail.json`
- No authentication required
- Always available offline

**Remote Modules** (Paid content):
- Source: `GET /api/modules/:id/details`
- Authentication required
- Subscription required
- Check `hasDetails` field in menu response

**Multi-Platform INO Files**:
- Both static and remote modules support ESP32 + Arduino UNO
- Default: Arduino UNO (per David's request)
- Save user's platform preference in SharedPreferences

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-16 | 1.0 | Initial specification with multi-platform INO support |

---

**Status**: Design Specification - Ready for Backend Implementation

**Next Steps**:
1. Backend team implements database schema
2. Backend team implements API endpoints
3. Admin panel for content upload
4. Flutter team integrates with new endpoints
