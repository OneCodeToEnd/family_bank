# 代码规范

本文档定义账清项目的代码规范和最佳实践。

## Dart代码规范

### 命名规范

**类名**：使用大驼峰命名法
```dart
class TransactionProvider {}
class DatabaseService {}
```

**变量和方法**：使用小驼峰命名法
```dart
String userName;
void createTransaction() {}
```

**常量**：使用小驼峰命名法
```dart
const double maxAmount = 999999.99;
```

**私有成员**：使用下划线前缀
```dart
String _privateField;
void _privateMethod() {}
```

### 文件命名

使用小写加下划线：
```
transaction_provider.dart
database_service.dart
```

---

## 代码组织

### 导入顺序

1. Dart SDK导入
2. Flutter导入
3. 第三方包导入
4. 项目内部导入

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';
```

### 类成员顺序

1. 静态常量
2. 静态变量
3. 实例变量
4. 构造函数
5. 静态方法
6. 实例方法
7. 重写方法

---

## Flutter最佳实践

### 使用const构造函数

```dart
// 好
const Text('Hello');
const SizedBox(height: 16);

// 避免
Text('Hello');
SizedBox(height: 16);
```

### 提取Widget

将复杂Widget提取为独立组件：

```dart
// 好
class TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return ListTile(...);
  }
}

// 避免
Widget _buildTransactionTile(Transaction transaction) {
  return ListTile(...);
}
```

---

## Provider使用规范

### 读取数据

```dart
// 监听变化
context.watch<TransactionProvider>()

// 不监听
context.read<TransactionProvider>()

// 选择性监听
context.select<TransactionProvider, List<Transaction>>(
  (provider) => provider.transactions
)
```

### 避免在build中调用方法

```dart
// 好
ElevatedButton(
  onPressed: () => context.read<Provider>().method(),
  child: Text('Button'),
)

// 避免
@override
Widget build(BuildContext context) {
  context.read<Provider>().method(); // 错误！
  return Container();
}
```

---

## 异步编程

### 使用async/await

```dart
// 好
Future<void> loadData() async {
  try {
    final data = await service.getData();
    setState(() => _data = data);
  } catch (e) {
    logger.e('Error: $e');
  }
}

// 避免
Future<void> loadData() {
  service.getData().then((data) {
    setState(() => _data = data);
  }).catchError((e) {
    logger.e('Error: $e');
  });
}
```

---

## 错误处理

### 捕获异常

```dart
try {
  await riskyOperation();
} on SpecificException catch (e) {
  // 处理特定异常
} catch (e, stackTrace) {
  logger.e('Error', e, stackTrace);
  // 处理通用异常
}
```

---

## 注释规范

### 文档注释

```dart
/// 创建新的交易记录
///
/// [transaction] 要创建的交易对象
/// 返回创建成功的交易ID
Future<int> createTransaction(Transaction transaction) async {
  // 实现
}
```

### 代码注释

只在必要时添加注释，代码应该自解释：

```dart
// 好：代码清晰，无需注释
final isExpense = transaction.type == 'expense';

// 避免：不必要的注释
// 检查是否是支出
final isExpense = transaction.type == 'expense';
```

---

## 测试规范

### 测试文件命名

```
lib/services/database_service.dart
test/services/database_service_test.dart
```

### 测试结构

```dart
void main() {
  group('DatabaseService', () {
    test('should create transaction', () async {
      // Arrange
      final service = DatabaseService();

      // Act
      final result = await service.createTransaction(transaction);

      // Assert
      expect(result, isNotNull);
    });
  });
}
```

---

## Git提交规范

### 提交信息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type类型

- `feat`: 新功能
- `fix`: Bug修复
- `docs`: 文档更新
- `style`: 代码格式
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

### 示例

```
feat(transaction): 添加交易导入功能

- 支持CSV文件导入
- 支持Excel文件导入
- 自动去重

Closes #123
```

---

## 代码审查

### 审查清单

- [ ] 代码符合规范
- [ ] 有适当的注释
- [ ] 有单元测试
- [ ] 无明显性能问题
- [ ] 无安全漏洞

---

## 相关文档

- [开发环境](setup.md)
- [测试指南](testing.md)