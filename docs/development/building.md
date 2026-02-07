# 构建与发布

本指南介绍如何构建和发布账清应用到各个平台。

## 构建准备

### 版本号管理

在`pubspec.yaml`中更新版本号：

```yaml
version: 1.0.0+1
```

格式：`主版本.次版本.修订号+构建号`

### 更新日志

更新`CHANGELOG.md`记录版本变更。

---

## Android构建

### Debug构建

```bash
flutter build apk --debug
```

### Release构建

```bash
flutter build apk --release
```

### App Bundle（推荐）

用于Google Play发布：

```bash
flutter build appbundle --release
```

### 签名配置

1. 创建密钥库：
```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

2. 在`android/key.properties`配置：
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=key
storeFile=<path-to-key.jks>
```

3. 在`android/app/build.gradle`引用：
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

---

## iOS构建

### 前置要求

- macOS系统
- Xcode已安装
- Apple Developer账号

### 配置签名

1. 在Xcode中打开`ios/Runner.xcworkspace`
2. 选择Runner target
3. 在Signing & Capabilities中配置Team

### 构建

```bash
flutter build ios --release
```

### 发布到App Store

1. 在Xcode中选择Product → Archive
2. 上传到App Store Connect
3. 提交审核

---

## macOS构建

### 配置

在`macos/Runner/DebugProfile.entitlements`和`Release.entitlements`中配置权限。

### 构建

```bash
flutter build macos --release
```

### 签名和公证

需要Apple Developer账号进行签名和公证。

---

## Windows构建

### 前置要求

- Windows 10/11
- Visual Studio 2022

### 构建

```bash
flutter build windows --release
```

### 打包

使用Inno Setup或NSIS创建安装程序。

---

## Linux构建

### 前置要求

安装必需的开发库：

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

### 构建

```bash
flutter build linux --release
```

### 打包

创建AppImage或Snap包。

---

## Web构建

### 构建

```bash
flutter build web --release
```

### 部署

将`build/web`目录部署到Web服务器。

---

## 构建优化

### 减小包体积

```bash
flutter build apk --release --split-per-abi
```

### 混淆代码

```bash
flutter build apk --release --obfuscate --split-debug-info=/<project-name>/<directory>
```

---

## 发布检查清单

- [ ] 更新版本号
- [ ] 更新CHANGELOG
- [ ] 运行所有测试
- [ ] 代码分析无错误
- [ ] 在真机上测试
- [ ] 检查性能
- [ ] 准备应用商店素材
- [ ] 更新应用描述

---

## 应用商店发布

### Google Play

1. 创建应用
2. 上传App Bundle
3. 填写商店信息
4. 提交审核

### App Store

1. 在App Store Connect创建应用
2. 上传构建版本
3. 填写应用信息
4. 提交审核

### Microsoft Store

1. 创建应用
2. 上传MSIX包
3. 填写商店信息
4. 提交审核

---

## 持续集成/部署

### GitHub Actions

配置自动构建：

```yaml
name: Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

## 相关文档

- [开发环境](setup.md)
- [测试指南](testing.md)
- [代码规范](coding-standards.md)