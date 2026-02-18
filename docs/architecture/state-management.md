# 状态管理

账清使用Provider进行状态管理，实现UI与业务逻辑的分离。

## Provider架构

### 核心Provider

应用包含6个主要Provider：

1. **FamilyProvider** - 家庭组和成员管理
2. **AccountProvider** - 账户管理
3. **CategoryProvider** - 分类管理
4. **TransactionProvider** - 交易记录管理
5. **SettingsProvider** - 应用设置管理
6. **ChatProvider** - AI问答对话管理

### Provider初始化

在`main.dart`中使用`MultiProvider`：

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FamilyProvider()),
    ChangeNotifierProvider(create: (_) => AccountProvider()),
    ChangeNotifierProvider(create: (_) => CategoryProvider()),
    ChangeNotifierProvider(create: (_) => TransactionProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => ChatProvider()),
  ],
  child: MyApp(),
)
```

---

## 数据流

### 单向数据流

```
User Action → Widget → Provider → Service → Database
                ↑                      ↓
                └──── notifyListeners() ──┘
```

### 示例流程

1. 用户点击"添加交易"按钮
2. Widget调用`TransactionProvider.createTransaction()`
3. Provider调用`TransactionDbService.insert()`
4. Service执行数据库操作
5. Provider调用`notifyListeners()`
6. 监听的Widget自动重建

---

## 使用Provider

### 读取数据

```dart
// 监听变化
final transactions = context.watch<TransactionProvider>().transactions;

// 不监听，仅读取
final provider = context.read<TransactionProvider>();
```

### 调用方法

```dart
// 创建交易
await context.read<TransactionProvider>().createTransaction(transaction);

// 更新交易
await context.read<TransactionProvider>().updateTransaction(transaction);
```

### Consumer组件

```dart
Consumer<TransactionProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.transactions.length,
      itemBuilder: (context, index) {
        return TransactionTile(provider.transactions[index]);
      },
    );
  },
)
```

---

## Provider实现

### 基本结构

```dart
class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  Future<void> initialize() async {
    _transactions = await TransactionDbService.getAll();
    notifyListeners();
  }

  Future<void> createTransaction(Transaction transaction) async {
    await TransactionDbService.insert(transaction);
    await initialize(); // 重新加载数据
  }
}
```

---

## ChatProvider

### 职责

管理AI问答的完整生命周期：

- 当前对话消息列表
- 多会话管理（创建、切换、删除、置顶）
- AI Agent交互（发送消息、接收流式回复）
- 用户反馈（点赞/点踩）与记忆保存
- 会话标题自动生成

### 数据流

```
用户输入 → ChatProvider.sendMessage()
    → AIAgentService.chat() → OpenAI API
    → 工具调用（SQL查询等） → 返回结果
    → 流式回调更新UI → 保存会话到数据库
```

### 关键方法

```dart
class ChatProvider extends ChangeNotifier {
  Future<void> sendMessage(String text);      // 发送消息
  Future<void> createNewSession();            // 新建会话
  Future<void> switchSession(String id);      // 切换会话
  Future<void> deleteSession(String id);      // 删除会话
  void likeMessage(String messageId);         // 点赞反馈
  void dislikeMessage(String id, String reason); // 点踩反馈
}
```

---

## 最佳实践

### 避免过度通知

- 只在数据真正变化时调用`notifyListeners()`
- 批量操作完成后统一通知

### 异步操作

- 使用`async/await`处理异步操作
- 捕获并处理异常

### 内存管理

- 及时dispose资源
- 避免内存泄漏

---

## 相关文档

- [技术栈](tech-stack.md)
- [服务层](services.md)