import 'package:flutter/material.dart';

/// 分类图标和颜色工具类
class CategoryIconUtils {
  /// 将图标名称映射为 IconData
  static IconData getIconData(String iconName) {
    final iconMap = {
      'work': Icons.work,
      'work_outline': Icons.work_outline,
      'part_time': Icons.access_time,
      'trending_up': Icons.trending_up,
      'show_chart': Icons.show_chart,
      'account_balance': Icons.account_balance,
      'savings': Icons.savings,
      'card_giftcard': Icons.card_giftcard,
      'more_horiz': Icons.more_horiz,
      'event_repeat': Icons.event_repeat,
      'home': Icons.home,
      'water_drop': Icons.water_drop,
      'phone': Icons.phone,
      'security': Icons.security,
      'shopping_cart': Icons.shopping_cart,
      'restaurant': Icons.restaurant,
      'restaurant_menu': Icons.restaurant_menu,
      'local_cafe': Icons.local_cafe,
      'delivery_dining': Icons.delivery_dining,
      'directions_car': Icons.directions_car,
      'directions_bus': Icons.directions_bus,
      'local_taxi': Icons.local_taxi,
      'local_gas_station': Icons.local_gas_station,
      'local_parking': Icons.local_parking,
      'shopping_bag': Icons.shopping_bag,
      'checkroom': Icons.checkroom,
      'face': Icons.face,
      'shopping_basket': Icons.shopping_basket,
      'local_grocery_store': Icons.local_grocery_store,
      'event': Icons.event,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'theaters': Icons.theaters,
      'movie': Icons.movie,
      'sports_esports': Icons.sports_esports,
      'flight': Icons.flight,
      'groups': Icons.groups,
      'fitness_center': Icons.fitness_center,
    };

    return iconMap[iconName] ?? Icons.category;
  }

  /// 解析颜色字符串
  static Color getColor(String? colorString) {
    if (colorString == null) return Colors.grey;

    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('0xFF${colorString.substring(1)}'));
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.grey;
    }
  }
}
