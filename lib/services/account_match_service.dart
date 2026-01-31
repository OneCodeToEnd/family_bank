import '../models/account.dart';
import '../services/database/account_db_service.dart';
import '../constants/db_constants.dart';
import '../utils/app_logger.dart';

/// 账户智能匹配服务
///
/// 根据账单平台（支付宝/微信）智能推荐合适的账户
class AccountMatchService {
  final AccountDbService _accountDbService = AccountDbService();

  /// 根据平台智能匹配账户
  ///
  /// [platform] 账单平台：'alipay', 'wechat', 'unknown'
  ///
  /// 返回推荐的账户列表，按匹配度排序：
  /// 1. 优先返回相同类型的账户
  /// 2. 如果没有匹配类型，返回所有非隐藏账户
  /// 3. 按创建时间倒序排序（最新的在前）
  Future<List<Account>> matchAccounts(String? platform) async {
    try {
      AppLogger.i('[AccountMatchService] 开始匹配账户，平台: $platform');

      // 获取所有非隐藏账户
      final allAccounts = await _accountDbService.getAllAccounts();
      final visibleAccounts = allAccounts.where((a) => !a.isHidden).toList();

      if (visibleAccounts.isEmpty) {
        AppLogger.w('[AccountMatchService] 没有可用的账户');
        return [];
      }

      // 如果没有指定平台，返回所有账户
      if (platform == null || platform.isEmpty || platform == 'unknown') {
        AppLogger.d('[AccountMatchService] 未指定平台，返回所有账户');
        return _sortByCreatedTime(visibleAccounts);
      }

      // 根据平台匹配账户类型
      final targetType = _platformToAccountType(platform);
      AppLogger.d('[AccountMatchService] 目标账户类型: $targetType');

      // 分离匹配和不匹配的账户
      final matchedAccounts = <Account>[];
      final otherAccounts = <Account>[];

      for (final account in visibleAccounts) {
        if (account.type == targetType) {
          matchedAccounts.add(account);
        } else {
          otherAccounts.add(account);
        }
      }

      AppLogger.i('[AccountMatchService] 匹配到 ${matchedAccounts.length} 个相同类型账户');

      // 排序：匹配的账户在前，其他账户在后
      final sortedMatched = _sortByCreatedTime(matchedAccounts);
      final sortedOthers = _sortByCreatedTime(otherAccounts);

      return [...sortedMatched, ...sortedOthers];
    } catch (e) {
      AppLogger.e('[AccountMatchService] 匹配账户失败', error: e);
      return [];
    }
  }

  /// 获取推荐的账户ID（第一个匹配的账户）
  ///
  /// [platform] 账单平台
  ///
  /// 返回推荐的账户ID，如果没有匹配则返回 null
  Future<int?> getSuggestedAccountId(String? platform) async {
    final accounts = await matchAccounts(platform);
    if (accounts.isEmpty) {
      return null;
    }
    return accounts.first.id;
  }

  /// 将平台转换为账户类型
  String _platformToAccountType(String platform) {
    switch (platform.toLowerCase()) {
      case 'alipay':
        return AccountType.alipay;
      case 'wechat':
        return AccountType.wechat;
      default:
        return AccountType.other;
    }
  }

  /// 按创建时间倒序排序（最新的在前）
  List<Account> _sortByCreatedTime(List<Account> accounts) {
    final sorted = List<Account>.from(accounts);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// 获取账户的显示名称（带类型标签）
  ///
  /// 例如：「我的支付宝 (支付宝)」
  String getAccountDisplayName(Account account) {
    final typeName = AccountType.getDisplayName(account.type);
    return '${account.name} ($typeName)';
  }

  /// 判断账户是否为推荐账户
  ///
  /// [account] 要判断的账户
  /// [platform] 账单平台
  bool isRecommendedAccount(Account account, String? platform) {
    if (platform == null || platform.isEmpty || platform == 'unknown') {
      return false;
    }
    final targetType = _platformToAccountType(platform);
    return account.type == targetType;
  }
}
