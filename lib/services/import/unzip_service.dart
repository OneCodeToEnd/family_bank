import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

/// ZIP解压服务
class UnzipService {
  /// 解压ZIP文件
  ///
  /// [zipFile] ZIP文件
  /// [password] 解压密码
  /// [targetDir] 目标目录
  ///
  /// 返回解压后的文件列表
  Future<List<File>> unzip(
    File zipFile,
    String password,
    String targetDir,
  ) async {
    try {
      // 读取ZIP文件
      final bytes = await zipFile.readAsBytes();

      // 解码ZIP
      final archive = ZipDecoder().decodeBytes(bytes, password: password);

      // 确保目标目录存在
      final targetDirectory = Directory(targetDir);
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      final extractedFiles = <File>[];

      // 解压所有文件
      for (final file in archive) {
        if (file.isFile) {
          final filename = path.join(targetDir, file.name);
          final outputFile = File(filename);

          // 创建父目录
          await outputFile.parent.create(recursive: true);

          // 写入文件
          await outputFile.writeAsBytes(file.content as List<int>);
          extractedFiles.add(outputFile);
        }
      }

      return extractedFiles;
    } catch (e) {
      if (e.toString().contains('password') ||
          e.toString().contains('Invalid') ||
          e.toString().contains('decrypt')) {
        throw Exception('解压密码错误');
      }
      throw Exception('解压失败: $e');
    }
  }

  /// 验证密码是否正确
  ///
  /// [zipFile] ZIP文件
  /// [password] 密码
  ///
  /// 返回密码是否正确
  Future<bool> validatePassword(File zipFile, String password) async {
    try {
      final bytes = await zipFile.readAsBytes();
      ZipDecoder().decodeBytes(bytes, password: password);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清理临时文件
  ///
  /// [dir] 要清理的目录
  Future<void> cleanupTempFiles(String dir) async {
    try {
      final directory = Directory(dir);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      // 忽略清理错误
    }
  }
}
