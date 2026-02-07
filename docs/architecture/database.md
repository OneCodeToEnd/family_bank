# 数据库设计

账清使用SQLite作为本地数据库，采用关系型数据库设计。

## 数据库概览

**当前版本**：V10
**文件位置**：应用文档目录/family_bank.db
**字符编码**：UTF-8

---

## 核心表结构

### family_groups - 家庭组

存储家庭组信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| name | TEXT NOT NULL | 家庭组名称 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

### family_members - 家庭成员

存储家庭成员信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| family_id | INTEGER | 家庭组ID（外键） |
| name | TEXT NOT NULL | 成员姓名 |
| role | TEXT | 角色 |
| created_at | TEXT | 创建时间 |

### accounts - 账户

存储账户信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| family_id | INTEGER | 家庭组ID（外键） |
| name | TEXT NOT NULL | 账户名称 |
| type | TEXT | 账户类型 |
| balance | REAL | 当前余额 |
| currency | TEXT | 货币类型 |
| icon | TEXT | 图标 |
| color | TEXT | 颜色 |
| is_default | INTEGER | 是否默认 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

### categories - 分类

存储分类信息（层级结构）。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| name | TEXT NOT NULL | 分类名称 |
| type | TEXT | 类型（income/expense） |
| parent_id | INTEGER | 父分类ID |
| icon | TEXT | 图标 |
| color | TEXT | 颜色 |
| tags | TEXT | 标签（JSON） |
| is_system | INTEGER | 是否系统分类 |
| is_hidden | INTEGER | 是否隐藏 |
| sort_order | INTEGER | 排序 |
| created_at | TEXT | 创建时间 |

### transactions - 交易记录

存储交易记录。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| account_id | INTEGER | 账户ID（外键） |
| category_id | INTEGER | 分类ID（外键） |
| type | TEXT | 类型（income/expense） |
| amount | REAL | 金额 |
| transaction_time | TEXT | 交易时间 |
| description | TEXT | 描述 |
| counterparty | TEXT | 交易对方 |
| import_source | TEXT | 导入来源 |
| hash | TEXT UNIQUE | 去重哈希 |
| is_confirmed | INTEGER | 是否已确认 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

---

## 辅助表

### category_rules - 分类规则

存储自动分类规则。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| category_id | INTEGER | 分类ID（外键） |
| keyword | TEXT | 关键词 |
| match_type | TEXT | 匹配类型 |
| match_position | TEXT | 匹配位置 |
| priority | INTEGER | 优先级 |
| min_confidence | REAL | 最小置信度 |
| counterparty | TEXT | 交易对方 |
| aliases | TEXT | 别名（JSON） |
| auto_learn | INTEGER | 自动学习 |
| case_sensitive | INTEGER | 大小写敏感 |
| is_active | INTEGER | 是否启用 |
| match_count | INTEGER | 匹配次数 |
| source | TEXT | 规则来源 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

### annual_budgets - 年度预算

存储年度预算信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| family_id | INTEGER | 家庭组ID（外键） |
| category_id | INTEGER | 分类ID（外键） |
| year | INTEGER | 年份 |
| type | TEXT | 类型（income/expense） |
| annual_amount | REAL | 年度预算金额 |
| monthly_amount | REAL | 月度预算金额 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

### counterparty_groups - 对手方分组

存储交易对手方的分组关系。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| main_counterparty | TEXT | 主对手方 |
| sub_counterparty | TEXT | 子对手方（唯一） |
| auto_created | INTEGER | 是否自动创建 |
| confidence_score | REAL | 置信度评分 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

### ai_models - AI模型配置

存储AI模型配置。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| provider | TEXT | 提供商 |
| model_name | TEXT | 模型名称 |
| api_key | TEXT | API密钥（加密） |
| custom_prompt | TEXT | 自定义提示词 |
| is_active | INTEGER | 是否启用 |
| created_at | TEXT | 创建时间 |

### email_configs - 邮箱配置

存储邮箱配置。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| email | TEXT | 邮箱地址 |
| imap_server | TEXT | IMAP服务器 |
| imap_port | INTEGER | IMAP端口 |
| password | TEXT | 密码（加密） |
| is_active | INTEGER | 是否启用 |
| created_at | TEXT | 创建时间 |

### http_logs - HTTP日志

存储HTTP请求日志。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PRIMARY KEY | 主键 |
| url | TEXT | 请求URL |
| method | TEXT | 请求方法 |
| request_body | TEXT | 请求体 |
| response_body | TEXT | 响应体 |
| status_code | INTEGER | 状态码 |
| created_at | TEXT | 创建时间 |

### app_settings - 应用设置

存储应用配置。

| 字段 | 类型 | 说明 |
|------|------|------|
| key | TEXT PRIMARY KEY | 配置键 |
| value | TEXT | 配置值 |
| updated_at | TEXT | 更新时间 |

---

## 索引设计

为提高查询性能，创建了以下索引：

```sql
-- 交易记录索引
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_time ON transactions(transaction_time);
CREATE INDEX idx_transactions_hash ON transactions(hash);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_counterparty ON transactions(counterparty);

-- 分类索引
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_type ON categories(type);

-- 分类规则索引
CREATE INDEX idx_category_rules_category ON category_rules(category_id);
CREATE INDEX idx_category_rules_keyword ON category_rules(keyword);
CREATE INDEX idx_category_rules_match_type ON category_rules(match_type);
CREATE INDEX idx_category_rules_counterparty ON category_rules(counterparty);
CREATE INDEX idx_category_rules_priority ON category_rules(priority DESC);

-- 年度预算索引
CREATE INDEX idx_annual_budget_family ON annual_budgets(family_id);
CREATE INDEX idx_annual_budget_category ON annual_budgets(category_id);
CREATE INDEX idx_annual_budget_year ON annual_budgets(year);
CREATE INDEX idx_annual_budget_type ON annual_budgets(type);

-- HTTP日志索引
CREATE INDEX idx_http_log_request_id ON http_logs(request_id);
CREATE INDEX idx_http_log_created_at ON http_logs(created_at DESC);
CREATE INDEX idx_http_log_service ON http_logs(service_name);
CREATE INDEX idx_http_log_status ON http_logs(status_code);

-- 对手方分组索引
CREATE INDEX idx_counterparty_groups_main ON counterparty_groups(main_counterparty);
CREATE INDEX idx_counterparty_groups_sub ON counterparty_groups(sub_counterparty);
```

---

## 外键约束

启用外键约束确保数据完整性：

```sql
PRAGMA foreign_keys = ON;
```

**级联删除**：
- 删除家庭组 → 级联删除成员、账户
- 删除账户 → 级联删除交易
- 删除分类 → 交易的category_id设为NULL

---

## 数据库迁移

### 版本历史

- **V1**：初始结构
- **V2**：添加`counterparty`字段到transactions表
- **V3**：增强分类规则（匹配类型、置信度、自动学习等）
- **V4**：添加HTTP日志表
- **V5**：添加邮箱配置表
- **V6**：添加AI模型配置表
- **V7**：添加年度预算表（annual_budgets）
- **V8**：为annual_budgets表添加type字段
- **V9**：删除未使用的budgets表
- **V10**：添加对手方分组表（counterparty_groups）

### 迁移策略

在`DatabaseService._onUpgrade()`中处理：

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // V1 → V2: 添加counterparty字段
    await db.execute('ALTER TABLE transactions ADD COLUMN counterparty TEXT');
  }
  if (oldVersion < 3) {
    // V2 → V3: 增强分类规则
    await db.execute('ALTER TABLE category_rules ADD COLUMN match_type TEXT');
    await db.execute('ALTER TABLE category_rules ADD COLUMN confidence REAL');
  }
  // ... 其他版本升级
}
```

---

## 数据完整性

### 约束

- **NOT NULL**：必填字段
- **UNIQUE**：唯一性约束（如hash）
- **FOREIGN KEY**：外键约束
- **CHECK**：检查约束（如金额>0）

### 事务

批量操作使用事务确保原子性：

```dart
await db.transaction((txn) async {
  // 批量插入
  for (var item in items) {
    await txn.insert('transactions', item);
  }
});
```

---

## 性能优化

### 查询优化

- 使用索引加速查询
- 避免SELECT *
- 使用参数化查询
- 合理使用LIMIT

### 批量操作

- 使用事务批量插入
- 批量更新减少I/O
- 定期VACUUM清理

---

## 相关文档

- [技术栈](tech-stack.md)
- [服务层](services.md)
- [数据库Schema详细文档](../reference/database-schema.md)