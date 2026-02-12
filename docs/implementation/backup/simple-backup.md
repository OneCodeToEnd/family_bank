# 备份与同步功能 - 简单实用方案

## 核心理念

**简单、可靠、易维护** - 不要过度设计，选择成熟的解决方案。

---

## 推荐方案：使用 PowerSync

### 为什么选择 PowerSync？

1. **专为 SQLite 设计** - 无需改造现有数据库架构
2. **开箱即用** - 自动处理冲突、离线同步、增量更新
3. **成熟稳定** - 专业团队维护，有完整文档
4. **保留隐私** - 支持端到端加密
5. **代码量少** - 只需添加少量代码即可实现同步

### 架构图

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  设备 A     │         │  Supabase    │         │  设备 B     │
│  (SQLite)   │◄───────►│  (PostgreSQL)│◄───────►│  (SQLite)   │
│  PowerSync  │  同步    │   后端服务    │  同步    │  PowerSync  │
└─────────────┘         └──────────────┘         └─────────────┘
```

---

## 实施步骤

### 第一步：添加依赖

```yaml
# pubspec.yaml
dependencies:
  powersync: ^1.0.0
  supabase_flutter: ^2.0.0  # 作为后端
```

### 第二步：配置 Supabase（免费）

1. 访问 https://supabase.com 创建项目（免费额度足够个人使用）
2. 创建数据表（PowerSync 会自动同步 SQLite 表结构）
3. 启用 Realtime 功能
4. 获取 API Key

### 第三步：集成 PowerSync（核心代码）

```dart
// lib/services/sync/powersync_service.dart
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PowerSyncService {
  static PowerSyncDatabase? _db;

  // 初始化
  static Future<void> initialize() async {
    // 1. 定义数据库 Schema（映射现有表）
    final schema = Schema([
      Table('transactions', [
        Column.text('account_id'),
        Column.text('category_id'),
        Column.real('amount'),
        Column.text('description'),
        Column.integer('transaction_time'),
        // ... 其他字段
      ]),
      Table('accounts', [...]),
      Table('categories', [...]),
      // ... 其他表
    ]);

    // 2. 创建 PowerSync 数据库
    _db = PowerSyncDatabase(
      schema: schema,
      path: 'family_bank_sync.db',
    );

    await _db!.initialize();

    // 3. 连接到 Supabase
    final connector = SupabaseConnector(
      supabaseUrl: 'YOUR_SUPABASE_URL',
      supabaseKey: 'YOUR_SUPABASE_KEY',
    );

    await _db!.connect(connector: connector);
  }

  // 获取数据库实例
  static PowerSyncDatabase get db => _db!;

  // 同步状态
  static Stream<SyncStatus> get syncStatus => _db!.statusStream;
}
```

### 第四步：修改现有代码（最小改动）

```dart
// 原来的代码
final db = await DatabaseService().database;
final results = await db.query('transactions');

// 改为
final db = PowerSyncService.db;
final results = await db.getAll('SELECT * FROM transactions');

// 就这么简单！PowerSync 会自动同步
```

---

## 备份功能（超简单）

### 方案：直接复制数据库文件

```dart
// lib/services/backup/simple_backup_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SimpleBackupService {
  // 1. 创建备份（复制数据库文件）
  Future<File> createBackup() async {
    final dbPath = await getDatabasePath();
    final backupDir = await getBackupDirectory();

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = '${backupDir.path}/backup_$timestamp.db';

    // 直接复制文件
    final dbFile = File(dbPath);
    final backupFile = await dbFile.copy(backupPath);

    return backupFile;
  }

  // 2. 恢复备份
  Future<void> restoreBackup(File backupFile) async {
    final dbPath = await getDatabasePath();

    // 关闭数据库连接
    await DatabaseService().close();

    // 替换数据库文件
    await backupFile.copy(dbPath);

    // 重新初始化
    await DatabaseService().database;
  }

  // 3. 分享备份文件（用户可以保存到云盘）
  Future<void> shareBackup(File backupFile) async {
    await Share.shareXFiles([XFile(backupFile.path)]);
  }

  // 4. 自动备份（每天一次）
  Future<void> autoBackup() async {
    final lastBackup = await getLastBackupTime();
    final now = DateTime.now();

    if (now.difference(lastBackup).inDays >= 1) {
      await createBackup();
      await saveLastBackupTime(now);

      // 清理旧备份（只保留最近 7 个）
      await cleanOldBackups(keepCount: 7);
    }
  }
}
```

---

## 完整实施方案

### 阶段 1：本地备份（1-2 天）

**功能：**
- 手动创建备份
- 恢复备份
- 分享备份文件（用户自己保存到 iCloud/Google Drive）

**代码量：** ~200 行

### 阶段 2：集成 PowerSync（3-5 天）

**功能：**
- 自动同步到 Supabase
- 多设备实时同步
- 离线支持
- 自动冲突解决

**代码量：** ~300 行（主要是配置）

### 阶段 3：优化体验（2-3 天）

**功能：**
- 同步状态显示
- 自动备份
- 备份历史管理

**代码量：** ~200 行

**总计：** 约 1-2 周完成，代码量 ~700 行

---

## 成本分析

### Supabase 免费额度（足够个人使用）

- 数据库：500MB
- 带宽：5GB/月
- 实时连接：200 个并发
- 认证用户：50,000 个

**结论：** 对于家庭财务应用，免费额度完全够用。

---

## 关键优势

### 1. 简单
- 不需要自建服务器
- 不需要写复杂的同步逻辑
- 不需要处理冲突（PowerSync 自动处理）

### 2. 可靠
- PowerSync 是专业的同步引擎
- Supabase 是成熟的 BaaS 平台
- 有完整的文档和社区支持

### 3. 易维护
- 代码量少
- 逻辑清晰
- 出问题容易排查

### 4. 可扩展
- 未来可以添加家庭成员协作
- 可以添加 Web 端
- 可以迁移到自建服务器

---

## UI 设计（简洁版）

```
设置页面
  └─ 数据管理
      ├─ 备份
      │   ├─ [立即备份] 按钮
      │   ├─ [恢复备份] 按钮
      │   └─ 最后备份：2024-01-15 10:30
      │
      └─ 同步
          ├─ 同步状态：✅ 已同步
          ├─ [立即同步] 按钮
          └─ 自动同步：[开关]
```

---

## 示例代码结构

```
lib/
├── services/
│   ├── backup/
│   │   └── simple_backup_service.dart    # 备份服务（200行）
│   └── sync/
│       └── powersync_service.dart        # 同步服务（300行）
├── providers/
│   └── sync_provider.dart                # 状态管理（100行）
└── screens/
    └── settings/
        └── data_management_screen.dart   # UI（200行）
```

**总代码量：** ~800 行（包括 UI）

---

## 常见问题

### Q1: PowerSync 安全吗？
A: 是的。支持端到端加密，数据传输使用 HTTPS，Supabase 有完善的安全机制。

### Q2: 如果 Supabase 挂了怎么办？
A: 本地数据不受影响，可以继续使用。恢复后自动同步。而且有本地备份作为保险。

### Q3: 可以迁移到自建服务器吗？
A: 可以。PowerSync 支持自定义后端，只需实现接口即可。

### Q4: 冲突怎么处理？
A: PowerSync 使用 CRDT 算法自动解决冲突，对于财务数据，可以配置"最后写入获胜"策略。

### Q5: 性能如何？
A: 非常好。只同步变更数据，支持离线操作，本地查询速度不受影响。

---

## 对比其他方案

| 方案 | 复杂度 | 代码量 | 维护成本 | 推荐度 |
|------|--------|--------|----------|--------|
| **PowerSync + Supabase** | ⭐⭐ | ~800行 | 低 | ⭐⭐⭐⭐⭐ |
| 自建同步服务 | ⭐⭐⭐⭐⭐ | ~5000行 | 高 | ⭐⭐ |
| Firebase Firestore | ⭐⭐⭐ | ~1500行 | 中 | ⭐⭐⭐⭐ |
| 只用云存储备份 | ⭐ | ~500行 | 低 | ⭐⭐⭐ |

---

## 总结

**最佳实践 = 简单 + 可靠 + 易维护**

1. **备份**：直接复制数据库文件 + 分享功能
2. **同步**：使用 PowerSync + Supabase
3. **时间**：1-2 周完成
4. **成本**：免费（Supabase 免费额度）
5. **代码**：~800 行

这个方案已经被很多应用验证过，简单可靠，不需要重复造轮子。

---

## 参考资源

- [PowerSync 官方文档](https://docs.powersync.com/)
- [Supabase 快速开始](https://supabase.com/docs/guides/getting-started)
- [PowerSync Flutter 示例](https://github.com/powersync-ja/powersync.dart/tree/main/demos)
