import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../models/family_member.dart';
import 'member_form_screen.dart';

/// 家庭成员列表页面
class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 避免在 build 期间调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMembers();
    });
  }

  Future<void> _loadMembers() async {
    final familyProvider = context.read<FamilyProvider>();
    await familyProvider.loadFamilyMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭成员管理'),
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, familyProvider, child) {
          if (familyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (familyProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(familyProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMembers,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final members = familyProvider.currentGroupMembers;

          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('还没有添加家庭成员'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddMember(),
                    icon: const Icon(Icons.add),
                    label: const Text('添加第一个成员'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 统计信息卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.groups, size: 32, color: Colors.blue),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            familyProvider.currentFamilyGroup?.name ?? '我的家庭',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '共 ${members.length} 位成员',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 成员列表
              ...members.map((member) => _buildMemberCard(member)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddMember(),
        icon: const Icon(Icons.person_add),
        label: const Text('添加成员'),
      ),
    );
  }

  Widget _buildMemberCard(FamilyMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: member.avatar != null && member.avatar!.isNotEmpty
              ? Text(member.avatar!)
              : Text(
                  member.name.isNotEmpty ? member.name[0] : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: member.role != null && member.role!.isNotEmpty
            ? Text(member.role!)
            : null,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToEditMember(member);
            } else if (value == 'delete') {
              _confirmDeleteMember(member);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToEditMember(member),
      ),
    );
  }

  Future<void> _navigateToAddMember() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MemberFormScreen(),
      ),
    );

    if (result == true && mounted) {
      _loadMembers();
    }
  }

  Future<void> _navigateToEditMember(FamilyMember member) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberFormScreen(member: member),
      ),
    );

    if (result == true && mounted) {
      _loadMembers();
    }
  }

  void _confirmDeleteMember(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除成员'),
        content: Text(
          '确定要删除 "${member.name}" 吗？\n\n'
          '注意：删除成员将同时删除该成员的所有账户和相关账单记录，此操作不可恢复！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMember(member);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMember(FamilyMember member) async {
    final familyProvider = context.read<FamilyProvider>();

    final success = await familyProvider.deleteFamilyMember(member.id!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('成员已删除'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMembers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(familyProvider.errorMessage ?? '删除失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
