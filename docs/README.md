# 账清 (Family Bank) 文档

欢迎来到账清项目文档！本文档提供了项目的完整技术文档和使用指南。

## 📚 文档结构

### 🚀 [快速开始](getting-started/)
新用户入门指南，帮助你快速了解和使用账清。

- [安装指南](getting-started/installation.md) - 如何安装和配置应用
- [快速开始](getting-started/quickstart.md) - 5分钟快速上手

### ✨ [功能特性](features/)
详细介绍账清的各项功能特性。

- [账户管理](features/accounts.md) - 多账户管理功能
- [交易记录](features/transactions.md) - 交易记录管理
- [分类管理](features/categories.md) - 层级分类系统
- [AI 智能分类](features/ai-classification.md) - AI 驱动的自动分类
- [账单导入](features/bill-import.md) - CSV/Excel 账单导入
- [预算管理](features/budget.md) - 年度预算规划与追踪
- [交易对手方](features/counterparty.md) - 交易对手方管理
- [备份同步](features/backup-sync.md) - 数据备份与云端同步
- [数据分析](features/analysis.md) - 财务数据分析与可视化

### 🏗️ [架构设计](architecture/)
深入了解账清的技术架构和设计理念。

- [架构概览](architecture/overview.md) - 整体架构设计
- [技术栈](architecture/tech-stack.md) - 使用的技术和框架
- [状态管理](architecture/state-management.md) - Provider 状态管理方案
- [服务层](architecture/services.md) - 服务层架构设计
- [数据库](architecture/database.md) - 数据库设计与实现
- **模块设计**
  - [分类模块](architecture/modules/category.md)
  - [交易模块](architecture/modules/transaction.md)
  - [数据库服务](architecture/modules/database-service.md)

### 🎨 [设计文档](design/)
功能设计和 UI 设计文档。

- [分类匹配设计](design/category-matching.md) - 智能分类匹配算法
- [账单导入映射](design/bill-import-mapping.md) - 账单字段映射规则
- **UI 设计**
  - [图标设计指南](design/ui/icon-design.md)
  - [应用图标设计](design/ui/app-icon-design.md)

### 🔧 [实现细节](implementation/)
关键功能的具体实现细节。

- [邮件同步](implementation/email-sync.md) - 邮件账单同步实现
- [HTTP 拦截](implementation/http-interception.md) - HTTP 请求拦截与日志
- **备份功能实现**
  - [备份概览](implementation/backup/overview.md)
  - [WebDAV 同步](implementation/backup/webdav-sync.md)
  - [自托管方案](implementation/backup/self-hosted.md)
  - [简易备份](implementation/backup/simple-backup.md)
  - [设置优化](implementation/backup/settings-optimization.md)
  - [测试指南](implementation/backup/testing.md)
  - [使用说明](implementation/backup/usage.md)

### 👨‍💻 [开发指南](development/)
面向开发者的指南和最佳实践。

- [环境搭建](development/setup.md) - 开发环境配置
- [编码规范](development/coding-standards.md) - 代码风格和规范
- [测试指南](development/testing.md) - 单元测试和集成测试
- [构建指南](development/building.md) - 多平台构建说明
- [重构指南](development/refactoring.md) - 代码重构最佳实践
- [图标生成](development/icon-generation.md) - 应用图标生成工具

### 📖 [参考文档](reference/)
API 参考、FAQ 和其他参考资料。

- [API 参考](reference/api.md) - API 接口文档
- [数据库模式](reference/database-schema.md) - 完整的数据库表结构
- [常见问题](reference/faq.md) - 常见问题解答
- [更新日志](reference/changelog.md) - 版本更新记录
- [Bug 修复记录](reference/bug-fixes.md) - 已修复的问题列表

### 📝 [元文档](meta/)
关于文档本身的说明。

- [MkDocs 配置](meta/mkdocs-setup.md) - 文档站点配置说明

## 🔍 快速导航

### 我想...

- **开始使用账清** → [快速开始](getting-started/quickstart.md)
- **了解如何导入账单** → [账单导入](features/bill-import.md)
- **设置 AI 自动分类** → [AI 智能分类](features/ai-classification.md)
- **配置云端同步** → [备份同步](features/backup-sync.md)
- **参与开发** → [开发指南](development/setup.md)
- **了解数据库结构** → [数据库模式](reference/database-schema.md)
- **查看更新内容** → [更新日志](reference/changelog.md)

## 🤝 贡献

如果你发现文档有任何问题或想要改进，欢迎提交 Issue 或 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](../LICENSE) 文件。
