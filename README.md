# 账清 (Family Bank)

个人账单流水分析APP - 帮助您轻松管理家庭账务

## 项目简介

账清是一款基于Flutter开发的跨平台家庭账务管理应用，专注于本地化数据存储和隐私保护，支持多账户管理、智能分类、数据分析等功能。

### 主要功能

- **家庭组管理**：支持创建多个家庭组，管理家庭成员及其账户
- **账户管理**：管理多个账户（支付宝、微信、银行卡、现金等）
- **智能分类**：
  - 层级分类树结构（一级/二级分类）
  - 基于关键词的自动分类规则
  - AI智能分类（支持通义千问、DeepSeek等模型）
  - 分类学习功能，根据用户修正自动优化规则
- **账单管理**：
  - 快速记录收入和支出
  - 支持CSV/Excel格式账单导入
  - 邮箱账单自动获取（IMAP）
  - 智能去重机制（基于交易哈希）
- **数据分析**：
  - 收支概览统计（年度/月度）
  - 分类占比分析（层级统计）
  - 趋势图表展示
  - 账户维度分析
- **数据安全**：
  - 本地SQLite数据库存储
  - 敏感数据加密（API密钥等）
  - 无需联网，完全离线可用

## 环境要求

### 必需环境

- **Flutter SDK**: 3.6.0 或更高版本
- **Dart SDK**: 3.6.0 或更高版本（随Flutter SDK一起安装）
- **操作系统**:
  - macOS (用于开发iOS/macOS应用)
  - Windows (用于开发Android/Windows应用)
  - Linux (用于开发Android/Linux应用)

### 平台特定要求

#### iOS/macOS开发
- Xcode 14.0 或更高版本
- CocoaPods

#### Android开发
- Android Studio 或 Android SDK
- JDK 11 或更高版本

#### Windows开发
- Visual Studio 2022 或更高版本（包含C++桌面开发工具）

#### Linux开发
- 必要的开发工具包（gcc, make等）

## 安装步骤

### 1. 安装Flutter

如果还没有安装Flutter，请访问 [Flutter官网](https://flutter.dev/docs/get-started/install) 按照说明安装。

验证Flutter安装：
```bash
flutter doctor
```

### 2. 克隆或获取项目

```bash
cd /Users/xiedi/data/rh/code/family_bank
```

### 3. 安装依赖

```bash
flutter pub get
```

## 运行项目

### 在模拟器/真机上运行

#### 1. 检查可用设备
```bash
flutter devices
```

#### 2. 运行应用

在默认设备上运行：
```bash
flutter run
```

在指定设备上运行：
```bash
# iOS模拟器
flutter run -d iphone

# Android模拟器
flutter run -d emulator-5554

# Chrome浏览器（用于Web开发测试）
flutter run -d chrome

# macOS桌面
flutter run -d macos

# Windows桌面
flutter run -d windows

# Linux桌面
flutter run -d linux
```

#### 3. 调试模式运行
```bash
# 开启调试模式（默认）
flutter run --debug

# 开启性能分析
flutter run --profile

# 发布模式
flutter run --release
```

### 热重载

应用运行后，在终端中按：
- `r` - 热重载 (Hot Reload)
- `R` - 热重启 (Hot Restart)
- `q` - 退出应用
- `p` - 显示网格 (Grid)
- `o` - 切换平台 (iOS/Android)

## 构建应用

### Android APK
```bash
# 构建Debug APK
flutter build apk --debug

# 构建Release APK
flutter build apk --release

# 构建AAB (用于Google Play上传)
flutter build appbundle --release
```

生成的文件位于：`build/app/outputs/flutter-apk/` 或 `build/app/outputs/bundle/`

### iOS IPA
```bash
# 构建iOS应用（需要macOS）
flutter build ios --release

# 使用Xcode打开项目进行签名和发布
open ios/Runner.xcworkspace
```

### macOS应用
```bash
flutter build macos --release
```

### Windows应用
```bash
flutter build windows --release
```

### Linux应用
```bash
flutter build linux --release
```

### Web应用
```bash
flutter build web --release
```

## 项目结构

```
lib/
├── main.dart                      # 应用入口，Provider初始化
├── constants/                     # 常量定义
│   ├── db_constants.dart         # 数据库常量（表名、字段名等）
│   ├── ai_model_constants.dart   # AI模型常量
│   └── bill_file_constants.dart  # 账单文件常量
├── models/                        # 数据模型
│   ├── family_group.dart         # 家庭组
│   ├── family_member.dart        # 家庭成员
│   ├── account.dart              # 账户
│   ├── category.dart             # 分类
│   ├── transaction.dart          # 交易记录
│   ├── category_rule.dart        # 分类规则
│   ├── budget.dart               # 预算
│   ├── email_config.dart         # 邮箱配置
│   ├── ai_model_config.dart      # AI模型配置
│   └── ...                       # 其他模型
├── providers/                     # 状态管理Provider
│   ├── family_provider.dart      # 家庭组状态
│   ├── account_provider.dart     # 账户状态
│   ├── category_provider.dart    # 分类状态
│   ├── transaction_provider.dart # 交易状态
│   └── settings_provider.dart    # 设置状态
├── services/                      # 服务层
│   ├── database/                 # 数据库服务
│   │   ├── database_service.dart # 数据库核心服务（单例）
│   │   ├── family_db_service.dart
│   │   ├── account_db_service.dart
│   │   ├── category_db_service.dart
│   │   ├── transaction_db_service.dart
│   │   ├── category_rule_db_service.dart
│   │   ├── email_config_db_service.dart
│   │   ├── ai_model_db_service.dart
│   │   ├── http_log_db_service.dart
│   │   └── preset_category_data.dart # 预设分类数据
│   ├── ai/                       # AI服务
│   │   ├── ai_classifier_factory.dart
│   │   ├── ai_classifier_service.dart
│   │   ├── qwen_classifier_service.dart
│   │   ├── deepseek_classifier_service.dart
│   │   ├── ai_config_service.dart
│   │   └── model_list_parser.dart
│   ├── category/                 # 分类服务
│   │   ├── category_match_service.dart    # 分类匹配
│   │   ├── category_learning_service.dart # 分类学习
│   │   ├── batch_classification_service.dart # 批量分类
│   │   └── classification_error_handler.dart
│   ├── import/                   # 导入服务
│   │   ├── bill_import_service.dart # 账单导入
│   │   ├── email_service.dart       # 邮箱服务
│   │   └── unzip_service.dart       # 解压服务
│   ├── encryption/               # 加密服务
│   │   └── encryption_service.dart
│   ├── http/                     # HTTP服务
│   │   └── logging_http_client.dart # 带日志的HTTP客户端
│   ├── bill_validation_service.dart # 账单验证
│   └── ai_model_config_service.dart # AI模型配置
├── screens/                       # 页面
│   ├── onboarding_screen.dart    # 引导页
│   ├── account/                  # 账户相关页面
│   │   ├── account_list_screen.dart
│   │   └── account_form_screen.dart
│   ├── category/                 # 分类相关页面
│   │   ├── category_list_screen.dart
│   │   ├── category_form_screen.dart
│   │   ├── category_rule_list_screen.dart
│   │   └── category_rule_form_screen.dart
│   ├── transaction/              # 交易相关页面
│   │   ├── transaction_list_screen.dart
│   │   ├── transaction_form_screen.dart
│   │   └── transaction_detail_screen.dart
│   ├── member/                   # 成员相关页面
│   │   ├── member_list_screen.dart
│   │   └── member_form_screen.dart
│   ├── import/                   # 导入相关页面
│   │   ├── bill_import_screen.dart
│   │   ├── import_confirmation_screen.dart
│   │   └── email_bill_select_screen.dart
│   ├── analysis/                 # 分析页面
│   │   └── analysis_screen.dart
│   └── settings/                 # 设置页面
│       ├── settings_screen.dart
│       ├── ai_settings_screen.dart
│       ├── ai_model_management_screen.dart
│       ├── ai_prompt_edit_screen.dart
│       └── email_config_screen.dart
├── widgets/                       # 可复用组件
│   ├── transaction_item_widget.dart
│   ├── transaction_detail_sheet.dart
│   ├── category_hierarchy_stat_card.dart
│   ├── category_stat_node_widget.dart
│   ├── validation/
│   │   └── validation_summary_card.dart
│   └── ai/
│       └── ai_model_dialog.dart
└── utils/                         # 工具类
    ├── app_logger.dart           # 日志工具
    └── category_icon_utils.dart  # 分类图标工具
```

## 技术栈

- **UI框架**: Flutter 3.6+ (Material Design 3)
- **状态管理**: Provider
- **路由管理**: 命令式导航（Navigator）
- **本地数据库**: SQLite (sqflite)
- **图表展示**: fl_chart
- **文件处理**: file_picker, csv, excel
- **数据加密**: crypto, encrypt
- **本地存储**: shared_preferences
- **邮件处理**: enough_mail (IMAP支持)
- **HTTP请求**: http (带日志记录)
- **日志**: logger
- **其他**: intl (国际化), uuid, package_info_plus, flutter_slidable

## 开发指南

### 代码规范

项目使用 `flutter_lints` 进行代码检查。运行以下命令检查代码：
```bash
flutter analyze
```

### 运行测试
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart
```

### 数据库版本管理

当前数据库版本：**6** (定义在 `DbConstants.dbVersion`)

数据库升级历史：
- V1: 初始数据库结构
- V2: 添加交易对方字段 (`counterparty`)
- V3: 增强分类规则（匹配类型、置信度、自动学习等）
- V4: 添加HTTP日志表
- V5: 添加邮箱配置表
- V6: 添加AI模型配置表

修改数据库结构时：
1. 更新 `DbConstants.dbVersion`
2. 在 `DatabaseService._onUpgrade()` 中添加升级逻辑
3. 测试从旧版本升级的兼容性

### AI分类功能

支持的AI提供商：
- **通义千问 (Qwen)**: 阿里云大模型
- **DeepSeek**: DeepSeek大模型

配置AI模型：
1. 在设置页面添加AI模型配置
2. 输入API密钥（自动加密存储）
3. 选择要使用的模型
4. 可自定义分类提示词

### 账单导入

支持的导入方式：
1. **文件导入**: CSV/Excel格式
2. **邮箱导入**: 通过IMAP自动获取邮件附件

导入流程：
1. 解析文件/邮件附件
2. 验证数据格式
3. 计算交易哈希（去重）
4. 匹配分类（规则匹配 + AI分类）
5. 用户确认后保存

### 分类匹配逻辑

分类匹配采用多级策略：
1. **精确匹配**: 基于关键词规则的精确匹配（优先级最高）
2. **模糊匹配**: 支持部分匹配和置信度评分
3. **AI分类**: 使用AI模型进行智能分类
4. **学习优化**: 根据用户修正自动优化规则

### 加密说明

使用 `EncryptionService` 加密敏感数据：
- AI模型API密钥
- 邮箱密码
- 其他敏感配置

加密算法：AES-256

## 常见问题

### 1. 依赖安装失败
```bash
# 清理缓存后重新安装
flutter clean
flutter pub get
```

### 2. iOS构建失败
```bash
cd ios
pod install
pod update
cd ..
flutter clean
flutter run
```

### 3. Android构建失败
- 确保Android SDK已正确安装
- 检查 `android/local.properties` 文件中SDK路径是否正确
- 尝试在Android Studio中打开 `android/` 目录并同步Gradle

### 4. macOS构建失败
```bash
cd macos
pod install
pod update
cd ..
flutter clean
flutter run -d macos
```

### 5. 数据库相关错误
首次运行时，应用会自动初始化数据库。如果遇到问题：
- 开发环境：卸载应用重新安装
- 生产环境：检查数据库版本和升级逻辑

### 6. AI分类不工作
- 检查是否配置了AI模型
- 验证API密钥是否正确
- 查看HTTP日志（设置 -> AI设置 -> 查看日志）
- 确保网络连接正常

### 7. 邮箱导入失败
- 验证IMAP服务器地址和端口
- 检查邮箱密码（可能需要应用专用密码）
- 确认邮箱已开启IMAP服务
- 查看错误日志获取详细信息

### 8. 图标生成问题
```bash
# 确保图标文件存在
ls assets/icon/app_icon.png

# 重新生成图标
flutter pub run flutter_launcher_icons
```

## 版本信息

- 当前版本: 1.0.0+1
- Flutter版本要求: >=3.6.0
- Dart版本要求: >=3.6.0
- 数据库版本: 6

## 功能路线图

详细的迭代计划请参考 [迭代计划.md](./迭代计划.md)

### 当前版本 (V1.0)
- ✅ 基础账单管理
- ✅ 家庭组功能
- ✅ 账户管理
- ✅ 分类管理（层级结构）
- ✅ 数据统计与分析
- ✅ CSV/Excel导入
- ✅ 智能分类规则
- ✅ AI智能分类（通义千问、DeepSeek）
- ✅ 邮箱账单导入
- ✅ 数据加密

### 计划功能 (V1.1+)
- 📋 OCR识别账单（google_mlkit_text_recognition）
- 📋 拍照上传（image_picker）
- 📋 生物识别登录（local_auth）
- 📋 预算管理功能
- 📋 多设备数据同步
- 📋 高级分析报表

## 核心特性

### 本地化优先
- 所有数据存储在本地SQLite数据库
- 无需联网即可使用核心功能
- AI分类功能可选，不影响离线使用

### 隐私保护
- 数据不上传到任何服务器
- 敏感信息（API密钥、密码）加密存储
- 用户完全掌控自己的数据

### 智能分类
- 基于关键词的规则匹配
- AI大模型智能分类
- 自动学习用户习惯
- 支持批量分类处理

### 灵活导入
- 支持CSV/Excel文件导入
- 邮箱自动获取账单
- 智能去重机制
- 导入前预览和确认

## 贡献指南

### 开发流程
1. Fork本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

### 代码规范
- 遵循Flutter官方代码规范
- 使用 `flutter analyze` 检查代码
- 提交前运行测试确保通过
- 添加必要的注释和文档

## 许可证

本项目为私有项目 (publish_to: 'none')

## 联系方式

如需帮助或反馈问题，请联系项目维护者。

---

**Happy Coding!** 🎉
