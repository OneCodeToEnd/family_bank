import 'package:flutter/material.dart';

/// 应用自定义颜色扩展
///
/// 使用 ThemeExtension 机制扩展主题，提供语义化的颜色定义
/// 自动适配浅色/深色模式
///
/// 使用方式：
/// ```dart
/// final appColors = Theme.of(context).extension<AppColors>()!;
/// color: appColors.successColor
/// ```
class AppColors extends ThemeExtension<AppColors> {
  /// 成功状态颜色（用于验证通过、操作成功等）
  final Color successColor;

  /// 成功状态的容器背景色
  final Color successContainer;

  /// 成功状态的文字/图标颜色
  final Color onSuccessContainer;

  /// 警告状态颜色（用于轻微问题、需要注意等）
  final Color warningColor;

  /// 警告状态的容器背景色
  final Color warningContainer;

  /// 警告状态的文字/图标颜色
  final Color onWarningContainer;

  /// 信息提示颜色（用于提示、说明等）
  final Color infoColor;

  /// 信息提示的容器背景色
  final Color infoContainer;

  /// 信息提示的文字/图标颜色
  final Color onInfoContainer;

  const AppColors({
    required this.successColor,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warningColor,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.infoColor,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  /// 浅色模式的颜色配置
  static const light = AppColors(
    // 成功色 - 绿色系
    successColor: Color(0xFF2E7D32), // Colors.green.shade700
    successContainer: Color(0xFFE8F5E9), // Colors.green.shade50
    onSuccessContainer: Color(0xFF1B5E20), // Colors.green.shade900

    // 警告色 - 橙色系
    warningColor: Color(0xFFE65100), // Colors.orange.shade700
    warningContainer: Color(0xFFFFF3E0), // Colors.orange.shade50
    onWarningContainer: Color(0xFFE65100), // Colors.orange.shade700

    // 信息色 - 蓝色系
    infoColor: Color(0xFF1976D2), // Colors.blue.shade700
    infoContainer: Color(0xFFE3F2FD), // Colors.blue.shade50
    onInfoContainer: Color(0xFF0D47A1), // Colors.blue.shade900
  );

  /// 深色模式的颜色配置
  static const dark = AppColors(
    // 成功色 - 绿色系（深色模式使用较浅的颜色）
    successColor: Color(0xFF81C784), // Colors.green.shade300
    successContainer: Color(0xFF1B5E20), // Colors.green.shade900 with opacity
    onSuccessContainer: Color(0xFFC8E6C9), // Colors.green.shade100

    // 警告色 - 橙色系
    warningColor: Color(0xFFFFB74D), // Colors.orange.shade300
    warningContainer: Color(0xFFE65100), // Colors.orange.shade900 with opacity
    onWarningContainer: Color(0xFFFFE0B2), // Colors.orange.shade100

    // 信息色 - 蓝色系
    infoColor: Color(0xFF64B5F6), // Colors.blue.shade300
    infoContainer: Color(0xFF0D47A1), // Colors.blue.shade900 with opacity
    onInfoContainer: Color(0xFFBBDEFB), // Colors.blue.shade100
  );

  @override
  ThemeExtension<AppColors> copyWith({
    Color? successColor,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningColor,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? infoColor,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return AppColors(
      successColor: successColor ?? this.successColor,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningColor: warningColor ?? this.warningColor,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      infoColor: infoColor ?? this.infoColor,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(
    covariant ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) {
      return this;
    }

    return AppColors(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}

/// 便捷扩展方法，简化颜色访问
extension AppColorsExtension on BuildContext {
  /// 获取应用自定义颜色
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
