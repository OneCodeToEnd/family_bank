# BillValidationService - 账单导入验证服务

## 服务概述

**服务名称**: BillValidationService
**文件路径**: `lib/services/bill_validation_service.dart`
**功能定位**: 账单导入准确率验证服务
**依赖服务**: AIClassifierService

## 业务背景

在账单导入过程中，由于文件格式、编码问题或解析逻辑错误，可能导致导入的数据与原始文件不一致。为了提高数据质量和用户信任度，需要在导入预览阶段对导入结果进行验证。

### 核心价值

1. **数据质量保障**: 及早发现导入错误，防止错误数据进入系统
2. **用户信任**: 通过透明的验证结果增强用户信心
3. **问题诊断**: 帮助定位文件解析问题
4. **减少人工核对**: 自动化验证减少用户手动检查工作量

## 核心功能

### 1. 文件摘要提取

使用 LLM 从原始账单文件中提取汇总统计信息。

**支持的文件类型**:
- 支付宝 CSV 账单
- 微信 XLSX 账单

**提取的统计信息**:
- 交易总笔数 (total_count)
- 收入笔数 (income_count)
- 支出笔数 (expense_count)
- 收入总金额 (total_income)
- 支出总金额 (total_expense)

### 2. 计算导入数据统计

从解析后的 Transaction 对象列表中计算相同的统计信息。

### 3. 对比验证

将文件摘要与计算结果进行对比，生成验证报告。

**验证状态**:
- **Perfect**: 所有指标完全匹配
- **Warning**: 存在轻微差异（可接受范围内）
- **Error**: 存在重大差异（需要用户注意）

### 4. 生成用户建议

根据验证结果生成可操作的建议信息。

## 技术架构

### 数据模型

#### BillSummary (账单摘要)

```dart
class BillSummary {
  final int totalCount;        // 交易总笔数
  final int incomeCount;       // 收入笔数
  final int expenseCount;      // 支出笔数
  final double totalIncome;    // 收入总金额
  final double totalExpense;   // 支出总金额
  final double netAmount;      // 净额 (收入-支出)

  // JSON 序列化方法
  Map<String, dynamic> toJson();
  factory BillSummary.fromJson(Map<String, dynamic> json);
}
```

#### ValidationResult (验证结果)

```dart
enum ValidationStatus {
  perfect,   // 完美匹配
  warning,   // 轻微差异
  error,     // 重大差异
}

class ValidationResult {
  final ValidationStatus status;
  final BillSummary fileSummary;        // 文件摘要
  final BillSummary calculatedSummary;  // 计算摘要
  final List<ValidationIssue> issues;   // 问题列表
  final String? suggestion;             // 建议信息

  bool get isValid => status != ValidationStatus.error;
  bool get hasWarnings => status == ValidationStatus.warning;
}
```

#### ValidationIssue (验证问题)

```dart
class ValidationIssue {
  final String field;           // 字段名 (如 "total_count")
  final dynamic expectedValue;  // 期望值 (来自文件)
  final dynamic actualValue;    // 实际值 (来自计算)
  final double discrepancy;     // 差异值
  final String message;         // 用户友好的消息
}
```

#### BillFileType (账单文件类型)

```dart
enum BillFileType {
  alipayCSV,    // 支付宝 CSV
  wechatXLSX,   // 微信 XLSX
  unknown,      // 未知类型
}

extension BillFileTypeExtension on BillFileType {
  static BillFileType fromFileName(String fileName);
}
```

### 核心方法

#### 1. extractSummaryFromFile

从原始文件中提取摘要信息。

```dart
Future<BillSummary> extractSummaryFromFile(
  Uint8List fileBytes,
  String fileName,
  BillFileType fileType,
) async
```

**流程**:
1. 根据文件类型准备文件内容
2. 构建 LLM 提示词
3. 调用 AIClassifierService 提取摘要
4. 解析 JSON 响应
5. 返回 BillSummary 对象

**错误处理**:
- LLM 调用失败: 返回空摘要，记录日志
- JSON 解析失败: 返回空摘要，记录日志
- 文件读取失败: 抛出异常

#### 2. calculateSummaryFromTransactions

从 Transaction 列表计算摘要。

```dart
BillSummary calculateSummaryFromTransactions(
  List<Transaction> transactions,
)
```

**计算逻辑**:
```dart
int totalCount = transactions.length;
int incomeCount = transactions.where((t) => t.type == 'income').length;
int expenseCount = transactions.where((t) => t.type == 'expense').length;
double totalIncome = transactions
    .where((t) => t.type == 'income')
    .fold(0.0, (sum, t) => sum + t.amount);
double totalExpense = transactions
    .where((t) => t.type == 'expense')
    .fold(0.0, (sum, t) => sum + t.amount);
```

#### 3. validateImport

对比验证并生成结果。

```dart
ValidationResult validateImport(
  BillSummary fileSummary,
  BillSummary calculatedSummary,
)
```

**验证规则**:

| 指标 | 验证方式 | 容差 |
|------|---------|------|
| 交易笔数 | 精确匹配 | 0 |
| 收入笔数 | 精确匹配 | 0 |
| 支出笔数 | 精确匹配 | 0 |
| 收入金额 | 浮点比较 | ±0.01 元 |
| 支出金额 | 浮点比较 | ±0.01 元 |

**状态判定**:
- **Perfect**: 无任何差异
- **Warning**: 差异 ≤ 2 笔交易 或 金额差异 < 5%
- **Error**: 差异 > 2 笔交易 或 金额差异 ≥ 5%

## LLM 集成

### 提示词设计

```
You are a financial data analyst. Extract summary statistics from the following bill file.

File Type: {fileType}
File Content:
{fileContent}

Please analyze the file and extract the following information:
1. Total number of transactions
2. Number of income transactions
3. Number of expense transactions
4. Total income amount
5. Total expense amount

IMPORTANT:
- Only count valid transaction records
- Ignore header rows, footer rows, and summary rows
- For Alipay CSV: Look for transaction records with valid amounts
- For WeChat XLSX: Look for transaction records in the data section

Return ONLY a JSON object with this exact structure (use English keys):
{
  "total_count": <number>,
  "income_count": <number>,
  "expense_count": <number>,
  "total_income": <number>,
  "total_expense": <number>
}

Do not include any explanation or additional text.
```

**注意事项**:
- 使用英文键名避免编码问题 (参考: context/experience/json-file-encoding-issue.md)
- 明确要求只返回 JSON，不包含额外文本
- 提供清晰的统计规则说明

### 文件内容准备

对于大文件，需要智能采样以减少 LLM 处理时间和成本。

**采样策略**:
- 小文件 (≤50 行): 发送完整内容
- 大文件 (>50 行): 发送头部 + 采样 + 尾部

```dart
String _prepareFileContentForLLM(String content, BillFileType fileType) {
  final lines = content.split('\n');

  if (lines.length <= 50) {
    return content; // 小文件，发送全部
  }

  // 大文件采样
  final header = lines.take(5).join('\n');
  final sample = lines.skip(5).take(20).join('\n');
  final footer = lines.skip(lines.length - 5).join('\n');

  return '$header\n...\n$sample\n...\n$footer';
}
```

## 服务集成

### 与 BillImportService 集成

```dart
class BillImportService {
  final BillValidationService _validationService;

  Future<ImportResult> importBillFile(File file) async {
    // 1. 读取文件
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;
    final fileType = BillFileType.fromFileName(fileName);

    // 2. 解析交易
    final transactions = await _parseFile(file);

    // 3. 验证导入
    final fileSummary = await _validationService.extractSummaryFromFile(
      bytes, fileName, fileType
    );
    final calculatedSummary = _validationService.calculateSummaryFromTransactions(
      transactions
    );
    final validationResult = _validationService.validateImport(
      fileSummary, calculatedSummary
    );

    // 4. 返回结果
    return ImportResult(
      transactions: transactions,
      validationResult: validationResult,
    );
  }
}
```

### 与 EmailService 集成

```dart
class EmailService {
  final BillValidationService _validationService;

  Future<ImportResult> processAttachment(EmailAttachment attachment) async {
    // 1. 下载附件
    final bytes = await _downloadAttachment(attachment);
    final fileType = BillFileType.fromFileName(attachment.fileName);

    // 2. 解析交易
    final transactions = await _parseAttachment(attachment);

    // 3. 验证导入
    final fileSummary = await _validationService.extractSummaryFromFile(
      bytes, attachment.fileName, fileType
    );
    final calculatedSummary = _validationService.calculateSummaryFromTransactions(
      transactions
    );
    final validationResult = _validationService.validateImport(
      fileSummary, calculatedSummary
    );

    // 4. 返回结果
    return ImportResult(
      transactions: transactions,
      validationResult: validationResult,
      source: 'email',
    );
  }
}
```

## UI 展示

### ImportConfirmationScreen 集成

验证结果在导入确认页面展示，包含：

1. **状态指示器**: 颜色编码的状态图标
   - 绿色 ✓: Perfect
   - 黄色 !: Warning
   - 红色 ✗: Error

2. **对比表格**: 文件摘要 vs 计算摘要

| 指标 | 文件统计 | 导入统计 | 状态 |
|------|---------|---------|------|
| 交易笔数 | 150 | 150 | ✓ |
| 收入笔数 | 50 | 50 | ✓ |
| 支出笔数 | 100 | 100 | ✓ |
| 收入金额 | ¥12,500 | ¥12,500 | ✓ |
| 支出金额 | ¥8,300 | ¥8,300 | ✓ |

3. **问题列表**: 显示具体差异

```
⚠️ 支出笔数不匹配
   期望: 100 笔
   实际: 98 笔
   差异: 2 笔缺失
```

4. **建议信息**: 可操作的建议

```
💡 建议
- 检查是否有交易被过滤（如失败交易）
- 确认文件格式是否正确
- 如果差异较小，可以继续导入
```

## 错误处理

### LLM 提取失败

```dart
try {
  final summary = await _aiClassifierService.extractBillSummary(...);
  return BillSummary.fromJson(summary);
} catch (e) {
  print('Failed to extract summary: $e');
  // 返回空摘要，允许用户继续导入
  return BillSummary(
    totalCount: 0,
    incomeCount: 0,
    expenseCount: 0,
    totalIncome: 0.0,
    totalExpense: 0.0,
  );
}
```

### 验证失败处理

- 验证失败不阻止导入
- 显示警告信息
- 允许用户确认后继续
- 记录验证日志供调试

## 性能优化

### 1. 文件采样

大文件只发送采样内容给 LLM，减少处理时间。

### 2. 并行处理

文件提取和交易解析可以并行进行。

```dart
final results = await Future.wait([
  _validationService.extractSummaryFromFile(bytes, fileName, fileType),
  _parseFile(file),
]);
final fileSummary = results[0] as BillSummary;
final transactions = results[1] as List<Transaction>;
```

### 3. 缓存结果

对于相同文件的重复验证，可以缓存结果。

### 4. 超时控制

LLM 调用设置超时，避免长时间等待。

```dart
final summary = await _aiClassifierService
    .extractBillSummary(content, fileType)
    .timeout(Duration(seconds: 30));
```

## 测试策略

### 单元测试

1. **BillSummary 模型测试**
   - JSON 序列化/反序列化
   - 净额计算

2. **calculateSummaryFromTransactions 测试**
   - 空列表
   - 只有收入
   - 只有支出
   - 混合交易

3. **validateImport 测试**
   - 完全匹配
   - 轻微差异
   - 重大差异
   - 边界情况

### 集成测试

1. **LLM 提取测试**
   - 真实支付宝 CSV 文件
   - 真实微信 XLSX 文件
   - 格式错误文件
   - 超大文件

2. **端到端测试**
   - 完整导入流程
   - 验证结果展示
   - 用户交互流程

## 监控指标

### 功能指标

- **提取成功率**: LLM 成功提取摘要的比例
- **验证准确率**: 验证结果与人工核对的一致性
- **误报率**: 错误警告的比例

### 性能指标

- **提取耗时**: LLM 提取摘要的平均时间
- **验证耗时**: 完整验证流程的平均时间
- **文件大小影响**: 不同文件大小的性能表现

### 用户体验指标

- **用户理解度**: 用户是否理解验证结果
- **操作完成率**: 用户是否完成导入流程
- **错误发现率**: 验证功能发现的实际错误数

## 已知限制

### 1. LLM 准确性

LLM 提取的准确性依赖于：
- 文件格式的规范性
- 提示词的质量
- 模型的能力

**缓解措施**: 提供清晰的提示词，测试多种文件格式

### 2. 浮点精度

金额计算可能存在浮点精度问题。

**缓解措施**: 使用 0.01 元的容差

### 3. 文件格式变化

支付宝/微信可能更新文件格式。

**缓解措施**:
- 记录提取失败日志
- 定期更新提示词
- 提供手动跳过选项

### 4. 大文件性能

超大文件（>10000 笔交易）可能影响性能。

**缓解措施**:
- 文件采样
- 异步处理
- 进度提示

## 未来增强

### Phase 2 功能

1. **智能建议**: 使用 LLM 分析差异原因并提供修复建议
2. **自动修正**: 对于常见问题自动修正
3. **历史对比**: 与历史导入记录对比
4. **批量验证**: 一次验证多个文件
5. **详细钻取**: 显示具体哪些交易缺失或不匹配

### 技术改进

1. **本地模型**: 使用本地小模型提高速度和隐私
2. **规则引擎**: 结合规则和 LLM 提高准确性
3. **增量验证**: 只验证新增交易
4. **离线支持**: 缓存验证结果支持离线查看

## 相关文档

- [账单导入字段映射](../../business/bill_import_mapping.md)
- [JSON 编码问题经验](../../experience/json-file-encoding-issue.md)
- [AI 分类服务](./ai-classifier-service.md)
- [REQ-001 设计文档](../../../.claude/state/requirements/REQ-001-design.md)

## 维护信息

| 属性 | 值 |
|------|-----|
| 创建日期 | 2026-01-24 |
| 最后更新 | 2026-01-24 |
| 维护者 | Claude |
| 需求编号 | REQ-001 |
| 实现状态 | 设计完成，待实现 |
