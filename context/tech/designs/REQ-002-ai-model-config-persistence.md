# AI Model Configuration Persistence - Technical Design

## Requirement Overview

### Business Goals
- Allow users to add custom AI model configurations
- Persist model configurations and API Keys
- Migrate existing DeepSeek configuration to new storage
- Improve user experience by avoiding repeated configuration input

### Technical Constraints
- Must use shared_preferences for configuration list storage
- Must use flutter_secure_storage for secure API Key storage
- Must be compatible with existing AIClassifierService interface
- Support existing DeepSeek and Qwen models
- Support user-added custom models

## Technical Solution

### Architecture Design

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────────────────┐  ┌──────────────────────────┐    │
│  │ ImportConfirmation   │  │ AIModelManagement        │    │
│  │ Screen               │  │ Screen (New)             │    │
│  └──────────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         AIModelConfigService (New)                    │  │
│  │  - Manage model config CRUD operations                │  │
│  │  - Coordinate SQLite and SecureStorage                │  │
│  │  - Provide configuration migration                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│         ┌────────────────────┼────────────────────┐         │
│         ▼                    ▼                    ▼         │
│  ┌─────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │AIClassifier │  │Database Helper   │  │SecureStorage │  │
│  │Service      │  │(SQLite)          │  │Service       │  │
│  └─────────────┘  └──────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Storage Layer                            │
│  ┌──────────────────────┐  ┌──────────────────────────┐    │
│  │ SQLite Database      │  │ FlutterSecureStorage     │    │
│  │ (Config metadata)    │  │ (API Keys)               │    │
│  │ Table: ai_models     │  │                          │    │
│  └──────────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Database Schema

#### ai_models Table

```sql
CREATE TABLE ai_models (
  id TEXT PRIMARY KEY,              -- UUID
  name TEXT NOT NULL,               -- Display name
  provider TEXT NOT NULL,           -- deepseek/qwen/custom
  model_id TEXT NOT NULL,           -- Model identifier
  api_endpoint TEXT NOT NULL,       -- API URL
  api_key TEXT NOT NULL,            -- Encrypted API key
  is_default INTEGER DEFAULT 0,     -- 0=false, 1=true
  created_at INTEGER NOT NULL,      -- Unix timestamp
  last_used_at INTEGER,             -- Unix timestamp
  UNIQUE(name)
);

CREATE INDEX idx_ai_models_provider ON ai_models(provider);
CREATE INDEX idx_ai_models_is_default ON ai_models(is_default);
```

**Note**: API keys are stored encrypted using the existing `EncryptionService`, following the same pattern as email passwords.

### Storage Strategy

1. **Configuration Metadata + Encrypted API Keys** → SQLite
   - Model ID, name, provider, endpoint
   - Default flag, timestamps
   - **API Keys stored encrypted in database** (using existing EncryptionService)
   - Easy to query and manage

2. **Encryption Approach**
   - Use existing `EncryptionService` (AESEncryptionService)
   - Same approach as email password storage
   - Encrypt API keys before storing in database
   - Decrypt when retrieving

3. **Benefits**
   - Simplified architecture (single storage layer)
   - Consistent with existing email config storage pattern
   - Better query performance
   - Easier to add new fields
   - No need for additional flutter_secure_storage dependency
   - Maintains API key security with encryption

### Data Model Design

#### 1. AIModelConfig (Core configuration model)

```dart
// lib/models/ai_model_config.dart

enum AIModelProvider {
  deepseek,
  qwen,
  custom,
}

class AIModelConfig {
  final String id;                    // Unique identifier (UUID)
  final String name;                  // Display name, e.g. "DeepSeek V3"
  final AIModelProvider provider;     // Provider type
  final String modelId;               // Model ID, e.g. "deepseek-chat"
  final String apiEndpoint;           // API endpoint
  final bool isDefault;               // Is default model
  final DateTime createdAt;           // Creation time
  final DateTime? lastUsedAt;         // Last used time

  // API Key not stored in this object, managed separately via SecureStorage

  AIModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.modelId,
    required this.apiEndpoint,
    this.isDefault = false,
    required this.createdAt,
    this.lastUsedAt,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.name,
      'modelId': modelId,
      'apiEndpoint': apiEndpoint,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  factory AIModelConfig.fromJson(Map<String, dynamic> json) {
    return AIModelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: AIModelProvider.values.firstWhere(
        (e) => e.name == json['provider'],
      ),
      modelId: json['modelId'] as String,
      apiEndpoint: json['apiEndpoint'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  AIModelConfig copyWith({
    String? name,
    String? modelId,
    String? apiEndpoint,
    bool? isDefault,
    DateTime? lastUsedAt,
  }) {
    return AIModelConfig(
      id: id,
      name: name ?? this.name,
      provider: provider,
      modelId: modelId ?? this.modelId,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
```

## Implementation Task List

### Phase 1: Foundation (2-3 hours)

- [ ] Task 1.1: Add dependencies
  - Add uuid: ^4.0.0 to pubspec.yaml
  - Run flutter pub get
  - Note: sqflite and EncryptionService already exist in project

- [ ] Task 1.2: Create database schema
  - Add ai_models table creation to DatabaseService
  - Create migration script for existing database
  - Add indexes for performance
  - Include api_key column for encrypted storage

- [ ] Task 1.3: Create data models
  - Create lib/models/ai_model_config.dart
  - Create lib/constants/ai_model_constants.dart
  - Add unit tests for serialization

### Phase 2: Core Service (3-4 hours)

- [ ] Task 2.1: Create AI model database service
  - Create lib/services/database/ai_model_db_service.dart
  - Follow EmailConfigDbService pattern
  - Use EncryptionService for API key encryption/decryption
  - Implement CRUD operations with database helper

- [ ] Task 2.2: Implement AIModelConfigService
  - Create lib/services/ai/ai_model_config_service.dart
  - Implement business logic layer
  - Add caching for performance
  - Coordinate with ai_model_db_service

- [ ] Task 2.3: Implement configuration migration
  - Check for legacy SharedPreferences config
  - Migrate to SQLite database with encryption
  - Add migration logging
  - Clean up legacy data

- [ ] Task 2.4: Update existing AI services
  - Modify import_confirmation_screen.dart to use AIModelConfigService
  - Update model selection logic
  - Test integration with DeepSeekClassifierService
  - Test integration with QwenClassifierService

### Phase 3: UI Implementation (4-5 hours)

- [ ] Task 3.1: Create model management screen
  - Create lib/screens/settings/ai_model_management_screen.dart
  - Implement model list display with SQLite queries
  - Add navigation from settings

- [ ] Task 3.2: Create model dialog
  - Create lib/widgets/ai/ai_model_dialog.dart
  - Implement add/edit form
  - Add form validation
  - Add API key visibility toggle

- [ ] Task 3.3: Update import confirmation screen
  - Modify model selection dropdown
  - Add "Manage Models" button
  - Update last used time on selection

### Phase 4: Testing (2-3 hours)

- [ ] Task 4.1: Unit tests
  - Test AIModelConfig serialization
  - Test database CRUD operations
  - Test encryption/decryption of API keys
  - Test AIModelConfigService business logic

- [ ] Task 4.2: Integration tests
  - Test configuration migration from SharedPreferences
  - Test model selection flow
  - Test API key encryption security
  - Test database transactions

- [ ] Task 4.3: UI tests
  - Test add/edit/delete model flow
  - Test default model selection
  - Test error handling

## Risk Assessment

### High Priority Risks

1. **API Key Security**
   - Risk: API keys stored insecurely
   - Mitigation: Use flutter_secure_storage with platform encryption
   - Status: Addressed in design

2. **Configuration Migration Failure**
   - Risk: User data loss during migration
   - Mitigation: Backup before migration, validate after migration
   - Status: Addressed in design

### Medium Priority Risks

3. **Model API Compatibility**
   - Risk: Different AI models have different API interfaces
   - Mitigation: Design flexible configuration structure
   - Status: Addressed in design

4. **UI Complexity**
   - Risk: Complex UI affects user experience
   - Mitigation: Provide default configs and simplified flow
   - Status: Addressed in design

## Security Considerations

### API Key Encryption
- Android: EncryptedSharedPreferences (AES256)
- iOS: Keychain (AES256-GCM)
- Keys stored separately from metadata

### Memory Safety
- API keys only loaded when needed
- No caching in memory
- Sanitized error messages

### Historical Pitfall Mitigation
- Use English keys in JSON to avoid encoding issues
- Store Chinese display names carefully
- Test file encoding after creation

## Migration Strategy

1. Check for legacy configuration in SharedPreferences
2. If found, create new AIModelConfig
3. Migrate API key to SecureStorage
4. Set as default model
5. Delete legacy configuration
6. Log migration success

## Next Steps

After design approval:
1. Review and approve design document
2. Proceed to implementation phase
3. Execute tasks in order
4. Test each phase before moving to next
