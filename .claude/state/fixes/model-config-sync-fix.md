# AI Model Configuration Sync Fix

## Problem Description

When users updated AI model configurations in the Model Management screen, the changes were not reflected when importing bills. The system continued to use the old model configuration.

## Root Cause

The application had two separate AI configuration systems:

1. **Legacy System**: `AIConfigService` reading from `app_settings` table
2. **New System**: `AIModelConfigService` reading from `ai_models` table

When users updated models in the Model Management screen, it updated the new system (`ai_models` table). However, the bill import functionality (`BatchClassificationService`, `BillImportScreen`, `EmailBillSelectScreen`) was still using the legacy `AIConfigService`, which read from the old `app_settings` table.

## Solution

Modified `AIConfigService` to prioritize reading from the new `AIModelConfigService`:

1. First attempts to load the active model from `ai_models` table
2. Converts the model configuration to `AIClassificationConfig` format
3. Falls back to legacy `app_settings` table if no active model is found
4. Maintains backward compatibility with existing code

### Files Modified

- `lib/services/ai/ai_config_service.dart`
  - Added dependency on `AIModelConfigService`
  - Modified `loadConfig()` to read from new system first
  - Created `_loadLegacyConfig()` for fallback behavior

## Testing Instructions

### Manual Testing

1. **Setup**:
   - Open the app
   - Go to Settings → AI Model Management
   - Add a new model (e.g., DeepSeek with a valid API key)
   - Set it as active

2. **Test Bill Import**:
   - Go to Bill Import screen
   - Select a bill file (Alipay or WeChat)
   - Import the bill
   - Verify that the import uses the newly configured model

3. **Test Model Switch**:
   - Go back to AI Model Management
   - Add another model (e.g., Qwen)
   - Set the new model as active
   - Import another bill
   - Verify that the import now uses the new model

4. **Test Email Import**:
   - Go to Email Bill Import
   - Select an email with bill attachment
   - Import the bill
   - Verify that validation uses the active model

### Expected Behavior

- Model changes in Model Management should immediately affect bill imports
- No app restart required
- Active model indicator should match the model being used
- Validation results should reflect the capabilities of the active model

## Backward Compatibility

The fix maintains full backward compatibility:

- Existing code using `AIConfigService` continues to work
- Falls back to legacy configuration if no models are configured in new system
- No breaking changes to API or data structures

## Related Files

- `lib/services/ai/ai_config_service.dart` (modified)
- `lib/services/ai_model_config_service.dart` (existing)
- `lib/services/category/batch_classification_service.dart` (uses AIConfigService)
- `lib/screens/import/bill_import_screen.dart` (uses AIConfigService)
- `lib/screens/import/email_bill_select_screen.dart` (uses AIConfigService)

## Date

2026-01-25
