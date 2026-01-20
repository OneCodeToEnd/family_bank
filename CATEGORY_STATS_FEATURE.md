# 分类统计看板功能说明

## 功能概述

在数据分析页面新增了**分类统计看板**，支持按照一级、二级、三级分类进行层级汇总展示，并可以查看每个分类下的流水明细。

## 主要特性

### 1. 层级展示
- **一级分类**：如"日常消费"、"固定支出"、"非日常消费"
- **二级分类**：如"餐饮"、"交通"、"购物"
- **三级分类**：如"一日三餐"、"咖啡饮品"、"外卖"

### 2. 统计信息
每个分类显示：
- 分类名称和图标
- 交易笔数
- 占比百分比
- 总金额（包含所有子分类）

### 3. 交互功能
- **非末级分类**：点击展开/收起子分类列表
- **末级分类**：点击展开/收起流水明细
- **流水明细**：显示交易对手方、交易时间、交易金额
- **流水详情**：点击流水条目查看完整详情

### 4. 类型切换
- 支持在"支出"和"收入"之间切换
- 切换后自动重新加载对应类型的分类统计

## 使用方法

1. 打开应用，进入"数据分析"页面
2. 在页面中找到"分类统计"卡片
3. 点击右上角的"支出"/"收入"按钮切换类型
4. 点击分类行展开/收起子分类或流水明细
5. 点击流水明细条目查看完整的流水详情

## 技术实现

### 数据模型
- `CategoryStatNode`: 分类统计节点，包含分类信息、金额、笔数、子分类和流水明细

### 数据库层
- `getTransactionsByCategoryHierarchy()`: 获取分类及其所有子分类的流水
- `getCategoryHierarchyStatistics()`: 获取分类层级统计信息

### Provider层
- `getCategoryHierarchyStats()`: 递归构建分类统计树
- `loadCategoryTransactions()`: 懒加载分类流水明细

### UI组件
- `CategoryHierarchyStatCard`: 分类统计卡片（主容器）
- `CategoryStatNodeWidget`: 分类节点组件（递归渲染）
- `TransactionItemWidget`: 流水条目组件
- `TransactionDetailSheet`: 流水详情弹窗

## 性能优化

1. **懒加载流水**：只在用户点击展开末级分类时才加载流水明细
2. **递归查询**：使用递归方式计算分类及其所有子分类的金额
3. **状态管理**：使用 Provider 管理状态，避免重复查询

## 示例效果

```
分类统计 (支出)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▼ 日常消费                    ¥8,520.00 (45笔)
  ├─▼ 餐饮                    ¥3,200.00 (25笔)
  │  ├─▼ 一日三餐              ¥2,100.00 (18笔)
  │  │  ├─ 美团外卖  2024-01-15 10:30  ¥35.00
  │  │  ├─ 沙县小吃  2024-01-14 12:15  ¥25.00
  │  │  └─ 永和大王  2024-01-14 08:20  ¥18.00
  │  ├─▶ 咖啡饮品              ¥600.00 (5笔)
  │  └─▶ 外卖                  ¥500.00 (2笔)
  ├─▶ 交通                    ¥1,800.00 (12笔)
  └─▶ 购物                    ¥3,520.00 (8笔)

▶ 固定支出                    ¥5,200.00 (4笔)
▶ 非日常消费                  ¥2,800.00 (6笔)
```

## 文件清单

### 新增文件
1. `lib/models/category_stat_node.dart` - 分类统计节点模型
2. `lib/widgets/transaction_item_widget.dart` - 流水条目组件
3. `lib/widgets/transaction_detail_sheet.dart` - 流水详情弹窗
4. `lib/widgets/category_stat_node_widget.dart` - 分类节点组件
5. `lib/widgets/category_hierarchy_stat_card.dart` - 分类统计卡片

### 修改文件
1. `lib/services/database/transaction_db_service.dart` - 添加分类层级查询方法
2. `lib/providers/transaction_provider.dart` - 添加分类统计方法
3. `lib/screens/analysis/analysis_screen.dart` - 集成分类统计看板
