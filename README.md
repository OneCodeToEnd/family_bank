# 账清 (Family Bank)

个人账单流水分析APP - 帮助您轻松管理家庭账务

## 项目简介

账清是一款基于Flutter开发的跨平台家庭账务管理应用，支持多账户管理、分类记账、数据分析等功能。

### 主要功能

- 家庭组管理：支持创建多个家庭组，管理家庭成员
- 账户管理：管理多个账户（如现金、银行卡、支付宝等）
- 分类管理：自定义收支分类
- 账单记录：快速记录收入和支出
- 数据分析：通过图表直观展示账务数据
- 数据导入：支持CSV格式账单导入
- 数据加密：支持本地数据加密存储

## 环境要求

### 必需环境

- **Flutter SDK**: 3.6.0 或更高版本
- **Dart SDK**: 随Flutter SDK一起安装
- **操作系统**:
  - macOS (用于开发iOS应用)
  - Windows / Linux (用于开发Android/桌面应用)

### 平台特定要求

#### iOS开发
- Xcode 14.0 或更高版本
- CocoaPods

#### Android开发
- Android Studio 或 Android SDK
- JDK 11 或更高版本

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
├── main.dart                 # 应用入口
├── models/                   # 数据模型
├── providers/               # 状态管理Provider
│   ├── family_provider.dart
│   ├── account_provider.dart
│   ├── category_provider.dart
│   └── transaction_provider.dart
├── screens/                 # 页面
│   ├── onboarding_screen.dart
│   └── account/
│       └── account_list_screen.dart
└── services/               # 服务层（数据库、文件处理等）
```

## 技术栈

- **UI框架**: Flutter (Material Design 3)
- **状态管理**: Provider
- **路由管理**: Go Router
- **本地数据库**: SQLite (sqflite)
- **图表展示**: fl_chart
- **文件处理**: file_picker, csv
- **数据加密**: crypto, encrypt
- **本地存储**: shared_preferences

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

### 4. 数据库相关错误
首次运行时，应用会自动初始化数据库。如果遇到问题，可以卸载应用重新安装。

## 版本信息

- 当前版本: 1.0.0+1
- Flutter版本要求: >=3.6.0
- Dart版本: 随Flutter版本

## 路线图

### 当前版本 (V1.0)
- 基础账单管理
- 家庭组功能
- 账户管理
- 分类管理
- 数据统计

### 计划功能 (V1.1)
- OCR识别账单（google_mlkit_text_recognition）
- 拍照上传（image_picker）
- 生物识别登录（local_auth）

## 开发者

如需帮助或反馈问题，请联系项目维护者。

## 许可证

本项目为私有项目 (publish_to: 'none')

---

**Happy Coding!** 🎉
