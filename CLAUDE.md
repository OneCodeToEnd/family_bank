# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**账清 (Family Bank)** is a cross-platform family financial management application built with Flutter. It supports multi-account management, transaction categorization, data analysis, and bill import functionality. All data is stored locally using SQLite with optional encryption.

## Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Check Flutter environment
flutter doctor

# Check available devices
flutter devices
```

### Running the App
```bash
# Run on default device
flutter run

# Run on specific platforms
flutter run -d macos
flutter run -d iphone
flutter run -d chrome
flutter run -d windows
flutter run -d linux

# Run with specific modes
flutter run --debug    # Debug mode (default)
flutter run --profile  # Profile mode for performance analysis
flutter run --release  # Release mode
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Clean build artifacts
flutter clean
```

### Building
```bash
# Android
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release  # For Google Play

# iOS (requires macOS)
flutter build ios --release
open ios/Runner.xcworkspace

# Desktop
flutter build macos --release
flutter build windows --release
flutter build linux --release

# Web
flutter build web --release
```

### Icon Generation
```bash
# Generate app icons for all platforms
flutter pub run flutter_launcher_icons
```

## Architecture

### State Management
The app uses **Provider** for state management with five main providers:
- `FamilyProvider` - Manages family groups and members
- `AccountProvider` - Manages financial accounts
- `CategoryProvider` - Manages transaction categories (hierarchical tree structure)
- `TransactionProvider` - Manages transaction records
- `SettingsProvider` - Manages app settings and theme

All providers are initialized in `main.dart` using `MultiProvider` and must be initialized before use.

### Database Layer
The app uses **SQLite** (via sqflite) with a centralized database service:
- `DatabaseService` - Singleton managing database lifecycle, schema creation, and migrations
- Current database version: 10 (see `DbConstants.dbVersion`)
- Database file: `family_bank.db` stored in app documents directory

**Key Tables:**
- `family_groups` - Family group information
- `family_members` - Family members linked to groups
- `accounts` - Financial accounts (Alipay, WeChat, cash, etc.)
- `categories` - Hierarchical category tree (parent-child relationships)
- `transactions` - Transaction records with deduplication via hash
- `category_rules` - Keyword-based auto-categorization rules
- `annual_budgets` - Annual budget management with monthly breakdown
- `counterparty_groups` - Transaction counterparty grouping and classification
- `app_settings` - Application settings
- `http_logs` - HTTP request/response logs for debugging
- `email_configs` - Email account configurations for bill import
- `ai_models` - AI model configurations for transaction classification

**Database Migrations:**
- V2: Added `counterparty` field to transactions
- V3: Enhanced category rules with match types, confidence scores, and auto-learning
- V4: Added HTTP logging table
- V5: Added email configuration table
- V6: Added AI model configuration table
- V7: Added annual budgets table
- V8: Added type field to annual_budgets
- V9: Removed unused budgets table
- V10: Added counterparty groups table

### Service Layer Architecture

**Database Services** (`lib/services/database/`):
- Each entity has a dedicated DB service (e.g., `FamilyDbService`, `AccountDbService`)
- Services handle CRUD operations and complex queries
- `TransactionDbService.getHomePageStatistics()` provides optimized home page stats

**AI Classification Services** (`lib/services/ai/`):
- `AiClassifierFactory` - Creates appropriate classifier based on provider
- `QwenClassifierService` - Qwen model integration
- `DeepseekClassifierService` - DeepSeek model integration
- `AiConfigService` - Manages AI configuration and prompts
- `AiModelConfigService` - Manages AI model configurations

**Category Services** (`lib/services/category/`):
- `CategoryMatchService` - Matches transactions to categories using rules
- `CategoryLearningService` - Learns from user corrections to improve matching
- `BatchClassificationService` - Batch processes transactions for AI classification

**Import Services** (`lib/services/import/`):
- `BillImportService` - Handles CSV/Excel bill imports with deduplication
- `EmailService` - Fetches bills from email accounts via IMAP
- `UnzipService` - Extracts password-protected ZIP files

**Other Services:**
- `EncryptionService` - Handles data encryption/decryption
- `BillValidationService` - Validates imported bill data
- `LoggingHttpClient` - HTTP client with automatic request/response logging

### Category System
Categories form a **hierarchical tree structure**:
- Support parent-child relationships (one level deep in current implementation)
- Each category has: name, type (income/expense), icon, color, tags
- System categories (`is_system=1`) are pre-populated and cannot be deleted
- Categories can be hidden without deletion
- Auto-categorization uses keyword matching rules with priority and confidence scores

### Transaction Import & Deduplication
- Supports CSV and Excel file imports
- Deduplication uses SHA-256 hash of: `account_id + transaction_time + amount + description`
- Import sources tracked via `import_source` field (manual, csv, email, etc.)
- Transactions can be marked as "confirmed" after review
- Email import supports fetching bills from IMAP servers with attachment extraction

### AI-Powered Classification
- Supports multiple AI providers (Qwen, DeepSeek)
- API keys stored encrypted in database
- Classification uses transaction description and optional counterparty
- Batch classification for multiple transactions
- Error handling with retry logic and fallback mechanisms
- HTTP requests/responses logged for debugging

### Navigation
The app uses **imperative navigation** (Navigator.push) rather than declarative routing:
- Main entry point: `HomePage` in `main.dart`
- Major screens: TransactionListScreen, AccountListScreen, CategoryListScreen, BillImportScreen, AnalysisScreen, SettingsScreen
- Forms use dedicated screens (e.g., TransactionFormScreen, AccountFormScreen)

### Data Flow Pattern
1. User interacts with UI (Screen)
2. Screen calls Provider methods
3. Provider calls Service layer
4. Service interacts with Database
5. Provider notifies listeners via `notifyListeners()`
6. UI rebuilds via `Consumer` or `context.watch()`

## Important Implementation Details

### Provider Initialization
All providers must be initialized before use. The `HomePage` widget handles this in `_initializeApp()` using `Future.wait()` to initialize all providers concurrently.

### Transaction Hash Calculation
When creating or importing transactions, always calculate the hash for deduplication:
```dart
final hash = sha256.convert(
  utf8.encode('$accountId$timestamp$amount$description')
).toString();
```

### Category Matching
The category matching system uses a multi-stage approach:
1. Exact keyword matching (highest priority)
2. Fuzzy matching with confidence scores
3. AI-powered classification (if enabled)
4. User confirmation for low-confidence matches

### Database Queries
- Use parameterized queries to prevent SQL injection
- Leverage indexes for performance (see `_createIndexes()` in DatabaseService)
- Use transactions for batch operations
- Foreign key constraints are enabled (CASCADE deletes)

### Theme Support
The app supports light/dark themes via `SettingsProvider.themeMode`:
- Uses Material Design 3 (`useMaterial3: true`)
- Theme colors derived from blue seed color
- Theme mode persisted in app settings

### Error Handling
- Database errors should be caught and logged
- UI should show user-friendly error messages
- HTTP errors logged to `http_logs` table for debugging
- Classification errors handled by `ClassificationErrorHandler`

## Testing Notes

### Running Tests
- Widget tests should mock Provider dependencies
- Database tests should use in-memory database or test database
- Clean up test data after each test

### Common Issues
- **iOS build failures**: Run `cd ios && pod install && pod update`
- **Android build failures**: Check SDK path in `android/local.properties`
- **Database errors**: Uninstall and reinstall app to reset database
- **Dependency conflicts**: Run `flutter clean && flutter pub get`

## Project Roadmap Context

The project follows a phased development plan (see 迭代计划.md):
- **V1.x**: Core functionality (account management, basic categorization, import, analysis)
- **V2.x**: AI-powered classification, family features, performance optimization
- **V3.x**: Budget management, multi-device sync, advanced analytics

Current focus is on V1.x features with AI classification capabilities from V2.x already implemented.
