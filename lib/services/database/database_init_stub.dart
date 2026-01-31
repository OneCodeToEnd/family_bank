/// Web 平台的数据库初始化（空实现）
///
/// Web 平台不支持 sqflite，通常使用 IndexedDB 或其他浏览器存储方案
/// 此文件提供一个空实现，避免在 Web 平台上导入 dart:io
void initializeDatabaseFactory() {
  // Web 平台不需要初始化 sqflite
  // 如果需要在 Web 上使用数据库，可以考虑使用 sqflite_common_ffi_web
  // 或其他 Web 兼容的数据库方案
}
