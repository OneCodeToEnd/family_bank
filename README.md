# 账清 (Family Bank)

基于Flutter的跨平台家庭账务管理应用，专注于本地化存储和隐私保护。

## 核心特性

- **本地优先**：SQLite本地存储，完全离线可用，数据不上传任何服务器
- **智能分类**：关键词规则匹配 + AI智能分类（通义千问/DeepSeek）+ 自动学习优化
- **灵活导入**：支持CSV/Excel文件导入、邮箱账单自动获取（IMAP）、智能去重
- **数据分析**：收支统计、分类占比、趋势图表、账户维度分析

## 快速开始

### 环境要求
- Flutter SDK ≥ 3.6.0
- 平台特定工具：Xcode (iOS/macOS)、Android Studio (Android)、Visual Studio (Windows)

### 安装与运行
```bash
# 安装依赖
flutter pub get

# 运行应用（默认设备）
flutter run

# 指定平台运行
flutter run -d macos    # macOS
flutter run -d iphone   # iOS
flutter run -d chrome   # Web

# 构建发布版本
flutter build apk --release      # Android
flutter build ios --release      # iOS
flutter build macos --release    # macOS
```

更多Flutter命令请参考 [Flutter官方文档](https://flutter.dev/docs)

## 架构设计

### 技术栈
- **UI框架**: Flutter 3.6+ (Material Design 3)
- **状态管理**: Provider
- **数据库**: SQLite (sqflite) - 当前版本 V6
- **图表**: fl_chart
- **加密**: AES-256 (crypto, encrypt)
- **邮件**: enough_mail (IMAP)
- **其他**: file_picker, csv, excel, http, logger

### 核心模块

```
lib/
├── models/           # 数据模型（家庭组、账户、分类、交易等）
├── providers/        # Provider状态管理
├── services/         # 服务层
│   ├── database/    # 数据库服务（单例DatabaseService + 各实体DB服务）
│   ├── ai/          # AI分类服务（Qwen、DeepSeek）
│   ├── category/    # 分类匹配、学习、批量分类
│   ├── import/      # 账单导入、邮箱服务、解压
│   └── encryption/  # 数据加密服务
├── screens/         # 页面（账户、分类、交易、导入、分析、设置）
└── widgets/         # 可复用组件
```

### 数据库版本历史
- V1: 初始结构
- V2: 添加交易对方字段
- V3: 增强分类规则（匹配类型、置信度、自动学习）
- V4: HTTP日志表
- V5: 邮箱配置表
- V6: AI模型配置表

### 数据流
用户操作 → Screen → Provider → Service → Database → Provider通知 → UI更新

## 开发指南

### 代码检查与测试
```bash
flutter analyze              # 代码检查
flutter test                 # 运行测试
flutter test test/xxx.dart   # 运行特定测试
```

### 关键实现

**交易去重**：使用SHA-256哈希（account_id + timestamp + amount + description）

**分类匹配策略**：
1. 精确关键词匹配（最高优先级）
2. 模糊匹配 + 置信度评分
3. AI智能分类
4. 用户修正后自动学习优化

**AI分类配置**：
1. 设置 → AI设置 → 添加模型配置
2. 输入API密钥（自动加密存储）
3. 选择模型并自定义提示词

**数据库升级**：
1. 更新 `DbConstants.dbVersion`
2. 在 `DatabaseService._onUpgrade()` 添加升级逻辑
3. 测试从旧版本升级的兼容性

## 常见问题

**依赖安装失败**
```bash
flutter clean && flutter pub get
```

**iOS/macOS构建失败**
```bash
cd ios && pod install && pod update && cd ..
flutter clean && flutter run
```

**Android构建失败**
- 检查 `android/local.properties` 中SDK路径
- 在Android Studio中同步Gradle

**数据库错误**
- 开发环境：卸载应用重新安装
- 生产环境：检查数据库版本和升级逻辑

**AI分类不工作**
- 验证API密钥是否正确
- 查看HTTP日志（设置 → AI设置 → 查看日志）
- 确保网络连接正常

**邮箱导入失败**
- 验证IMAP服务器地址和端口
- 检查邮箱密码（可能需要应用专用密码）
- 确认已开启IMAP服务

## 版本与路线图

**当前版本**: 1.0.0 | **数据库版本**: V6 | **Flutter要求**: ≥3.6.0

### 已实现功能
✅ 家庭组与账户管理
✅ 层级分类树结构
✅ 智能分类规则 + AI分类（通义千问、DeepSeek）
✅ CSV/Excel/邮箱账单导入
✅ 数据统计与分析
✅ 预算管理（年度预算、月度统计、预算预警）
✅ 数据加密与隐私保护

### 计划功能
📋 登录认证
📋 多设备同步

---

**License**: Private Project | **Contact**: 项目维护者
