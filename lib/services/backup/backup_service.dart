import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/backup/backup_info.dart';
import '../../utils/app_logger.dart';
import '../../constants/db_constants.dart';
import '../database/database_service.dart';

/// 基础备份服务
/// 负责本地备份的创建、恢复、管理
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const String _backupDirName = 'backups';
  static const String _tempBackupSuffix = '.temp_backup';

  /// 获取备份目录
  Future<Directory> getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, _backupDirName));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      AppLogger.d('[BackupService] 创建备份目录: ${backupDir.path}');
    }

    return backupDir;
  }

  /// 获取数据库文件路径
  Future<String> getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, DbConstants.dbName);
  }

  /// 创建备份
  /// [type] 备份类型
  /// 返回备份信息
  Future<BackupInfo> createBackup({
    BackupType type = BackupType.manual,
  }) async {
    try {
      AppLogger.i('[BackupService] 开始创建备份，类型: $type');

      // 1. 获取数据库路径
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw BackupException('数据库文件不存在');
      }

      // 2. 生成备份文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'backup_$timestamp.db';

      // 3. 获取备份目录
      final backupDir = await getBackupDirectory();
      final backupPath = path.join(backupDir.path, backupFileName);

      // 4. 复制数据库文件
      AppLogger.d('[BackupService] 复制数据库文件到: $backupPath');
      final backupFile = await dbFile.copy(backupPath);

      // 5. 获取文件大小
      final fileSize = await backupFile.length();

      // 6. 创建备份信息
      final backupInfo = BackupInfo(
        id: timestamp.toString(),
        filePath: backupPath,
        fileName: backupFileName,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        type: type,
      );

      AppLogger.i('[BackupService] 备份创建成功: ${backupInfo.fileName}, 大小: ${backupInfo.fileSizeFormatted}');

      return backupInfo;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupService] 创建备份失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 恢复备份
  /// [backupPath] 备份文件路径
  Future<void> restoreBackup(String backupPath) async {
    try {
      AppLogger.i('[BackupService] 开始恢复备份: $backupPath');

      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        throw BackupException('备份文件不存在');
      }

      // 1. 验证备份文件
      AppLogger.d('[BackupService] 验证备份文件');
      final isValid = await _validateBackupFile(backupFile);
      if (!isValid) {
        throw BackupException('备份文件无效或已损坏');
      }

      // 2. 关闭当前数据库连接
      AppLogger.d('[BackupService] 关闭当前数据库连接');
      await DatabaseService().close();

      // 3. 备份当前数据库（以防恢复失败）
      final dbPath = await getDatabasePath();
      final currentDbFile = File(dbPath);
      final tempBackupPath = '$dbPath$_tempBackupSuffix.${DateTime.now().millisecondsSinceEpoch}';

      if (await currentDbFile.exists()) {
        AppLogger.d('[BackupService] 备份当前数据库到临时文件');
        await currentDbFile.copy(tempBackupPath);
      }

      try {
        // 4. 替换数据库文件
        AppLogger.d('[BackupService] 替换数据库文件');
        await backupFile.copy(dbPath);

        // 5. 重新初始化数据库
        AppLogger.d('[BackupService] 重新初始化数据库');
        await DatabaseService().database;

        // 6. 删除临时备份
        final tempBackupFile = File(tempBackupPath);
        if (await tempBackupFile.exists()) {
          await tempBackupFile.delete();
        }

        AppLogger.i('[BackupService] 备份恢复成功');
      } catch (e) {
        // 恢复失败，还原原数据库
        AppLogger.e('[BackupService] 恢复失败，还原原数据库', error: e);
        final tempBackupFile = File(tempBackupPath);
        if (await tempBackupFile.exists()) {
          await tempBackupFile.copy(dbPath);
          await tempBackupFile.delete();
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      AppLogger.e('[BackupService] 恢复备份失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 验证备份文件
  Future<bool> _validateBackupFile(File backupFile) async {
    Database? db;
    try {
      // 尝试打开数据库
      db = await openDatabase(backupFile.path, readOnly: true);

      // 检查必要的表是否存在
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );

      final tableNames = tables.map((t) => t['name'] as String).toList();

      // 必须包含的核心表
      final requiredTables = [
        DbConstants.tableTransactions,
        DbConstants.tableAccounts,
        DbConstants.tableCategories,
        DbConstants.tableFamilyGroups,
        DbConstants.tableFamilyMembers,
      ];

      final hasAllTables = requiredTables.every(
        (table) => tableNames.contains(table),
      );

      return hasAllTables;
    } catch (e) {
      AppLogger.e('[BackupService] 验证备份文件失败', error: e);
      return false;
    } finally {
      // 确保数据库被关闭
      await db?.close();
    }
  }

  /// 列出所有备份
  Future<List<BackupInfo>> listBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      final files = await backupDir.list().toList();

      final backups = <BackupInfo>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.db') && !file.path.contains(_tempBackupSuffix)) {
          final fileName = path.basename(file.path);
          final fileSize = await file.length();
          final stat = await file.stat();

          // 从文件名解析时间戳
          final timestampStr = fileName
              .replaceAll('backup_', '')
              .replaceAll('.db', '');

          final timestamp = int.tryParse(timestampStr);
          final createdAt = timestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : stat.modified;

          // 尝试推断备份类型（基于文件名模式）
          BackupType type = BackupType.manual;
          // 可以根据需要添加更复杂的类型推断逻辑

          backups.add(BackupInfo(
            id: timestampStr,
            filePath: file.path,
            fileName: fileName,
            fileSize: fileSize,
            createdAt: createdAt,
            type: type,
          ));
        }
      }

      // 按创建时间倒序排列
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      AppLogger.d('[BackupService] 找到 ${backups.length} 个备份');

      return backups;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupService] 列出备份失败', error: e, stackTrace: stackTrace);
      // 返回空列表而不是抛出异常，因为这是查询操作
      return [];
    }
  }

  /// 删除备份
  Future<void> deleteBackup(String backupPath) async {
    try {
      AppLogger.i('[BackupService] 删除备份: $backupPath');

      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.delete();
        AppLogger.i('[BackupService] 备份删除成功');
      } else {
        AppLogger.w('[BackupService] 备份文件不存在: $backupPath');
      }
    } catch (e, stackTrace) {
      AppLogger.e('[BackupService] 删除备份失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 清理旧备份
  /// [keepCount] 保留的备份数量
  Future<void> cleanOldBackups({int keepCount = 7}) async {
    try {
      AppLogger.i('[BackupService] 清理旧备份，保留最近 $keepCount 个');

      final backups = await listBackups();

      if (backups.length <= keepCount) {
        AppLogger.d('[BackupService] 备份数量未超过限制，无需清理');
        return;
      }

      // 删除多余的备份
      final backupsToDelete = backups.skip(keepCount).toList();

      for (final backup in backupsToDelete) {
        try {
          await deleteBackup(backup.filePath);
        } catch (e) {
          // 单个备份删除失败不影响其他备份的清理
          AppLogger.w('[BackupService] 删除备份失败，继续清理其他备份', error: e);
        }
      }

      AppLogger.i('[BackupService] 清理完成，删除了 ${backupsToDelete.length} 个旧备份');
    } catch (e, stackTrace) {
      AppLogger.e('[BackupService] 清理旧备份失败', error: e, stackTrace: stackTrace);
      // 清理失败不抛出异常，因为这不是关键操作
    }
  }
}

/// 备份异常
class BackupException implements Exception {
  final String message;

  BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}
