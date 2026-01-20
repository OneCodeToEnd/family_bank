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
      'color': '#66BB6A',
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
      'color': '#81C784',
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
      'color': '#FFD54F',
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
      'color': '#FFE082',
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
      'color': '#FFECB3',
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
      'color': '#EF5350',
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
      'color': '#E57373',
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
      'color': '#EF9A9A',
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
      'color': '#FFCDD2',
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
      'color': '#42A5F5',
      'is_system': 1,
      'sort_order': 1,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': foodId,
      'name': '一日三餐',
      'type': 'expense',
      'icon': 'restaurant_menu',
      'color': '#64B5F6',
      'is_system': 1,
      'sort_order': 1,
      'tags': '[]',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await db.insert(DbConstants.tableCategories, {
      'parent_id': foodId,
      'name': '咖啡饮品',
      'type': 'expense',
      'icon': 'local_cafe',
      'color': '#90CAF9',
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
      'color': '#BBDEFB',
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
      'color': '#29B6F6',
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
      'color': '#4FC3F7',
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
      'color': '#81D4FA',
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
      'color': '#B3E5FC',
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
      'color': '#E1F5FE',
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
      'color': '#26C6DA',
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
      'color': '#4DD0E1',
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
      'color': '#80DEEA',
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
      'color': '#B2EBF2',
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
      'color': '#00ACC1',
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
      'color': '#AB47BC',
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
      'color': '#BA68C8',
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
      'color': '#CE93D8',
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
      'color': '#E1BEE7',
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
      'color': '#F3E5F5',
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
      'color': '#EA80FC',
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
      'color': '#D500F9',
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
      'color': '#AA00FF',
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
