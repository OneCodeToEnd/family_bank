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
