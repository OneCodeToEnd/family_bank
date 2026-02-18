import 'dart:convert';
import '../../database/database_service.dart';
import '../../database/agent_memory_db_service.dart';
import '../../../models/agent_memory.dart';
import '../../../utils/app_logger.dart';
import 'agent_tool.dart';

/// 敏感表列表（不暴露给 AI）
const _sensitiveTables = [
  'ai_models',
  'email_configs',
  'app_settings',
  'http_logs',
  'agent_memories',
  'chat_sessions',
];

/// SQL 黑名单关键词
const _sqlBlacklist = [
  'INSERT',
  'UPDATE',
  'DELETE',
  'DROP',
  'ALTER',
  'CREATE',
  'ATTACH',
  'PRAGMA',
  'REPLACE',
  'TRUNCATE',
];

/// 业务表中文描述
const _tableDescriptions = {
  'families': '家庭信息表',
  'family_members': '家庭成员表',
  'accounts': '账户表（银行卡、现金等）',
  'categories': '收支分类表（支持多级分类，parentId关联父分类）',
  'transactions': '交易记录表（核心表，amount为正数，type区分income/expense）',
  'annual_budgets': '年度预算表',
  'category_rules': '分类规则表（自动分类匹配规则）',
  'counterparties': '交易对手方表',
  'counterparty_groups': '对手方分组表',
};

/// 允许查询的表名白名单
List<String> get _allowedTables => _tableDescriptions.keys.toList();

/// 创建数据库工具列表
List<AgentTool> createDatabaseTools() {
  final dbService = DatabaseService();

  return [
    _createGetTablesTool(dbService),
    _createGetTableSchemaTool(dbService),
    _createExecuteSqlTool(dbService),
    _createSaveMemoryTool(),
  ];
}

AgentTool _createGetTablesTool(DatabaseService dbService) {
  return AgentTool(
    name: 'get_tables',
    description: '获取数据库中所有业务表的名称和中文描述',
    parameters: {
      'type': 'object',
      'properties': {},
      'required': [],
    },
    execute: (params) async {
      final result = _tableDescriptions.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      return result;
    },
  );
}

AgentTool _createGetTableSchemaTool(DatabaseService dbService) {
  return AgentTool(
    name: 'get_table_schema',
    description: '获取指定表的建表语句（DDL），了解表结构和字段',
    parameters: {
      'type': 'object',
      'properties': {
        'table_name': {
          'type': 'string',
          'description': '表名',
        },
      },
      'required': ['table_name'],
    },
    execute: (params) async {
      final tableName = params['table_name'] as String;

      // 白名单校验
      if (!_allowedTables.contains(tableName)) {
        return '错误：不允许查询表 "$tableName" 的结构';
      }

      try {
        final db = await dbService.database;
        final result = await db.rawQuery(
          "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );
        if (result.isEmpty) {
          return '表 "$tableName" 不存在';
        }
        return result.first['sql'] as String;
      } catch (e) {
        AppLogger.e('get_table_schema failed', error: e);
        return '查询表结构失败: $e';
      }
    },
  );
}

AgentTool _createExecuteSqlTool(DatabaseService dbService) {
  return AgentTool(
    name: 'execute_sql',
    description: '执行只读SQL查询，仅支持SELECT语句。注意：transactions表中amount为正数，type字段区分收支(income/expense)，时间字段date为毫秒时间戳',
    parameters: {
      'type': 'object',
      'properties': {
        'sql': {
          'type': 'string',
          'description': 'SELECT SQL语句',
        },
      },
      'required': ['sql'],
    },
    execute: (params) async {
      final sql = (params['sql'] as String).trim();

      // 安全校验
      final validation = _validateSql(sql);
      if (validation != null) return validation;

      try {
        final db = await dbService.database;
        final results = await db.rawQuery(sql);

        // 限制结果行数
        final limited = results.take(50).toList();
        final jsonStr = jsonEncode(limited);

        // 限制字符数
        if (jsonStr.length > 4000) {
          return '${jsonStr.substring(0, 4000)}\n... (结果已截断，共${results.length}行)';
        }

        if (limited.length < results.length) {
          return '$jsonStr\n(显示前50行，共${results.length}行)';
        }

        return jsonStr;
      } catch (e) {
        AppLogger.e('execute_sql failed', error: e);
        return '执行SQL失败: $e';
      }
    },
  );
}

AgentTool _createSaveMemoryTool() {
  return AgentTool(
    name: 'save_memory',
    description: '保存用户要求记住的信息，当用户说"记住..."、"以后..."、"请注意..."时调用',
    parameters: {
      'type': 'object',
      'properties': {
        'content': {
          'type': 'string',
          'description': '要记住的内容',
        },
        'related_query': {
          'type': 'string',
          'description': '对用户核心问题的简短概括，不超过30字',
        },
      },
      'required': ['content'],
    },
    execute: (params) async {
      final content = params['content'] as String;
      if (content.length > 500) return '内容过长，最多500字符';
      final relatedQuery = params['related_query'] as String?;
      try {
        await AgentMemoryDbService().save(AgentMemory(
          type: 'note',
          content: content,
          relatedQuery: relatedQuery,
          createdAt: DateTime.now(),
        ));
        return '已记住';
      } catch (e) {
        AppLogger.e('save_memory failed', error: e);
        return '保存失败: $e';
      }
    },
  );
}

/// 校验 SQL 安全性，返回 null 表示通过
String? _validateSql(String sql) {
  final upper = sql.toUpperCase().trimLeft();

  // 白名单：仅允许 SELECT / WITH 开头
  if (!upper.startsWith('SELECT') && !upper.startsWith('WITH')) {
    return '错误：仅允许 SELECT 查询';
  }

  // 黑名单：拦截 DML/DDL 关键词
  for (final keyword in _sqlBlacklist) {
    // 使用单词边界匹配，避免误伤列名
    if (RegExp('\\b$keyword\\b', caseSensitive: false).hasMatch(sql)) {
      return '错误：SQL 中包含不允许的操作: $keyword';
    }
  }

  // 检查是否引用了敏感表
  for (final table in _sensitiveTables) {
    if (RegExp('\\b$table\\b', caseSensitive: false).hasMatch(sql)) {
      return '错误：不允许查询敏感表: $table';
    }
  }

  return null;
}
