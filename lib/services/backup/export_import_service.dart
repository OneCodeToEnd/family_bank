import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/backup/backup_info.dart';
import '../../utils/app_logger.dart';
import 'backup_service.dart';

/// 导出导入服务
/// 负责备份文件的导出和导入
class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  final _backupService = BackupService();

  /// 导出备份
  /// 创建备份并通过系统分享功能导出
  Future<void> exportBackup() async {
    try {
      AppLogger.i('[ExportImportService] 开始导出备份');

      // 1. 创建备份
      final backupInfo = await _backupService.createBackup(
        type: BackupType.export,
      );

      // 2. 分享备份文件
      await _shareBackupFile(backupInfo);

      AppLogger.i('[ExportImportService] 备份导出成功');
    } catch (e, stackTrace) {
      AppLogger.e('[ExportImportService] 导出备份失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 导出指定的备份
  Future<void> exportExistingBackup(BackupInfo backupInfo) async {
    try {
      AppLogger.i('[ExportImportService] 导出现有备份: ${backupInfo.fileName}');

      await _shareBackupFile(backupInfo);

      AppLogger.i('[ExportImportService] 备份导出成功');
    } catch (e, stackTrace) {
      AppLogger.e('[ExportImportService] 导出备份失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 分享备份文件
  Future<void> _shareBackupFile(BackupInfo backupInfo) async {
    final file = XFile(
      backupInfo.filePath,
      name: backupInfo.fileName,
      mimeType: 'application/x-sqlite3',
    );

    final result = await Share.shareXFiles(
      [file],
      subject: '账清数据备份',
      text: '备份时间：${backupInfo.createdAtFormatted}\n'
          '文件大小：${backupInfo.fileSizeFormatted}',
    );

    AppLogger.d('[ExportImportService] 分享结果: ${result.status}');
  }

  /// 导入备份
  /// 让用户选择备份文件并恢复
  Future<bool> importBackup() async {
    try {
      AppLogger.i('[ExportImportService] 开始导入备份');

      // 1. 让用户选择文件
      // 在移动端使用 FileType.any 避免扩展名兼容性问题
      // 在桌面端使用 FileType.custom 提供更好的用户体验
      final FilePickerResult? result;

      if (Platform.isAndroid || Platform.isIOS) {
        // 移动端：使用 FileType.any
        // 因为某些设备不支持 .db 扩展名过滤
        AppLogger.d('[ExportImportService] 移动端：使用 FileType.any');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          dialogTitle: '选择备份文件',
        );
      } else {
        // 桌面端：使用 FileType.custom 提供文件类型过滤
        AppLogger.d('[ExportImportService] 桌面端：使用 FileType.custom');
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['db'],
          dialogTitle: '选择备份文件',
        );
      }

      if (result == null || result.files.single.path == null) {
        AppLogger.d('[ExportImportService] 用户取消选择');
        return false;
      }

      final filePath = result.files.single.path!;
      AppLogger.d('[ExportImportService] 用户选择文件: $filePath');

      // 验证文件扩展名（移动端需要手动验证）
      if (!filePath.toLowerCase().endsWith('.db')) {
        AppLogger.w('[ExportImportService] 选择的文件不是 .db 文件: $filePath');
        throw Exception('请选择 .db 格式的备份文件');
      }

      // 2. 恢复备份
      await _backupService.restoreBackup(filePath);

      AppLogger.i('[ExportImportService] 备份导入成功');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[ExportImportService] 导入备份失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
