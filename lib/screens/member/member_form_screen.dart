import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../models/family_member.dart';

/// 添加/编辑家庭成员页面
class MemberFormScreen extends StatefulWidget {
  final FamilyMember? member;

  const MemberFormScreen({super.key, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();

  String? _selectedAvatar;
  bool _isSubmitting = false;

  // 头像选项
  final List<String> _avatarOptions = [
    '👨', '👩', '👦', '👧', '👴', '👵',
    '👶', '🧒', '🧑', '👨‍💼', '👩‍💼', '🎓',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _roleController.text = widget.member!.role ?? '';
      _selectedAvatar = widget.member!.avatar;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑成员' : '添加成员'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 头像选择卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择头像',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
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
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
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
                    if (_selectedAvatar != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedAvatar = null;
                            });
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('清除头像'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 成员信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '成员信息',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // 姓名
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '成员姓名',
                        hintText: '例如：爸爸、妈妈、宝宝',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入成员姓名';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 角色
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: '角色（可选）',
                        hintText: '例如：父亲、母亲、儿子、女儿',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final familyProvider = context.read<FamilyProvider>();
    final isEditing = widget.member != null;

    bool success;
    if (isEditing) {
      // 编辑成员
      final updatedMember = widget.member!.copyWith(
        name: _nameController.text.trim(),
        role: _roleController.text.trim().isEmpty
            ? null
            : _roleController.text.trim(),
        avatar: _selectedAvatar,
      );
      success = await familyProvider.updateFamilyMember(updatedMember);
    } else {
      // 添加成员
      final currentGroup = familyProvider.currentFamilyGroup;
      if (currentGroup == null) {
        setState(() {
          _isSubmitting = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先创建家庭组'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      success = await familyProvider.createFamilyMember(
        familyGroupId: currentGroup.id!,
        name: _nameController.text.trim(),
        role: _roleController.text.trim().isEmpty
            ? null
            : _roleController.text.trim(),
        avatar: _selectedAvatar,
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '成员已更新' : '成员已添加'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(familyProvider.errorMessage ?? '操作失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
