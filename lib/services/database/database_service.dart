import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../constants/db_constants.dart';
import 'preset_category_data.dart';
import '../../utils/app_logger.dart';

/// 数据库服务类
/// 负责数据库的初始化、创建、升级和管理
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    AppLogger.i('[DatabaseService] 开始初始化数据库');

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DbConstants.dbName);

    AppLogger.d('[DatabaseService] 数据库路径: $path');
    AppLogger.d('[DatabaseService] 数据库版本: ${DbConstants.dbVersion}');

    final db = await openDatabase(
      path,
      version: DbConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    AppLogger.i('[DatabaseService] 数据库初始化完成');
    return db;
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    AppLogger.i('[DatabaseService] 开始创建数据库表 (版本: $version)');

    // 创建家庭组表
    AppLogger.d('[DatabaseService] 创建 family_groups 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableFamilyGroups} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnGroupName} TEXT NOT NULL,
        ${DbConstants.columnGroupDescription} TEXT,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // 创建家庭成员表
    AppLogger.d('[DatabaseService] 创建 family_members 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableFamilyMembers} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnMemberFamilyGroupId} INTEGER NOT NULL,
        ${DbConstants.columnMemberName} TEXT NOT NULL,
        ${DbConstants.columnMemberAvatar} TEXT,
        ${DbConstants.columnMemberRole} TEXT,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.columnMemberFamilyGroupId})
          REFERENCES ${DbConstants.tableFamilyGroups}(${DbConstants.columnId}) ON DELETE CASCADE
      )
    ''');

    // 创建账户表
    AppLogger.d('[DatabaseService] 创建 accounts 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableAccounts} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnAccountMemberId} INTEGER NOT NULL,
        ${DbConstants.columnAccountName} TEXT NOT NULL,
        ${DbConstants.columnAccountType} TEXT NOT NULL,
        ${DbConstants.columnAccountIcon} TEXT,
        ${DbConstants.columnAccountIsHidden} INTEGER DEFAULT 0,
        ${DbConstants.columnAccountNotes} TEXT,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.columnAccountMemberId})
          REFERENCES ${DbConstants.tableFamilyMembers}(${DbConstants.columnId}) ON DELETE CASCADE
      )
    ''');

    // 创建分类表
    AppLogger.d('[DatabaseService] 创建 categories 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCategories} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnCategoryParentId} INTEGER,
        ${DbConstants.columnCategoryName} TEXT NOT NULL,
        ${DbConstants.columnCategoryType} TEXT NOT NULL,
        ${DbConstants.columnCategoryIcon} TEXT,
        ${DbConstants.columnCategoryColor} TEXT,
        ${DbConstants.columnCategoryIsSystem} INTEGER DEFAULT 0,
        ${DbConstants.columnCategoryIsHidden} INTEGER DEFAULT 0,
        ${DbConstants.columnCategorySortOrder} INTEGER DEFAULT 0,
        ${DbConstants.columnCategoryTags} TEXT,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.columnCategoryParentId})
          REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) ON DELETE SET NULL
      )
    ''');

    // 创建账单流水表
    AppLogger.d('[DatabaseService] 创建 transactions 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableTransactions} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnTransactionAccountId} INTEGER NOT NULL,
        ${DbConstants.columnTransactionCategoryId} INTEGER,
        ${DbConstants.columnTransactionType} TEXT NOT NULL,
        ${DbConstants.columnTransactionAmount} REAL NOT NULL,
        ${DbConstants.columnTransactionDescription} TEXT,
        ${DbConstants.columnTransactionTime} INTEGER NOT NULL,
        ${DbConstants.columnTransactionImportSource} TEXT DEFAULT 'manual',
        ${DbConstants.columnTransactionIsConfirmed} INTEGER DEFAULT 0,
        ${DbConstants.columnTransactionNotes} TEXT,
        ${DbConstants.columnTransactionHash} TEXT,
        ${DbConstants.columnTransactionCounterparty} TEXT,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.columnTransactionAccountId})
          REFERENCES ${DbConstants.tableAccounts}(${DbConstants.columnId}) ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.columnTransactionCategoryId})
          REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) ON DELETE SET NULL
      )
    ''');

    // 创建分类规则表
    AppLogger.d('[DatabaseService] 创建 category_rules 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCategoryRules} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnRuleKeyword} TEXT NOT NULL,
        ${DbConstants.columnRuleCategoryId} INTEGER NOT NULL,
        ${DbConstants.columnRulePriority} INTEGER DEFAULT 0,
        ${DbConstants.columnRuleIsActive} INTEGER DEFAULT 1,
        ${DbConstants.columnRuleMatchCount} INTEGER DEFAULT 0,
        ${DbConstants.columnRuleSource} TEXT DEFAULT 'user',
        ${DbConstants.columnRuleMatchType} TEXT DEFAULT 'exact',
        ${DbConstants.columnRuleMatchPosition} TEXT DEFAULT NULL,
        ${DbConstants.columnRuleMinConfidence} REAL DEFAULT 0.8,
        ${DbConstants.columnRuleCounterparty} TEXT DEFAULT NULL,
        ${DbConstants.columnRuleAliases} TEXT DEFAULT '[]',
        ${DbConstants.columnRuleAutoLearn} INTEGER DEFAULT 0,
        ${DbConstants.columnRuleCaseSensitive} INTEGER DEFAULT 0,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.columnRuleCategoryId})
          REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) ON DELETE CASCADE
      )
    ''');


    // 创建应用设置表
    AppLogger.d('[DatabaseService] 创建 app_settings 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableAppSettings} (
        ${DbConstants.columnSettingKey} TEXT PRIMARY KEY,
        ${DbConstants.columnSettingValue} TEXT NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // 创建HTTP日志表 (V4新增)
    AppLogger.d('[DatabaseService] 创建 http_logs 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableHttpLogs} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnLogRequestId} TEXT NOT NULL UNIQUE,
        ${DbConstants.columnLogMethod} TEXT NOT NULL,
        ${DbConstants.columnLogUrl} TEXT NOT NULL,
        ${DbConstants.columnLogRequestHeaders} TEXT,
        ${DbConstants.columnLogRequestBody} TEXT,
        ${DbConstants.columnLogRequestSize} INTEGER,
        ${DbConstants.columnLogStatusCode} INTEGER,
        ${DbConstants.columnLogStatusMessage} TEXT,
        ${DbConstants.columnLogResponseHeaders} TEXT,
        ${DbConstants.columnLogResponseBody} TEXT,
        ${DbConstants.columnLogResponseSize} INTEGER,
        ${DbConstants.columnLogStartTime} INTEGER NOT NULL,
        ${DbConstants.columnLogEndTime} INTEGER,
        ${DbConstants.columnLogDurationMs} INTEGER,
        ${DbConstants.columnLogErrorType} TEXT,
        ${DbConstants.columnLogErrorMessage} TEXT,
        ${DbConstants.columnLogStackTrace} TEXT,
        ${DbConstants.columnLogServiceName} TEXT,
        ${DbConstants.columnLogApiProvider} TEXT,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // 创建邮箱配置表 (V5新增)
    AppLogger.d('[DatabaseService] 创建 email_configs 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableEmailConfigs} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        imap_server TEXT NOT NULL,
        imap_port INTEGER NOT NULL,
        password TEXT NOT NULL,
        is_enabled INTEGER DEFAULT 1,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // 创建AI模型配置表 (V6新增)
    AppLogger.d('[DatabaseService] 创建 ai_models 表');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableAIModels} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        provider TEXT NOT NULL,
        model_name TEXT NOT NULL,
        encrypted_api_key TEXT NOT NULL,
        base_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(provider, model_name)
      )
    ''');

    // 创建年度预算表 (V7新增)
    AppLogger.d('[DatabaseService] 创建 annual_budgets 表');
    await db.execute('''\n      CREATE TABLE ${DbConstants.tableAnnualBudgets} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnAnnualBudgetFamilyId} INTEGER NOT NULL,
        ${DbConstants.columnAnnualBudgetCategoryId} INTEGER NOT NULL,
        ${DbConstants.columnAnnualBudgetYear} INTEGER NOT NULL,
        ${DbConstants.columnAnnualBudgetType} TEXT NOT NULL DEFAULT 'expense',
        ${DbConstants.columnAnnualBudgetAnnualAmount} REAL NOT NULL,
        ${DbConstants.columnAnnualBudgetMonthlyAmount} REAL NOT NULL,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
        UNIQUE(${DbConstants.columnAnnualBudgetFamilyId}, ${DbConstants.columnAnnualBudgetCategoryId}, ${DbConstants.columnAnnualBudgetYear}),
        FOREIGN KEY (${DbConstants.columnAnnualBudgetFamilyId}) REFERENCES ${DbConstants.tableFamilyGroups}(${DbConstants.columnId}) ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.columnAnnualBudgetCategoryId}) REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    AppLogger.d('[DatabaseService] 创建数据库索引');
    await _createIndexes(db);

    // 初始化预设分类数据
    AppLogger.d('[DatabaseService] 初始化预设分类数据');
    await PresetCategoryData.initialize(db);

    AppLogger.i('[DatabaseService] 数据库表创建完成');
  }

  /// 创建索引
  Future<void> _createIndexes(Database db) async {
    // 家庭成员表索引
    await db.execute(
      'CREATE INDEX idx_member_group ON ${DbConstants.tableFamilyMembers}(${DbConstants.columnMemberFamilyGroupId})',
    );

    // 账户表索引
    await db.execute(
      'CREATE INDEX idx_account_member ON ${DbConstants.tableAccounts}(${DbConstants.columnAccountMemberId})',
    );

    // 分类表索引
    await db.execute(
      'CREATE INDEX idx_category_parent ON ${DbConstants.tableCategories}(${DbConstants.columnCategoryParentId})',
    );
    await db.execute(
      'CREATE INDEX idx_category_type ON ${DbConstants.tableCategories}(${DbConstants.columnCategoryType})',
    );

    // 账单流水表索引
    await db.execute(
      'CREATE INDEX idx_transaction_account ON ${DbConstants.tableTransactions}(${DbConstants.columnTransactionAccountId})',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_category ON ${DbConstants.tableTransactions}(${DbConstants.columnTransactionCategoryId})',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_time ON ${DbConstants.tableTransactions}(${DbConstants.columnTransactionTime})',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_hash ON ${DbConstants.tableTransactions}(${DbConstants.columnTransactionHash})',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_type ON ${DbConstants.tableTransactions}(${DbConstants.columnTransactionType})',
    );

    // 分类规则表索引
    await db.execute(
      'CREATE INDEX idx_rule_keyword ON ${DbConstants.tableCategoryRules}(${DbConstants.columnRuleKeyword})',
    );
    await db.execute(
      'CREATE INDEX idx_rule_category ON ${DbConstants.tableCategoryRules}(${DbConstants.columnRuleCategoryId})',
    );
    await db.execute(
      'CREATE INDEX idx_rule_match_type ON ${DbConstants.tableCategoryRules}(${DbConstants.columnRuleMatchType})',
    );
    await db.execute(
      'CREATE INDEX idx_rule_counterparty ON ${DbConstants.tableCategoryRules}(${DbConstants.columnRuleCounterparty})',
    );
    await db.execute(
      'CREATE INDEX idx_rule_priority ON ${DbConstants.tableCategoryRules}(${DbConstants.columnRulePriority} DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_counterparty ON ${DbConstants.tableTransactions}(${DbConstants.columnTransactionCounterparty})',
    );

    // 年度预算表索引
    await db.execute(
      'CREATE INDEX idx_annual_budget_family ON ${DbConstants.tableAnnualBudgets}(${DbConstants.columnAnnualBudgetFamilyId})',
    );
    await db.execute(
      'CREATE INDEX idx_annual_budget_category ON ${DbConstants.tableAnnualBudgets}(${DbConstants.columnAnnualBudgetCategoryId})',
    );
    await db.execute(
      'CREATE INDEX idx_annual_budget_year ON ${DbConstants.tableAnnualBudgets}(${DbConstants.columnAnnualBudgetYear})',
    );
    await db.execute(
      'CREATE INDEX idx_annual_budget_type ON ${DbConstants.tableAnnualBudgets}(${DbConstants.columnAnnualBudgetType})',
    );

    // HTTP日志表索引
    await db.execute(
      'CREATE INDEX idx_http_log_request_id ON ${DbConstants.tableHttpLogs}(${DbConstants.columnLogRequestId})',
    );
    await db.execute(
      'CREATE INDEX idx_http_log_created_at ON ${DbConstants.tableHttpLogs}(${DbConstants.columnCreatedAt} DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_http_log_service ON ${DbConstants.tableHttpLogs}(${DbConstants.columnLogServiceName})',
    );
    await db.execute(
      'CREATE INDEX idx_http_log_status ON ${DbConstants.tableHttpLogs}(${DbConstants.columnLogStatusCode})',
    );
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 确保 app_settings 表存在（对所有旧版本）
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableAppSettings} (
        ${DbConstants.columnSettingKey} TEXT PRIMARY KEY,
        ${DbConstants.columnSettingValue} TEXT NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // V2升级：为transactions表添加交易对方字段
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE ${DbConstants.tableTransactions}
        ADD COLUMN ${DbConstants.columnTransactionCounterparty} TEXT DEFAULT NULL
      ''');

      // 创建索引以优化查询性能
      await db.execute('''
        CREATE INDEX idx_transaction_counterparty
        ON ${DbConstants.tableTransactions}(${DbConstants.columnTransactionCounterparty})
      ''');
    }

    // V3升级：为category_rules表添加增强分类匹配字段
    if (oldVersion < 3) {
      // 添加新字段
      await db.execute('''
        ALTER TABLE ${DbConstants.tableCategoryRules}
        ADD COLUMN ${DbConstants.columnRuleMatchType} TEXT DEFAULT 'exact'
      ''');

      await db.execute('''
        ALTER TABLE ${DbConstants.tableCategoryRules}
        ADD COLUMN ${DbConstants.columnRuleMatchPosition} TEXT DEFAULT NULL
      ''');

      await db.execute('''
        ALTER TABLE ${DbConstants.tableCategoryRules}
        ADD COLUMN ${DbConstants.columnRuleMinConfidence} REAL DEFAULT 0.8
      ''');

      await db.execute('''
        ALTER TABLE ${DbConstants.tableCategoryRules}
        ADD COLUMN ${DbConstants.columnRuleCounterparty} TEXT DEFAULT NULL
      ''');

      await db.execute('''
        ALTER TABLE ${DbConstants.tableCategoryRules}
        ADD COLUMN ${DbConstants.columnRuleAliases} TEXT DEFAULT '[]'
      ''');

      await db.execute('''
        ALTER TABLE ${DbConstants.tableCategoryRules}
        ADD COLUMN ${DbConstants.columnRuleAutoLearn} INTEGER DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE ${DbConstants.tableCategoryRules}
        ADD COLUMN ${DbConstants.columnRuleCaseSensitive} INTEGER DEFAULT 0
      ''');

      // 创建新索引以优化查询性能
      await db.execute('''
        CREATE INDEX idx_rule_match_type
        ON ${DbConstants.tableCategoryRules}(${DbConstants.columnRuleMatchType})
      ''');

      await db.execute('''
        CREATE INDEX idx_rule_counterparty
        ON ${DbConstants.tableCategoryRules}(${DbConstants.columnRuleCounterparty})
      ''');

      await db.execute('''
        CREATE INDEX idx_rule_priority
        ON ${DbConstants.tableCategoryRules}(${DbConstants.columnRulePriority} DESC)
      ''');
    }

    // V4升级：添加HTTP日志表
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE ${DbConstants.tableHttpLogs} (
          ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${DbConstants.columnLogRequestId} TEXT NOT NULL UNIQUE,
          ${DbConstants.columnLogMethod} TEXT NOT NULL,
          ${DbConstants.columnLogUrl} TEXT NOT NULL,
          ${DbConstants.columnLogRequestHeaders} TEXT,
          ${DbConstants.columnLogRequestBody} TEXT,
          ${DbConstants.columnLogRequestSize} INTEGER,
          ${DbConstants.columnLogStatusCode} INTEGER,
          ${DbConstants.columnLogStatusMessage} TEXT,
          ${DbConstants.columnLogResponseHeaders} TEXT,
          ${DbConstants.columnLogResponseBody} TEXT,
          ${DbConstants.columnLogResponseSize} INTEGER,
          ${DbConstants.columnLogStartTime} INTEGER NOT NULL,
          ${DbConstants.columnLogEndTime} INTEGER,
          ${DbConstants.columnLogDurationMs} INTEGER,
          ${DbConstants.columnLogErrorType} TEXT,
          ${DbConstants.columnLogErrorMessage} TEXT,
          ${DbConstants.columnLogStackTrace} TEXT,
          ${DbConstants.columnLogServiceName} TEXT,
          ${DbConstants.columnLogApiProvider} TEXT,
          ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
          ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
        )
      ''');

      // 创建索引
      await db.execute('''
        CREATE INDEX idx_http_log_request_id
        ON ${DbConstants.tableHttpLogs}(${DbConstants.columnLogRequestId})
      ''');

      await db.execute('''
        CREATE INDEX idx_http_log_created_at
        ON ${DbConstants.tableHttpLogs}(${DbConstants.columnCreatedAt} DESC)
      ''');

      await db.execute('''
        CREATE INDEX idx_http_log_service
        ON ${DbConstants.tableHttpLogs}(${DbConstants.columnLogServiceName})
      ''');

      await db.execute('''
        CREATE INDEX idx_http_log_status
        ON ${DbConstants.tableHttpLogs}(${DbConstants.columnLogStatusCode})
      ''');
    }

    // V5升级：添加邮箱配置表
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE ${DbConstants.tableEmailConfigs} (
          ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL UNIQUE,
          imap_server TEXT NOT NULL,
          imap_port INTEGER NOT NULL,
          password TEXT NOT NULL,
          is_enabled INTEGER DEFAULT 1,
          ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
          ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
        )
      ''');
    }

    // V6升级：添加AI模型配置表
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE ${DbConstants.tableAIModels} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          provider TEXT NOT NULL,
          model_name TEXT NOT NULL,
          encrypted_api_key TEXT NOT NULL,
          base_url TEXT,
          is_active INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(provider, model_name)
        )
      ''');

      // 创建索引
      await db.execute('''
        CREATE INDEX idx_ai_models_provider
        ON ${DbConstants.tableAIModels}(provider)
      ''');

      await db.execute('''
        CREATE INDEX idx_ai_models_is_active
        ON ${DbConstants.tableAIModels}(is_active)
      ''');
    }

    // V7升级：添加年度预算表
    if (oldVersion < 7) {
      await db.execute('''\n        CREATE TABLE ${DbConstants.tableAnnualBudgets} (
          ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${DbConstants.columnAnnualBudgetFamilyId} INTEGER NOT NULL,
          ${DbConstants.columnAnnualBudgetCategoryId} INTEGER NOT NULL,
          ${DbConstants.columnAnnualBudgetYear} INTEGER NOT NULL,
          ${DbConstants.columnAnnualBudgetAnnualAmount} REAL NOT NULL,
          ${DbConstants.columnAnnualBudgetMonthlyAmount} REAL NOT NULL,
          ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
          ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
          UNIQUE(${DbConstants.columnAnnualBudgetFamilyId}, ${DbConstants.columnAnnualBudgetCategoryId}, ${DbConstants.columnAnnualBudgetYear}),
          FOREIGN KEY (${DbConstants.columnAnnualBudgetFamilyId}) REFERENCES ${DbConstants.tableFamilyGroups}(${DbConstants.columnId}) ON DELETE CASCADE,
          FOREIGN KEY (${DbConstants.columnAnnualBudgetCategoryId}) REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) ON DELETE CASCADE
        )
      ''');

      // 创建索引
      await db.execute('''\n        CREATE INDEX idx_annual_budget_family
        ON ${DbConstants.tableAnnualBudgets}(${DbConstants.columnAnnualBudgetFamilyId})
      ''');

      await db.execute('''\n        CREATE INDEX idx_annual_budget_category
        ON ${DbConstants.tableAnnualBudgets}(${DbConstants.columnAnnualBudgetCategoryId})
      ''');

      await db.execute('''\n        CREATE INDEX idx_annual_budget_year
        ON ${DbConstants.tableAnnualBudgets}(${DbConstants.columnAnnualBudgetYear})
      ''');
    }

    // V8升级：为annual_budgets表添加type字段
    if (oldVersion < 8) {
      await db.execute('''\n        ALTER TABLE ${DbConstants.tableAnnualBudgets}\n        ADD COLUMN ${DbConstants.columnAnnualBudgetType} TEXT NOT NULL DEFAULT 'expense'
      ''');

      // 创建索引以优化查询性能
      await db.execute('''\n        CREATE INDEX idx_annual_budget_type
        ON ${DbConstants.tableAnnualBudgets}(${DbConstants.columnAnnualBudgetType})
      ''');
    }

    // V9升级：删除未使用的budgets表
    if (oldVersion < 9) {
      // 删除budgets表（该表从未被使用，已被annual_budgets替代）
      await db.execute('DROP TABLE IF EXISTS budgets');
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 删除数据库(仅用于开发测试)
  Future<void> deleteDatabase() async {
    AppLogger.i('[DatabaseService] 🗑️ 开始删除数据库');

    try {
      // 关闭现有数据库连接
      if (_database != null) {
        AppLogger.d('[DatabaseService] 关闭现有数据库连接');
        await _database!.close();
        _database = null;
        AppLogger.d('[DatabaseService] 数据库连接已关闭');
      } else {
        AppLogger.d('[DatabaseService] 没有活动的数据库连接');
      }

      // 获取数据库路径
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, DbConstants.dbName);
      AppLogger.d('[DatabaseService] 数据库路径: $path');

      // 检查文件是否存在
      final dbFile = File(path);
      final exists = await dbFile.exists();
      AppLogger.d('[DatabaseService] 数据库文件存在: $exists');

      if (exists) {
        // 获取文件大小
        final fileSize = await dbFile.length();
        AppLogger.d('[DatabaseService] 数据库文件大小: $fileSize bytes');

        // 删除数据库文件
        AppLogger.d('[DatabaseService] 正在删除数据库文件...');
        await databaseFactory.deleteDatabase(path);
        AppLogger.i('[DatabaseService] ✅ 数据库文件已删除');

        // 再次确认文件已删除
        final stillExists = await dbFile.exists();
        if (stillExists) {
          AppLogger.w('[DatabaseService] ⚠️ 警告: 删除后文件仍然存在!');
        } else {
          AppLogger.d('[DatabaseService] 确认: 文件已成功删除');
        }
      } else {
        AppLogger.w('[DatabaseService] 数据库文件不存在，无需删除');
      }

      AppLogger.i('[DatabaseService] ✅ 数据库删除操作完成');
    } catch (e, stackTrace) {
      AppLogger.e('[DatabaseService] ❌ 删除数据库失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
