import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../constants/db_constants.dart';
import 'preset_category_data.dart';

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
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DbConstants.dbName);

    return await openDatabase(
      path,
      version: DbConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建家庭组表
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
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.columnTransactionAccountId})
          REFERENCES ${DbConstants.tableAccounts}(${DbConstants.columnId}) ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.columnTransactionCategoryId})
          REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) ON DELETE SET NULL
      )
    ''');

    // 创建分类规则表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCategoryRules} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnRuleKeyword} TEXT NOT NULL,
        ${DbConstants.columnRuleCategoryId} INTEGER NOT NULL,
        ${DbConstants.columnRulePriority} INTEGER DEFAULT 0,
        ${DbConstants.columnRuleIsActive} INTEGER DEFAULT 1,
        ${DbConstants.columnRuleMatchCount} INTEGER DEFAULT 0,
        ${DbConstants.columnRuleSource} TEXT DEFAULT 'user',
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.columnRuleCategoryId})
          REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) ON DELETE CASCADE
      )
    ''');

    // 创建预算表 (V3.0功能,先创建表结构)
    await db.execute('''
      CREATE TABLE ${DbConstants.tableBudgets} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnBudgetTargetType} TEXT NOT NULL,
        ${DbConstants.columnBudgetTargetId} INTEGER NOT NULL,
        ${DbConstants.columnBudgetAmount} REAL NOT NULL,
        ${DbConstants.columnBudgetPeriod} TEXT NOT NULL,
        ${DbConstants.columnBudgetStartDate} INTEGER NOT NULL,
        ${DbConstants.columnBudgetEndDate} INTEGER,
        ${DbConstants.columnBudgetIsActive} INTEGER DEFAULT 1,
        ${DbConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // 创建应用设置表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableAppSettings} (
        ${DbConstants.columnSettingKey} TEXT PRIMARY KEY,
        ${DbConstants.columnSettingValue} TEXT NOT NULL,
        ${DbConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // 创建索引
    await _createIndexes(db);

    // 初始化预设分类数据
    await PresetCategoryData.initialize(db);
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

    // 预算表索引
    await db.execute(
      'CREATE INDEX idx_budget_target ON ${DbConstants.tableBudgets}(${DbConstants.columnBudgetTargetType}, ${DbConstants.columnBudgetTargetId})',
    );
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级逻辑
    // if (oldVersion < 2) {
    //   // 执行V2版本的升级脚本
    // }
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 删除数据库(仅用于开发测试)
  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DbConstants.dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
