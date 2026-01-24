---
description: 快速 Git 提交 - 自动分析并提交当前修改
allowed-tools: [Bash, Read]
---

# 快速 Git 提交

自动分析当前修改并生成提交信息，然后执行提交。

## 执行流程

1. 运行 `git status` 和 `git diff --stat` 查看修改
2. 分析修改内容，自动判断提交类型
3. 生成规范的中文提交信息
4. 执行 `git add .` 和 `git commit`

提交信息格式遵循约定式提交规范，包含：
- 类型和简短描述
- 详细的修改说明
- Claude Code 标识

注意：此命令会自动提交所有修改，请确保修改内容正确。
