# 快速开始：使用提取的Widget

## 第一步：在主文件中添加import

在 `lib/screens/analysis/analysis_screen.dart` 文件顶部添加：

```dart
// 添加这两行import
import '../../widgets/analysis/period_info_card.dart';
import '../../widgets/analysis/overview_card.dart';
```

## 第二步：替换原来的方法调用

在 `build` 方法的 ListView 中，找到并替换：

### 替换 PeriodInfoCard

**原来的代码（第134行）：**
```dart
_buildPeriodInfo(),
```

**替换为：**
```dart
PeriodInfoCard(
  selectedPeriod: _selectedPeriod,
  customStartDate: _customStartDate,
  customEndDate: _customEndDate,
  selectedAccountId: _selectedAccountId,
),
```

### 替换 OverviewCard

**原来的代码（第138行）：**
```dart
_buildOverviewCard(provider),
```

**替换为：**
```dart
const OverviewCard(),
```

## 第三步：删除原来的方法

删除以下方法（它们已经不需要了）：

1. `_buildPeriodInfo()` 方法（第183-251行）
2. `_buildOverviewCard(TransactionProvider provider)` 方法（第253-355行）
3. `_buildStatItem()` 方法（第357-408行）

## 第四步：测试

运行应用，确保功能正常：

```bash
flutter run
```

检查：
- ✅ 时间段信息卡片显示正常
- ✅ 总览统计卡片显示正常
- ✅ 切换时间段和账户后，数据更新正常
- ✅ 没有编译错误

## 预期效果

- **主文件减少约 200 行代码**
- **代码结构更清晰**
- **Widget可以在其他地方复用**

## 继续重构

按照 `REFACTORING_GUIDE.md` 中的步骤，继续提取其他8个Widget。

每提取一个Widget，都重复上述四个步骤：
1. 添加import
2. 替换方法调用
3. 删除原方法
4. 测试功能

---

**提示**：建议使用Git提交每次重构，方便回滚：

```bash
git add .
git commit -m "refactor: extract PeriodInfoCard and OverviewCard"
```
