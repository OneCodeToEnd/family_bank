# CLAUDE.md

本文件为 Claude Code 提供项目开发指导和规范。

## 文档管理规范

**所有设计方案文档必须存放在 `docs/` 目录下的相应子目录中，禁止在项目根目录创建设计文档。**

### 文档分类规则

- **功能设计** → `docs/features/` - 新功能需求和设计
- **架构设计** → `docs/architecture/` - 系统架构和技术选型
- **详细设计** → `docs/design/` - 算法、数据结构、业务流程
- **实现方案** → `docs/implementation/` - 具体实现细节
- **开发规范** → `docs/development/` - 开发流程和规范
- **参考文档** → `docs/reference/` - API、Schema、更新日志

### 命名规范

- 使用小写字母，单词用中划线（-）连接
- 示例：`budget-management.md`、`webdav-sync.md`

### 文档内容要求

每个设计文档应包含：标题概述、背景动机、设计目标、详细设计、技术选型、实现计划、风险注意事项

## 开发规范

### 提交规范
- 遵循 Conventional Commits：feat/fix/docs/refactor/test/chore
- 提交信息使用中文

### 项目特定规范

**Provider 使用：**
- 必须在 `main.dart` 初始化
- 调用后必须 `notifyListeners()`

**数据库操作：**
- 使用参数化查询防注入
- 批量操作使用事务
- 版本升级提供迁移脚本


## 注意事项

1. 用户数据本地存储，不上传服务器
2. 支持数据库加密，敏感信息加密存储
3. 大数据量查询使用分页和索引
4. 所有异步操作添加错误处理
5. UI设计兼容移动端、桌面端

