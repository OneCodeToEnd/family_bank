# 测试指南

本指南介绍账清项目的测试策略和实践。

## 测试类型

### 单元测试

测试单个函数或类：
- 数据模型
- 服务层方法
- 工具函数

### Widget测试

测试UI组件：
- 单个Widget
- Widget交互
- 状态变化

### 集成测试

测试完整流程：
- 用户场景
- 多个组件协作
- 端到端测试

---

## 运行测试

### 运行所有测试

```bash
flutter test
```

### 运行特定测试

```bash
flutter test test/services/database_service_test.dart
```

### 生成覆盖率报告

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 单元测试

### 测试结构

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionService', () {
    late TransactionService service;

    setUp(() {
      service = TransactionService();
    });

    tearDown(() {
      // 清理资源
    });

    test('should create transaction', () async {
      // Arrange
      final transaction = Transaction(...);

      // Act
      final result = await service.create(transaction);

      // Assert
      expect(result, isNotNull);
      expect(result.id, isPositive);
    });
  });
}
```

### Mock依赖

使用`mockito`创建Mock对象：

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([DatabaseService])
void main() {
  test('should use mocked service', () async {
    // Arrange
    final mockDb = MockDatabaseService();
    when(mockDb.query(any)).thenAnswer((_) async => []);

    // Act & Assert
    // ...
  });
}
```

---

## Widget测试

### 基本Widget测试

```dart
testWidgets('should display transaction tile', (tester) async {
  // Arrange
  final transaction = Transaction(...);

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: TransactionTile(transaction: transaction),
    ),
  );

  // Assert
  expect(find.text(transaction.description), findsOneWidget);
  expect(find.text('¥${transaction.amount}'), findsOneWidget);
});
```

### 测试交互

```dart
testWidgets('should navigate on tap', (tester) async {
  // Arrange
  await tester.pumpWidget(MyApp());

  // Act
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();

  // Assert
  expect(find.byType(DetailScreen), findsOneWidget);
});
```

### 测试Provider

```dart
testWidgets('should update when provider changes', (tester) async {
  // Arrange
  final provider = TransactionProvider();

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: TransactionList()),
    ),
  );

  // Act
  provider.addTransaction(transaction);
  await tester.pump();

  // Assert
  expect(find.byType(TransactionTile), findsNWidgets(1));
});
```

---

## 集成测试

### 创建集成测试

在`integration_test/`目录创建测试：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete transaction flow', (tester) async {
    // 启动应用
    await tester.pumpWidget(MyApp());

    // 创建交易
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('amount')), '100');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 验证结果
    expect(find.text('¥100.00'), findsOneWidget);
  });
}
```

### 运行集成测试

```bash
flutter test integration_test/
```

---

## 数据库测试

### 使用内存数据库

```dart
test('should insert and query transaction', () async {
  // Arrange
  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (db, version) {
      // 创建表结构
    },
  );

  // Act
  await db.insert('transactions', transaction.toMap());
  final result = await db.query('transactions');

  // Assert
  expect(result.length, 1);
  expect(result.first['amount'], transaction.amount);
});
```

---

## 测试最佳实践

### AAA模式

- **Arrange**: 准备测试数据
- **Act**: 执行被测试代码
- **Assert**: 验证结果

### 测试命名

使用描述性名称：

```dart
// 好
test('should return empty list when no transactions exist', () {});

// 避免
test('test1', () {});
```

### 独立性

每个测试应该独立：
- 不依赖其他测试
- 不影响其他测试
- 可以单独运行

### 覆盖率目标

- 核心业务逻辑：≥80%
- UI组件：≥60%
- 整体覆盖率：≥70%

---

## 持续集成

### GitHub Actions

在`.github/workflows/test.yml`配置：

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
```

---

## 故障排除

### 测试超时

增加超时时间：

```dart
test('long running test', () async {
  // ...
}, timeout: Timeout(Duration(minutes: 5)));
```

### 异步测试

确保使用`async/await`：

```dart
test('async test', () async {
  final result = await asyncOperation();
  expect(result, isNotNull);
});
```

---

## 相关文档

- [开发环境](setup.md)
- [代码规范](coding-standards.md)
- [构建发布](building.md)