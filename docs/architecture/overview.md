# 项目架构文档

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider
- **本地数据库**: sqflite
- **路由**: go_router
- **图表**: fl_chart
- **文件处理**: file_picker, csv
- **OCR**: google_mlkit_text_recognition
- **UI组件**: Material Design 3

## 项目目录结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # App 配置和路由
│
├── constants/                # 常量定义
│   ├── app_constants.dart    # 应用常量
│   ├── db_constants.dart     # 数据库常量
│   └── theme_constants.dart  # 主题常量
│
├── models/                   # 数据模型层
│   ├── family_group.dart     # 家庭组模型
│   ├── family_member.dart    # 家庭成员模型
│   ├── account.dart          # 账户模型
│   ├── category.dart         # 分类模型
│   ├── transaction.dart      # 账单流水模型
│   ├── category_rule.dart    # 分类规则模型
│   └── budget.dart           # 预算模型
│
├── services/                 # 业务逻辑服务层
│   ├── database/             # 数据库服务
│   │   ├── database_service.dart      # 数据库初始化和版本管理
│   │   ├── family_db_service.dart     # 家庭组/成员数据库操作
│   │   ├── account_db_service.dart    # 账户数据库操作
│   │   ├── category_db_service.dart   # 分类数据库操作
│   │   ├── transaction_db_service.dart # 账单数据库操作
│   │   └── rule_db_service.dart       # 规则数据库操作
│   │
│   ├── import/               # 导入服务
│   │   ├── csv_import_service.dart    # CSV导入
│   │   ├── alipay_parser.dart         # 支付宝账单解析
│   │   ├── wechat_parser.dart         # 微信账单解析
│   │   └── ocr_service.dart           # OCR识别服务
│   │
│   ├── classification/       # 分类服务
│   │   ├── classification_service.dart # 分类推荐
│   │   ├── rule_engine.dart           # 规则引擎
│   │   └── ml_classifier.dart         # 本地ML分类器(V2.0)
│   │
│   ├── analysis/             # 分析服务
│   │   ├── statistics_service.dart    # 统计分析
│   │   └── report_service.dart        # 报表生成
│   │
│   └── security/             # 安全服务
│       ├── encryption_service.dart    # 加密服务
│       └── auth_service.dart          # 认证服务(应用锁)
│
├── providers/                # 状态管理层(Provider)
│   ├── family_provider.dart  # 家庭组/成员状态
│   ├── account_provider.dart # 账户状态
│   ├── category_provider.dart # 分类状态
│   ├── transaction_provider.dart # 账单状态
│   ├── analysis_provider.dart # 分析数据状态
│   └── settings_provider.dart # 应用设置状态
│
├── screens/                  # 页面层
│   ├── home/                 # 首页
│   │   └── home_screen.dart
│   │
│   ├── account/              # 账户管理
│   │   ├── account_list_screen.dart
│   │   ├── account_detail_screen.dart
│   │   └── account_form_screen.dart
│   │
│   ├── category/             # 分类管理
│   │   ├── category_list_screen.dart
│   │   └── category_form_screen.dart
│   │
│   ├── transaction/          # 账单管理
│   │   ├── transaction_list_screen.dart
│   │   ├── transaction_detail_screen.dart
│   │   ├── import_screen.dart
│   │   └── classify_screen.dart
│   │
│   ├── analysis/             # 数据分析
│   │   ├── analysis_screen.dart
│   │   └── report_screen.dart
│   │
│   └── settings/             # 设置
│       ├── settings_screen.dart
│       └── security_screen.dart
│
├── widgets/                  # 可复用组件层
│   ├── common/               # 通用组件
│   │   ├── custom_app_bar.dart
│   │   ├── custom_button.dart
│   │   ├── loading_indicator.dart
│   │   └── empty_state.dart
│   │
│   └── charts/               # 图表组件
│       ├── pie_chart_widget.dart
│       ├── line_chart_widget.dart
│       └── bar_chart_widget.dart
│
└── utils/                    # 工具类
    ├── date_utils.dart       # 日期工具
    ├── number_utils.dart     # 数字格式化
    ├── validator.dart        # 表单验证
    └── logger.dart           # 日志工具
```

## 分层架构说明

### 1. Models (数据模型层)
- 纯数据类，包含字段定义
- 提供 `fromMap`/`toMap` 方法用于数据库序列化
- 提供 `copyWith` 方法用于对象复制

### 2. Services (服务层)
- **Database Services**: 封装所有数据库操作，提供 CRUD 接口
- **Import Services**: 处理各种来源的账单导入和解析
- **Classification Services**: 账单自动分类逻辑
- **Analysis Services**: 数据统计和分析
- **Security Services**: 加密和认证

### 3. Providers (状态管理层)
- 使用 Provider 管理应用状态
- 调用 Services 层获取和更新数据
- 通知 UI 层数据变化

### 4. Screens (页面层)
- UI 页面组件
- 使用 Provider 获取状态
- 处理用户交互

### 5. Widgets (可复用组件层)
- 通用 UI 组件
- 图表组件
- 可在多个页面复用

### 6. Utils (工具层)
- 纯函数工具类
- 不包含状态

## 数据流向

```
用户操作 → Screen → Provider → Service → Database
                      ↓
                    notify
                      ↓
                   UI 更新
```

## 开发原则

1. **单一职责**: 每个类只负责一个功能
2. **依赖注入**: 通过构造函数注入依赖
3. **面向接口**: Service 层提供清晰的接口
4. **状态隔离**: 状态只在 Provider 中管理
5. **代码复用**: 通用逻辑抽取到 Utils 和 Widgets

## V1.0 开发优先级

### 阶段1：数据层 (Week 1-2)
1. Models 定义
2. Database Services 实现
3. 预设分类数据初始化

### 阶段2：业务层 (Week 3-4)
1. Import Services (CSV导入)
2. Classification Services (关键词规则)
3. Providers 实现

### 阶段3：UI层 (Week 5-6)
1. 基础页面框架和路由
2. 账户管理页面
3. 账单导入和分类页面

### 阶段4：分析功能 (Week 7-8)
1. 统计分析服务
2. 图表组件
3. 分析页面

### 阶段5：测试和优化 (Week 9-10)
1. 单元测试
2. 性能优化
3. Bug 修复
