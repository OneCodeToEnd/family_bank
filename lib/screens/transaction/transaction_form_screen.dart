import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/family_provider.dart';
import '../../models/transaction.dart' as model;
import '../../models/category.dart';

/// 添加/编辑账单页面
class TransactionFormScreen extends StatefulWidget {
  final model.Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _counterpartyController = TextEditingController();

  String _selectedType = 'expense'; // income, expense
  int? _selectedAccountId;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isSubmitting = false;
  List<Category> _suggestedCategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _notesController.text = widget.transaction!.notes ?? '';
      _counterpartyController.text = widget.transaction!.counterparty ?? '';
      _selectedType = widget.transaction!.type;
      _selectedAccountId = widget.transaction!.accountId;
      _selectedCategoryId = widget.transaction!.categoryId;
      _selectedDate = widget.transaction!.transactionTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.transaction!.transactionTime);
    }

    // 加载历史对手方
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false)
          .loadCounterparties();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _counterpartyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑账单' : '添加账单'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 类型切换
            _buildTypeSelector(),
            const SizedBox(height: 16),

            // 金额输入
            _buildAmountInput(),
            const SizedBox(height: 16),

            // 账户选择
            _buildAccountSelector(),
            const SizedBox(height: 16),

            // 分类选择
            _buildCategorySelector(),
            const SizedBox(height: 16),

            // 描述输入
            _buildDescriptionInput(),
            const SizedBox(height: 16),

            // 交易对方输入
            _buildCounterpartyInput(),
            const SizedBox(height: 16),

            // 日期时间
            _buildDateTimeSelector(),
            const SizedBox(height: 16),

            // 备注
            _buildNotesInput(),
            const SizedBox(height: 24),

            // 提交按钮
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? '保存' : '添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 类型选择器
  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('类型', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                          SizedBox(width: 4),
                          Text('收入'),
                        ],
                      ),
                    ),
                    selected: _selectedType == 'income',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = 'income';
                          _selectedCategoryId = null; // 切换类型时清除分类
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                          SizedBox(width: 4),
                          Text('支出'),
                        ],
                      ),
                    ),
                    selected: _selectedType == 'expense',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = 'expense';
                          _selectedCategoryId = null; // 切换类型时清除分类
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 金额输入
  Widget _buildAmountInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: '金额',
            prefixText: '¥ ',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.attach_money,
              color: _selectedType == 'income' ? Colors.green : Colors.red,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _selectedType == 'income' ? Colors.green : Colors.red,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入金额';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return '请输入有效的金额';
            }
            return null;
          },
        ),
      ),
    );
  }

  /// 账户选择
  Widget _buildAccountSelector() {
    return Consumer2<AccountProvider, FamilyProvider>(
      builder: (context, accountProvider, familyProvider, child) {
        final accounts = accountProvider.visibleAccounts;

        if (accounts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('还没有可用的账户'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('先去添加账户'),
                  ),
                ],
              ),
            ),
          );
        }

        // 如果没有选择账户，默认选择第一个
        if (_selectedAccountId == null && accounts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedAccountId = accounts.first.id;
            });
          });
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              value: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: '账户',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              items: accounts.map((account) {
                final member = familyProvider.getMemberById(account.familyMemberId);
                return DropdownMenuItem(
                  value: account.id,
                  child: Text('${account.name} (${member?.name ?? ''})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccountId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return '请选择账户';
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }

  /// 分类选择
  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        // 根据类型筛选分类
        final categories = categoryProvider.visibleCategories
            .where((c) => c.type == _selectedType)
            .toList();

        // 只显示叶子节点（没有子分类的分类）
        final leafCategories = categories.where((c) {
          return !categories.any((other) => other.parentId == c.id);
        }).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('分类', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_suggestedCategories.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.lightbulb_outline, size: 16),
                        label: const Text('智能推荐', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: '选择分类',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('未分类')),
                    ...leafCategories.map((category) {
                      final parentPath = _getCategoryPath(category, categoryProvider);
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(parentPath),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
                if (_suggestedCategories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('智能推荐：', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _suggestedCategories.take(3).map((category) {
                      return ActionChip(
                        label: Text(category.name),
                        onPressed: () {
                          setState(() {
                            _selectedCategoryId = category.id;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 获取分类路径
  String _getCategoryPath(Category category, CategoryProvider provider) {
    final path = <String>[];
    Category? current = category;

    while (current != null) {
      path.insert(0, current.name);
      if (current.parentId != null) {
        current = provider.getCategoryById(current.parentId!);
      } else {
        current = null;
      }
    }

    return path.join(' > ');
  }

  /// 描述输入
  Widget _buildDescriptionInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '描述',
            hintText: '例如：午餐',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入描述';
            }
            return null;
          },
          onChanged: (value) {
            // 当描述改变时，尝试智能推荐分类
            if (value.trim().isNotEmpty) {
              _suggestCategories(value);
            }
          },
        ),
      ),
    );
  }

  /// 交易对方输入（支持自动补全）
  Widget _buildCounterpartyInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  // 显示最近使用的对手方
                  return provider.counterparties.take(10);
                }
                // 搜索匹配的对手方
                return await provider.searchCounterparties(textEditingValue.text);
              },
              onSelected: (String selection) {
                _counterpartyController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // 同步控制器
                if (controller.text != _counterpartyController.text) {
                  controller.text = _counterpartyController.text;
                }
                controller.addListener(() {
                  if (_counterpartyController.text != controller.text) {
                    _counterpartyController.text = controller.text;
                  }
                });

                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: '交易对方（可选）',
                    hintText: '例如：小明、超市、房东',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: options.length,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.history, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      option,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 日期时间选择
  Widget _buildDateTimeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('日期时间', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 备注输入
  Widget _buildNotesInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: '备注（可选）',
            hintText: '添加额外说明',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  /// 选择日期
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 选择时间
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// 智能推荐分类
  Future<void> _suggestCategories(String description) async {
    final categoryProvider = context.read<CategoryProvider>();

    // 使用智能分类功能
    final suggestions = await categoryProvider.suggestCategories(description, _selectedType);

    setState(() {
      _suggestedCategories = suggestions.take(3).toList();
    });
  }

  /// 提交表单
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final transactionProvider = context.read<TransactionProvider>();
    final isEditing = widget.transaction != null;

    // 合并日期和时间
    final transactionTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    bool success;
    if (isEditing) {
      // 编辑账单
      final updatedTransaction = widget.transaction!.copyWith(
        type: _selectedType,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId,
        amount: double.parse(_amountController.text.trim()),
        description: _descriptionController.text.trim(),
        counterparty: _counterpartyController.text.trim().isNotEmpty
            ? _counterpartyController.text.trim()
            : null,
        transactionTime: transactionTime,
      );
      success = await transactionProvider.updateTransaction(updatedTransaction);
    } else {
      // 添加账单
      success = await transactionProvider.createTransaction(
        type: _selectedType,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId,
        amount: double.parse(_amountController.text.trim()),
        description: _descriptionController.text.trim(),
        counterparty: _counterpartyController.text.trim().isNotEmpty
            ? _counterpartyController.text.trim()
            : null,
        transactionTime: transactionTime,
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '账单已更新' : '账单已添加'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transactionProvider.errorMessage ?? '操作失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
