import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/category_match_result.dart';
import '../../services/category/batch_classification_service.dart';
import '../../services/category/category_learning_service.dart';
import '../../services/database/transaction_db_service.dart';
import '../../services/database/database_service.dart';

/// 导入确认界面
/// 显示导入的交易和自动匹配的分类结果
class ImportConfirmationScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const ImportConfirmationScreen({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  State<ImportConfirmationScreen> createState() => _ImportConfirmationScreenState();
}

class _ImportConfirmationScreenState extends State<ImportConfirmationScreen> {
  final BatchClassificationService _classificationService = BatchClassificationService();
  final CategoryLearningService _learningService = CategoryLearningService();
  final TransactionDbService _transactionDbService = TransactionDbService();

  List<CategoryMatchResult?>? _matchResults;
  Map<int, Category> _categoryMap = {};
  bool _processing = false;
  bool _saving = false;
  int _currentProgress = 0;
  int _totalProgress = 0;
  String _progressStatus = '';

  @override
  void initState() {
    super.initState();
    _startClassification();
  }

  Future<void> _startClassification() async {
    setState(() {
      _processing = true;
    });

    try {
      // 加载分类数据
      await _loadCategories();

      // 批量分类
      final result = await _classificationService.classifyBatch(
        widget.transactions,
        onProgress: (current, total, status) {
          if (mounted) {
            setState(() {
              _currentProgress = current;
              _totalProgress = total;
              _progressStatus = status;
            });
          }
        },
        useAI: true,
        batchSize: 20,
      );

      if (mounted) {
        setState(() {
          _matchResults = result.results;
          _processing = false;
        });

        // 显示统计信息
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
        });
        _showError('自动分类失败: $e');
      }
    }
  }

  Future<void> _loadCategories() async {
    final db = await DatabaseService().database;
    final results = await db.query('categories', where: 'is_hidden = 0');
    _categoryMap = {
      for (final map in results)
        map['id'] as int: Category.fromMap(map)
    };
  }

  void _showResultDialog(BatchClassificationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分类结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('总计: ${result.totalCount} 条'),
            Text('成功: ${result.successCount} 条', style: const TextStyle(color: Colors.green)),
            Text('失败: ${result.failedCount} 条', style: const TextStyle(color: Colors.red)),
            Text('耗时: ${result.duration.inSeconds} 秒'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('错误信息:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.take(3).map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('确认导入'),
        actions: [
          if (!_processing && _matchResults != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: _saving ? null : _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '全部确认',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_processing) {
      return _buildProcessingView();
    }

    if (_matchResults == null) {
      return const Center(child: Text('加载失败'));
    }

    return _buildTransactionList();
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_progressStatus),
          if (_totalProgress > 0)
            Text('${_currentProgress}/${_totalProgress}'),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      itemCount: widget.transactions.length,
      itemBuilder: (context, index) {
        final transaction = widget.transactions[index];
        final matchResult = _matchResults![index];

        return _TransactionMatchCard(
          transaction: transaction,
          matchResult: matchResult,
          category: matchResult?.categoryId != null
              ? _categoryMap[matchResult!.categoryId]
              : null,
          onCategorySelected: (categoryId) {
            _onCategoryConfirmed(index, transaction, categoryId);
          },
          allCategories: _categoryMap.values.toList(),
        );
      },
    );
  }

  void _onCategoryConfirmed(int index, Transaction transaction, int categoryId) {
    setState(() {
      // 更新匹配结果
      _matchResults![index] = CategoryMatchResult(
        categoryId: categoryId,
        confidence: 1.0,
        matchType: 'manual',
        matchedRule: '用户确认',
      );
    });

    // 异步学习规则
    _learningService.learnFromConfirmation(transaction, categoryId);
  }

  Future<void> _saveAll() async {
    setState(() {
      _saving = true;
    });

    try {
      int savedCount = 0;
      int learnedCount = 0;

      // 准备要保存的交易列表
      List<Transaction> transactionsToSave = [];

      // 批量处理交易和分类
      for (var i = 0; i < widget.transactions.length; i++) {
        final transaction = widget.transactions[i];
        final matchResult = _matchResults![i];

        if (matchResult?.categoryId != null) {
          // 更新交易分类
          final updated = transaction.copyWith(
            categoryId: matchResult!.categoryId,
            isConfirmed: matchResult.confidence >= 0.8,
            updatedAt: DateTime.now(),
          );

          transactionsToSave.add(updated);

          // 如果是用户手动确认的，学习规则
          if (matchResult.matchType == 'manual' || matchResult.confidence >= 0.8) {
            await _learningService.learnFromConfirmation(
              transaction,
              matchResult.categoryId!,
            );
            learnedCount++;
          }
        } else {
          // 没有分类的也保存，保持未分类状态
          transactionsToSave.add(transaction);
        }
      }

      // 批量保存到数据库
      if (transactionsToSave.isNotEmpty) {
        final result = await _transactionDbService.createTransactionsBatch(transactionsToSave);
        savedCount = result['successCount'] ?? 0;
        final duplicateCount = result['duplicateCount'] ?? 0;

        if (mounted) {
          // 显示成功消息
          String message = '已保存 $savedCount 条交易';
          if (duplicateCount > 0) {
            message += '，跳过 $duplicateCount 条重复记录';
          }
          if (learnedCount > 0) {
            message += '，学习了 $learnedCount 条规则';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );

          // 返回上一页
          Navigator.pop(context, savedCount);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

/// 交易匹配卡片
class _TransactionMatchCard extends StatelessWidget {
  final Transaction transaction;
  final CategoryMatchResult? matchResult;
  final Category? category;
  final Function(int) onCategorySelected;
  final List<Category> allCategories;

  const _TransactionMatchCard({
    required this.transaction,
    required this.matchResult,
    required this.category,
    required this.onCategorySelected,
    required this.allCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 交易信息
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description ?? '无描述',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (transaction.counterparty != null)
                        Text(
                          transaction.counterparty!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                Text(
                  '¥${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == 'income' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 分类信息
            Row(
              children: [
                const Text('分类：'),
                if (category != null)
                  Chip(
                    label: Text(category!.name),
                    avatar: _buildConfidenceBadge(),
                  )
                else
                  const Chip(
                    label: Text('未分类'),
                    backgroundColor: Colors.grey,
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showCategoryPicker(context),
                  child: const Text('修改'),
                ),
              ],
            ),

            // 匹配信息
            if (matchResult != null && matchResult!.matchedRule != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  matchResult!.matchedRule!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    if (matchResult == null) return const SizedBox.shrink();

    Color color;
    if (matchResult!.confidence >= 0.9) {
      color = Colors.green;
    } else if (matchResult!.confidence >= 0.7) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Icon(Icons.check_circle, size: 16, color: color);
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    final selected = await showDialog<Category>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择分类'),
        children: allCategories
            .where((c) => c.type == transaction.type)
            .map((category) {
          return SimpleDialogOption(
            child: Text(category.name),
            onPressed: () => Navigator.pop(context, category),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      onCategorySelected(selected.id!);
    }
  }
}
