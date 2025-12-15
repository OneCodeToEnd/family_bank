import 'package:sqflite/sqflite.dart';
import '../../constants/db_constants.dart';

/// 预设分类数据服务
/// 负责初始化系统预设的分类树
class PresetCategoryData {
  /// 初始化预设分类数据
  static Future<void> initialize(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 检查是否已经初始化过
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbConstants.tableCategories}'),
    );
    if (count != null && count > 0) {
      return; // 已有数据，不重复初始化
    }

    // 收入类分类
    await _initIncomeCategories(db, now);

    // 支出类分类
    await _initExpenseCategories(db, now);
  }

  /// 初始化收入类分类
  static Future<void> _initIncomeCategories(Database db, int timestamp) async {
    // 一级分类：工资
    final salaryId = await db.insert(DbConstants.tableCategories, {
      'name': '工资',
      'type': 'income',
      'icon': 'work',
      'color': '#4CAF50',
      'is_system': 1,
      'sort_order': 1,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 二级分类：工资下的子分类
    await db.insert(DbConstants.tableCategories, {
      'parent_id': salaryId,
      'name': '主业工资',
      'type': 'income',
      'icon': 'work',
      'is_system': 1,
      'sort_order': 1,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': salaryId,
      'name': '副业工资',
      'type': 'income',
      'icon': 'work_outline',
      'is_system': 1,
      'sort_order': 2,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 一级分类：兼职
    await db.insert(DbConstants.tableCategories, {
      'name': '兼职',
      'type': 'income',
      'icon': 'part_time',
      'color': '#8BC34A',
      'is_system': 1,
      'sort_order': 2,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 一级分类：投资收益
    final investmentId = await db.insert(DbConstants.tableCategories, {
      'name': '投资收益',
      'type': 'income',
      'icon': 'trending_up',
      'color': '#FFC107',
      'is_system': 1,
      'sort_order': 3,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': investmentId,
      'name': '股票',
      'type': 'income',
      'icon': 'show_chart',
      'is_system': 1,
      'sort_order': 1,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': investmentId,
      'name': '基金',
      'type': 'income',
      'icon': 'account_balance',
      'is_system': 1,
      'sort_order': 2,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': investmentId,
      'name': '理财',
      'type': 'income',
      'icon': 'savings',
      'is_system': 1,
      'sort_order': 3,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 一级分类：礼金
    await db.insert(DbConstants.tableCategories, {
      'name': '礼金',
      'type': 'income',
      'icon': 'card_giftcard',
      'color': '#FF5722',
      'is_system': 1,
      'sort_order': 4,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 一级分类：其他收入
    await db.insert(DbConstants.tableCategories, {
      'name': '其他收入',
      'type': 'income',
      'icon': 'more_horiz',
      'color': '#9E9E9E',
      'is_system': 1,
      'sort_order': 5,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
  }

  /// 初始化支出类分类
  static Future<void> _initExpenseCategories(Database db, int timestamp) async {
    // 一级分类：固定支出
    final fixedId = await db.insert(DbConstants.tableCategories, {
      'name': '固定支出',
      'type': 'expense',
      'icon': 'event_repeat',
      'color': '#F44336',
      'is_system': 1,
      'sort_order': 1,
      'tags': '["必要支出"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': fixedId,
      'name': '房租/房贷',
      'type': 'expense',
      'icon': 'home',
      'is_system': 1,
      'sort_order': 1,
      'tags': '["必要支出"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': fixedId,
      'name': '水电燃气',
      'type': 'expense',
      'icon': 'water_drop',
      'is_system': 1,
      'sort_order': 2,
      'tags': '["必要支出"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': fixedId,
      'name': '通讯费',
      'type': 'expense',
      'icon': 'phone',
      'is_system': 1,
      'sort_order': 3,
      'tags': '["必要支出"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': fixedId,
      'name': '保险',
      'type': 'expense',
      'icon': 'security',
      'is_system': 1,
      'sort_order': 4,
      'tags': '["必要支出"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 一级分类：日常消费
    final dailyId = await db.insert(DbConstants.tableCategories, {
      'name': '日常消费',
      'type': 'expense',
      'icon': 'shopping_cart',
      'color': '#2196F3',
      'is_system': 1,
      'sort_order': 2,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 餐饮
    final foodId = await db.insert(DbConstants.tableCategories, {
      'parent_id': dailyId,
      'name': '餐饮',
      'type': 'expense',
      'icon': 'restaurant',
      'is_system': 1,
      'sort_order': 1,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': foodId,
      'name': '早餐',
      'type': 'expense',
      'icon': 'breakfast_dining',
      'is_system': 1,
      'sort_order': 1,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': foodId,
      'name': '午餐',
      'type': 'expense',
      'icon': 'lunch_dining',
      'is_system': 1,
      'sort_order': 2,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': foodId,
      'name': '晚餐',
      'type': 'expense',
      'icon': 'dinner_dining',
      'is_system': 1,
      'sort_order': 3,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': foodId,
      'name': '咖啡饮品',
      'type': 'expense',
      'icon': 'local_cafe',
      'is_system': 1,
      'sort_order': 4,
      'tags': '["可选消费"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': foodId,
      'name': '外卖',
      'type': 'expense',
      'icon': 'delivery_dining',
      'is_system': 1,
      'sort_order': 5,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 交通
    final transportId = await db.insert(DbConstants.tableCategories, {
      'parent_id': dailyId,
      'name': '交通',
      'type': 'expense',
      'icon': 'directions_car',
      'is_system': 1,
      'sort_order': 2,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': transportId,
      'name': '公共交通',
      'type': 'expense',
      'icon': 'directions_bus',
      'is_system': 1,
      'sort_order': 1,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': transportId,
      'name': '打车',
      'type': 'expense',
      'icon': 'local_taxi',
      'is_system': 1,
      'sort_order': 2,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': transportId,
      'name': '加油',
      'type': 'expense',
      'icon': 'local_gas_station',
      'is_system': 1,
      'sort_order': 3,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': transportId,
      'name': '停车费',
      'type': 'expense',
      'icon': 'local_parking',
      'is_system': 1,
      'sort_order': 4,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 购物
    final shoppingId = await db.insert(DbConstants.tableCategories, {
      'parent_id': dailyId,
      'name': '购物',
      'type': 'expense',
      'icon': 'shopping_bag',
      'is_system': 1,
      'sort_order': 3,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': shoppingId,
      'name': '服饰',
      'type': 'expense',
      'icon': 'checkroom',
      'is_system': 1,
      'sort_order': 1,
      'tags': '["可选消费"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': shoppingId,
      'name': '美妆',
      'type': 'expense',
      'icon': 'face',
      'is_system': 1,
      'sort_order': 2,
      'tags': '["可选消费"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': shoppingId,
      'name': '日用品',
      'type': 'expense',
      'icon': 'shopping_basket',
      'is_system': 1,
      'sort_order': 3,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 生鲜果蔬
    await db.insert(DbConstants.tableCategories, {
      'parent_id': dailyId,
      'name': '生鲜果蔬',
      'type': 'expense',
      'icon': 'local_grocery_store',
      'is_system': 1,
      'sort_order': 4,
      'tags': '["必要支出"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 一级分类：非日常消费
    final nonDailyId = await db.insert(DbConstants.tableCategories, {
      'name': '非日常消费',
      'type': 'expense',
      'icon': 'event',
      'color': '#9C27B0',
      'is_system': 1,
      'sort_order': 3,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': nonDailyId,
      'name': '医疗',
      'type': 'expense',
      'icon': 'local_hospital',
      'is_system': 1,
      'sort_order': 1,
      'tags': '["必要支出"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': nonDailyId,
      'name': '教育',
      'type': 'expense',
      'icon': 'school',
      'is_system': 1,
      'sort_order': 2,
      'tags': '["必要支出"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 娱乐
    final entertainmentId = await db.insert(DbConstants.tableCategories, {
      'parent_id': nonDailyId,
      'name': '娱乐',
      'type': 'expense',
      'icon': 'theaters',
      'is_system': 1,
      'sort_order': 3,
      'tags': '["可选消费"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': entertainmentId,
      'name': '电影',
      'type': 'expense',
      'icon': 'movie',
      'is_system': 1,
      'sort_order': 1,
      'tags': '["可选消费"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': entertainmentId,
      'name': '游戏',
      'type': 'expense',
      'icon': 'sports_esports',
      'is_system': 1,
      'sort_order': 2,
      'tags': '["可选消费"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': entertainmentId,
      'name': '旅游',
      'type': 'expense',
      'icon': 'flight',
      'is_system': 1,
      'sort_order': 3,
      'tags': '["可选消费"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': nonDailyId,
      'name': '人情往来',
      'type': 'expense',
      'icon': 'groups',
      'is_system': 1,
      'sort_order': 4,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': nonDailyId,
      'name': '运动健身',
      'type': 'expense',
      'icon': 'fitness_center',
      'is_system': 1,
      'sort_order': 5,
      'tags': '["可选消费"]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    // 一级分类：其他支出
    await db.insert(DbConstants.tableCategories, {
      'name': '其他支出',
      'type': 'expense',
      'icon': 'more_horiz',
      'color': '#607D8B',
      'is_system': 1,
      'sort_order': 4,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
  }
}
