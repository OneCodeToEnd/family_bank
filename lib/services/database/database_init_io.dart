import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 桌面/移动平台的数据库初始化
///
/// 在桌面平台（Windows、Linux、macOS）上，需要使用 sqflite_common_ffi
/// 在移动平台（iOS、Android）上，使用原生 sqflite 实现
void initializeDatabaseFactory() {
  // 仅在桌面平台初始化 FFI 数据库工厂
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 初始化 FFI
    sqfliteFfiInit();
    // 设置全局数据库工厂为 FFI 实现
    databaseFactory = databaseFactoryFfi;
  }
  // 移动平台（iOS、Android）会自动使用原生 sqflite 实现，无需额外配置
}
