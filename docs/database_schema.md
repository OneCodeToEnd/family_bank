# 数据库设计文档

## 数据库表结构设计

### 1. 家庭组表 (family_groups)
管理家庭组信息

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| name | TEXT | NOT NULL | 家庭组名称 |
| description | TEXT | | 描述 |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

### 2. 家庭成员表 (family_members)
管理家庭成员信息

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| family_group_id | INTEGER | NOT NULL, FOREIGN KEY | 所属家庭组ID |
| name | TEXT | NOT NULL | 成员姓名 |
| avatar | TEXT | | 头像路径 |
| role | TEXT | | 角色(爸爸/妈妈/孩子等) |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**索引:**
- `idx_member_group` ON (family_group_id)

### 3. 账户表 (accounts)
管理支付账户信息

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| family_member_id | INTEGER | NOT NULL, FOREIGN KEY | 所属成员ID |
| name | TEXT | NOT NULL | 账户名称(如"爸爸的微信") |
| type | TEXT | NOT NULL | 账户类型(alipay/wechat/bank/cash) |
| icon | TEXT | | 图标标识 |
| is_hidden | INTEGER | DEFAULT 0 | 是否隐藏(0:否, 1:是) |
| notes | TEXT | | 备注 |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**索引:**
- `idx_account_member` ON (family_member_id)

### 4. 资金分类表 (categories)
管理收支分类树

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| parent_id | INTEGER | | 父分类ID(NULL表示一级分类) |
| name | TEXT | NOT NULL | 分类名称 |
| type | TEXT | NOT NULL | 类型(income/expense) |
| icon | TEXT | | 图标标识 |
| color | TEXT | | 颜色标识 |
| is_system | INTEGER | DEFAULT 0 | 是否系统预设(0:否, 1:是) |
| is_hidden | INTEGER | DEFAULT 0 | 是否隐藏(0:否, 1:是) |
| sort_order | INTEGER | DEFAULT 0 | 排序序号 |
| tags | TEXT | | 标签(JSON数组,如["必要支出","可选消费"]) |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**索引:**
- `idx_category_parent` ON (parent_id)
- `idx_category_type` ON (type)

### 5. 账单流水表 (transactions)
管理账单记录

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| account_id | INTEGER | NOT NULL, FOREIGN KEY | 账户ID |
| category_id | INTEGER | FOREIGN KEY | 分类ID |
| type | TEXT | NOT NULL | 类型(income/expense) |
| amount | REAL | NOT NULL | 金额 |
| description | TEXT | | 交易描述 |
| transaction_time | INTEGER | NOT NULL | 交易时间(时间戳) |
| import_source | TEXT | | 导入来源(manual/alipay/wechat/photo) |
| is_confirmed | INTEGER | DEFAULT 0 | 是否已确认分类(0:否, 1:是) |
| notes | TEXT | | 备注 |
| hash | TEXT | | 去重哈希值(时间+金额+描述) |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**索引:**
- `idx_transaction_account` ON (account_id)
- `idx_transaction_category` ON (category_id)
- `idx_transaction_time` ON (transaction_time)
- `idx_transaction_hash` ON (hash)
- `idx_transaction_type` ON (type)

### 6. 分类规则表 (category_rules)
管理自动分类规则

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| keyword | TEXT | NOT NULL | 关键词(如"星巴克") |
| category_id | INTEGER | NOT NULL, FOREIGN KEY | 目标分类ID |
| priority | INTEGER | DEFAULT 0 | 优先级(数字越大优先级越高) |
| is_active | INTEGER | DEFAULT 1 | 是否启用(0:否, 1:是) |
| match_count | INTEGER | DEFAULT 0 | 匹配次数统计 |
| source | TEXT | DEFAULT 'user' | 来源(user:用户创建, model:模型学习) |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**索引:**
- `idx_rule_keyword` ON (keyword)
- `idx_rule_category` ON (category_id)

### 7. 预算表 (budgets)
管理预算设置(V3.0功能)

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| target_type | TEXT | NOT NULL | 目标类型(category/account) |
| target_id | INTEGER | NOT NULL | 目标ID(分类ID或账户ID) |
| amount | REAL | NOT NULL | 预算金额 |
| period | TEXT | NOT NULL | 周期(monthly/yearly) |
| start_date | INTEGER | NOT NULL | 开始日期(时间戳) |
| end_date | INTEGER | | 结束日期(时间戳,NULL表示无限期) |
| is_active | INTEGER | DEFAULT 1 | 是否启用(0:否, 1:是) |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**索引:**
- `idx_budget_target` ON (target_type, target_id)

### 8. 应用设置表 (app_settings)
管理应用设置

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| key | TEXT | PRIMARY KEY | 设置键 |
| value | TEXT | NOT NULL | 设置值(JSON格式) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**常用设置项:**
- `theme_mode`: 主题模式(light/dark/system)
- `security_pin`: 应用锁密码(加密存储)
- `security_biometric`: 是否启用生物识别
- `default_family_group`: 默认家庭组ID
- `model_version`: 本地模型版本
- `model_enabled`: 是否启用模型推荐

## 数据库版本管理

### V1.0 数据库版本
- 表: family_groups, family_members, accounts, categories, transactions, category_rules, app_settings
- 初始预设分类数据

### 未来版本迁移计划
- V2.0: 优化索引,添加全文搜索支持
- V3.0: 添加budgets表,扩展预算管理功能

## 预设数据

### 默认分类树(categories表预设数据)

#### 收入类分类
- 工资
  - 主业工资
  - 副业工资
- 兼职
- 投资收益
  - 股票
  - 基金
  - 理财
- 礼金
- 其他收入

#### 支出类分类
- 固定支出
  - 房租/房贷
  - 水电燃气
  - 通讯费
  - 保险
- 日常消费
  - 餐饮
    - 早餐
    - 午餐
    - 晚餐
    - 咖啡饮品
    - 外卖
  - 交通
    - 公共交通
    - 打车
    - 加油
    - 停车费
  - 购物
    - 服饰
    - 美妆
    - 日用品
  - 生鲜果蔬
- 非日常消费
  - 医疗
  - 教育
  - 娱乐
    - 电影
    - 游戏
    - 旅游
  - 人情往来
  - 运动健身
- 其他支出

## 数据安全说明

1. **本地存储**: 所有数据存储在SQLite数据库,路径为应用沙盒目录
2. **加密**: 敏感数据(如PIN码)使用AES加密存储
3. **备份**: 支持导出加密的数据库备份文件
4. **隐私**: 不存储任何账号密码等敏感认证信息
