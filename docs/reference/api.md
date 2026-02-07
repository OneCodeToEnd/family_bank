# API参考文档

本文档提供账清应用的核心API接口说明。

## Provider API

### FamilyProvider

家庭组和成员管理。

```dart
class FamilyProvider extends ChangeNotifier {
  // 初始化
  Future<void> initialize()

  // 创建家庭组
  Future<void> createFamily(FamilyGroup family)

  // 更新家庭组
  Future<void> updateFamily(FamilyGroup family)

  // 删除家庭组
  Future<void> deleteFamily(int familyId)

  // 添加成员
  Future<void> addMember(FamilyMember member)

  // 更新成员
  Future<void> updateMember(FamilyMember member)

  // 删除成员
  Future<void> deleteMember(int memberId)
}
```

### AccountProvider

账户管理。

```dart
class AccountProvider extends ChangeNotifier {
  // 初始化
  Future<void> initialize()

  // 创建账户
  Future<void> createAccount(Account account)

  // 更新账户
  Future<void> updateAccount(Account account)

  // 删除账户
  Future<void> deleteAccount(int accountId)

  // 更新账户余额
  Future<void> updateBalance(int accountId, double newBalance)
}
```

### CategoryProvider

分类管理。

```dart
class CategoryProvider extends ChangeNotifier {
  // 初始化
  Future<void> initialize()

  // 创建分类
  Future<void> createCategory(Category category)

  // 更新分类
  Future<void> updateCategory(Category category)

  // 删除分类
  Future<void> deleteCategory(int categoryId)

  // 获取分类树
  List<Category> getCategoryTree(String type)

  // 添加分类规则
  Future<void> addCategoryRule(CategoryRule rule)
}
```

### TransactionProvider

交易记录管理。

```dart
class TransactionProvider extends ChangeNotifier {
  // 初始化
  Future<void> initialize()

  // 创建交易
  Future<void> createTransaction(Transaction transaction)

  // 更新交易
  Future<void> updateTransaction(Transaction transaction)

  // 删除交易
  Future<void> deleteTransaction(int transactionId)

  // 批量删除
  Future<void> deleteTransactions(List<int> ids)

  // 获取交易列表
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
    int? categoryId,
  })

  // 获取统计数据
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  })
}
```

---

## Service API

### DatabaseService

数据库核心服务（单例）。

```dart
class DatabaseService {
  // 获取实例
  static DatabaseService get instance

  // 初始化数据库
  Future<Database> get database

  // 关闭数据库
  Future<void> close()
}
```

### BillImportService

账单导入服务。

```dart
class BillImportService {
  // 导入CSV文件
  Future<ImportResult> importFromCsv(
    String filePath,
    Map<String, String> fieldMapping,
  )

  // 导入Excel文件
  Future<ImportResult> importFromExcel(
    String filePath,
    Map<String, String> fieldMapping,
  )

  // 验证导入数据
  Future<ValidationResult> validateImportData(
    List<Map<String, dynamic>> data,
  )
}
```

### CategoryMatchService

分类匹配服务。

```dart
class CategoryMatchService {
  // 匹配分类
  Future<CategoryMatch?> matchCategory(
    String description,
    String? counterparty,
  )

  // 批量匹配
  Future<List<CategoryMatch>> batchMatch(
    List<Transaction> transactions,
  )
}
```

### AiClassifierService

AI分类服务。

```dart
abstract class AiClassifierService {
  // 分类单个交易
  Future<ClassificationResult> classify(
    String description,
    String? counterparty,
    List<Category> categories,
  )

  // 批量分类
  Future<List<ClassificationResult>> batchClassify(
    List<Transaction> transactions,
    List<Category> categories,
  )
}
```

---

## 数据模型

### Transaction

交易记录模型。

```dart
class Transaction {
  final int? id;
  final int accountId;
  final int? categoryId;
  final String type;              // 'income' | 'expense'
  final double amount;
  final DateTime transactionTime;
  final String? description;
  final String? counterparty;
  final String? importSource;
  final String hash;
  final bool isConfirmed;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Category

分类模型。

```dart
class Category {
  final int? id;
  final String name;
  final String type;              // 'income' | 'expense'
  final int? parentId;
  final String? icon;
  final String? color;
  final List<String>? tags;
  final bool isSystem;
  final bool isHidden;
  final int sortOrder;
}
```

### Account

账户模型。

```dart
class Account {
  final int? id;
  final int familyId;
  final String name;
  final String type;              // 'alipay' | 'wechat' | 'bank' | 'cash'
  final double balance;
  final String? currency;
  final String? icon;
  final String? color;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## 事件与回调

### Provider通知

所有Provider继承自`ChangeNotifier`，在数据变更时会自动通知监听者。

使用方式：

```dart
// 监听整个Provider
Consumer<TransactionProvider>(
  builder: (context, provider, child) {
    return YourWidget();
  },
)

// 监听特定值
context.watch<TransactionProvider>().transactions

// 不监听，仅获取
context.read<TransactionProvider>().createTransaction(...)
```

---

## 错误处理

所有异步方法可能抛出以下异常：

- `DatabaseException`: 数据库操作错误
- `ValidationException`: 数据验证失败
- `NetworkException`: 网络请求失败
- `AuthenticationException`: 认证失败（AI API、邮箱等）

建议使用try-catch处理：

```dart
try {
  await provider.createTransaction(transaction);
} on DatabaseException catch (e) {
  // 处理数据库错误
} on ValidationException catch (e) {
  // 处理验证错误
} catch (e) {
  // 处理其他错误
}
```

---

## 更多信息

- [数据库Schema](database-schema.md)
- [架构设计](../architecture/tech-stack.md)
- [开发指南](../development/setup.md)