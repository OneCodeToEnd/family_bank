# 数据分析页面集成预算展示设计方案

## 1. 设计目标

在数据分析页面的分类统计中内联展示预算信息，让用户在查看支出统计时同步了解预算执行情况。

**核心原则**：
- 移动端优先设计
- 信息密度适中，避免拥挤
- 视觉层次清晰
- 交互简洁直观

## 2. 移动端 UI 设计

### 2.1 一级分类展示（有预算）

```
┌─────────────────────────────────────────┐
│ ▼ 🍔 餐饮                    ¥2,400    │  ← 点击展开/收起
│    3笔 · 80.0%                          │
│                                         │
│    预算 ¥3,000/月  剩余 ¥600           │  ← 预算信息行
│    [████████░░] 80%                     │  ← 进度条（颜色根据状态变化）
├─────────────────────────────────────────┤
```

**布局说明**：
- 第一行：展开图标 + 分类图标 + 名称 + 金额（右对齐）
- 第二行：笔数和占比（灰色小字）
- 第三行：预算信息（仅一级分类显示）
  - 左侧：预算金额/周期
  - 右侧：剩余金额
- 第四行：进度条 + 百分比

**颜色方案**：
- 正常（< 80%）：绿色进度条 `Colors.green`
- 预警（80% ~ 100%）：橙色进度条 `Colors.orange`
- 超支（≥ 100%）：红色进度条 `Colors.red`

### 2.2 一级分类展示（无预算）

```
┌─────────────────────────────────────────┐
│ ▼ 🛍️ 购物                    ¥1,500    │
│    5笔 · 15.0%                          │
│                                         │
│    [设置预算]                           │  ← 快捷入口（可选）
├─────────────────────────────────────────┤
```

### 2.3 子分类展示（不显示预算）

```
┌─────────────────────────────────────────┐
│ ▼ 🍔 餐饮                    ¥2,400    │
│    3笔 · 80.0%                          │
│    预算 ¥3,000/月  剩余 ¥600           │
│    [████████░░] 80%                     │
│                                         │
│    ▶ 🌅 早餐                   ¥800    │  ← 子分类（缩进）
│       1笔 · 26.7%                       │
│                                         │
│    ▶ 🌞 午餐                 ¥1,000    │
│       1笔 · 33.3%                       │
│                                         │
│    ▶ 🌙 晚餐                   ¥600    │
│       1笔 · 20.0%                       │
├─────────────────────────────────────────┤
```

### 2.4 超支状态特殊展示

```
┌─────────────────────────────────────────┐
│ ▼ 🚗 交通                    ¥1,200    │
│    8笔 · 120.0%                         │
│                                         │
│    预算 ¥1,000/月  超支 ¥200 ⚠️        │  ← 超支警告
│    [██████████] 120%                    │  ← 红色进度条
├─────────────────────────────────────────┤
```

## 3. 数据模型扩展

### 3.1 CategoryStatNode 增强

```dart
class CategoryStatNode {
  final Category category;
  final double amount;
  final int transactionCount;
  final List<CategoryStatNode> children;

  // 新增预算相关字段
  final double? budgetAmount;        // 月度预算金额（根据时间范围计算）
  final double? budgetUsagePercent;  // 预算使用百分比
  final BudgetStatus? budgetStatus;  // 预算状态

  // ... 其他字段
}

enum BudgetStatus {
  normal,    // < 80%
  warning,   // 80% ~ 100%
  exceeded,  // >= 100%
}
```

### 3.2 时间范围与预算计算

| 时间范围 | 预算计算逻辑 | 显示文案 |
|---------|------------|---------|
| 本月 | 年度预算 ÷ 12 | "预算 ¥3,000/月" |
| 本季度 | 年度预算 ÷ 4 | "预算 ¥9,000/季" |
| 本年 | 年度预算 | "预算 ¥36,000/年" |
| 自定义 | 不显示预算 | - |
| 全部 | 不显示预算 | - |

## 4. 数据查询优化

### 4.1 SQL 查询增强

在 `TransactionProvider.getCategoryHierarchyStats()` 中增加预算关联查询：

```sql
WITH RECURSIVE category_tree AS (
  -- 递归获取分类树及其交易统计
  ...
)
SELECT
  c.*,
  ct.amount,
  ct.transaction_count,
  ab.annual_amount,
  ab.monthly_amount,
  ab.year as budget_year
FROM categories c
LEFT JOIN category_tree ct ON c.id = ct.category_id
LEFT JOIN annual_budgets ab ON c.id = ab.category_id
  AND ab.year = ?
  AND ab.family_id = ?
  AND c.parent_id IS NULL  -- 只为一级分类关联预算
WHERE c.type = ?
ORDER BY ct.amount DESC
```

### 4.2 预算状态计算

```dart
BudgetStatus? _calculateBudgetStatus(double amount, double? budgetAmount) {
  if (budgetAmount == null || budgetAmount == 0) return null;

  final percent = amount / budgetAmount;
  if (percent >= 1.0) return BudgetStatus.exceeded;
  if (percent >= 0.8) return BudgetStatus.warning;
  return BudgetStatus.normal;
}
```

## 5. UI 组件实现

### 5.1 预算信息行组件

```dart
Widget _buildBudgetInfo(CategoryStatNode node, String timeRange) {
  if (node.budgetAmount == null || node.category.parentId != null) {
    return const SizedBox.shrink(); // 无预算或非一级分类不显示
  }

  final remaining = node.budgetAmount! - node.amount;
  final isExceeded = remaining < 0;

  return Padding(
    padding: const EdgeInsets.only(left: 44, right: 16, top: 4, bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '预算 ¥${node.budgetAmount!.toStringAsFixed(0)}/$timeRange',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        Row(
          children: [
            Text(
              isExceeded
                ? '超支 ¥${(-remaining).toStringAsFixed(0)}'
                : '剩余 ¥${remaining.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: isExceeded ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isExceeded) ...[
              const SizedBox(width: 4),
              const Icon(Icons.warning_amber, size: 14, color: Colors.red),
            ],
          ],
        ),
      ],
    ),
  );
}
```

### 5.2 进度条组件

```dart
Widget _buildBudgetProgress(CategoryStatNode node) {
  if (node.budgetAmount == null || node.category.parentId != null) {
    return const SizedBox.shrink();
  }

  final percent = node.budgetUsagePercent ?? 0;
  final status = node.budgetStatus ?? BudgetStatus.normal;

  Color progressColor;
  switch (status) {
    case BudgetStatus.normal:
      progressColor = Colors.green;
      break;
    case BudgetStatus.warning:
      progressColor = Colors.orange;
      break;
    case BudgetStatus.exceeded:
      progressColor = Colors.red;
      break;
  }

  return Padding(
    padding: const EdgeInsets.only(left: 44, right: 16, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            color: progressColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
```

## 6. 响应式设计

### 6.1 屏幕尺寸适配

```dart
// 根据屏幕宽度调整字体大小和间距
final screenWidth = MediaQuery.of(context).size.width;
final isSmallScreen = screenWidth < 360;

final categoryFontSize = isSmallScreen ? 14.0 : 15.0;
final amountFontSize = isSmallScreen ? 15.0 : 16.0;
final budgetFontSize = isSmallScreen ? 11.0 : 12.0;
```

### 6.2 横屏适配

横屏时可以考虑将预算信息和进度条合并到一行：

```
┌─────────────────────────────────────────────────────┐
│ ▼ 🍔 餐饮  3笔·80%  ¥2,400  [████░] 80%  剩余¥600  │
├─────────────────────────────────────────────────────┤
```

## 7. 交互设计

### 7.1 点击行为

- **点击分类行**：展开/收起子分类或流水明细（保持现有逻辑）
- **长按分类行**：显示快捷菜单
  - 查看预算详情
  - 设置/编辑预算
  - 查看历史趋势

### 7.2 快捷操作

对于未设置预算的一级分类，显示"设置预算"按钮：

```dart
if (node.budgetAmount == null && node.category.parentId == null) {
  return TextButton.icon(
    onPressed: () => _navigateToBudgetForm(node.category),
    icon: const Icon(Icons.add_circle_outline, size: 16),
    label: const Text('设置预算', style: TextStyle(fontSize: 12)),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 4),
      alignment: Alignment.centerLeft,
    ),
  );
}
```

## 8. 性能优化

### 8.1 数据缓存

- 预算数据随分类统计一次性查询，避免多次数据库访问
- 使用 FutureBuilder 的 key 机制，确保筛选条件变化时重新加载

### 8.2 渲染优化

- 预算信息仅在一级分类显示，减少渲染负担
- 进度条使用 LinearProgressIndicator，性能优于自定义绘制
- 避免不必要的 setState，子组件自管理状态

## 9. 实现步骤

### Phase 1：数据层（1-2小时）
1. 扩展 `CategoryStatNode` 模型，增加预算字段
2. 修改 `TransactionProvider.getCategoryHierarchyStats()`，关联查询预算数据
3. 实现预算金额计算逻辑（根据时间范围）
4. 实现预算状态判断逻辑

### Phase 2：UI层（2-3小时）
1. 修改 `CategoryStatNodeWidget`，增加预算信息展示
2. 实现预算信息行组件
3. 实现进度条组件
4. 调整布局和样式，确保移动端友好

### Phase 3：交互优化（1小时）
1. 实现"设置预算"快捷入口
2. 添加长按菜单（可选）
3. 测试各种屏幕尺寸和状态

### Phase 4：测试与优化（1小时）
1. 测试不同时间范围的预算显示
2. 测试有/无预算的分类展示
3. 测试超支状态显示
4. 性能测试和优化

## 10. 测试用例

- [ ] 本月时间范围，显示月度预算
- [ ] 本季度时间范围，显示季度预算
- [ ] 本年时间范围，显示年度预算
- [ ] 自定义/全部时间范围，不显示预算
- [ ] 一级分类有预算，正确显示预算信息和进度条
- [ ] 一级分类无预算，显示"设置预算"按钮
- [ ] 子分类不显示预算信息
- [ ] 预算使用 < 80%，绿色进度条
- [ ] 预算使用 80%-100%，橙色进度条
- [ ] 预算使用 ≥ 100%，红色进度条，显示超支金额
- [ ] 小屏幕设备（< 360px）布局正常
- [ ] 横屏模式布局正常
- [ ] 展开/收起子分类，预算信息保持显示

## 11. 未来扩展

- 预算趋势图（点击预算信息展开）
- 预算完成度排行
- 预算预测（基于当前进度预测月底是否超支）
- 预算对比（本月 vs 上月）
