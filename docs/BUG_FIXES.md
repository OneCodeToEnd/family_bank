# Bug 修复记录

本文档记录所有 Bug 的修复过程，最新的 Bug 在最前面。

---

## Bug #5: 导入交易数据未入库 (2026-01-07)

### 问题描述
用户导入 Excel/CSV 账单后，AI 分类接口正常调用并学习了规则，但交易数据没有保存到数据库中。导致导入流程看似成功，但交易列表中看不到导入的数据。

### 根本原因

**原因 1**：在 `ImportConfirmationScreen._saveAll()` 方法中，错误地使用了 `updateTransaction()` 方法来保存新导入的交易。

**问题代码**：
```dart
await _transactionDbService.updateTransaction(updated);  // ❌ 错误
```

新导入的交易在数据库中不存在（没有 ID），`updateTransaction()` 无法更新不存在的记录，导致数据丢失。

**原因 2**：`TransactionDbService.createTransactionsBatch()` 返回值的 key 使用下划线命名（`success_count`），但读取时使用驼峰命名（`successCount`），导致返回值读取失败，实际没有执行插入操作。

**问题代码**：
```dart
// TransactionDbService.dart
return {
  'success_count': successCount,     // ❌ 下划线
  'duplicate_count': duplicateCount,
};

// ImportConfirmationScreen.dart
savedCount = result['successCount'] ?? 0;  // ❌ 驼峰，读取为 null
```

### 解决方案

**修改文件 1**：`lib/screens/import/import_confirmation_screen.dart`

1. **使用批量创建方法**：将所有交易收集到列表，使用 `createTransactionsBatch()` 批量保存
2. **保存所有交易**：即使未分类的交易也保存到数据库
3. **利用内置去重**：`createTransactionsBatch()` 方法内置去重逻辑，避免重复导入

**修复后代码**：
```dart
Future<void> _saveAll() async {
  // 准备要保存的交易列表
  List<Transaction> transactionsToSave = [];

  for (var i = 0; i < widget.transactions.length; i++) {
    final transaction = widget.transactions[i];
    final matchResult = _matchResults![i];

    if (matchResult?.categoryId != null) {
      final updated = transaction.copyWith(
        categoryId: matchResult!.categoryId,
        isConfirmed: matchResult.confidence >= 0.8,
        updatedAt: DateTime.now(),
      );
      transactionsToSave.add(updated);
    } else {
      // 没有分类的也保存
      transactionsToSave.add(transaction);
    }
  }

  // 批量保存到数据库 ✅
  if (transactionsToSave.isNotEmpty) {
    final result = await _transactionDbService.createTransactionsBatch(transactionsToSave);
    savedCount = result['successCount'] ?? 0;
    duplicateCount = result['duplicateCount'] ?? 0;
  }
}
```

**修改文件 2**：`lib/services/database/transaction_db_service.dart`

统一返回值的命名风格为驼峰命名：

```dart
return {
  'successCount': successCount,      // ✅ 驼峰
  'duplicateCount': duplicateCount,
  'duplicateHashes': duplicateHashes,
};
```

### 改进点
1. 显示更详细的反馈信息（成功数量、重复数量、学习规则数量）
2. 自动去重，防止重复导入
3. 未分类的交易也会保存，不会丢失数据
4. 统一代码风格，使用驼峰命名

### 修复状态
✅ 已修复并验证

---

## Bug #4: macOS 网络权限缺失 (2026-01-07)

### 问题描述
在 macOS 上运行时，AI 模型列表获取失败：
```
Connection failed (OS Error: Operation not permitted, errno = 1)
address = api.deepseek.com, port = 443
```

### 根本原因
macOS 沙箱应用需要在 entitlements 文件中显式声明网络客户端权限。

### 解决方案

在 macOS entitlements 文件中添加网络客户端权限：

**文件 1：`macos/Runner/DebugProfile.entitlements`**
```xml
<key>com.apple.security.network.client</key>
<true/>
```

**文件 2：`macos/Runner/Release.entitlements`**
```xml
<key>com.apple.security.network.client</key>
<true/>
```

### 注意事项
- 修改后需要完全重启应用（热重启无效）
- 也可以使用 `flutter run` 重新运行

### 修复状态
✅ 已修复

---

## Bug #3: Late Final 初始化错误 (2026-01-07)

### 问题描述
进入 AI 设置页面时崩溃：
```
LateInitializationError: Field '_db@1585021399' has already been initialized.
```

### 根本原因
多个服务类使用了错误的初始化模式：
- 使用 `late final Database _db` 声明
- 构造函数中调用 `_init()` 一次
- 每个方法又调用 `_init()` 一次
- **`late final` 只能赋值一次**，第二次赋值时崩溃

### 受影响的文件
- `lib/services/ai/ai_config_service.dart`
- `lib/services/category/batch_classification_service.dart`
- `lib/services/category/category_match_service.dart`
- `lib/services/category/category_learning_service.dart`

### 解决方案

**方案 1：使用 Getter（AIConfigService）**
```dart
// 修改前
late final Database _db;

// 修改后
Future<Database> get _db async => await _dbService.database;
```

**方案 2：使用可空类型 + 防重复初始化（其他服务）**
```dart
// 修改前
late final Database _db;

CategoryMatchService() {
  _init();
}

Future<void> _init() async {
  _db = await _dbService.database;
}

// 修改后
Database? _db;

Future<void> _init() async {
  if (_db != null) return; // 防止重复初始化
  _db = await _dbService.database;
}

Future<void> someMethod() async {
  await _init(); // 确保初始化
  // 使用 _db!
}
```

### 修复状态
✅ 已修复并验证

---

## Bug #2: app_settings 表缺失 (2026-01-07)

### 问题描述
进入 AI 设置页面时提示"加载配置失败"。

### 根本原因
`app_settings` 表只在数据库初始创建（`_onCreate`）时创建，在数据库升级（`_onUpgrade`）时没有为从旧版本（V1/V2）升级的用户创建该表。

### 受影响用户
- 从 V1 升级到 V3 的用户
- 从 V2 升级到 V3 的用户

### 解决方案

在 `_onUpgrade` 方法开始时，使用 `CREATE TABLE IF NOT EXISTS` 确保表存在：

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // 确保 app_settings 表存在（对所有旧版本）
  await db.execute('''
    CREATE TABLE IF NOT EXISTS ${DbConstants.tableAppSettings} (
      ${DbConstants.columnSettingKey} TEXT PRIMARY KEY,
      ${DbConstants.columnSettingValue} TEXT NOT NULL,
      ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
    )
  ''');

  // 其他升级逻辑...
}
```

### 修复的文件
- `lib/services/database/database_service.dart`

### 修复状态
✅ 已修复并验证

---

## Bug #1: setState() 在 build 期间调用 (2026-01-07)

### 问题描述
应用启动时崩溃：
```
setState() or markNeedsBuild() called during build.
```

### 根本原因
在 `initState` 中直接调用 Provider 的方法会触发 `notifyListeners()`，这会在 build 阶段调用 `setState()`，违反了 Flutter 的规则。

### 受影响的文件
- `lib/screens/account/account_list_screen.dart`
- `lib/screens/member/member_list_screen.dart`
- `lib/screens/settings/ai_settings_screen.dart`

### 解决方案

使用 `WidgetsBinding.instance.addPostFrameCallback` 将数据加载延迟到 build 完成之后：

```dart
// 修改前
@override
void initState() {
  super.initState();
  _loadAccounts(); // ❌ 直接调用会触发 setState
}

// 修改后
@override
void initState() {
  super.initState();
  // 使用 addPostFrameCallback 避免在 build 期间调用 setState
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAccounts(); // ✅ 在 build 完成后调用
  });
}
```

### 修复状态
✅ 已修复并验证

---

## Bug 修复最佳实践

### 1. Late 变量初始化
- ❌ 避免在构造函数和方法中多次调用 `_init()`
- ✅ 使用 getter 或可空类型 + 防重复检查
- ✅ 记住：`late final` 只能赋值一次

### 2. 数据库升级
- ❌ 避免假设表已存在
- ✅ 使用 `CREATE TABLE IF NOT EXISTS`
- ✅ 在 `_onUpgrade` 开始时确保关键表存在

### 3. Flutter 生命周期
- ❌ 避免在 `initState` 中直接调用可能触发 `setState` 的方法
- ✅ 使用 `addPostFrameCallback` 延迟到 build 后
- ✅ 或使用 `FutureBuilder` / `StreamBuilder`

### 4. 调试技巧
- 查看完整的堆栈跟踪
- 使用 `flutter analyze` 检查静态错误
- 添加日志输出定位问题
- 使用 DevTools 调试工具
