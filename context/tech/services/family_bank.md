# 账清 (Family Bank) - 技术文档

## 基本信息

- **项目名称**: family_bank (账清)
- **项目描述**: 个人账单流水分析APP
- **版本**: 1.0.0+1
- **SDK**: Dart ^3.6.0
- **框架**: Flutter
- **开发平台**: 支持 Android、iOS、macOS、Windows、Web

## 业务定位

账清是一款个人财务管理应用，主要功能包括：

1. **账单流水管理**: 记录和管理个人/家庭的收支流水
2. **智能分类**: 基于 AI 的交易自动分类功能
3. **账单导入**: 支持支付宝、微信等平台的账单导入
4. **邮件账单**: 支持从邮箱导入账单附件
5. **数据分析**: 提供收支统计和可视化分析
6. **多账户管理**: 支持多个账户和家庭成员管理
7. **预算管理**: 设置和跟踪预算目标

## 技术栈

### 核心框架
- **Flutter**: 跨平台 UI 框架
- **Dart**: 编程语言

### 状态管理
- **Provider** (^6.1.1): 状态管理方案

### 路由管理
- **go_router** (^14.0.0): 声明式路由管理

### 本地存储
- **sqflite** (^2.3.2): SQLite 数据库
- **shared_preferences** (^2.2.2): 键值对存储
- **path_provider** (^2.1.2): 文件路径管理

### 数据可视化
- **fl_chart** (^0.68.0): 图表组件

### 文件处理
- **file_picker** (^8.0.0): 文件选择器
- **csv** (^6.0.0): CSV 文件解析
- **excel** (^4.0.6): Excel 文件处理
- **charset** (^1.0.0): 字符编码转换
- **archive** (^3.4.0): ZIP 解压（支持密码）

### 网络与 AI
- **http** (^1.1.0): HTTP 请求客户端
- **html** (^0.15.4): HTML 解析
- 支持通义千问、DeepSeek 等 AI 模型

### 邮件处理
- **enough_mail** (^2.1.0): 邮件协议支持（IMAP）

### 工具库
- **intl** (^0.19.0): 国际化和日期格式化
- **crypto** (^3.0.3): 加密和哈希
- **uuid** (^4.0.0): UUID 生成
- **logger** (^2.0.2): 日志记录
- **package_info_plus** (^8.0.0): 应用信息

### UI 组件
- **flutter_slidable** (^3.0.1): 滑动操作组件
- **cupertino_icons** (^1.0.8): iOS 风格图标

## 核心模块说明

### 1. 数据模型层 (lib/models/)

#### 核心实体
- **Transaction**: 账单流水模型
  - 支持收入/支出类型
  - 包含去重哈希机制
  - 支持多种导入来源（手动、支付宝、微信、照片）
  - 字段：金额、描述、交易时间、交易对方、分类等

- **Category**: 分类模型
  - 支持层级结构（父子分类）
  - 包含标签系统
  - 区分系统分类和自定义分类
  - 支持隐藏和排序

- **Account**: 账户模型
  - 支持多账户管理
  - 关联家庭成员

- **FamilyGroup & FamilyMember**: 家庭组和成员模型
  - 支持多成员管理
  - 成员角色和权限

- **CategoryRule**: 分类规则模型
  - 基于规则的自动分类
  - 支持关键词匹配

- **AIModel & AIProvider**: AI 模型配置
  - 支持多个 AI 提供商
  - 模型列表和配置管理

- **EmailConfig**: 邮件配置
  - IMAP 服务器配置
  - 支持加密存储

- **Budget**: 预算模型
  - 预算设置和跟踪

- **HttpLog**: HTTP 日志
  - 记录 AI API 调用日志

### 2. 服务层 (lib/services/)

#### 数据库服务 (services/database/)
- **DatabaseService**: 数据库核心服务
  - 数据库初始化和版本管理
  - 表结构定义和迁移

- **TransactionDBService**: 交易数据库服务
  - CRUD 操作
  - 查询和统计

- **CategoryDBService**: 分类数据库服务
  - 层级分类管理
  - 预设分类数据

- **AccountDBService**: 账户数据库服务
- **FamilyDBService**: 家庭数据库服务
- **CategoryRuleDBService**: 分类规则数据库服务
- **EmailConfigDBService**: 邮件配置数据库服务
- **HttpLogDBService**: HTTP 日志数据库服务

#### AI 服务 (services/ai/)
- **AIClassifierService**: AI 分类服务抽象接口
  - 单笔和批量分类
  - 模型列表获取
  - 连接测试

- **QwenClassifierService**: 通义千问分类服务实现
- **DeepSeekClassifierService**: DeepSeek 分类服务实现
- **AIClassifierFactory**: AI 分类器工厂
- **AIConfigService**: AI 配置服务
- **ModelListParser**: 模型列表解析器

#### 分类服务 (services/category/)
- **CategoryMatchService**: 分类匹配服务
  - 基于规则的匹配
  - 学习历史匹配

- **CategoryLearningService**: 分类学习服务
  - 从历史交易学习分类规则

- **BatchClassificationService**: 批量分类服务
  - 高效的批量处理

- **ClassificationErrorHandler**: 分类错误处理

#### 导入服务 (services/import/)
- **BillImportService**: 账单导入服务
  - 支付宝 CSV 导入
  - 微信账单导入
  - 字符编码处理（GBK）

- **EmailService**: 邮件服务
  - IMAP 连接
  - 邮件列表获取
  - 附件下载

- **UnzipService**: 解压服务
  - 支持密码保护的 ZIP 文件

#### 其他服务
- **EncryptionService**: 加密服务
  - 敏感数据加密存储

- **LoggingHttpClient**: HTTP 日志客户端
  - 记录所有 HTTP 请求和响应

### 3. 状态管理层 (lib/providers/)

- **FamilyProvider**: 家庭和成员状态管理
- **AccountProvider**: 账户状态管理
- **CategoryProvider**: 分类状态管理
- **TransactionProvider**: 交易状态管理
- **SettingsProvider**: 设置状态管理（主题、AI 配置等）

### 4. 界面层 (lib/screens/)

#### 交易管理 (screens/transaction/)
- **TransactionListScreen**: 交易列表
- **TransactionFormScreen**: 交易表单
- **TransactionDetailScreen**: 交易详情

#### 分类管理 (screens/category/)
- **CategoryListScreen**: 分类列表
- **CategoryFormScreen**: 分类表单
- **CategoryRuleListScreen**: 分类规则列表
- **CategoryRuleFormScreen**: 分类规则表单

#### 账户管理 (screens/account/)
- **AccountListScreen**: 账户列表
- **AccountFormScreen**: 账户表单

#### 成员管理 (screens/member/)
- **MemberListScreen**: 成员列表
- **MemberFormScreen**: 成员表单

#### 导入功能 (screens/import/)
- **BillImportScreen**: 账单导入
- **EmailBillSelectScreen**: 邮件账单选择
- **ImportConfirmationScreen**: 导入确认

#### 分析功能 (screens/analysis/)
- **AnalysisScreen**: 数据分析和可视化

#### 设置 (screens/settings/)
- **SettingsScreen**: 设置主页
- **AISettingsScreen**: AI 设置
- **AIPromptEditScreen**: AI 提示词编辑
- **EmailConfigScreen**: 邮件配置

#### 其他
- **OnboardingScreen**: 引导页

### 5. 组件层 (lib/widgets/)

- **TransactionItemWidget**: 交易列表项组件
- **TransactionDetailSheet**: 交易详情底部表单
- **CategoryHierarchyStatCard**: 分类层级统计卡片
- **CategoryStatNodeWidget**: 分类统计节点组件

## API 列表

### AI 分类 API

#### 通义千问 (Qwen)
- **接口**: `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`
- **方法**: POST
- **认证**: API Key (Bearer Token)
- **功能**: 交易描述智能分类

#### DeepSeek
- **接口**: `https://api.deepseek.com/v1/chat/completions`
- **方法**: POST
- **认证**: API Key (Bearer Token)
- **功能**: 交易描述智能分类

### 邮件服务 API

#### IMAP 协议
- **协议**: IMAP
- **端口**: 993 (SSL/TLS)
- **功能**:
  - 连接邮箱服务器
  - 获取邮件列表
  - 下载附件

## 数据模型

### 数据库表结构

#### transactions (交易表)
- id: 主键
- account_id: 账户 ID
- category_id: 分类 ID
- type: 类型 (income/expense)
- amount: 金额
- description: 描述
- transaction_time: 交易时间
- import_source: 导入来源
- is_confirmed: 是否已确认
- notes: 备注
- counterparty: 交易对方
- hash: 去重哈希
- created_at: 创建时间
- updated_at: 更新时间

#### categories (分类表)
- id: 主键
- parent_id: 父分类 ID
- name: 名称
- type: 类型 (income/expense)
- icon: 图标
- color: 颜色
- is_system: 是否系统分类
- is_hidden: 是否隐藏
- sort_order: 排序
- tags: 标签 (JSON)
- created_at: 创建时间
- updated_at: 更新时间

#### accounts (账户表)
- id: 主键
- member_id: 成员 ID
- name: 名称
- type: 类型
- balance: 余额
- currency: 货币
- is_default: 是否默认
- created_at: 创建时间
- updated_at: 更新时间

#### family_groups (家庭组表)
- id: 主键
- name: 名称
- created_at: 创建时间
- updated_at: 更新时间

#### family_members (家庭成员表)
- id: 主键
- group_id: 家庭组 ID
- name: 名称
- role: 角色
- avatar: 头像
- created_at: 创建时间
- updated_at: 更新时间

#### category_rules (分类规则表)
- id: 主键
- category_id: 分类 ID
- rule_type: 规则类型
- pattern: 匹配模式
- priority: 优先级
- is_enabled: 是否启用
- created_at: 创建时间
- updated_at: 更新时间

#### email_configs (邮件配置表)
- id: 主键
- name: 配置名称
- email: 邮箱地址
- imap_host: IMAP 服务器
- imap_port: IMAP 端口
- password: 密码（加密）
- is_default: 是否默认
- created_at: 创建时间
- updated_at: 更新时间

#### http_logs (HTTP 日志表)
- id: 主键
- url: 请求 URL
- method: 请求方法
- request_headers: 请求头
- request_body: 请求体
- response_status: 响应状态码
- response_headers: 响应头
- response_body: 响应体
- duration_ms: 耗时（毫秒）
- error: 错误信息
- created_at: 创建时间

## 配置要点

### 1. 数据库配置
- 数据库名称: `family_bank.db`
- 位置: 应用文档目录
- 版本管理: 支持数据库迁移

### 2. AI 配置
- 支持多个 AI 提供商
- API Key 加密存储
- 自定义提示词
- 模型选择

### 3. 邮件配置
- IMAP 服务器配置
- 密码加密存储
- SSL/TLS 支持

### 4. 主题配置
- 支持亮色/暗色主题
- Material Design 3
- 自定义主题色

### 5. 导入配置
- 支持 CSV、Excel 格式
- 字符编码自动检测（GBK、UTF-8）
- 去重机制（基于哈希）

## 架构特点

### 1. 分层架构
- **Model**: 数据模型层
- **Service**: 业务逻辑层
- **Provider**: 状态管理层
- **Screen/Widget**: 界面层

### 2. 状态管理
- 使用 Provider 模式
- 响应式数据更新
- 生命周期管理

### 3. 数据持久化
- SQLite 本地数据库
- SharedPreferences 配置存储
- 加密敏感数据

### 4. 扩展性
- 插件化 AI 服务
- 工厂模式创建分类器
- 支持多种导入格式

### 5. 安全性
- 密码加密存储
- API Key 加密
- 数据去重防止重复导入

## 关键技术点

### 1. 智能分类
- 基于 AI 的自动分类
- 规则引擎匹配
- 历史学习优化

### 2. 账单导入
- 多格式支持（CSV、Excel）
- 字符编码处理
- 去重机制

### 3. 邮件集成
- IMAP 协议支持
- 附件自动下载
- ZIP 密码解压

### 4. 数据分析
- 图表可视化
- 层级统计
- 时间维度分析

### 5. 跨平台支持
- Flutter 跨平台框架
- 适配多个操作系统
- 响应式布局
