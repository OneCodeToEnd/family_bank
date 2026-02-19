# 服务层

账清采用分层架构，服务层负责业务逻辑和数据访问。

## 服务层架构

### 分层设计

```
UI Layer (Screens/Widgets)
    ↓
Provider Layer (State Management)
    ↓
Service Layer (Business Logic)
    ↓
Database Layer (Data Access)
```

---

## 数据库服务

### DatabaseService

核心数据库服务（单例）：

```dart
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  Future<Database> get database async {
    // 返回数据库实例
  }
}
```

### 实体DB服务

每个实体有专门的DB服务：

- `FamilyDbService` - 家庭组数据访问
- `AccountDbService` - 账户数据访问
- `CategoryDbService` - 分类数据访问
- `TransactionDbService` - 交易数据访问
- `AgentMemoryDbService` - Agent记忆数据访问
- `ChatSessionDbService` - 对话会话数据访问

---

## AI服务

### AiClassifierFactory

创建AI分类器：

```dart
class AiClassifierFactory {
  static AiClassifierService create(String provider) {
    switch (provider) {
      case 'qwen':
        return QwenClassifierService();
      case 'deepseek':
        return DeepseekClassifierService();
      default:
        throw Exception('Unknown provider');
    }
  }
}
```

### AI分类服务

- `QwenClassifierService` - 通义千问集成
- `DeepseekClassifierService` - DeepSeek集成
- `AiConfigService` - AI配置管理

### AI Agent服务

基于ReAct模式的智能问答Agent：

```dart
abstract class AIAgentService {
  Future<String> chat(
    List<ChatMessage> history,
    String userMessage,
    OnMessageCallback onMessage,
  );
  Future<String> summarizeFeedback(String context, String type);
  Future<String> generateTitle(String userMessage, String assistantMessage);
}
```

- `AIAgentFactory` - Agent工厂，创建并初始化Agent实例
- `OpenAIAgentService` - 基于OpenAI兼容API的Agent实现
- `DatabaseTools` - Agent可调用的数据库工具集（获取表列表、查看表结构、执行SQL、保存记忆）
- `QuickQuestionService` - 快捷提问管理，存储在app_settings表中

**安全机制**：
- SQL白名单校验，仅允许SELECT查询
- 敏感表（ai_models、email_configs等）不可访问
- 结果限制50行/4000字符

---

## 分类服务

### CategoryMatchService

分类匹配服务：

```dart
class CategoryMatchService {
  Future<CategoryMatch?> matchCategory(
    String description,
    String? counterparty,
  ) async {
    // 1. 精确关键词匹配
    // 2. 模糊匹配
    // 3. 返回最佳匹配
  }
}
```

### CategoryLearningService

自动学习服务：

```dart
class CategoryLearningService {
  Future<void> learnFromCorrection(
    Transaction transaction,
    int oldCategoryId,
    int newCategoryId,
  ) async {
    // 分析修正模式
    // 生成新规则
    // 优化匹配准确度
  }
}
```

---

## 导入服务

### BillImportService

账单导入服务：

```dart
class BillImportService {
  Future<ImportResult> importFromCsv(
    String filePath,
    Map<String, String> fieldMapping,
  ) async {
    // 1. 读取文件
    // 2. 解析数据
    // 3. 验证数据
    // 4. 去重检查
    // 5. 插入数据库
  }
}
```

### EmailService

邮箱服务：

```dart
class EmailService {
  Future<List<Email>> fetchBills(
    EmailConfig config,
    DateTime startDate,
  ) async {
    // 1. 连接IMAP服务器
    // 2. 搜索账单邮件
    // 3. 下载附件
    // 4. 解析账单
  }
}
```

---

## 其他服务

### EncryptionService

加密服务：

```dart
class EncryptionService {
  String encrypt(String plainText, String key) {
    // AES-256加密
  }

  String decrypt(String cipherText, String key) {
    // AES-256解密
  }
}
```

### LoggingHttpClient

HTTP日志客户端：

```dart
class LoggingHttpClient extends BaseClient {
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // 记录请求
    final response = await _inner.send(request);
    // 记录响应
    return response;
  }
}
```

### LoggingDatabase

数据库SQL日志包装器（仅debug模式启用）：

```dart
class LoggingDatabase implements Database {
  final Database _delegate;
  // 代理所有数据库操作，打印SQL语句、参数、耗时和结果行数
  // 日志格式: [SQL] QUERY transactions WHERE id = ? args=[1] -> 3 rows [2ms]
}
```

配套 `LoggingBatch` 包装批量操作，在 commit 时打印操作数和耗时。

---

## 服务调用

### 在Provider中使用

```dart
class TransactionProvider extends ChangeNotifier {
  Future<void> importFromCsv(String filePath) async {
    final result = await BillImportService.importFromCsv(
      filePath,
      fieldMapping,
    );

    if (result.success) {
      await initialize(); // 重新加载数据
    }
  }
}
```

---

## 最佳实践

### 单一职责

每个服务专注于特定功能

### 依赖注入

通过构造函数注入依赖

### 错误处理

统一的错误处理机制

### 日志记录

记录关键操作和错误

---

## 相关文档

- [技术栈](tech-stack.md)
- [数据库设计](database.md)
- [状态管理](state-management.md)