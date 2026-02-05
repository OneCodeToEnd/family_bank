import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sync/sync_status.dart';
import '../../../models/sync/sync_comparison.dart';
import '../../../services/sync/sync_service.dart';
import '../../../services/sync/sync_state_manager.dart';
import '../../../services/sync/webdav_config_service.dart';
import 'webdav_setup_screen.dart';

/// 同步状态界面
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final _configService = WebDAVConfigService();
  final _stateManager = SyncStateManager();
  late final SyncService _syncService;

  SyncStatus? _syncStatus;
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _hasConfig = false;

  @override
  void initState() {
    super.initState();
    _syncService = SyncService();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await _configService.loadConfig();
      final status = await _stateManager.loadSyncState();

      setState(() {
        _hasConfig = config != null;
        _syncStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV 同步'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '配置',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasConfig
              ? _buildNoConfigView()
              : _buildSyncStatusView(),
    );
  }

  Widget _buildNoConfigView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              '未配置 WebDAV',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '请先配置 WebDAV 服务器以启用同步功能',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings),
              label: const Text('立即配置'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusView() {
    return RefreshIndicator(
      onRefresh: _loadStatus,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 同步状态卡片
          _buildStatusCard(),
          const SizedBox(height: 16),

          // 同步按钮
          _buildSyncButton(),
          const SizedBox(height: 16),

          // 版本信息
          if (_syncStatus != null) ...[
            _buildVersionInfo(),
            const SizedBox(height: 16),
          ],

          // 冲突处理
          if (_syncStatus?.hasConflict == true) ...[
            _buildConflictCard(),
            const SizedBox(height: 16),
          ],

          // 同步历史
          _buildSyncHistory(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _syncStatus;
    final state = status?.state ?? SyncState.idle;

    IconData icon;
    Color color;
    String title;
    String? subtitle;

    switch (state) {
      case SyncState.idle:
        icon = Icons.cloud_done;
        color = Colors.grey;
        title = '空闲';
        subtitle = status?.lastSyncTime != null
            ? '最后同步: ${_formatDateTime(status!.lastSyncTime!)}'
            : '尚未同步';
        break;
      case SyncState.checking:
        icon = Icons.cloud_sync;
        color = Colors.blue;
        title = '检查中';
        subtitle = '正在检查远程版本...';
        break;
      case SyncState.uploading:
        icon = Icons.cloud_upload;
        color = Colors.blue;
        title = '上传中';
        subtitle = status?.progress != null
            ? '进度: ${(status!.progress! * 100).toStringAsFixed(0)}%'
            : null;
        break;
      case SyncState.downloading:
        icon = Icons.cloud_download;
        color = Colors.blue;
        title = '下载中';
        subtitle = status?.progress != null
            ? '进度: ${(status!.progress! * 100).toStringAsFixed(0)}%'
            : null;
        break;
      case SyncState.restoring:
        icon = Icons.restore;
        color = Colors.blue;
        title = '恢复中';
        subtitle = '正在恢复数据...';
        break;
      case SyncState.success:
        icon = Icons.check_circle;
        color = Colors.green;
        title = '同步成功';
        subtitle = status?.lastSyncTime != null
            ? '同步时间: ${_formatDateTime(status!.lastSyncTime!)}'
            : null;
        break;
      case SyncState.error:
        icon = Icons.error;
        color = Colors.red;
        title = '同步失败';
        subtitle = status?.errorMessage;
        break;
      case SyncState.conflict:
        icon = Icons.warning;
        color = Colors.orange;
        title = '检测到冲突';
        subtitle = '需要手动解决';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    final canSync = !_isSyncing &&
        _syncStatus?.state != SyncState.uploading &&
        _syncStatus?.state != SyncState.downloading &&
        _syncStatus?.state != SyncState.restoring;

    return ElevatedButton.icon(
      onPressed: canSync ? _performSync : null,
      icon: _isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      label: Text(_isSyncing ? '同步中...' : '立即同步'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildVersionInfo() {
    final status = _syncStatus!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (status.localMetadata != null) ...[
              _buildMetadataRow('本地版本', status.localMetadata!),
              const Divider(height: 24),
            ],
            if (status.remoteMetadata != null) ...[
              _buildMetadataRow('远程版本', status.remoteMetadata!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, dynamic metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text('设备: ${metadata.deviceId}', style: const TextStyle(fontSize: 12)),
        Text('创建时间: ${_formatDateTime(metadata.createdAt)}',
            style: const TextStyle(fontSize: 12)),
        Text('交易数量: ${metadata.transactionCount}',
            style: const TextStyle(fontSize: 12)),
        Text('文件大小: ${_formatFileSize(metadata.fileSize)}',
            style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildConflictCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Text(
                  '检测到同步冲突',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '本地和远程数据存在冲突，请选择要保留的版本：',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolveConflict(useLocal: true),
                    child: const Text('使用本地数据'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolveConflict(useLocal: false),
                    child: const Text('使用远程数据'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '同步历史',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_syncStatus?.lastSyncTime != null)
              ListTile(
                leading: Icon(
                  _syncStatus!.state == SyncState.success
                      ? Icons.check_circle
                      : Icons.error,
                  color: _syncStatus!.state == SyncState.success
                      ? Colors.green
                      : Colors.red,
                ),
                title: Text(
                  _syncStatus!.state == SyncState.success ? '同步成功' : '同步失败',
                ),
                subtitle: Text(_formatDateTime(_syncStatus!.lastSyncTime!)),
                dense: true,
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无同步记录'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final config = await _configService.loadConfig();
    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WebDAVSetupScreen(existingConfig: config),
      ),
    );

    if (result == true) {
      _loadStatus();
    }
  }

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await _syncService.sync();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (result.action == SyncAction.conflict) {
          // 冲突情况，刷新状态显示冲突卡片
          _loadStatus();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('同步失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _loadStatus();
      }
    }
  }

  Future<void> _resolveConflict({required bool useLocal}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text(
          useLocal
              ? '将使用本地数据覆盖远程数据，远程数据将丢失。确定继续吗？'
              : '将使用远程数据覆盖本地数据，本地数据将丢失。确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      // 调用冲突解决方法
      final result = useLocal
          ? await _syncService.resolveConflictWithLocal()
          : await _syncService.resolveConflictWithRemote();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('冲突已解决'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解决冲突失败: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('解决冲突失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _loadStatus();
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
