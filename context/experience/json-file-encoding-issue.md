# JSON File Encoding Issue - Use English to Avoid Garbled Text

> Category: Experience / Lesson Learned
> Tags: JSON, encoding, Chinese characters, file writing, UTF-8
> Severity: Medium

## Background

When using the Write tool to create JSON files containing Chinese characters, encoding issues may occur, resulting in garbled text in the file content.

- **Scenario**: Creating JSON configuration files or state files with Chinese text
- **Impact**: File content becomes unreadable, JSON parsing fails
- **Discovery**: During REQ-001 development when creating requirement state files

## Problem Description

### Symptoms
When writing JSON files with Chinese characters using the Write tool, the Chinese characters are replaced with garbled characters.

Example of garbled output:
```
"title": "chatgpt-api-service��check.quota.flagMny/����v��k8s�U�configmap.yaml"
```

### Root Cause
- The Write tool may have encoding issues when handling long strings with Chinese characters
- JSON serialization process may not properly handle UTF-8 encoding for Chinese text
- Character encoding mismatch between tool and file system

## Solution

### Recommended Approach 1: Use English for JSON Files

**Best Practice**: Use English for JSON file content, especially for identifiers and technical descriptions.

```json
{
  "id": "REQ-001",
  "title": "Support environment variable for check.quota.flag",
  "description": "Make check.quota.flag configuration support environment variable"
}
```

### Recommended Approach 2: Use Bash Heredoc

When Chinese text is necessary, use bash heredoc to write files:

```bash
cat > file.json << 'EOF'
{
  "id": "REQ-001",
  "title": "Configuration item supports environment variables"
}
EOF
```

### Recommended Approach 3: Separate Chinese Content

Keep JSON structure in English, put Chinese content in separate markdown files:

```json
{
  "id": "REQ-001",
  "title_en": "Support environment variable",
  "description_file": "REQ-001-description.md"
}
```

### Wrong Approach

Do not directly use Write tool with Chinese in JSON - this may cause encoding issues.

## Best Practices

### For State Files
- Use English for all JSON keys and values
- Use ISO 8601 format for timestamps
- Use standard codes/enums instead of Chinese descriptions

### For Documentation
- Use markdown files for Chinese content
- Reference markdown files from JSON
- Keep JSON as metadata/index only

### For Configuration
- Use English property names
- Use environment variables for runtime values
- Document Chinese explanations separately

## Checklist

When creating JSON files:

- [ ] Are all keys in English?
- [ ] Are technical terms in English?
- [ ] Is Chinese content necessary in JSON?
- [ ] Can Chinese content be moved to markdown?
- [ ] Have you tested file encoding?

## Related Files

- `.claude/state/requirements/*.json` - Requirement state files
- `context/INDEX.md` - Context index (can contain Chinese)
- `context/**/*.md` - Documentation files (Chinese OK)

## Affected Services/Modules

- All services using JSON configuration
- State management files
- API request/response bodies
- Configuration files

## Verification Commands

```bash
# Check file encoding
file -I filename.json

# Verify JSON is valid
cat filename.json | jq .

# Check for garbled characters
grep -P '[\x80-\xFF]{2,}' filename.json
```

## Alternative Solutions

### If Chinese is Required

1. **Use UTF-8 BOM**: Add BOM header to file
2. **Escape Unicode**: Use Unicode escape sequences
3. **Base64 Encode**: Encode Chinese content
4. **External Files**: Store Chinese in separate files

### Example: Unicode Escape
```json
{
  "title": "\u914d\u7f6e\u9879\u652f\u6301\u73af\u5883\u53d8\u91cf"
}
```

But this is **not recommended** as it is hard to read and maintain.

---

## Document Metadata

| Property | Value |
|----------|-------|
| Created | 2026-01-19 |
| Source | /remember command |
| Last Updated | 2026-01-19 |
| Update Count | 1 |
| Related Issues | REQ-001 state file encoding |
