# 备份与同步 - 完全自主方案

## 设计原则

1. **零外部依赖** - 不依赖任何第三方服务
2. **简单可靠** - 逻辑清晰，容易维护
3. **用户可控** - 数据完全由用户掌控

---

## 方案一：本地备份 + 系统云盘（推荐）

### 核心思路

利用操作系统自带的云同步功能，应用只负责备份到特定文件夹。

```
应用数据库 → 备份到云盘文件夹 → 系统自动同步 → 其他设备
```

### 实现方式

#### 1. iOS/macOS：使用 iCloud Drive

```dart
// lib/services/backup/icloud_backup_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ICloudBackupService {
  // 获取 iCloud Drive 目录
  Future<Directory> getICloudDirectory() async {
    // iOS/macOS 会自动同步这个目录
    final appSupport = await getApplicationSupportDirectory();
    final icloudDir = Directory('${appSupport.parent.path}/iCloud~com.yourapp.familybank');

    if (!await icloudDir.exists()) {
      await icloudDir.create(recursive: true);
    }

    return icloudDir;
  }

  // 备份到 iCloud
  Future<void> backupToICloud() async {
    final dbPath = await getDatabasePath();
    final icloudDir = await getICloudDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${icloudDir.path}/backup_$timestamp.db';

    // 复制数据库文件
    await File(dbPath).copy(backupPath);

    // 保存最新备份的元信息
    await File('${icloudDir.path}/latest.txt').writeAsString(backupPath);
  }

  // 从 iCloud 恢复
  Future<void> restoreFromICloud() async {
    final icloudDir = await getICloudDirectory();
    final latestPath = await File('${icloudDir.path}/latest.txt').readAsString();

    if (await File(latestPath).exists()) {
      final dbPath = await getDatabasePath();
      await File(latestPath).copy(dbPath);
    }
  }
}
```

#### 2. Android：使用 Google Drive 文件夹

```dart
// 类似的实现，使用 Android 的 Documents Provider
// 用户可以选择 Google Drive 文件夹
```

**优点：**
- 零代码复杂度，系统自动同步
- 不需要网络代码
- 用户数据在自己的云盘

**缺点：**
- 不是实时同步（系统决定何时同步）
- 需要用户登录 iCloud/Google 账号

---

## 方案二：文件导入导出（最简单）

### 核心思路

提供导出和导入功能，用户自己决定如何传输文件。

```dart
// lib/services/backup/export_import_service.dart
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class ExportImportService {
  // 1. 导出数据库
  Future<void> exportDatabase() async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);

    // 创建临时副本（带时间戳）
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final exportPath = '${tempDir.path}/family_bank_$timestamp.db';

    await dbFile.copy(exportPath);

    // 分享文件（用户可以保存到任何地方）
    await Share.shareXFiles(
      [XFile(exportPath)],
      subject: '账清数据备份',
      text: '备份时间：${DateTime.now()}',
    );
  }

  // 2. 导入数据库
  Future<void> importDatabase() async {
    // 让用户选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result != null && result.files.single.path != null) {
      final importFile = File(result.files.single.path!);

      // 验证文件
      if (await _validateDatabase(importFile)) {
        // 关闭当前数据库
        await DatabaseService().close();

        // 替换数据库文件
        final dbPath = await getDatabasePath();
        await importFile.copy(dbPath);

        // 重新初始化
        await DatabaseService().database;
      }
    }
  }

  // 验证数据库文件
  Future<bool> _validateDatabase(File dbFile) async {
    try {
      final db = await openDatabase(dbFile.path);
      // 检查必要的表是否存在
      final tables = await db.query('sqlite_master',
        where: 'type = ?',
        whereArgs: ['table']
      );
      await db.close();

      return tables.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
```

**使用场景：**
- 用户导出文件 → 通过微信/邮件发送 → 其他设备导入
- 用户导出文件 → 保存到 U 盘 → 其他设备导入
- 用户导出文件 → 上传到自己的网盘 → 其他设备下载导入

**优点：**
- 极其简单，代码量 ~100 行
- 完全由用户控制
- 零外部依赖

**缺点：**
- 需要手动操作
- 不是自动同步

---

## 方案三：WebDAV 同步（进阶）

### 核心思路

支持 WebDAV 协议，用户可以使用：
- 自建的 Nextcloud/ownCloud
- 坚果云等支持 WebDAV 的网盘
- NAS 设备

```dart
// lib/services/sync/webdav_sync_service.dart
import 'package:webdav_client/webdav_client.dart';

class WebDAVSyncService {
  late Client _client;

  // 初始化连接
  Future<void> connect({
    required String url,
    required String username,
    required String password,
  }) async {
    _client = newClient(
      url,
      user: username,
      password: password,
    );

    // 测试连接
    await _client.ping();
  }

  // 上传备份
  Future<void> uploadBackup() async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    final bytes = await dbFile.readAsBytes();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final remotePath = '/family_bank/backup_$timestamp.db';

    await _client.write(remotePath, bytes);

    // 更新最新备份标记
    await _client.write('/family_bank/latest.txt',
      utf8.encode(remotePath)
    );
  }

  // 下载备份
  Future<void> downloadBackup() async {
    // 获取最新备份路径
    final latestBytes = await _client.read('/family_bank/latest.txt');
    final remotePath = utf8.decode(latestBytes);

    // 下载备份文件
    final backupBytes = await _client.read(remotePath);

    // 保存到本地
    final dbPath = await getDatabasePath();
    await DatabaseService().close();
    await File(dbPath).writeAsBytes(backupBytes);
    await DatabaseService().database;
  }

  // 自动同步
  Future<void> sync() async {
    try {
      // 1. 检查远程是否有更新
      final remoteTime = await _getRemoteModifyTime();
      final localTime = await _getLocalModifyTime();

      if (remoteTime > localTime) {
        // 远程更新，下载
        await downloadBackup();
      } else if (localTime > remoteTime) {
        // 本地更新，上传
        await uploadBackup();
      }
    } catch (e) {
      // 网络错误，忽略
    }
  }
}
```

**优点：**
- 自动同步
- 用户数据在自己的服务器
- 标准协议，兼容性好

**缺点：**
- 需要用户配置 WebDAV 服务器
- 代码量稍多（~300 行）

---

## 推荐实施方案

### 阶段 1：基础备份（必须实现）

**功能：**
1. 手动创建备份
2. 导出备份文件（分享）
3. 导入备份文件

**代码量：** ~150 行
**时间：** 1 天

```dart
class BackupService {
  // 创建备份
  Future<File> createBackup() async {
    final dbPath = await getDatabasePath();
    final backupDir = await getBackupDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${backupDir.path}/backup_$timestamp.db';

    return await File(dbPath).copy(backupPath);
  }

  // 导出备份
  Future<void> exportBackup(File backupFile) async {
    await Share.shareXFiles([XFile(backupFile.path)]);
  }

  // 导入备份
  Future<void> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result != null) {
      final importFile = File(result.files.single.path!);
      await _restoreDatabase(importFile);
    }
  }
}
```

### 阶段 2：自动备份（可选）

**功能：**
1. 定时自动备份（每天/每周）
2. 备份到系统云盘文件夹
3. 清理旧备份

**代码量：** ~100 行
**时间：** 1 天

```dart
class AutoBackupService {
  // 自动备份
  Future<void> autoBackup() async {
    final settings = await getBackupSettings();

    if (!settings.autoBackupEnabled) return;

    final lastBackup = settings.lastBackupTime;
    final now = DateTime.now();

    // 检查是否需要备份
    if (now.difference(lastBackup).inDays >= settings.backupIntervalDays) {
      final backup = await BackupService().createBackup();

      // 复制到云盘文件夹（系统会自动同步）
      await _copyToCloudFolder(backup);

      // 清理旧备份
      await _cleanOldBackups(keepCount: 7);

      // 更新设置
      await saveLastBackupTime(now);
    }
  }
}
```

### 阶段 3：WebDAV 同步（高级功能）

**功能：**
1. 配置 WebDAV 服务器
2. 自动上传/下载
3. 冲突检测

**代码量：** ~300 行
**时间：** 2-3 天

---

## 完整代码结构

```
lib/
├── services/
│   └── backup/
│       ├── backup_service.dart          # 基础备份（150行）
│       ├── auto_backup_service.dart     # 自动备份（100行）
│       └── webdav_sync_service.dart     # WebDAV同步（300行，可选）
├── providers/
│   └── backup_provider.dart             # 状态管理（100行）
└── screens/
    └── settings/
        └── backup_settings_screen.dart  # UI（150行）
```

**总代码量：**
- 基础版：~400 行（阶段 1 + 2）
- 完整版：~700 行（包含 WebDAV）

---

## UI 设计

```
设置 → 数据管理
  ├─ 备份管理
  │   ├─ [立即备份] 按钮
  │   ├─ [导出备份] 按钮
  │   ├─ [导入备份] 按钮
  │   ├─ 最后备份：2024-01-15 10:30
  │   └─ 备份历史（列表）
  │
  ├─ 自动备份
  │   ├─ 启用自动备份 [开关]
  │   ├─ 备份频率：每天/每周
  │   └─ 保留备份数：7 个
  │
  └─ 高级同步（可选）
      ├─ WebDAV 配置
      │   ├─ 服务器地址
      │   ├─ 用户名
      │   └─ 密码
      └─ [测试连接] 按钮
```

---

## 依赖包（最少）

```yaml
dependencies:
  path_provider: ^2.0.0    # 获取路径（必须）
  share_plus: ^7.0.0       # 分享文件（必须）
  file_picker: ^6.0.0      # 选择文件（必须）
  webdav_client: ^1.2.0    # WebDAV（可选）
```

**说明：**
- 前 3 个是 Flutter 官方维护的包，非常稳定
- webdav_client 是可选的，不用也可以

---

## 数据安全

### 1. 备份加密（可选）

```dart
class EncryptedBackupService {
  Future<File> createEncryptedBackup(String password) async {
    // 1. 创建普通备份
    final backup = await BackupService().createBackup();

    // 2. 加密文件
    final key = await _deriveKey(password);
    final encrypted = await EncryptionService.encryptFile(backup, key);

    // 3. 保存加密文件
    final encryptedPath = '${backup.path}.encrypted';
    await File(encryptedPath).writeAsBytes(encrypted);

    // 4. 删除明文备份
    await backup.delete();

    return File(encryptedPath);
  }
}
```

### 2. 备份验证

```dart
Future<bool> validateBackup(File backupFile) async {
  try {
    // 尝试打开数据库
    final db = await openDatabase(backupFile.path);

    // 检查关键表
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );

    final requiredTables = [
      'transactions', 'accounts', 'categories'
    ];

    final tableNames = result.map((r) => r['name']).toList();
    final hasAllTables = requiredTables.every(
      (table) => tableNames.contains(table)
    );

    await db.close();
    return hasAllTables;
  } catch (e) {
    return false;
  }
}
```

---

## 使用场景示例

### 场景 1：个人多设备使用

**方案：** 自动备份到系统云盘

1. 在 iPhone 上启用自动备份
2. 备份自动保存到 iCloud Drive
3. 在 iPad 上打开应用，导入最新备份
4. 每天自动备份，保持数据同步

**操作：** 每台设备每天点一次"导入最新备份"

### 场景 2：家庭成员共享

**方案：** 导出/导入 + 微信传输

1. 主要使用者定期导出备份
2. 通过微信发送给家人
3. 家人导入备份查看数据

**操作：** 需要时手动导出/导入

### 场景 3：高级用户

**方案：** WebDAV 自动同步

1. 配置家里的 NAS 或 Nextcloud
2. 启用自动同步
3. 所有设备自动保持同步

**操作：** 配置一次，自动同步

---

## 对比方案

| 方案 | 复杂度 | 代码量 | 外部依赖 | 推荐度 |
|------|--------|--------|----------|--------|
| **导出/导入** | ⭐ | ~150行 | 0 | ⭐⭐⭐⭐⭐ |
| **自动备份到云盘** | ⭐⭐ | ~250行 | 0 | ⭐⭐⭐⭐⭐ |
| **WebDAV 同步** | ⭐⭐⭐ | ~550行 | 1个包 | ⭐⭐⭐⭐ |
| PowerSync | ⭐⭐⭐⭐ | ~800行 | 2个包+服务 | ⭐⭐⭐ |
| 自建服务器 | ⭐⭐⭐⭐⭐ | ~3000行 | 需要服务器 | ⭐⭐ |

---

## 总结

### 最简单可靠的方案

**阶段 1（必须）：** 导出/导入功能
- 代码量：~150 行
- 时间：1 天
- 依赖：3 个官方包

**阶段 2（推荐）：** 自动备份到云盘
- 代码量：+100 行
- 时间：+1 天
- 依赖：0 新增

**阶段 3（可选）：** WebDAV 同步
- 代码量：+300 行
- 时间：+2-3 天
- 依赖：+1 个包

### 核心优势

1. **零外部服务依赖** - 不依赖任何第三方服务
2. **简单可控** - 代码量少，逻辑清晰
3. **灵活** - 用户可以选择任何传输方式
4. **安全** - 数据完全由用户掌控
5. **可靠** - 没有网络服务的不确定性

### 实施建议

**先实现阶段 1 和 2**（~250 行代码，2 天时间），这已经能满足 90% 的使用场景。

如果用户有高级需求，再考虑实现 WebDAV 同步。

---

## 参考代码

完整的示例代码见：`lib/services/backup/` 目录

- `backup_service.dart` - 基础备份服务
- `auto_backup_service.dart` - 自动备份服务
- `webdav_sync_service.dart` - WebDAV 同步服务（可选）
