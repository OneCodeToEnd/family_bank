import 'package:flutter/material.dart';
import '../models/quick_action.dart';

/// 快捷操作常量定义
/// 包含所有可用的预设快捷操作
class QuickActionConstants {
  // 操作ID常量
  static const String idAccountList = 'account_list';
  static const String idCategoryList = 'category_list';
  static const String idBillImport = 'bill_import';
  static const String idAnalysis = 'analysis';
  static const String idMemberList = 'member_list';
  static const String idAiSettings = 'ai_settings';
  static const String idCategoryRules = 'category_rules';
  static const String idEmailSync = 'email_sync';
  static const String idTransactionList = 'transaction_list';
  static const String idAddTransaction = 'add_transaction';
  static const String idBudgetManagement = 'budget_management';
  static const String idCounterpartyManagement = 'counterparty_management';

  // 默认快捷操作ID列表（首次启动时使用）
  static const List<String> defaultActionIds = [
    idAccountList,
    idCategoryList,
    idBillImport,
    idAnalysis,
    idAddTransaction,
    idTransactionList,
  ];

  // 约束条件
  static const int minActions = 4; // 最少快捷操作数量
  static const int maxActions = 8; // 最多快捷操作数量

  // 所有可用的快捷操作
  static final List<QuickAction> allActions = [
    const QuickAction(
      id: idAccountList,
      name: '账户管理',
      icon: Icons.account_balance_wallet,
      routeName: 'AccountListScreen',
      sortOrder: 0,
    ),
    const QuickAction(
      id: idCategoryList,
      name: '分类管理',
      icon: Icons.category,
      routeName: 'CategoryListScreen',
      sortOrder: 1,
    ),
    const QuickAction(
      id: idBillImport,
      name: '导入账单',
      icon: Icons.file_upload,
      routeName: 'BillImportScreen',
      sortOrder: 2,
    ),
    const QuickAction(
      id: idAnalysis,
      name: '数据分析',
      icon: Icons.analytics,
      routeName: 'AnalysisScreen',
      sortOrder: 3,
    ),
    const QuickAction(
      id: idAddTransaction,
      name: '记一笔',
      icon: Icons.add_circle_outline,
      routeName: 'TransactionFormScreen',
      sortOrder: 4,
    ),
    const QuickAction(
      id: idTransactionList,
      name: '账单列表',
      icon: Icons.receipt_long,
      routeName: 'TransactionListScreen',
      sortOrder: 5,
    ),
    const QuickAction(
      id: idMemberList,
      name: '家庭成员',
      icon: Icons.people,
      routeName: 'MemberListScreen',
      sortOrder: 6,
    ),
    const QuickAction(
      id: idAiSettings,
      name: 'AI设置',
      icon: Icons.smart_toy,
      routeName: 'AISettingsScreen',
      sortOrder: 7,
    ),
    const QuickAction(
      id: idCategoryRules,
      name: '分类规则',
      icon: Icons.rule,
      routeName: 'CategoryRuleListScreen',
      sortOrder: 8,
    ),
    const QuickAction(
      id: idEmailSync,
      name: '邮箱同步',
      icon: Icons.email,
      routeName: 'EmailBillSelectScreen',
      sortOrder: 9,
    ),
    const QuickAction(
      id: idBudgetManagement,
      name: '预算管理',
      icon: Icons.account_balance,
      routeName: 'BudgetOverviewScreen',
      sortOrder: 10,
    ),
    const QuickAction(
      id: idCounterpartyManagement,
      name: '对手方管理',
      icon: Icons.people_alt,
      routeName: 'CounterpartyManagementScreen',
      sortOrder: 11,
    ),
  ];

  /// 根据ID获取快捷操作
  static QuickAction? getActionById(String id) {
    try {
      return allActions.firstWhere((action) => action.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取默认快捷操作列表
  static List<QuickAction> getDefaultActions() {
    return defaultActionIds
        .map((id) => getActionById(id))
        .whereType<QuickAction>()
        .toList();
  }
}
