import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/family_provider.dart';
import '../../../models/family_group.dart';

/// 家庭组创建步骤
class FamilyGroupStep extends StatefulWidget {
  final Function(int groupId) onNext;
  final VoidCallback onBack;

  const FamilyGroupStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<FamilyGroupStep> createState() => _FamilyGroupStepState();
}

class _FamilyGroupStepState extends State<FamilyGroupStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: '我的家庭');
  bool _isCreating = false;
  bool _isLoading = true;
  bool _showCreateForm = false;
  List<FamilyGroup> _existingGroups = [];
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 避免在 build 期间调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingGroups();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingGroups() async {
    try {
      final familyProvider = context.read<FamilyProvider>();
      await familyProvider.loadFamilyGroups();

      setState(() {
        _existingGroups = familyProvider.familyGroups;
        _showCreateForm = _existingGroups.isEmpty;
        if (_existingGroups.isNotEmpty) {
          _selectedGroupId = _existingGroups.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _showCreateForm = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectExistingGroup() async {
    if (_selectedGroupId == null) return;
    widget.onNext(_selectedGroupId!);
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final familyProvider = context.read<FamilyProvider>();
      final success = await familyProvider.createFamilyGroup(
        _nameController.text.trim(),
      );

      if (!mounted) return;

      if (success && familyProvider.currentFamilyGroup != null) {
        widget.onNext(familyProvider.currentFamilyGroup!.id!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('创建家庭组失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isCreating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('创建失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Text(
            '第 1 步',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            _showCreateForm ? '创建家庭组' : '选择家庭组',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            _showCreateForm
                ? '家庭组用于管理家庭成员和账户'
                : '选择一个已有的家庭组，或创建新的家庭组',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 32),

          // 内容区域
          Expanded(
            child: _showCreateForm ? _buildCreateForm() : _buildSelectForm(),
          ),

          // 底部按钮
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildSelectForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已有家庭组列表
        Expanded(
          child: ListView.builder(
            itemCount: _existingGroups.length,
            itemBuilder: (context, index) {
              final group = _existingGroups[index];
              final isSelected = _selectedGroupId == group.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGroupId = group.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.home,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            group.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // 创建新家庭组按钮
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _showCreateForm = true;
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('创建新家庭组'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 家庭组名称输入
            TextFormField(
              controller: _nameController,
              enabled: !_isCreating,
              decoration: const InputDecoration(
                labelText: '家庭组名称',
                hintText: '例如：我的家庭、张家、李家',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入家庭组名称';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _createGroup(),
            ),

            const SizedBox(height: 24),

            // 提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '你可以创建多个家庭组，分别管理不同的家庭财务',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 如果有已有家庭组，显示返回选择按钮
            if (_existingGroups.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _isCreating
                    ? null
                    : () {
                        setState(() {
                          _showCreateForm = false;
                        });
                      },
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回选择已有家庭组'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        // 返回按钮
        OutlinedButton(
          onPressed: _isCreating ? null : widget.onBack,
          child: const Text('返回'),
        ),

        const SizedBox(width: 12),

        // 下一步按钮
        Expanded(
          child: ElevatedButton(
            onPressed: _isCreating
                ? null
                : (_showCreateForm ? _createGroup : _selectExistingGroup),
            child: _isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('下一步'),
          ),
        ),
      ],
    );
  }
}
