import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backup/backup_provider.dart';
import '../../../models/backup/backup_info.dart';
import '../../../models/sync/webdav_config.dart';
import '../../../services/sync/webdav_config_service.dart';
import '../sync/webdav_setup_screen.dart';
import 'cloud_backup_list_dialog.dart';

/// 备份管理页面
class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  final _configService = WebDAVConfigService();
  WebDAVConfig? _cachedConfig;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    // 初始化备份管理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupProvider>().initialize();
      _loadWebDAVConfig();
    });
  }

  /// 加载 WebDAV 配置（缓存）
  Future<void> _loadWebDAVConfig() async {
    final config = await _configService.loadConfig();
    if (mounted) {
      setState(() {
        _cachedConfig = config;
        _configLoaded = true;
      });
    }
  }

  /// 刷新 WebDAV 配置
  Future<void> _refreshWebDAVConfig() async {
    await _loadWebDAVConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份管理'),
      ),
      body: Consumer<BackupProvider>(
        builder: (context, backupProvider, child) {
          if (backupProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            children: [
              // 快速操作区
              _buildQuickActionsSection(context, backupProvider),

              const Divider(),

              // 云端同步区
              _buildCloudSyncSection(context, backupProvider),

              const Divider(),

              // 自动备份设置
              _buildAutoBackupSection(context, backupProvider),

              const Divider(),

              // 备份历史
              _buildBackupHistorySection(context, backupProvider),
            ],
          );
        },
      ),
    );
  }

  /// 快速操作区
  Widget _buildQuickActionsSection(
    BuildContext context,
    BackupProvider backupProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速操作',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleCreateBackup(context, backupProvider),
                  icon: const Icon(Icons.backup),
                  label: const Text('立即备份'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleExportBackup(context, backupProvider),
                  icon: const Icon(Icons.share),
                  label: const Text('导出备份'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleImportBackup(context, backupProvider),
              icon: const Icon(Icons.file_upload),
              label: const Text('导入备份'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (backupProvider.settings.lastBackupTime != null) ...[
            const SizedBox(height: 12),
            Text(
              '最后备份：${_formatDateTime(backupProvider.settings.lastBackupTime!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 自动备份设置区
  Widget _buildAutoBackupSection(
    BuildContext context,
    BackupProvider backupProvider,
  ) {
    final settings = backupProvider.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: const Text(
            '自动备份',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('启用自动备份'),
          subtitle: const Text('应用启动时自动检查并备份'),
          value: settings.autoBackupEnabled,
          onChanged: (value) {
            _updateAutoBackupEnabled(context, backupProvider, value);
          },
        ),
        if (settings.autoBackupEnabled) ...[
          ListTile(
            title: const Text('备份频率'),
            subtitle: Text('每 ${settings.backupIntervalDays} 天'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackupIntervalDialog(context, backupProvider),
          ),
          ListTile(
            title: const Text('保留备份数'),
            subtitle: Text('保留最近 ${settings.keepBackupCount} 个备份'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showKeepBackupCountDialog(context, backupProvider),
          ),
        ],
      ],
    );
  }

  /// 备份历史区
  Widget _buildBackupHistorySection(
    BuildContext context,
    BackupProvider backupProvider,
  ) {
    final backups = backupProvider.backups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '备份历史',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '共 ${backups.length} 个',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (backups.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.backup_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无备份',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...backups.map((backup) => _buildBackupItem(
                context,
                backupProvider,
                backup,
              )),
      ],
    );
  }

  /// 备份项
  Widget _buildBackupItem(
    BuildContext context,
    BackupProvider backupProvider,
    BackupInfo backup,
  ) {
    return ListTile(
      leading: Icon(
        _getBackupTypeIcon(backup.type),
        color: Theme.of(context).primaryColor,
      ),
      title: Text(backup.createdAtFormatted),
      subtitle: Text(backup.fileSizeFormatted),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'restore':
              _handleRestoreBackup(context, backupProvider, backup);
              break;
            case 'export':
              _handleExportExistingBackup(context, backupProvider, backup);
              break;
            case 'upload_to_cloud':
              _handleUploadBackupToCloud(context, backupProvider, backup);
              break;
            case 'delete':
              _handleDeleteBackup(context, backupProvider, backup);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'restore',
            child: Row(
              children: [
                Icon(Icons.restore),
                SizedBox(width: 8),
                Text('恢复'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                Icon(Icons.share),
                SizedBox(width: 8),
                Text('导出'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'upload_to_cloud',
            child: Row(
              children: [
                Icon(Icons.cloud_upload),
                SizedBox(width: 8),
                Text('上传到云端'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('删除', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取备份类型图标
  IconData _getBackupTypeIcon(BackupType type) {
    switch (type) {
      case BackupType.manual:
        return Icons.backup;
      case BackupType.auto:
        return Icons.backup_outlined;
      case BackupType.export:
        return Icons.share;
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 处理创建备份
  Future<void> _handleCreateBackup(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    final success = await backupProvider.createBackup();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份创建成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份创建失败：${backupProvider.errorMessage}')),
      );
    }
  }

  /// 处理导出备份
  Future<void> _handleExportBackup(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    final success = await backupProvider.exportBackup();

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：${backupProvider.errorMessage}')),
      );
    }
  }

  /// 处理导入备份
  Future<void> _handleImportBackup(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    // 显示警告对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入备份'),
        content: const Text('导入备份将替换当前所有数据，此操作不可撤销。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await backupProvider.importBackup();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份导入成功，请重启应用')),
      );
    } else if (backupProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：${backupProvider.errorMessage}')),
      );
    }
  }

  /// 处理导出现有备份
  Future<void> _handleExportExistingBackup(
    BuildContext context,
    BackupProvider backupProvider,
    BackupInfo backup,
  ) async {
    final success = await backupProvider.exportExistingBackup(backup);

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：${backupProvider.errorMessage}')),
      );
    }
  }

  /// 处理恢复备份
  Future<void> _handleRestoreBackup(
    BuildContext context,
    BackupProvider backupProvider,
    BackupInfo backup,
  ) async {
    // 显示警告对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复备份'),
        content: Text('确定要恢复到 ${backup.createdAtFormatted} 的备份吗？\n\n当前数据将被替换，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await backupProvider.restoreBackup(backup);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份恢复成功，请重启应用')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败：${backupProvider.errorMessage}')),
      );
    }
  }

  /// 处理删除备份
  Future<void> _handleDeleteBackup(
    BuildContext context,
    BackupProvider backupProvider,
    BackupInfo backup,
  ) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: Text('确定要删除 ${backup.createdAtFormatted} 的备份吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await backupProvider.deleteBackup(backup);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份已删除')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：${backupProvider.errorMessage}')),
      );
    }
  }

  /// 更新自动备份开关
  Future<void> _updateAutoBackupEnabled(
    BuildContext context,
    BackupProvider backupProvider,
    bool enabled,
  ) async {
    final newSettings = backupProvider.settings.copyWith(
      autoBackupEnabled: enabled,
    );

    await backupProvider.updateSettings(newSettings);
  }

  /// 显示备份频率对话框
  Future<void> _showBackupIntervalDialog(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    final intervals = [1, 3, 7, 14, 30];
    final currentInterval = backupProvider.settings.backupIntervalDays;

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择备份频率'),
        children: intervals.map((interval) {
          return RadioListTile<int>(
            title: Text('每 $interval 天'),
            value: interval,
            groupValue: currentInterval,
            onChanged: (value) => Navigator.pop(context, value),
          );
        }).toList(),
      ),
    );

    if (selected == null) return;

    final newSettings = backupProvider.settings.copyWith(
      backupIntervalDays: selected,
    );

    await backupProvider.updateSettings(newSettings);
  }

  /// 显示保留备份数对话框
  Future<void> _showKeepBackupCountDialog(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    final counts = [3, 5, 7, 10, 15, 30];
    final currentCount = backupProvider.settings.keepBackupCount;

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择保留备份数'),
        children: counts.map((count) {
          return RadioListTile<int>(
            title: Text('保留 $count 个'),
            value: count,
            groupValue: currentCount,
            onChanged: (value) => Navigator.pop(context, value),
          );
        }).toList(),
      ),
    );

    if (selected == null) return;

    final newSettings = backupProvider.settings.copyWith(
      keepBackupCount: selected,
    );

    await backupProvider.updateSettings(newSettings);
  }

  /// 云端同步区域
  Widget _buildCloudSyncSection(
    BuildContext context,
    BackupProvider backupProvider,
  ) {
    // 使用缓存的配置，避免每次 build 都查询数据库
    if (!_configLoaded) {
      return const SizedBox.shrink();
    }

    final hasConfig = _cachedConfig != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                '云端同步 (WebDAV)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _openWebDAVSettings(context),
                tooltip: '配置 WebDAV',
              ),
            ],
          ),
        ),
        if (!hasConfig)
          _buildNoConfigCard(context)
        else
          _buildCloudSyncCard(context, backupProvider, _cachedConfig!),
      ],
    );
  }

  /// 未配置卡片
  Widget _buildNoConfigCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('未配置 WebDAV 服务器'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _openWebDAVSettings(context),
              icon: const Icon(Icons.settings),
              label: const Text('立即配置'),
            ),
          ],
        ),
      ),
    );
  }

  /// 云端同步卡片
  Widget _buildCloudSyncCard(
    BuildContext context,
    BackupProvider backupProvider,
    WebDAVConfig config,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _extractServerName(config.serverUrl),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            if (backupProvider.lastCloudSyncTime != null) ...[
              const SizedBox(height: 4),
              Text(
                '最后同步：${_formatDateTime(backupProvider.lastCloudSyncTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            // 移动端优化：使用列布局避免按钮文字挤压
            LayoutBuilder(
              builder: (context, constraints) {
                // 小屏幕使用列布局，大屏幕使用行布局
                final isSmallScreen = constraints.maxWidth < 400;

                if (isSmallScreen) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _handleRestoreFromCloud(context, backupProvider),
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('从云端恢复'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handleUploadToCloud(context, backupProvider),
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('上传到云端'),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleRestoreFromCloud(context, backupProvider),
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('从云端恢复'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleUploadToCloud(context, backupProvider),
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('上传到云端'),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 提取服务器名称
  String _extractServerName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  /// 打开 WebDAV 设置
  Future<void> _openWebDAVSettings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebDAVSetupScreen(),
      ),
    );

    // 返回后刷新配置
    await _refreshWebDAVConfig();
  }

  /// 处理从云端恢复
  Future<void> _handleRestoreFromCloud(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    bool isLoadingDialogShown = false;

    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在获取云端备份列表...'),
                ],
              ),
            ),
          ),
        ),
      );
      isLoadingDialogShown = true;

      // 获取云端备份列表
      final cloudBackups = await backupProvider.getCloudBackups();

      if (!context.mounted) return;

      // 关闭加载对话框
      if (isLoadingDialogShown) {
        Navigator.pop(context);
        isLoadingDialogShown = false;
      }

      if (cloudBackups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('云端暂无备份')),
        );
        return;
      }

      // 显示云端备份选择对话框
      final selectedBackup = await showDialog(
        context: context,
        builder: (context) => CloudBackupListDialog(backups: cloudBackups),
      );

      if (!context.mounted) return;
      if (selectedBackup == null) return;

      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('恢复云端备份'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '确定要恢复到 ${_formatDateTime(selectedBackup.metadata.createdAt)} 的备份吗？',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('设备', selectedBackup.metadata.deviceId),
                _buildInfoRow('交易数', '${selectedBackup.metadata.transactionCount} 条'),
                const SizedBox(height: 12),
                const Text(
                  '当前数据将被替换，此操作不可撤销。',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      if (confirmed != true) return;

      // 执行恢复
      final success = await backupProvider.restoreFromCloud(selectedBackup);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('从云端恢复成功，请重启应用')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('从云端恢复失败：${backupProvider.errorMessage}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      // 只关闭加载对话框（如果还在显示）
      if (isLoadingDialogShown) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：$e')),
      );
    }
  }

  /// 处理上传到云端
  Future<void> _handleUploadToCloud(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上传到云端'),
        content: const Text('确定要将当前数据上传到云端吗？\n\n这将创建一个新的云端备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 执行上传
    final success = await backupProvider.uploadCurrentDataToCloud();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上传到云端成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败：${backupProvider.errorMessage}')),
      );
    }
  }

  /// 处理上传备份到云端
  Future<void> _handleUploadBackupToCloud(
    BuildContext context,
    BackupProvider backupProvider,
    BackupInfo backup,
  ) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上传到云端'),
        content: Text('确定要将 ${backup.createdAtFormatted} 的备份上传到云端吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 执行上传
    final success = await backupProvider.uploadToCloud(backup);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上传到云端成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败：${backupProvider.errorMessage}')),
      );
    }
  }

  /// 构建信息行（移动端优化）
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label：',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
