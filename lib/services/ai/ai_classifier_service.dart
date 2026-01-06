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

  /// 获取提供商信息
  AIProvider get provider;

  /// 当前使用的模型
  String get currentModel;
}
