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
- **数据库**: SQLite (sqflite) - 当前版本 V10
- **图表**: fl_chart
- **加密**: AES-256 (crypto, encrypt)
- **邮件**: enough_mail (IMAP)

---

## 版本信息

**当前版本**: 1.0.0
**数据库版本**: V10
**Flutter要求**: ≥3.6.0

---

## 开源协议

本项目采用 [MIT License](https://github.com/OneCodeToEnd/family_bank/blob/main/LICENSE) 开源协议。

---

## 文档导航

### 🚀 快速开始
- [安装指南](getting-started/installation.md) - 环境配置和安装步骤
- [快速上手](getting-started/quickstart.md) - 5分钟快速入门

### ✨ 功能特性
- [账户管理](features/accounts.md) - 多账户管理
- [交易记录](features/transactions.md) - 交易记录管理
- [分类管理](features/categories.md) - 层级分类系统
- [AI 智能分类](features/ai-classification.md) - AI 驱动的自动分类
- [账单导入](features/bill-import.md) - CSV/Excel 账单导入
- [预算管理](features/budget.md) - 年度预算规划
- [备份同步](features/backup-sync.md) - 数据备份与云端同步
- [数据分析](features/analysis.md) - 财务数据分析

### 🏗️ 架构设计
- [架构概览](architecture/overview.md) - 整体架构设计
- [技术栈](architecture/tech-stack.md) - 使用的技术和框架
- [状态管理](architecture/state-management.md) - Provider 状态管理
- [数据库](architecture/database.md) - 数据库设计

### 👨‍💻 开发指南
- [环境搭建](development/setup.md) - 开发环境配置
- [编码规范](development/coding-standards.md) - 代码风格和规范
- [测试指南](development/testing.md) - 单元测试和集成测试
- [构建指南](development/building.md) - 多平台构建说明

### 📖 参考文档
- [API 参考](reference/api.md) - API 接口文档
- [数据库模式](reference/database-schema.md) - 数据库表结构
- [常见问题](reference/faq.md) - 疑难解答
- [更新日志](reference/changelog.md) - 版本更新记录

---

📚 完整文档结构请查看项目文档导航
