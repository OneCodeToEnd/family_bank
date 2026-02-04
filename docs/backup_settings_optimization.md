# 备份设置存储优化

## 问题

最初实现使用了 `shared_preferences` 包来存储备份设置，这导致：
1. 增加了不必要的依赖
2. 数据存储不统一（部分在 SQLite，部分在 SharedPreferences）
3. 备份数据库时，设置不会被自动备份

## 解决方案

改用 SQLite 的 `app_settings` 表存储备份设置。

### 优势

1. **统一存储** - 所有应用设置都在同一个地方
2. **自动备份** - 备份数据库时，设置也会被自动备份
3. **减少依赖** - 不需要额外的 shared_preferences 包（虽然项目其他地方还在用）
4. **数据一致性** - 避免多个存储源导致的数据不一致

### 实现方式

参考项目中已有的 `QuickActionService`，使用相同的模式：

```dart
// 保存设置
await db.rawInsert('''
  INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
    (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
  VALUES (?, ?, ?)
''', [
  'backup_settings',
  jsonEncode(settings.toJson()),
  DateTime.now().millisecondsSinceEpoch,
]);

// 读取设置
final result = await db.query(
  DbConstants.tableAppSettings,
  where: '${DbConstants.columnSettingKey} = ?',
  whereArgs: ['backup_settings'],
);

if (result.isNotEmpty) {
  final jsonStr = result.first[DbConstants.columnSettingValue] as String;
  final json = jsonDecode(jsonStr);
  return BackupSettings.fromJson(json);
}
```

### 存储格式

设置以 JSON 格式存储在 `app_settings` 表中：

| setting_key | setting_value | updated_at |
|-------------|---------------|------------|
| backup_settings | {"autoBackupEnabled":true,"backupIntervalDays":1,...} | 1705123456789 |

### 兼容性

- 新用户：直接使用 SQLite 存储
- 老用户：如果之前使用了 SharedPreferences，首次启动时会使用默认设置（因为 SQLite 中没有记录）

如果需要迁移老用户的设置，可以添加迁移逻辑：

```dart
Future<void> migrateFromSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final oldSettings = prefs.getString('backup_settings');

  if (oldSettings != null) {
    // 迁移到 SQLite
    final settings = BackupSettings.fromJson(jsonDecode(oldSettings));
    await saveSettings(settings);

    // 删除旧数据
    await prefs.remove('backup_settings');
  }
}
```

## 代码变更

### 修改前

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<BackupSettings> getSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString(_settingsKey);
  // ...
}

Future<void> saveSettings(BackupSettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
}
```

### 修改后

```dart
import '../../services/database/database_service.dart';
import '../../constants/db_constants.dart';

Future<BackupSettings> getSettings() async {
  final db = await _dbService.database;
  final result = await db.query(
    DbConstants.tableAppSettings,
    where: '${DbConstants.columnSettingKey} = ?',
    whereArgs: [_settingsKey],
  );
  // ...
}

Future<void> saveSettings(BackupSettings settings) async {
  final db = await _dbService.database;
  await db.rawInsert('''
    INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
      (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
    VALUES (?, ?, ?)
  ''', [_settingsKey, jsonEncode(settings.toJson()), DateTime.now().millisecondsSinceEpoch]);
}
```

## 测试

需要测试的场景：
1. ✅ 首次使用（默认设置）
2. ✅ 保存设置
3. ✅ 读取设置
4. ✅ 更新设置
5. ✅ 备份数据库后，设置也被备份
6. ✅ 恢复数据库后，设置也被恢复

## 总结

这个优化使得备份功能更加简洁、统一，符合项目的整体架构设计。感谢用户的建议！
