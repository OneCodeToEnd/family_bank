---
description: 智能 Git 提交 - 分析修改并生成规范的提交信息
allowed-tools: [Bash, Read, Grep]
argument-hint: [可选的提交类型: feat/fix/refactor/perf/style/docs/test/chore]
---

# Git 智能提交

请帮我执行完整的 git 提交流程：

## 步骤

1. **查看修改状态**
   - 运行 `git status` 查看当前修改的文件
   - 运行 `git diff --stat` 查看修改统计

2. **分析修改内容**
   - 如果修改涉及代码文件，使用 Read 工具查看关键修改
   - 理解修改的目的和影响范围
   - 确定合适的提交类型

3. **生成提交信息**
   根据修改内容生成清晰的中文提交信息，格式：
   ```
   <type>: <简短描述>

   <详细说明>
   - 列出主要修改点
   - 列出技术实现
   - 列出修复的问题（如果有）

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
   ```

4. **执行提交**
   - 运行 `git add .` 添加所有修改
   - 运行 `git commit -m "$(cat <<'EOF'...EOF)"` 提交

## 提交类型说明

- **feat**: 新功能
- **fix**: 修复 bug
- **refactor**: 重构代码（不改变功能）
- **perf**: 性能优化
- **style**: 代码格式调整（不影响逻辑）
- **docs**: 文档更新
- **test**: 测试相关
- **chore**: 构建/工具/依赖相关

## 注意事项

- 提交信息要准确描述修改内容
- 使用中文描述，清晰易懂
- 突出重要的技术实现和修复
- 不要提交包含敏感信息的文件
- 如果有 .env、credentials 等敏感文件，警告用户

## 参数说明

如果用户提供了参数（如 `feat`、`fix` 等），使用该类型作为提交类型。
否则根据修改内容自动判断合适的类型。
