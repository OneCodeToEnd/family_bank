# 安装指南

本指南将帮助您配置开发环境并安装账清应用。

## 环境要求

### 必需软件

- **Flutter SDK**: ≥ 3.6.0
- **Dart SDK**: 随Flutter自动安装
- **Git**: 用于克隆项目

### 平台特定工具

=== "macOS"
    - **Xcode**: 用于iOS/macOS开发
    - **CocoaPods**: iOS依赖管理
    ```bash
    # 安装CocoaPods
    sudo gem install cocoapods
    ```

=== "Windows"
    - **Visual Studio**: 用于Windows桌面开发
    - **Android Studio**: 用于Android开发

=== "Linux"
    - **Android Studio**: 用于Android开发
    - **必需的Linux库**:
    ```bash
    sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
    ```

---

## 安装步骤

### 1. 安装Flutter

访问 [Flutter官网](https://flutter.dev/docs/get-started/install) 下载并安装Flutter SDK。

验证安装：
```bash
flutter doctor
```

### 2. 克隆项目

```bash
git clone https://github.com/OneCodeToEnd/family_bank.git
cd family_bank
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 运行应用

```bash
# 查看可用设备
flutter devices

# 在默认设备上运行
flutter run

# 在指定设备上运行
flutter run -d macos
flutter run -d iphone
flutter run -d chrome
```

---

## 验证安装

运行以下命令检查环境配置：

```bash
# 检查Flutter环境
flutter doctor -v

# 分析代码
flutter analyze

# 运行测试
flutter test
```

---

## 常见问题

### Flutter doctor显示错误

**问题**: `flutter doctor` 显示某些组件未安装

**解决方案**: 根据提示安装缺失的组件，例如：
- Android toolchain: 安装Android Studio
- Xcode: 从App Store安装
- CocoaPods: `sudo gem install cocoapods`

### 依赖安装失败

**问题**: `flutter pub get` 失败

**解决方案**:
```bash
flutter clean
flutter pub get
```

### iOS/macOS构建失败

**问题**: Pod安装或构建失败

**解决方案**:
```bash
cd ios
pod install
pod update
cd ..
flutter clean
flutter run
```

---

## 下一步

安装完成后，查看 [快速上手](quickstart.md) 开始使用应用。