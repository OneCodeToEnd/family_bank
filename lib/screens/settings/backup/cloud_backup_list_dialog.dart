import 'package:flutter/material.dart';
import '../../../models/sync/sync_comparison.dart';

/// 云端备份选择对话框
class CloudBackupListDialog extends StatefulWidget {
  final List<RemoteBackupWithMetadata> backups;

  const CloudBackupListDialog({
    super.key,
    required this.backups,
  });

  @override
  State<CloudBackupListDialog> createState() => _CloudBackupListDialogState();
}

class _CloudBackupListDialogState extends State<CloudBackupListDialog> {
  RemoteBackupWithMetadata? _selectedBackup;

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return AlertDialog(
      title: const Text('选择要恢复的云端备份'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        // 移动端优化：限制对话框宽度和高度
        width: isSmallScreen ? screenSize.width * 0.9 : double.maxFinite,
        height: screenSize.height * 0.6, // 限制最大高度为屏幕的60%
        child: widget.backups.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('云端暂无备份'),
                ),
              )
            : ListView.builder(
                shrinkWrap: false, // 改为 false，让 ListView 可以滚动
                itemCount: widget.backups.length,
                itemBuilder: (context, index) {
                  final backup = widget.backups[index];
                  return RadioListTile<RemoteBackupWithMetadata>(
                    value: backup,
                    groupValue: _selectedBackup,
                    onChanged: (value) {
                      setState(() {
                        _selectedBackup = value;
                      });
                    },
                    title: Text(
                      _formatDateTime(backup.metadata.createdAt),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '设备：${backup.metadata.deviceId}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          '大小：${_formatFileSize(backup.metadata.fileSize)} | '
                          '交易：${backup.metadata.transactionCount} 条',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedBackup == null
              ? null
              : () => Navigator.pop(context, _selectedBackup),
          child: const Text('恢复选中的备份'),
        ),
      ],
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

