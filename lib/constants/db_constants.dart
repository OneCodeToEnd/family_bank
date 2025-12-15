/// 数据库常量定义
class DbConstants {
  // 数据库信息
  static const String dbName = 'family_bank.db';
  static const int dbVersion = 1;

  // 表名
  static const String tableFamilyGroups = 'family_groups';
  static const String tableFamilyMembers = 'family_members';
  static const String tableAccounts = 'accounts';
  static const String tableCategories = 'categories';
  static const String tableTransactions = 'transactions';
  static const String tableCategoryRules = 'category_rules';
  static const String tableBudgets = 'budgets';
  static const String tableAppSettings = 'app_settings';

  // 通用字段
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // family_groups 表字段
  static const String columnGroupName = 'name';
  static const String columnGroupDescription = 'description';

  // family_members 表字段
  static const String columnMemberFamilyGroupId = 'family_group_id';
  static const String columnMemberName = 'name';
  static const String columnMemberAvatar = 'avatar';
  static const String columnMemberRole = 'role';

  // accounts 表字段
  static const String columnAccountMemberId = 'family_member_id';
  static const String columnAccountName = 'name';
  static const String columnAccountType = 'type';
  static const String columnAccountIcon = 'icon';
  static const String columnAccountIsHidden = 'is_hidden';
  static const String columnAccountNotes = 'notes';

  // categories 表字段
  static const String columnCategoryParentId = 'parent_id';
  static const String columnCategoryName = 'name';
  static const String columnCategoryType = 'type';
  static const String columnCategoryIcon = 'icon';
  static const String columnCategoryColor = 'color';
  static const String columnCategoryIsSystem = 'is_system';
  static const String columnCategoryIsHidden = 'is_hidden';
  static const String columnCategorySortOrder = 'sort_order';
  static const String columnCategoryTags = 'tags';

  // transactions 表字段
  static const String columnTransactionAccountId = 'account_id';
  static const String columnTransactionCategoryId = 'category_id';
  static const String columnTransactionType = 'type';
  static const String columnTransactionAmount = 'amount';
  static const String columnTransactionDescription = 'description';
  static const String columnTransactionTime = 'transaction_time';
  static const String columnTransactionImportSource = 'import_source';
  static const String columnTransactionIsConfirmed = 'is_confirmed';
  static const String columnTransactionNotes = 'notes';
  static const String columnTransactionHash = 'hash';

  // category_rules 表字段
  static const String columnRuleKeyword = 'keyword';
  static const String columnRuleCategoryId = 'category_id';
  static const String columnRulePriority = 'priority';
  static const String columnRuleIsActive = 'is_active';
  static const String columnRuleMatchCount = 'match_count';
  static const String columnRuleSource = 'source';

  // budgets 表字段
  static const String columnBudgetTargetType = 'target_type';
  static const String columnBudgetTargetId = 'target_id';
  static const String columnBudgetAmount = 'amount';
  static const String columnBudgetPeriod = 'period';
  static const String columnBudgetStartDate = 'start_date';
  static const String columnBudgetEndDate = 'end_date';
  static const String columnBudgetIsActive = 'is_active';

  // app_settings 表字段
  static const String columnSettingKey = 'key';
  static const String columnSettingValue = 'value';
}

/// 账户类型枚举
class AccountType {
  static const String alipay = 'alipay';
  static const String wechat = 'wechat';
  static const String bank = 'bank';
  static const String cash = 'cash';
  static const String other = 'other';

  static const List<String> all = [alipay, wechat, bank, cash, other];

  static String getDisplayName(String type) {
    switch (type) {
      case alipay:
        return '支付宝';
      case wechat:
        return '微信';
      case bank:
        return '银行卡';
      case cash:
        return '现金';
      case other:
        return '其他';
      default:
        return type;
    }
  }
}

/// 交易类型枚举
class TransactionType {
  static const String income = 'income';
  static const String expense = 'expense';

  static String getDisplayName(String type) {
    switch (type) {
      case income:
        return '收入';
      case expense:
        return '支出';
      default:
        return type;
    }
  }
}

/// 导入来源枚举
class ImportSource {
  static const String manual = 'manual';
  static const String alipay = 'alipay';
  static const String wechat = 'wechat';
  static const String photo = 'photo';

  static String getDisplayName(String source) {
    switch (source) {
      case manual:
        return '手动输入';
      case alipay:
        return '支付宝导入';
      case wechat:
        return '微信导入';
      case photo:
        return '拍照识别';
      default:
        return source;
    }
  }
}

/// 规则来源枚举
class RuleSource {
  static const String user = 'user';
  static const String model = 'model';
}

/// 预算周期枚举
class BudgetPeriod {
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';

  static String getDisplayName(String period) {
    switch (period) {
      case monthly:
        return '月度';
      case yearly:
        return '年度';
      default:
        return period;
    }
  }
}

/// 预算目标类型枚举
class BudgetTargetType {
  static const String category = 'category';
  static const String account = 'account';
}
