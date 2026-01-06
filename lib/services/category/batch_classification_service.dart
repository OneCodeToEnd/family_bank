import 'package:sqflite/sqflite.dart';
import '../../models/transaction.dart' as models;
import '../../models/category.dart';
import '../../models/category_match_result.dart';
import '../database/database_service.dart';
import '../ai/ai_config_service.dart';
import '../ai/ai_classifier_factory.dart';
import '../ai/ai_classifier_service.dart';
import 'category_match_service.dart';
import '../../utils/app_logger.dart';
/// 批量分类处理进度回调
typedef BatchProgressCallback = void Function(int current, int total, String status);

/// 批量分类处理结果
class BatchClassificationResult {
  final int totalCount;
  final int successCount;
  final int failedCount;
  final List<String> errors;
  final Duration duration;
  final List<CategoryMatchResult?> results; // 添加结果列表

  BatchClassificationResult({
    required this.totalCount,
    required this.successCount,
    required this.failedCount,
    required this.errors,
    required this.duration,
    required this.results,
  });

  double get successRate => totalCount > 0 ? successCount / totalCount : 0;
}

/// 批量分类处理服务
/// 优化批量处理性能，包括预加载、批处理、错误处理
class BatchClassificationService {
  final DatabaseService _dbService = DatabaseService();
  Database? _db;
  CategoryMatchService? _matchService;
  final AIConfigService _aiConfigService = AIConfigService();

  // 缓存的数据（仅在批量处理期间）
  List<Category>? _cachedCategories;
  AIClassifierService? _aiService;

  Future<void> _init() async {
    if (_db != null) return; // 已经初始化

    _db = await _dbService.database;
    _matchService = CategoryMatchService();
  }

  /// 批量分类交易
  /// 优化性能：预加载数据、批处理、进度回调
  Future<BatchClassificationResult> classifyBatch(
    List<models.Transaction> transactions, {
    BatchProgressCallback? onProgress,
    bool useAI = true,
    int batchSize = 50,
  }) async {
    final startTime = DateTime.now();
    final errors = <String>[];
    final allResults = <CategoryMatchResult?>[];
    int successCount = 0;
    int failedCount = 0;

    try {
      await _init();

      // 预加载所有需要的数据
      onProgress?.call(0, transactions.length, '预加载数据...');
      await _preloadData(useAI: useAI);

      // 按批次处理
      for (var i = 0; i < transactions.length; i += batchSize) {
        final batch = transactions.skip(i).take(batchSize).toList();
        final batchNumber = (i ~/ batchSize) + 1;
        final totalBatches = (transactions.length / batchSize).ceil();

        onProgress?.call(
          i,
          transactions.length,
          '处理批次 $batchNumber/$totalBatches...',
        );

        try {
          // 处理当前批次
          final results = await _processBatch(
            batch,
            useAI: useAI,
          );

          // 添加到总结果
          allResults.addAll(results);

          // 统计结果
          for (var j = 0; j < results.length; j++) {
            if (results[j] != null && results[j]!.categoryId != null) {
              successCount++;
            } else {
              failedCount++;
            }

            // 更新单个进度
            final currentIndex = i + j + 1;
            onProgress?.call(
              currentIndex,
              transactions.length,
              '已处理 $currentIndex/${transactions.length}',
            );
          }
        } catch (e) {
          errors.add('批次 $batchNumber 处理失败: $e');
          // 为失败的批次添加null结果
          allResults.addAll(List<CategoryMatchResult?>.filled(batch.length, null));
          failedCount += batch.length;
        }

        // 批次间短暂延迟，避免资源耗尽
        if (i + batchSize < transactions.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      errors.add('批量处理初始化失败: $e');
      failedCount = transactions.length;
      // 填充null结果
      allResults.addAll(List<CategoryMatchResult?>.filled(
        transactions.length - allResults.length,
        null,
      ));
    } finally {
      // 清理缓存
      _clearCache();
    }

    final duration = DateTime.now().difference(startTime);

    return BatchClassificationResult(
      totalCount: transactions.length,
      successCount: successCount,
      failedCount: failedCount,
      errors: errors,
      duration: duration,
      results: allResults,
    );
  }

  /// 预加载所有需要的数据
  Future<void> _preloadData({required bool useAI}) async {
    // 预加载分类
    _cachedCategories = await _loadAllCategories();

    // 如果启用AI，预加载AI配置
    if (useAI) {
      final aiConfig = await _aiConfigService.loadConfig();
      if (aiConfig.enabled && aiConfig.apiKey.isNotEmpty && aiConfig.modelId.isNotEmpty) {
        try {
          _aiService = AIClassifierFactory.create(
            aiConfig.provider,
            aiConfig.apiKey,
            aiConfig.modelId,
            aiConfig,
          );
        } catch (e) {
          AppLogger.e('Failed to initialize AI service: $e');
        }
      }
    }
  }

  /// 处理单个批次
  Future<List<CategoryMatchResult?>> _processBatch(
    List<models.Transaction> batch, {
    required bool useAI,
  }) async {
    final results = <CategoryMatchResult?>[];

    // 使用规则匹配批次
    for (final transaction in batch) {
      try {
        var result = await _matchService!.matchCategory(transaction);

        // 如果规则匹配失败且启用AI，尝试AI分类
        if (useAI &&
            _aiService != null &&
            _cachedCategories != null &&
            (result.categoryId == null || result.confidence < 0.7)) {
          try {
            final aiResult = await _aiService!.classify(
              transaction,
              _cachedCategories!,
            );

            if (aiResult != null && aiResult.confidence > result.confidence) {
              result = aiResult;
            }
          } catch (e) {
            AppLogger.w('AI classification failed for transaction ${transaction.id}', error: e);
            // 继续使用规则匹配的结果
          }
        }

        results.add(result);
      } catch (e) {
        AppLogger.e('Failed to classify transaction ${transaction.id}: $e');
        results.add(null);
      }
    }

    return results;
  }

  /// 加载所有分类
  Future<List<Category>> _loadAllCategories() async {
    final result = await _db!.query(
      'categories',
      where: 'is_hidden = 0',
      orderBy: 'sort_order ASC, name ASC',
    );

    return result.map((map) => Category.fromMap(map)).toList();
  }

  /// 清理缓存
  void _clearCache() {
    _cachedCategories = null;
    _aiService = null;
  }

  /// 批量应用分类结果到交易
  Future<int> applyClassificationResults(
    List<models.Transaction> transactions,
    List<CategoryMatchResult?> results, {
    bool onlyHighConfidence = false,
    double minConfidence = 0.8,
  }) async {
    if (transactions.length != results.length) {
      throw ArgumentError('Transactions and results must have the same length');
    }

    await _init();
    int appliedCount = 0;

    final batch = _db!.batch();

    for (var i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final result = results[i];

      if (result == null || result.categoryId == null) continue;

      // 如果只应用高置信度结果，检查置信度
      if (onlyHighConfidence && result.confidence < minConfidence) {
        continue;
      }

      // 批量更新
      batch.update(
        'transactions',
        {
          'category_id': result.categoryId,
          'is_confirmed': result.confidence >= minConfidence ? 1 : 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      appliedCount++;
    }

    await batch.commit(noResult: true);

    return appliedCount;
  }
}
