import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/family_provider.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
            '创建家庭组',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            '家庭组用于管理家庭成员和账户',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 32),

          // 表单
          Form(
            key: _formKey,
            child: Column(
              children: [
                // 家庭组名称输入
                TextFormField(
                  controller: _nameController,
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
              ],
            ),
          ),

          const Spacer(),

          // 底部按钮
          Row(
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
                  onPressed: _isCreating ? null : _createGroup,
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
          ),
        ],
      ),
    );
  }
}
