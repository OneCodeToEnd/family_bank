/// 数据库常量定义
class DbConstants {
  // 数据库信息
  static const String dbName = 'family_bank.db';
  static const int dbVersion = 12;

  // 表名
  static const String tableFamilyGroups = 'family_groups';
  static const String tableFamilyMembers = 'family_members';
  static const String tableAccounts = 'accounts';
  static const String tableCategories = 'categories';
  static const String tableTransactions = 'transactions';
  static const String tableCategoryRules = 'category_rules';
  static const String tableAnnualBudgets = 'annual_budgets';
  static const String tableAppSettings = 'app_settings';
  static const String tableHttpLogs = 'http_logs';
  static const String tableEmailConfigs = 'email_configs';
  static const String tableAIModels = 'ai_models';
  static const String tableCounterpartyGroups = 'counterparty_groups';
  static const String tableAgentMemories = 'agent_memories';
  static const String tableChatSessions = 'chat_sessions';

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
  static const String columnTransactionCounterparty = 'counterparty';

  // category_rules 表字段
  static const String columnRuleKeyword = 'keyword';
  static const String columnRuleCategoryId = 'category_id';
  static const String columnRulePriority = 'priority';
  static const String columnRuleIsActive = 'is_active';
  static const String columnRuleMatchCount = 'match_count';
  static const String columnRuleSource = 'source';

  // V3.0 新增字段
  static const String columnRuleMatchType = 'match_type';
  static const String columnRuleMatchPosition = 'match_position';
  static const String columnRuleMinConfidence = 'min_confidence';
  static const String columnRuleCounterparty = 'counterparty';
  static const String columnRuleAliases = 'aliases';
  static const String columnRuleAutoLearn = 'auto_learn';
  static const String columnRuleCaseSensitive = 'case_sensitive';

  // annual_budgets 表字段
  static const String columnAnnualBudgetFamilyId = 'family_id';
  static const String columnAnnualBudgetCategoryId = 'category_id';
  static const String columnAnnualBudgetYear = 'year';
  static const String columnAnnualBudgetType = 'type';
  static const String columnAnnualBudgetAnnualAmount = 'annual_amount';
  static const String columnAnnualBudgetMonthlyAmount = 'monthly_amount';

  // app_settings 表字段
  static const String columnSettingKey = 'key';
  static const String columnSettingValue = 'value';

  // http_logs 表字段
  static const String columnLogRequestId = 'request_id';
  static const String columnLogMethod = 'method';
  static const String columnLogUrl = 'url';
  static const String columnLogRequestHeaders = 'request_headers';
  static const String columnLogRequestBody = 'request_body';
  static const String columnLogRequestSize = 'request_size';
  static const String columnLogStatusCode = 'status_code';
  static const String columnLogStatusMessage = 'status_message';
  static const String columnLogResponseHeaders = 'response_headers';
  static const String columnLogResponseBody = 'response_body';
  static const String columnLogResponseSize = 'response_size';
  static const String columnLogStartTime = 'start_time';
  static const String columnLogEndTime = 'end_time';
  static const String columnLogDurationMs = 'duration_ms';
  static const String columnLogErrorType = 'error_type';
  static const String columnLogErrorMessage = 'error_message';
  static const String columnLogStackTrace = 'stack_trace';
  static const String columnLogServiceName = 'service_name';
  static const String columnLogApiProvider = 'api_provider';

  // counterparty_groups 表字段
  static const String columnCounterpartyGroupMainCounterparty = 'main_counterparty';
  static const String columnCounterpartyGroupSubCounterparty = 'sub_counterparty';
  static const String columnCounterpartyGroupAutoCreated = 'auto_created';
  static const String columnCounterpartyGroupConfidenceScore = 'confidence_score';

  // agent_memories 表字段
  static const String columnMemoryType = 'type';
  static const String columnMemoryContent = 'content';
  static const String columnMemoryRelatedQuery = 'related_query';

  // chat_sessions 表字段
  static const String columnSessionTitle = 'title';
  static const String columnSessionIsPinned = 'is_pinned';
  static const String columnSessionMessages = 'messages';
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
  static const String learned = 'learned';
}

/// 规则匹配类型枚举
class RuleMatchType {
  static const String exact = 'exact';
  static const String partial = 'partial';
  static const String counterparty = 'counterparty';

  static String getDisplayName(String type) {
    switch (type) {
      case exact:
        return '精确匹配';
      case partial:
        return '部分匹配';
      case counterparty:
        return '交易对方';
      default:
        return type;
    }
  }
}

/// 规则匹配位置枚举
class RuleMatchPosition {
  static const String contains = 'contains';
  static const String prefix = 'prefix';
  static const String suffix = 'suffix';

  static String getDisplayName(String position) {
    switch (position) {
      case contains:
        return '包含';
      case prefix:
        return '前缀';
      case suffix:
        return '后缀';
      default:
        return position;
    }
  }
}
