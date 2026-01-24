# Claude Code 自定义命令

这个目录包含了项目的自定义 Claude Code 命令，用于简化常见的开发任务。

## 可用命令

### 📝 Git 提交相关

#### `/commit` - 智能 Git 提交
完整的 Git 提交流程，包括查看修改、分析内容、生成提交信息并执行提交。

**使用方法：**
```bash
/commit              # 自动判断提交类型
/commit feat         # 指定为新功能提交
/commit fix          # 指定为 bug 修复提交
/commit refactor     # 指定为重构提交
```

**支持的提交类型：**
- `feat` - 新功能
- `fix` - 修复 bug
- `refactor` - 重构代码
- `perf` - 性能优化
- `style` - 代码格式调整
- `docs` - 文档更新
- `test` - 测试相关
- `chore` - 构建/工具相关

#### `/quick-commit` - 快速提交
简化版的提交命令，自动分析并快速提交。

**使用方法：**
```bash
/quick-commit
```

#### `/log` - 查看提交历史
美化显示最近的 Git 提交记录。

**使用方法：**
```bash
/log           # 显示最近 10 条提交
/log 20        # 显示最近 20 条提交
```

## 命令格式说明

每个命令文件都遵循 Claude Code 的标准格式：

```markdown
---
description: 命令的简短描述
allowed-tools: [允许使用的工具列表]
argument-hint: [参数提示]
---

# 命令标题

命令的详细说明...
```

## 创建自定义命令

1. 在 `.claude/commands/` 目录下创建 `.md` 文件
2. 添加 YAML 前置元数据（description、allowed-tools 等）
3. 编写命令的详细说明和执行步骤
4. 使用 `/命令名` 调用

## 最佳实践

- **清晰的描述**：在 description 中简洁说明命令用途
- **合适的工具**：在 allowed-tools 中只列出必需的工具
- **详细的说明**：在正文中详细说明执行步骤和注意事项
- **参数提示**：使用 argument-hint 提示用户可用的参数

## 参考资源

- [Claude Code 文档](https://claude.com/claude-code)
- [约定式提交规范](https://www.conventionalcommits.org/zh-hans/)
