# 预算管理功能需求文档

## 1. 功能概述

预算管理功能帮助用户设定年度支出预算，系统自动生成月度预算并监控执行情况。

**核心价值**：一次配置全年预算，每月自动监控，简单实用。

**重要规则**：只能为一级分类设置预算，系统自动汇总子分类的实际支出。

## 2. 核心功能

### 2.1 年度预算配置

**功能描述**：为一级分类设定年度预算，系统自动按月平均

**操作流程**：
1. 进入"预算管理"页面
2. 点击"设置年度预算"
3. 选择年份（如：2026年）
4. 为各一级分类设置年度预算金额
   - 餐饮：36000元/年 → 自动生成 3000元/月
   - 交通：6000元/年 → 自动生成 500元/月
5. 保存后自动生成12个月的月度预算

**规则**：
- 年度预算金额必须 > 0
- **只能为一级分类（parentId == null）设置预算**
- 支持收入和支出两种类型
- 月度预算 = 年度预算 ÷ 12（四舍五入到分）
- 同一分类同一年份只能有一个年度预算
- **实际支出自动汇总该分类及其所有子分类的交易**

### 2.2 月度预算监控

**功能描述**：展示当月各一级分类预算执行情况

**展示内容**：
- 当前月份（如：2026年1月）
- 预算列表（按一级分类）
  - 分类名称和图标
  - 月度预算金额（年度预算÷12）
  - 已用金额（当月该分类及其所有子分类的实际支出总和）
  - 剩余金额
  - 使用进度条

**状态标识**：
- 正常：已用 < 80%（绿色）
- 预警：80% ≤ 已用 < 100%（黄色）
- 超支：已用 ≥ 100%（红色）

**层级汇总规则**：
- 预算设置在一级分类（如"餐饮"）
- 实际支出包含该分类及所有子分类（如"早餐"、"午餐"、"晚餐"）的交易
- 使用递归 CTE 自动汇总子分类交易

### 2.3 超支提醒

**提醒时机**：
- 某分类当月支出达到预算的 80% 时提醒
- 某分类当月支出超过预算时提醒
- 每个分类每月仅提醒一次

**提醒方式**：应用内弹窗

## 3. 数据模型

### 3.1 年度预算表（annual_budgets）

```sql
CREATE TABLE annual_budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  family_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,  -- 只能是一级分类（parent_id IS NULL）
  year INTEGER NOT NULL,           -- 2026
  type TEXT NOT NULL DEFAULT 'expense',  -- 'income' 或 'expense'
  annual_amount REAL NOT NULL,     -- 36000
  monthly_amount REAL NOT NULL,    -- 3000 (自动计算)
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(family_id, category_id, year),
  FOREIGN KEY (family_id) REFERENCES family_groups(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

-- 索引
CREATE INDEX idx_annual_budget_family ON annual_budgets(family_id);
CREATE INDEX idx_annual_budget_category ON annual_budgets(category_id);
CREATE INDEX idx_annual_budget_year ON annual_budgets(year);
CREATE INDEX idx_annual_budget_type ON annual_budgets(type);
```

**重要约束**：
- `category_id` 必须指向一级分类（在应用层验证）
- 系统通过 BudgetProvider 确保只能为一级分类创建预算

### 3.2 月度预算使用统计

实时从 `transactions` 表计算：
- 筛选：当月 + 对应分类（包含子分类）+ 对应类型
- 统计：使用递归 CTE 汇总父分类及所有子分类的交易
- 公式：`SUM(amount)` WHERE category_id IN (父分类 + 所有子分类)

**SQL 实现**：
```sql
WITH RECURSIVE category_tree AS (
  -- 选择预算分类本身
  SELECT id as category_id FROM categories WHERE id = ?
  UNION ALL
  -- 递归选择所有子分类
  SELECT c.id FROM categories c
  INNER JOIN category_tree ct ON c.parent_id = ct.category_id
)
SELECT SUM(amount) FROM transactions
WHERE category_id IN (SELECT category_id FROM category_tree)
  AND type = ? AND year = ? AND month = ?
```

## 4. 界面设计

### 4.1 预算管理主页

**入口**：首页 → 预算 或 设置 → 预算管理

**页面结构**：
```
┌─────────────────────────────┐
│ 2026年预算                   │
│ [上一年] 2026年 [下一年]      │
│ 总预算: ¥50,000  已配置: 5项  │
│ [设置年度预算]               │
└─────────────────────────────┘

┌─────────────────────────────┐
│ 当月执行情况 (2026年1月)     │
│                             │
│ [餐饮图标] 餐饮              │
│ 预算: ¥3,000  已用: ¥2,400   │
│ [████████░░] 80%            │
│                             │
│ [交通图标] 交通              │
│ 预算: ¥500   已用: ¥320      │
│ [██████░░░░] 64%            │
│                             │
│ ...                         │
└─────────────────────────────┘
```

### 4.2 年度预算配置页面

**表单结构**：
```
┌─────────────────────────────┐
│ 设置 2026年 预算             │
│                             │
│ [餐饮] ¥ [36000] /年         │
│        → 3000元/月           │
│                             │
│ [交通] ¥ [6000] /年          │
│        → 500元/月            │
│                             │
│ [购物] ¥ [12000] /年         │
│        → 1000元/月           │
│                             │
│ [添加更多分类]               │
│                             │
│ [保存]  [取消]               │
└─────────────────────────────┘
```

## 5. 业务规则

1. **预算配置**
   - **只能为一级分类（parentId == null）设置预算**
   - 同一分类同一年份只能配置一次
   - 修改年度预算后，月度预算自动更新（annual_amount / 12）
   - 删除分类时，相关预算自动删除（CASCADE）

2. **预算计算**
   - 月度预算 = 年度预算 ÷ 12
   - 已用金额 = 当月该分类及其所有子分类的交易总和（递归汇总）
   - 剩余金额 = 月度预算 - 已用金额

3. **预算周期**
   - 每年1月1日开始新的预算年度
   - 上一年度预算不自动延续（需重新配置）

4. **层级汇总规则**
   - 预算只能设置在一级分类
   - 实际支出自动包含所有子分类的交易
   - 例如：为"餐饮"设置预算36000/年，实际支出包含"早餐"、"午餐"、"晚餐"等子分类的所有交易
   - 避免重复计算：不允许同时为父分类和子分类设置预算

## 6. 实现步骤

### 第一步：数据库
- 创建 `annual_budgets` 表
- 添加数据库迁移（V7）

### 第二步：Service 层
- `AnnualBudgetDbService` - 年度预算 CRUD
- `BudgetCalculationService` - 计算月度使用情况

### 第三步：Provider 层
- `BudgetProvider` - 管理预算状态和业务逻辑

### 第四步：UI 层
- `BudgetOverviewScreen` - 预算概览页面
- `AnnualBudgetFormScreen` - 年度预算配置页面
- `MonthlyBudgetCard` - 月度预算卡片组件

### 第五步：集成
- 在首页添加预算入口
- 在设置页面添加预算管理入口
- 实现超支提醒逻辑

## 7. 测试要点

- 年度预算配置和月度预算自动生成
- **验证只能为一级分类设置预算（子分类应被拒绝）**
- **验证子分类交易正确汇总到父分类预算**
- 月度预算使用金额计算准确性（包含子分类）
- 跨年份预算隔离
- 超支状态判断
- 修改年度预算后月度预算更新
- **预算汇总只统计一级分类（避免重复计算）**
- **递归 CTE 正确汇总多层级子分类交易**

## 8. 未来扩展

- 预算模板（快速复制上一年预算）
- 预算执行报告（年度/月度对比）
- 灵活调整（某月单独调整预算）
- 家庭成员预算分配
