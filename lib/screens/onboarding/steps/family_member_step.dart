import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/family_provider.dart';
import '../../../models/family_member.dart';

/// 家庭成员添加步骤
class FamilyMemberStep extends StatefulWidget {
  final int? familyGroupId;
  final Function(int memberId) onNext;
  final VoidCallback onBack;

  const FamilyMemberStep({
    super.key,
    required this.familyGroupId,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<FamilyMemberStep> createState() => _FamilyMemberStepState();
}

class _FamilyMemberStepState extends State<FamilyMemberStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  String? _selectedAvatar;
  bool _isCreating = false;
  bool _isLoading = true;
  bool _showCreateForm = false;
  List<FamilyMember> _existingMembers = [];
  int? _selectedMemberId;

  // 头像选项
  final List<String> _avatarOptions = [
    '👨', '👩', '👦', '👧', '👴', '👵',
    '👶', '🧒', '🧑', '👨‍💼', '👩‍💼', '🎓',
  ];

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 避免在 build 期间调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingMembers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingMembers() async {
    if (widget.familyGroupId == null) {
      setState(() {
        _showCreateForm = true;
        _isLoading = false;
      });
      return;
    }

    try {
      final familyProvider = context.read<FamilyProvider>();

      // 先加载家庭组列表
      await familyProvider.loadFamilyGroups();

      // 设置当前家庭组
      final group = familyProvider.familyGroups
          .firstWhere((g) => g.id == widget.familyGroupId);
      familyProvider.setCurrentFamilyGroup(group);

      // 加载该家庭组的成员
      await familyProvider.loadMembersByGroupId(widget.familyGroupId!);

      setState(() {
        _existingMembers = familyProvider.currentGroupMembers;
        _showCreateForm = _existingMembers.isEmpty;
        if (_existingMembers.isNotEmpty) {
          _selectedMemberId = _existingMembers.first.id;
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

  Future<void> _selectExistingMember() async {
    if (_selectedMemberId == null) return;
    widget.onNext(_selectedMemberId!);
  }

  Future<void> _skipStep() async {
    // 如果有成员，使用第一个成员的ID
    if (_existingMembers.isNotEmpty) {
      widget.onNext(_existingMembers.first.id!);
    }
  }

  Future<void> _createMember() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.familyGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('家庭组ID不存在，请返回重新创建'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final familyProvider = context.read<FamilyProvider>();
      final success = await familyProvider.createFamilyMember(
        familyGroupId: widget.familyGroupId!,
        name: _nameController.text.trim(),
        role: _roleController.text.trim().isEmpty
            ? null
            : _roleController.text.trim(),
        avatar: _selectedAvatar,
      );

      if (!mounted) return;

      if (success) {
        // 获取刚创建的成员ID
        await familyProvider.loadFamilyMembers();
        final members = familyProvider.currentGroupMembers;
        if (members.isNotEmpty) {
          widget.onNext(members.last.id!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('创建成员失败，请重试'),
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
            '第 2 步',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            _showCreateForm ? '添加家庭成员' : '选择家庭成员',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            _showCreateForm
                ? '添加第一个家庭成员，通常是你自己'
                : '选择一个已有的家庭成员，或添加新成员',
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
        // 已有家庭成员列表
        Expanded(
          child: ListView.builder(
            itemCount: _existingMembers.length,
            itemBuilder: (context, index) {
              final member = _existingMembers[index];
              final isSelected = _selectedMemberId == member.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMemberId = member.id;
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
                        // 头像
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              member.avatar ?? '👤',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                              if (member.role != null && member.role!.isNotEmpty)
                                Text(
                                  member.role!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
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

        // 添加新成员按钮
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _showCreateForm = true;
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('添加新家庭成员'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // 头像选择
          Text(
            '选择头像',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatarOptions.map((avatar) {
              final isSelected = _selectedAvatar == avatar;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                  });
                },
                child: Container(
                  width: 56,
                  height: 56,
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
                  child: Center(
                    child: Text(
                      avatar,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 姓名输入
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '姓名 *',
              hintText: '例如：张三、小明',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入姓名';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // 角色输入（可选）
          TextFormField(
            controller: _roleController,
            decoration: const InputDecoration(
              labelText: '角色（可选）',
              hintText: '例如：爸爸、妈妈、儿子',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _createMember(),
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
                    '后续可以在设置中添加更多家庭成员',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 如果有已有成员，显示返回选择按钮
          if (_existingMembers.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isCreating
                  ? null
                  : () {
                      setState(() {
                        _showCreateForm = false;
                      });
                    },
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回选择已有成员'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
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

        // 如果有已有成员且在选择界面，显示跳过按钮
        if (!_showCreateForm && _existingMembers.isNotEmpty) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _skipStep,
              child: const Text('跳过'),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // 下一步按钮
        Expanded(
          child: ElevatedButton(
            onPressed: _isCreating
                ? null
                : (_showCreateForm ? _createMember : _selectExistingMember),
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
