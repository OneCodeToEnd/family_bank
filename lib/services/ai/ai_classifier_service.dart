import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/category_match_result.dart';
import '../../models/ai_model.dart';
import '../../models/ai_provider.dart';

/// AI 分类服务抽象接口
abstract class AIClassifierService {
  /// 使用AI对交易进行分类
  Future<CategoryMatchResult?> classify(
    Transaction transaction,
    List<Category> availableCategories,
  );

  /// 批量分类（更高效）
  Future<List<CategoryMatchResult?>> classifyBatch(
    List<Transaction> transactions,
    List<Category> availableCategories,
  );

  /// 获取可用的模型列表
  Future<List<AIModel>> getAvailableModels();

  /// 测试 API 连接
  Future<bool> testConnection();

  /// 提取账单摘要信息（用于验证导入准确性）
  ///
  /// 从文件内容中提取汇总统计信息
  /// [fileContent] 文件内容（文本格式）
  /// [fileType] 文件类型（alipay/wechat）
  /// 返回包含统计信息的 JSON 对象
  Future<Map<String, dynamic>> extractBillSummary(
    String fileContent,
    String fileType,
  );

  /// 获取提供商信息
  AIProvider get provider;

  /// 当前使用的模型
  String get currentModel;
}

/// AI 分类服务的共享功能 mixin
///
/// 提供通用的提示词构建方法，避免代码重复
mixin AIClassifierServiceMixin {
  /// 构建账单摘要提取的消息（共享方法）
  ///
  /// 子类可以直接使用此方法构建标准的摘要提取提示词
  List<Map<String, String>> buildSummaryExtractionMessages(
    String fileContent,
    String fileType,
  ) {
    final systemPrompt = '''You are a financial data analyst. Extract summary statistics from bill files.
Your task is to analyze the file header/summary section and extract key statistics.
Return ONLY a valid JSON object with the required fields. Do not include any explanation or additional text.''';

    final userPrompt = '''Extract bill summary from the following $fileType file header:

$fileContent

Please analyze the file and extract the following information:
1. Total number of transactions (income + expense only)
2. Number of income transactions
3. Number of expense transactions
4. Total income amount
5. Total expense amount

IMPORTANT:
- Only count valid transaction records that are either income or expense
- EXCLUDE the following transaction types from totalCount:
  * "不计收支" (not counted in income/expense)
  * "中性交易" (neutral transactions)
  * Any transactions that are neither income nor expense
- Ignore header rows, footer rows, and summary rows
- For Alipay CSV: Look for summary information in the header section (first 24 lines)
- For WeChat XLSX: Look for summary information in the header section (first 17 lines)
- The header often contains total statistics like "交易笔数", "收入笔数", "支出笔数", "收入金额", "支出金额"
- totalCount should equal incomeCount + expenseCount (excluding neutral/non-counted transactions)

Return ONLY a JSON object with this exact structure (use English keys):
{
  "totalCount": <number>,
  "incomeCount": <number>,
  "expenseCount": <number>,
  "totalIncome": <number>,
  "totalExpense": <number>,
  "netAmount": <number>
}

Do not include any explanation or additional text. Return only the JSON object.''';

    return [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];
  }
}
