import 'package:sqflite/sqflite.dart';
import '../../models/category.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';

/// 分类数据库操作服务
class CategoryDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 创建分类
  Future<int> createCategory(Category category) async {
    final db = await _dbService.database;
    return await db.insert(
      DbConstants.tableCategories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有分类
  Future<List<Category>> getAllCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      orderBy: '${DbConstants.columnCategorySortOrder} ASC, ${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 获取所有未隐藏的分类
  Future<List<Category>> getVisibleCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.columnCategoryIsHidden} = ?',
      whereArgs: [0],
      orderBy: '${DbConstants.columnCategorySortOrder} ASC, ${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 根据ID获取分类
  Future<Category?> getCategoryById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  /// 根据类型获取分类（收入/支出）
  Future<List<Category>> getCategoriesByType(String type) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.columnCategoryType} = ?',
      whereArgs: [type],
      orderBy: '${DbConstants.columnCategorySortOrder} ASC, ${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 获取一级分类（父分类）
  Future<List<Category>> getTopLevelCategories({String? type}) async {
    final db = await _dbService.database;

    String? whereClause = '${DbConstants.columnCategoryParentId} IS NULL';
    List<dynamic>? whereArgs;

    if (type != null) {
      whereClause += ' AND ${DbConstants.columnCategoryType} = ?';
      whereArgs = [type];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DbConstants.columnCategorySortOrder} ASC, ${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 获取子分类
  Future<List<Category>> getSubCategories(int parentId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.columnCategoryParentId} = ?',
      whereArgs: [parentId],
      orderBy: '${DbConstants.columnCategorySortOrder} ASC, ${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 获取分类树（包含子分类）
  Future<List<Map<String, dynamic>>> getCategoryTree({String? type}) async {
    // 获取一级分类
    final topCategories = await getTopLevelCategories(type: type);

    List<Map<String, dynamic>> tree = [];

    for (var parent in topCategories) {
      if (parent.id == null) continue;

      // 获取子分类
      final children = await getSubCategories(parent.id!);

      tree.add({
        'category': parent,
        'children': children,
        'childCount': children.length,
      });
    }

    return tree;
  }

  /// 更新分类
  Future<int> updateCategory(Category category) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableCategories,
      category.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [category.id],
    );
  }

  /// 删除分类
  /// 注意：如果是一级分类，会自动删除所有子分类（数据库外键级联）
  Future<int> deleteCategory(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableCategories,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 切换分类隐藏状态
  Future<int> toggleCategoryVisibility(int id, bool isHidden) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableCategories,
      {
        DbConstants.columnCategoryIsHidden: isHidden ? 1 : 0,
        DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 批量更新分类排序
  Future<void> updateCategorySortOrder(Map<int, int> sortOrders) async {
    final db = await _dbService.database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var entry in sortOrders.entries) {
      batch.update(
        DbConstants.tableCategories,
        {
          DbConstants.columnCategorySortOrder: entry.value,
          DbConstants.columnUpdatedAt: now,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: [entry.key],
      );
    }

    await batch.commit(noResult: true);
  }

  /// 检查分类名称是否已存在（同一父分类下）
  Future<bool> isCategoryNameExists(
    String name,
    String type, {
    int? parentId,
    int? excludeId,
  }) async {
    final db = await _dbService.database;

    String whereClause = '${DbConstants.columnCategoryName} = ? AND ${DbConstants.columnCategoryType} = ?';
    List<dynamic> whereArgs = [name, type];

    if (parentId != null) {
      whereClause += ' AND ${DbConstants.columnCategoryParentId} = ?';
      whereArgs.add(parentId);
    } else {
      whereClause += ' AND ${DbConstants.columnCategoryParentId} IS NULL';
    }

    if (excludeId != null) {
      whereClause += ' AND ${DbConstants.columnId} != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      DbConstants.tableCategories,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// 获取系统预设分类
  Future<List<Category>> getSystemCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.columnCategoryIsSystem} = ?',
      whereArgs: [1],
      orderBy: '${DbConstants.columnCategorySortOrder} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 获取用户自定义分类
  Future<List<Category>> getUserCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.columnCategoryIsSystem} = ?',
      whereArgs: [0],
      orderBy: '${DbConstants.columnCategorySortOrder} ASC, ${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 根据标签搜索分类
  Future<List<Category>> searchCategoriesByTag(String tag) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.columnCategoryTags} LIKE ?',
      whereArgs: ['%"$tag"%'],
      orderBy: '${DbConstants.columnCategorySortOrder} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 根据名称搜索分类
  Future<List<Category>> searchCategoriesByName(String keyword) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.columnCategoryName} LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: '${DbConstants.columnCategorySortOrder} ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  /// 获取分类统计信息（关联的账单数量和总金额）
  Future<Map<String, dynamic>> getCategoryStatistics(int categoryId) async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as transaction_count,
        SUM(${DbConstants.columnTransactionAmount}) as total_amount
      FROM ${DbConstants.tableTransactions}
      WHERE ${DbConstants.columnTransactionCategoryId} = ?
    ''', [categoryId]);

    if (result.isEmpty) {
      return {
        'transaction_count': 0,
        'total_amount': 0.0,
      };
    }

    final data = result.first;
    return {
      'transaction_count': data['transaction_count'] ?? 0,
      'total_amount': (data['total_amount'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// 批量创建分类
  Future<List<int>> createCategoriesBatch(List<Category> categories) async {
    final db = await _dbService.database;
    final batch = db.batch();

    for (var category in categories) {
      batch.insert(
        DbConstants.tableCategories,
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }
}
