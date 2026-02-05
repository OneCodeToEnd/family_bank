import 'dart:async';
import 'package:logger/logger.dart';
import '../../models/sync/webdav_config.dart';
import 'sync_service.dart';
import 'webdav_config_service.dart';

/// 自动同步服务
///
/// 负责管理自动同步的触发机制：
/// 1. 定时同步 - 根据配置的间隔定期触发
/// 2. 启动时同步 - 应用启动时触发
/// 3. 数据变化时同步 - 数据修改后触发（可选）
class AutoSyncService {
  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal();

  final _configService = WebDAVConfigService();
  final _syncService = SyncService();
  final _logger = Logger();

  Timer? _syncTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;

  /// 初始化自动同步服务
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.d('[AutoSyncService] 已经初始化，跳过');
      return;
    }

    try {
      _logger.i('[AutoSyncService] 初始化自动同步服务');

      // 加载配置
      final config = await _configService.loadConfig();
      if (config == null) {
        _logger.d('[AutoSyncService] 未配置 WebDAV，跳过自动同步');
        return;
      }

      // 检查是否启用自动同步
      if (!config.autoSync) {
        _logger.d('[AutoSyncService] 自动同步未启用');
        return;
      }

      // 启动定时同步
      _startPeriodicSync(config);

      // 如果配置了启动时同步，立即执行一次
      if (config.syncOnStart) {
        _logger.i('[AutoSyncService] 启动时同步已启用，开始同步');
        // 延迟 3 秒后执行，避免应用启动时的性能影响
        Future.delayed(const Duration(seconds: 3), () {
          _performSync();
        });
      }

      _isInitialized = true;
      _logger.i('[AutoSyncService] 自动同步服务初始化完成');
    } catch (e, stackTrace) {
      _logger.e('[AutoSyncService] 初始化失败',
          error: e, stackTrace: stackTrace);
    }
  }

  /// 启动定时同步
  void _startPeriodicSync(WebDAVConfig config) {
    // 取消现有的定时器
    _syncTimer?.cancel();

    final interval = Duration(minutes: config.syncInterval);
    _logger.i('[AutoSyncService] 启动定时同步，间隔: ${config.syncInterval} 分钟');

    _syncTimer = Timer.periodic(interval, (timer) {
      _logger.d('[AutoSyncService] 定时同步触发');
      _performSync();
    });
  }

  /// 执行同步
  Future<void> _performSync() async {
    // 防止并发同步
    if (_isSyncing) {
      _logger.d('[AutoSyncService] 已有同步任务在进行，跳过');
      return;
    }

    _isSyncing = true;

    try {
      _logger.i('[AutoSyncService] 开始自动同步');
      final result = await _syncService.sync();

      if (result.success) {
        _logger.i('[AutoSyncService] 自动同步成功: ${result.message}');
      } else {
        _logger.w('[AutoSyncService] 自动同步失败: ${result.message}');
      }
    } catch (e, stackTrace) {
      _logger.e('[AutoSyncService] 自动同步异常',
          error: e, stackTrace: stackTrace);
    } finally {
      _isSyncing = false;
    }
  }

  /// 手动触发同步
  ///
  /// 用于数据变化时触发同步
  Future<void> triggerSync() async {
    try {
      // 检查配置
      final config = await _configService.loadConfig();
      if (config == null || !config.autoSync) {
        _logger.d('[AutoSyncService] 自动同步未启用，跳过触发');
        return;
      }

      // 检查是否启用数据变化时同步
      if (!config.syncOnChange) {
        _logger.d('[AutoSyncService] 数据变化时同步未启用，跳过触发');
        return;
      }

      _logger.i('[AutoSyncService] 数据变化触发同步');
      await _performSync();
    } catch (e, stackTrace) {
      _logger.e('[AutoSyncService] 触发同步失败',
          error: e, stackTrace: stackTrace);
    }
  }

  /// 重新加载配置并重启定时器
  Future<void> reloadConfig() async {
    try {
      _logger.i('[AutoSyncService] 重新加载配置');

      // 停止现有的定时器
      _syncTimer?.cancel();
      _isInitialized = false;

      // 重新初始化
      await initialize();
    } catch (e, stackTrace) {
      _logger.e('[AutoSyncService] 重新加载配置失败',
          error: e, stackTrace: stackTrace);
    }
  }

  /// 停止自动同步
  void stop() {
    _logger.i('[AutoSyncService] 停止自动同步服务');
    _syncTimer?.cancel();
    _syncTimer = null;
    _isInitialized = false;
  }

  /// 获取当前状态
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
}
