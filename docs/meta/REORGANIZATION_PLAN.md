# 文档重组计划

## 目标
将 docs 目录下的文档按照功能和用途进行合理分类，提升文档的可维护性和可读性。

## 新的目录结构

```
docs/
├── index.md                          # 文档首页（保留）
├── getting-started/                  # 快速开始
│   ├── installation.md              # 安装指南（已存在）
│   ├── quickstart.md                # 快速开始（已存在）
│   └── quick-start.md               # 移动：QUICK_START.md
├── features/                         # 功能特性
│   ├── accounts.md                  # 账户管理（已存在）
│   ├── transactions.md              # 交易记录（已存在）
│   ├── categories.md                # 分类管理（已存在）
│   ├── ai-classification.md         # AI 分类（已存在）
│   ├── bill-import.md               # 账单导入（已存在）
│   ├── backup-sync.md               # 备份同步（已存在）
│   ├── analysis.md                  # 数据分析（已存在）
│   ├── budget.md                    # 移动：budget_feature_design.md
│   └── counterparty.md              # 移动：counterparty_feature.md
├── architecture/                     # 架构设计
│   ├── overview.md                  # 移动：project_architecture.md
│   ├── tech-stack.md                # 技术栈（已存在）
│   ├── state-management.md          # 状态管理（已存在）
│   ├── services.md                  # 服务层（已存在）
│   ├── database.md                  # 数据库架构（已存在）
│   └── modules/                     # 模块设计
│       ├── category.md              # 移动：category_module_summary.md
│       ├── transaction.md           # 移动：transaction_module_summary.md
│       └── database-service.md      # 移动：database_service_summary.md
├── design/                           # 设计文档（新建）
│   ├── category-matching.md         # 移动：category_matching_design.md
│   ├── bill-import-mapping.md       # 移动：bill_import_mapping.md
│   └── ui/                          # UI 设计（新建）
│       ├── icon-design.md           # 移动：ICON_DESIGN_GUIDE.md
│       └── app-icon-design.md       # 移动：APP_ICON_DESIGN_GUIDE.md
├── implementation/                   # 实现细节（新建）
│   ├── backup/                      # 备份相关
│   │   ├── overview.md              # 移动：backup_implementation_summary.md
│   │   ├── webdav-sync.md           # 移动：webdav_sync_implementation.md
│   │   ├── self-hosted.md           # 移动：backup_sync_self_hosted.md
│   │   ├── simple-backup.md         # 移动：backup_sync_simple.md
│   │   ├── settings-optimization.md # 移动：backup_settings_optimization.md
│   │   ├── testing.md               # 移动：backup_testing_guide.md
│   │   └── usage.md                 # 移动：backup_usage.md
│   ├── email-sync.md                # 移动：email_sync_implementation.md
│   └── http-interception.md         # 移动：http_interception.md
├── development/                      # 开发指南
│   ├── setup.md                     # 环境搭建（已存在）
│   ├── coding-standards.md          # 编码规范（已存在）
│   ├── testing.md                   # 测试指南（已存在）
│   ├── building.md                  # 构建指南（已存在）
│   ├── refactoring.md               # 移动：REFACTORING_GUIDE.md
│   └── icon-generation.md           # 移动：ICON_GEN_GUIDE.md
├── reference/                        # 参考文档
│   ├── api.md                       # API 参考（已存在）
│   ├── faq.md                       # 常见问题（已存在）
│   ├── database-schema.md           # 数据库模式（已存在）
│   ├── changelog.md                 # 移动：changelog.md
│   └── bug-fixes.md                 # 移动：BUG_FIXES.md
└── meta/                             # 元文档（新建）
    ├── mkdocs-setup.md              # 移动：MK_DOCS_SETUP.md
    └── reorganization-plan.md       # 本文件

## 移动操作清单

### 1. getting-started/
- [ ] QUICK_START.md → getting-started/quick-start.md

### 2. features/
- [ ] budget_feature_design.md → features/budget.md
- [ ] counterparty_feature.md → features/counterparty.md

### 3. architecture/modules/
- [ ] category_module_summary.md → architecture/modules/category.md
- [ ] transaction_module_summary.md → architecture/modules/transaction.md
- [ ] database_service_summary.md → architecture/modules/database-service.md
- [ ] project_architecture.md → architecture/overview.md

### 4. design/ (新建目录)
- [ ] category_matching_design.md → design/category-matching.md
- [ ] bill_import_mapping.md → design/bill-import-mapping.md
- [ ] ICON_DESIGN_GUIDE.md → design/ui/icon-design.md
- [ ] APP_ICON_DESIGN_GUIDE.md → design/ui/app-icon-design.md

### 5. implementation/ (新建目录)
- [ ] backup_implementation_summary.md → implementation/backup/overview.md
- [ ] webdav_sync_implementation.md → implementation/backup/webdav-sync.md
- [ ] backup_sync_self_hosted.md → implementation/backup/self-hosted.md
- [ ] backup_sync_simple.md → implementation/backup/simple-backup.md
- [ ] backup_settings_optimization.md → implementation/backup/settings-optimization.md
- [ ] backup_testing_guide.md → implementation/backup/testing.md
- [ ] backup_usage.md → implementation/backup/usage.md
- [ ] email_sync_implementation.md → implementation/email-sync.md
- [ ] http_interception.md → implementation/http-interception.md

### 6. development/
- [ ] REFACTORING_GUIDE.md → development/refactoring.md
- [ ] ICON_GEN_GUIDE.md → development/icon-generation.md

### 7. reference/
- [ ] changelog.md → reference/changelog.md
- [ ] BUG_FIXES.md → reference/bug-fixes.md
- [ ] database_schema.md → reference/database-schema.md (已存在，需合并)

### 8. meta/ (新建目录)
- [ ] MK_DOCS_SETUP.md → meta/mkdocs-setup.md

## 需要处理的重复文件

1. **database_schema.md** vs **reference/database-schema.md**
   - 需要比较内容，合并或删除重复

## 命名规范

- 所有文件名使用小写字母
- 单词之间使用中划线（-）连接
- 避免使用下划线（_）和大写字母

## 执行步骤

1. 创建新目录：design/、design/ui/、implementation/、implementation/backup/、architecture/modules/、meta/
2. 移动文件到对应目录
3. 更新文件内的交叉引用链接
4. 更新 mkdocs.yml 配置
5. 删除空目录和重复文件
6. 验证所有链接有效性

## 注意事项

- 移动文件前先备份
- 更新所有文档中的相对路径引用
- 更新 mkdocs.yml 中的导航配置
- 检查 CLAUDE.md 中是否有文档路径引用需要更新
