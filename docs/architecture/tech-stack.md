# 技术栈

账清采用现代化的技术栈，确保应用的性能、可维护性和跨平台能力。

## 核心技术

### Flutter

**版本要求**：≥ 3.6.0

Flutter是Google开发的跨平台UI框架：
- 单一代码库支持多平台
- 高性能原生体验
- 丰富的UI组件
- 热重载开发体验

**支持平台**：
- iOS
- Android
- macOS
- Windows
- Linux
- Web

### Dart

**版本**：随Flutter自动安装

Dart是Flutter的编程语言：
- 强类型语言
- 空安全特性
- 异步编程支持
- AOT和JIT编译

---

## UI框架

### Material Design 3

使用最新的Material Design 3设计规范：
- 现代化的视觉设计
- 动态颜色系统
- 自适应布局
- 深色模式支持

### 主要UI库

- **flutter/material.dart** - Material组件
- **fl_chart** - 图表库
- **file_picker** - 文件选择器
- **image_picker** - 图片选择器

---

## 状态管理

### Provider

使用Provider进行状态管理：
- 简单易用
- 性能优秀
- 官方推荐
- 良好的可测试性

**核心Provider**：
- `FamilyProvider` - 家庭组管理
- `AccountProvider` - 账户管理
- `CategoryProvider` - 分类管理
- `TransactionProvider` - 交易管理
- `SettingsProvider` - 设置管理

---

## 数据存储

### SQLite

使用SQLite作为本地数据库：
- **sqflite** - Flutter SQLite插件
- 轻量级嵌入式数据库
- 支持复杂查询
- 事务支持
- 外键约束

**当前数据库版本**：V6

### 数据加密

- **crypto** - 加密算法库
- **encrypt** - 加密工具
- AES-256加密
- SHA-256哈希

---

## 网络通信

### HTTP客户端

- **http** - HTTP请求库
- 自定义日志拦截器
- 请求/响应日志记录

### 邮件服务

- **enough_mail** - IMAP邮件库
- 支持邮箱账单获取
- 附件下载和解析

---

## 文件处理

### 文件操作

- **path_provider** - 路径获取
- **path** - 路径处理
- **file_picker** - 文件选择

### 数据格式

- **csv** - CSV文件解析
- **excel** - Excel文件处理
- **archive** - ZIP文件解压

---

## 工具库

### 日志

- **logger** - 日志记录
- 分级日志输出
- 调试信息记录

### 日期时间

- **intl** - 国际化和日期格式化
- 支持多语言
- 日期时间格式化

### 其他

- **shared_preferences** - 本地配置存储
- **url_launcher** - URL启动器
- **package_info_plus** - 应用信息获取

---

## 开发工具

### 代码质量

```bash
# 代码分析
flutter analyze

# 代码格式化
flutter format .

# 运行测试
flutter test
```

### 构建工具

```bash
# Debug构建
flutter build apk --debug

# Release构建
flutter build apk --release
flutter build ios --release
flutter build macos --release
```

---

## 依赖管理

### pubspec.yaml

所有依赖在`pubspec.yaml`中管理：

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  sqflite: ^2.0.0
  fl_chart: ^0.60.0
  # ... 其他依赖
```

### 版本控制

- 使用语义化版本号
- 定期更新依赖
- 测试兼容性

---

## 性能优化

### 数据库优化

- 使用索引加速查询
- 批量操作使用事务
- 分页加载大数据集

### UI优化

- 使用`const`构造函数
- 避免不必要的重建
- 图片缓存和压缩

### 内存优化

- 及时释放资源
- 避免内存泄漏
- 使用弱引用

---

## 安全性

### 数据安全

- 本地数据加密
- API密钥加密存储
- 安全的密码处理

### 网络安全

- HTTPS通信
- 证书验证
- 防止中间人攻击

---

## 相关文档

- [数据库设计](database.md)
- [状态管理](state-management.md)
- [服务层](services.md)