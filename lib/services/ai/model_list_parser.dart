import 'dart:convert';
import '../../models/ai_model.dart';
import '../../utils/app_logger.dart';

/// AI 模型列表解析器
///
/// 提供通用的模型列表解析逻辑，避免代码重复
class ModelListParser {
  /// 从 API 响应中安全地解析模型列表
  ///
  /// [responseBody] API 响应的字节数据
  /// [modelFilter] 可选的模型过滤函数
  /// [modelIdKey] 模型 ID 的字段名，默认为 'id'
  /// [modelNameKey] 模型名称的字段名，默认为 'id'
  /// [descriptionKey] 描述的字段名，默认为 'description'
  ///
  /// 返回解析后的模型列表，如果解析失败返回 null
  static List<AIModel>? parseModelList(
    List<int> responseBody, {
    bool Function(AIModel)? modelFilter,
    String modelIdKey = 'id',
    String modelNameKey = 'id',
    String descriptionKey = 'description',
  }) {
    try {
      final data = jsonDecode(utf8.decode(responseBody));

      // 检查 data 字段是否存在且为 List
      if (data['data'] == null) {
        AppLogger.w('API response missing data field: ${data.keys}');
        return null;
      }

      if (data['data'] is! List) {
        AppLogger.w('API response data field is not a List: ${data['data'].runtimeType}');
        return null;
      }

      final modelsList = data['data'] as List;

      // 解析每个模型，跳过解析失败的项
      final models = modelsList
          .map((m) {
            try {
              // 支持多种字段名格式
              final id = m[modelIdKey] as String? ??
                        m['model_id'] as String? ??
                        m['id'] as String;

              final name = m[modelNameKey] as String? ??
                           m['model_name'] as String? ??
                           m['id'] as String;

              return AIModel(
                id: id,
                name: name,
                description: m[descriptionKey] as String?,
              );
            } catch (e) {
              AppLogger.w('Failed to parse model item: $e');
              return null;
            }
          })
          .whereType<AIModel>()
          .toList();

      // 应用过滤器
      if (modelFilter != null) {
        return models.where(modelFilter).toList();
      }

      return models;
    } catch (e) {
      AppLogger.e('Failed to parse model list: $e');
      return null;
    }
  }

  /// 常用的模型过滤器

  /// 过滤 Qwen 系列模型
  static bool isQwenModel(AIModel model) {
    return model.id.toLowerCase().startsWith('qwen');
  }

  /// 过滤聊天模型（包含 chat 或 turbo）
  static bool isChatModel(AIModel model) {
    final id = model.id.toLowerCase();
    return id.contains('chat') || id.contains('turbo');
  }
}
