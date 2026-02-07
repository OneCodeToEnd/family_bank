# 开发环境设置

本指南帮助开发者配置账清项目的开发环境。

## 前置要求

### 必需软件

- **Flutter SDK** ≥ 3.6.0
- **Dart SDK** (随Flutter安装)
- **Git**
- **IDE**: VS Code 或 Android Studio

### 平台工具

=== "macOS"
    - Xcode (iOS/macOS开发)
    - CocoaPods
    - Homebrew (推荐)

=== "Windows"
    - Visual Studio 2022
    - Windows SDK

=== "Linux"
    - 必需的开发库

---

## 环境配置

### 1. 安装Flutter

访问 [Flutter官网](https://flutter.dev/docs/get-started/install) 安装Flutter SDK。

验证安装：
```bash
flutter doctor -v
```

### 2. 配置IDE

**VS Code:**
```bash
# 安装Flutter扩展
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
```

**Android Studio:**
- 安装Flutter插件
- 安装Dart插件

### 3. 克隆项目

```bash
git clone https://github.com/OneCodeToEnd/family_bank.git
cd family_bank
```

### 4. 安装依赖

```bash
flutter pub get
```

---

## 项目结构

```
family_bank/
├── lib/
│   ├── models/          # 数据模型
│   ├── providers/       # Provider状态管理
│   ├── services/        # 服务层
│   ├── screens/         # 页面
│   ├── widgets/         # 组件
│   └── main.dart        # 入口文件
├── test/                # 测试文件
├── docs/                # 文档
├── android/             # Android配置
├── ios/                 # iOS配置
├── macos/               # macOS配置
├── windows/             # Windows配置
├── linux/               # Linux配置
└── pubspec.yaml         # 依赖配置
```

---

## 运行项目

### 查看可用设备

```bash
flutter devices
```

### 运行应用

```bash
# 默认设备
flutter run

# 指定设备
flutter run -d macos
flutter run -d chrome
flutter run -d iphone
```

### 热重载

运行时按 `r` 进行热重载，按 `R` 进行热重启。

---

## 开发工具

### 代码分析

```bash
flutter analyze
```

### 代码格式化

```bash
flutter format lib/
```

### 运行测试

```bash
flutter test
```

---

## 调试

### 日志输出

使用`logger`包记录日志：

```dart
import 'package:logger/logger.dart';

final logger = Logger();
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
```

### 断点调试

在VS Code或Android Studio中设置断点进行调试。

---

## 常见问题

### 依赖冲突

```bash
flutter clean
flutter pub get
```

### iOS构建失败

```bash
cd ios
pod install
pod update
cd ..
```

---

## 相关文档

- [代码规范](coding-standards.md)
- [测试指南](testing.md)
- [构建发布](building.md)