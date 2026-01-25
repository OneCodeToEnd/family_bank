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
| counterparty | TEXT | | 交易对方(V2.0新增) |
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
- `idx_transaction_counterparty` ON (counterparty) — V2.0新增

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
| source | TEXT | DEFAULT 'user' | 来源(user:用户创建, model:模型学习, learned:自动学习) |
| match_type | TEXT | DEFAULT 'exact' | 匹配类型(exact:精确, partial:部分, counterparty:交易对方) |
| match_position | TEXT | | 匹配位置(contains:包含, prefix:前缀, suffix:后缀，仅用于partial) |
| min_confidence | REAL | DEFAULT 0.8 | 最小置信度阈值(0-1) |
| counterparty | TEXT | | 交易对方名称(matchType=counterparty时使用) |
| aliases | TEXT | DEFAULT '[]' | 别名列表(JSON数组) |
| auto_learn | INTEGER | DEFAULT 0 | 是否自动学习(0:否, 1:是) |
| case_sensitive | INTEGER | DEFAULT 0 | 是否区分大小写(0:否, 1:是) |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**索引:**
- `idx_rule_keyword` ON (keyword)
- `idx_rule_category` ON (category_id)
- `idx_rule_match_type` ON (match_type) — V3.0新增
- `idx_rule_counterparty` ON (counterparty) — V3.0新增
- `idx_rule_priority` ON (priority DESC) — V3.0新增

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
- `ai_classification_config`: AI分类配置(JSON格式，包含加密的API Key)

### 9. HTTP日志表 (http_logs)
管理HTTP请求日志（V4.0新增）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| request_id | TEXT | NOT NULL, UNIQUE | 请求唯一ID(UUID) |
| method | TEXT | NOT NULL | HTTP方法(GET/POST/PUT/DELETE) |
| url | TEXT | NOT NULL | 请求URL(完整路径) |
| request_headers | TEXT | | 请求头(JSON格式) |
| request_body | TEXT | | 请求体 |
| request_size | INTEGER | | 请求大小(字节) |
| status_code | INTEGER | | HTTP状态码(200/404/500等) |
| status_message | TEXT | | 状态消息(OK/Not Found等) |
| response_headers | TEXT | | 响应头(JSON格式) |
| response_body | TEXT | | 响应体 |
| response_size | INTEGER | | 响应大小(字节) |
| start_time | INTEGER | NOT NULL | 请求开始时间(时间戳) |
| end_time | INTEGER | | 请求结束时间(时间戳) |
| duration_ms | INTEGER | | 请求耗时(毫秒) |
| error_type | TEXT | | 错误类型(timeout/network/api/parse/unknown) |
| error_message | TEXT | | 错误消息 |
| stack_trace | TEXT | | 堆栈跟踪 |
| service_name | TEXT | | 服务名称(deepseek_classifier/qwen_classifier) |
| api_provider | TEXT | | API提供商(deepseek/qwen) |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**索引:**
- `idx_http_log_request_id` ON (request_id) — 唯一索引
- `idx_http_log_created_at` ON (created_at DESC) — 时间倒序索引
- `idx_http_log_service` ON (service_name) — 服务名索引
- `idx_http_log_status` ON (status_code) — 状态码索引

**用途说明:**
- 记录所有AI服务的HTTP请求和响应
- 支持性能分析和问题排查
- 包含完整的请求/响应数据（含敏感信息）
- 仅用于开发调试，生产环境应定期清理

## 数据库版本管理

### V1.0 数据库版本
- 表: family_groups, family_members, accounts, categories, transactions, category_rules, budgets, app_settings
- 初始预设分类数据

### V2.0 数据库版本 (2026-01-04)
- **新增**: transactions 表添加 counterparty 字段（交易对方）
- **新增**: idx_transaction_counterparty 索引
- **功能**: 支持记录和管理交易对手方信息
- **兼容性**: 向后兼容，旧数据自动升级

### V3.0 数据库版本 (2026-01-06)
- **新增**: category_rules 表添加增强分类匹配字段
  - match_type: 匹配类型（exact/partial/counterparty）
  - match_position: 匹配位置（contains/prefix/suffix）
  - min_confidence: 最小置信度阈值
  - counterparty: 交易对方名称
  - aliases: 别名列表（JSON数组）
  - auto_learn: 是否自动学习
  - case_sensitive: 是否区分大小写
- **新增**: 三个新索引优化查询性能
  - idx_rule_match_type
  - idx_rule_counterparty
  - idx_rule_priority
- **功能**: 支持多层分类匹配策略和自动学习机制
- **兼容性**: 向后兼容，旧规则自动使用默认值（exact类型）

### V4.0 数据库版本 (2026-01-07)
- **新增**: http_logs 表（HTTP调用日志）
  - 22个字段记录完整的请求/响应信息
  - 支持性能分析、错误追踪、问题排查
  - 记录请求URL、方法、headers、body、响应状态、耗时等
- **新增**: 四个索引优化日志查询
  - idx_http_log_request_id (UNIQUE): 请求ID唯一索引
  - idx_http_log_created_at (DESC): 时间倒序索引
  - idx_http_log_service: 按服务名过滤
  - idx_http_log_status: 按状态码查询失败请求
- **新增**: uuid 依赖（v4.0.0）用于生成请求ID
- **功能**:
  - 拦截所有AI服务的HTTP请求
  - 异步记录日志，不阻塞请求
  - 支持手动清理旧日志
  - 提供统计分析接口
- **安全**: 日志包含完整敏感信息（API Key等），仅用于调试
- **兼容性**: 向后兼容，升级时自动创建http_logs表

### 未来版本迁移计划
- V5.0: 添加全文搜索支持，扩展预算管理功能，日志级别控制

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
2. **加密**: 敏感数据(如PIN码、API Key)使用AES加密存储
3. **备份**: 支持导出加密的数据库备份文件
4. **隐私**: 不存储任何账号密码等敏感认证信息
5. **日志安全**: HTTP日志包含完整的API Key等敏感信息，仅用于调试，建议定期清理

## 数据库性能优化

### 索引策略
- **外键索引**: 所有外键字段都有对应索引，优化JOIN查询
- **时间索引**: transaction_time、created_at等时间字段建立倒序索引，支持分页查询
- **搜索索引**: keyword、counterparty等搜索字段建立索引
- **复合索引**: budget表使用(target_type, target_id)复合索引
- **唯一索引**: request_id使用唯一索引，保证日志不重复

### 查询优化建议
1. 使用参数化查询防止SQL注入
2. 批量操作使用batch API减少事务开销
3. 大量数据查询使用分页(LIMIT + OFFSET)
4. 定期清理历史日志数据(http_logs表)
5. 使用EXPLAIN QUERY PLAN分析查询性能

## 表间关系图

```
family_groups (1) ----< (n) family_members
                              |
                              | (1)
                              |
                              v
                            (n) accounts
                              |
                              | (1)
                              |
                              v
                            (n) transactions ----< (1) categories
                                                      |
                                                      | (1)
                                                      |
                                                      v
                                                    (n) category_rules

budgets ----< categories/accounts (target_type + target_id)

http_logs (独立表，记录HTTP调用日志)

email_configs (独立表，存储邮箱配置)

app_settings (独立表，键值对存储)
```

## 版本历史

### V5.0 (2026-01-20)
**新增表**: email_configs

**功能**: 邮箱账单同步
- 支持通过IMAP协议连接邮箱
- 自动搜索支付宝/微信的账单邮件
- 下载并解压账单附件
- 密码加密存储

### 9. 邮箱配置表 (email_configs) - V5.0新增
管理邮箱账单同步配置

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| email | TEXT | NOT NULL UNIQUE | 邮箱地址 |
| imap_server | TEXT | NOT NULL | IMAP服务器地址 |
| imap_port | INTEGER | NOT NULL | IMAP端口(通常为993) |
| password | TEXT | NOT NULL | 邮箱密码/授权码(AES加密存储) |
| is_enabled | INTEGER | DEFAULT 1 | 是否启用(0:否, 1:是) |
| created_at | INTEGER | NOT NULL | 创建时间(时间戳) |
| updated_at | INTEGER | NOT NULL | 更新时间(时间戳) |

**说明:**
- 密码使用AES加密存储，通过EncryptionService加密/解密
- 支持的邮箱：QQ、163、126、Gmail、Outlook等
- 需要开启IMAP服务并使用授权码（部分邮箱）
- 用于自动从邮箱下载支付宝/微信的账单附件

**安全性:**
- 密码加密存储，不以明文形式保存
- 只读取特定发件人的邮件（支付宝/微信官方）
- 不修改邮箱内容
- 临时文件导入后自动清理
```
