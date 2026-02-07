# 账清 (Family Bank)

<div align="center">
  <h3>基于Flutter的跨平台家庭账务管理应用</h3>
  <p>专注于本地化存储和隐私保护</p>
</div>

---

## 核心特性

### 🔒 本地优先
SQLite本地存储，完全离线可用，数据不上传任何服务器，保护您的隐私安全。

### 🤖 智能分类
- 关键词规则匹配
- AI智能分类（通义千问/DeepSeek）
- 自动学习优化

### 📊 灵活导入
- CSV/Excel文件导入
- 邮箱账单自动获取（IMAP）
- 智能去重机制

### 📈 数据分析
- 收支统计
- 分类占比
- 趋势图表
- 账户维度分析

---

## 快速开始

```bash
# 克隆项目
git clone https://github.com/OneCodeToEnd/family_bank.git
cd family_bank

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

查看 [安装指南](getting-started/installation.md) 了解详细步骤。

---

## 技术栈

- **UI框架**: Flutter 3.6+ (Material Design 3)
- **状态管理**: Provider
- **数据库**: SQLite (sqflite) - 当前版本 V6
- **图表**: fl_chart
- **加密**: AES-256 (crypto, encrypt)
- **邮件**: enough_mail (IMAP)

---

## 版本信息

**当前版本**: 1.0.0
**数据库版本**: V6
**Flutter要求**: ≥3.6.0

---

## 开源协议

本项目采用 [MIT License](https://github.com/OneCodeToEnd/family_bank/blob/main/LICENSE) 开源协议。

---

## 文档导航

- [安装指南](getting-started/installation.md) - 环境配置和安装步骤
- [快速上手](getting-started/quickstart.md) - 5分钟快速入门
- [功能特性](features/accounts.md) - 详细功能介绍
- [架构设计](architecture/tech-stack.md) - 技术架构说明
- [开发指南](development/setup.md) - 开发者文档
- [常见问题](reference/faq.md) - 疑难解答
