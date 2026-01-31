import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../models/category_match_result.dart';
import '../../models/import_result.dart';
import '../../services/category/batch_classification_service.dart';
import '../../services/category/category_learning_service.dart';
import '../../services/database/transaction_db_service.dart';
import '../../services/database/database_service.dart';
import '../../services/account_match_service.dart';
import '../../widgets/validation/validation_summary_card.dart';
import '../../widgets/transaction_detail_sheet.dart';
import '../account/account_form_screen.dart';

/// 导入确认界面
/// 显示导入的交易和自动匹配的分类结果
class ImportConfirmationScreen extends StatefulWidget {
  final List<Transaction>? transactions;
  final ImportResult? importResult;

  const ImportConfirmationScreen({
    super.key,
    this.transactions,
    this.importResult,
  });

  @override
  State<ImportConfirmationScreen> createState() => _ImportConfirmationScreenState();
}

class _ImportConfirmationScreenState extends State<ImportConfirmationScreen> {
  final BatchClassificationService _classificationService = BatchClassificationService();
  final CategoryLearningService _learningService = CategoryLearningService();
  final TransactionDbService _transactionDbService = TransactionDbService();
  final AccountMatchService _accountMatchService = AccountMatchService();

  List<CategoryMatchResult?>? _matchResults;
  Map<int, Category> _categoryMap = {};
  List<Account> _availableAccounts = [];
  int? _selectedAccountId;
  bool _processing = false;
  bool _saving = false;
  int _currentProgress = 0;
  int _totalProgress = 0;
  String _progressStatus = '';

  // 获取交易列表
  List<Transaction> get _transactions {
    if (widget.importResult != null) {
      return widget.importResult!.transactions;
    }
    return widget.transactions ?? [];
  }

  // 获取验证结果
  ImportResult? get _importResult => widget.importResult;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // 加载账户列表
    await _loadAccounts();
    // 开始分类
    await _startClassification();
  }

  /// 加载账户列表
  Future<void> _loadAccounts() async {
    try {
      final platform = _importResult?.platform;
      _availableAccounts = await _accountMatchService.matchAccounts(platform);

      // 设置默认选中的账户
      if (_importResult?.suggestedAccountId != null) {
        _selectedAccountId = _importResult!.suggestedAccountId;
      } else if (_availableAccounts.isNotEmpty) {
        _selectedAccountId = _availableAccounts.first.id;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // 加载失败，使用默认值
      _selectedAccountId = _transactions.isNotEmpty ? _transactions.first.accountId : null;
    }
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
        _transactions,
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

    // 创建索引列表并排序：失败的分类排在前面
    final sortedIndices = List.generate(_transactions.length, (i) => i);
    sortedIndices.sort((indexA, indexB) {
      final matchResultA = _matchResults![indexA];
      final matchResultB = _matchResults![indexB];

      // 判断是否为失败的分类（没有匹配结果或没有分类ID）
      final isClassificationFailedA = matchResultA == null || matchResultA.categoryId == null;
      final isClassificationFailedB = matchResultB == null || matchResultB.categoryId == null;

      // 失败的排在前面
      if (isClassificationFailedA && !isClassificationFailedB) return -1;
      if (!isClassificationFailedA && isClassificationFailedB) return 1;

      // 如果都失败或都成功，保持原始顺序
      return 0;
    });

    return CustomScrollView(
      slivers: [
        // 账户选择卡片
        SliverToBoxAdapter(
          child: _buildAccountSelector(),
        ),
        // 显示验证结果（如果有）
        if (_importResult?.validationResult != null)
          SliverToBoxAdapter(
            child: ValidationSummaryCard(
              validationResult: _importResult!.validationResult!,
            ),
          ),
        // 交易列表
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final originalIndex = sortedIndices[index];
              final transaction = _transactions[originalIndex];
              final matchResult = _matchResults![originalIndex];

              return _TransactionMatchCard(
                transaction: transaction,
                matchResult: matchResult,
                category: matchResult?.categoryId != null
                    ? _categoryMap[matchResult!.categoryId]
                    : null,
                onCategorySelected: (categoryId) {
                  _onCategoryConfirmed(originalIndex, transaction, categoryId);
                },
                allCategories: _categoryMap.values.toList(),
              );
            },
            childCount: _transactions.length,
          ),
        ),
      ],
    );
  }

  /// 构建账户选择器
  Widget _buildAccountSelector() {
    final platform = _importResult?.platform;
    final hasSuggestion = _importResult?.hasSuggestedAccount ?? false;

    // 如果没有可用账户，显示提示卡片
    if (_availableAccounts.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '没有可用的账户',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '导入账单前需要先创建一个账户。建议创建与账单平台对应的账户类型。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 跳转到账户创建页面
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountFormScreen(),
                      ),
                    );
                    // 如果创建成功，重新加载账户列表
                    if (result == true && mounted) {
                      await _loadAccounts();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('创建账户'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '选择账户',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasSuggestion) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      '智能推荐',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedAccountId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _availableAccounts.map((account) {
                final isRecommended = _accountMatchService.isRecommendedAccount(account, platform);
                return DropdownMenuItem<int>(
                  value: account.id,
                  child: Row(
                    children: [
                      if (isRecommended)
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                      if (isRecommended) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _accountMatchService.getAccountDisplayName(account),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccountId = value;
                });
              },
            ),
            if (hasSuggestion)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '已根据账单平台智能推荐账户',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
            Text('$_currentProgress/$_totalProgress'),
        ],
      ),
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
    // 检查是否选择了账户
    if (_selectedAccountId == null) {
      _showError('请选择一个账户');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      int savedCount = 0;
      int learnedCount = 0;

      // 准备要保存的交易列表
      List<Transaction> transactionsToSave = [];

      // 批量处理交易和分类
      for (var i = 0; i < _transactions.length; i++) {
        final transaction = _transactions[i];
        final matchResult = _matchResults![i];

        if (matchResult?.categoryId != null) {
          // 更新交易分类和账户
          final updated = transaction.copyWith(
            accountId: _selectedAccountId!,
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
          // 没有分类的也保存，但更新账户ID
          final updated = transaction.copyWith(
            accountId: _selectedAccountId!,
            updatedAt: DateTime.now(),
          );
          transactionsToSave.add(updated);
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
    return InkWell(
      onTap: () => _showTransactionDetail(context),
      child: Card(
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

  void _showTransactionDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailSheet(transaction: transaction),
    );
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
