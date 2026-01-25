---
description: 删除需求相关的远程分支，保持仓库整洁
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
argument-hint: <requirement-id> [--force]
---

# 需求分支清理命令

删除需求 **$ARGUMENTS** 相关的远程分支。

## 命令说明

此命令用于：
1. 读取需求状态文件，获取涉及的模块列表
2. 检查每个模块的远程分支是否存在
3. 删除远程分支（可选：同时删除本地分支）
4. 生成清理报告

## 使用方法

```bash
/req-branch-clean REQ-002              # 删除 REQ-002 相关的远程分支
/req-branch-clean REQ-002 --force      # 强制删除，不进行确认
```

---

## 执行步骤

### Step 1: 解析参数

从 $ARGUMENTS 中解析：
- 第一个参数：需求ID（必需）
- 可选参数：--force（跳过确认）

### Step 2: 读取需求状态

读取 `.claude/state/requirements/{requirement-id}.json` 文件，获取：
- 需求标题
- 涉及的模块列表（见 related_services 配置项）
- 推送的分支名（如果有记录）

如果文件不存在，提示用户需求不存在并退出。

### Step 3: 确定分支名

优先级：
1. 从需求状态文件中读取已推送的分支名
2. 如果没有记录，默认使用需求ID作为分支名

### Step 4: 检查远程分支

对于每个涉及的模块：

#### 4.1 进入模块目录

```bash
cd {module-path}
```

#### 4.2 检查远程分支是否存在

```bash
git ls-remote --heads origin {branch-name}
```

如果分支存在，记录该模块需要清理。

#### 4.3 检查本地分支

```bash
git branch --list {branch-name}
```

记录本地分支是否存在。

### Step 5: 用户确认（除非使用 --force）

如果没有 --force 参数，显示将要删除的分支列表并询问用户：

```
⚠️  即将删除以下远程分支：

1. chatgpt-db-core
   - 远程分支: origin/REQ-002
   - 本地分支: REQ-002 (存在)

2. llm-workflow-service
   - 远程分支: origin/REQ-002
   - 本地分支: REQ-002 (存在)

3. chatdb-visual-service
   - 远程分支: origin/REQ-002
   - 本地分支: REQ-002 (不存在)

是否继续删除？
- 选项1: 删除远程分支和本地分支
- 选项2: 仅删除远程分支
- 选项3: 取消操作
```

使用 AskUserQuestion 工具获取用户选择。

### Step 6: 执行删除操作

对于每个需要清理的模块：

#### 6.1 删除远程分支

```bash
cd {module-path}
git push origin --delete {branch-name}
```

#### 6.2 删除本地分支（如果用户选择）

首先检查当前是否在该分支上：

```bash
current_branch=$(git branch --show-current)
if [ "$current_branch" = "{branch-name}" ]; then
    git checkout develop || git checkout master
fi
```

然后删除本地分支：

```bash
git branch -D {branch-name}
```

#### 6.3 错误处理

- 如果远程分支不存在：跳过并记录
- 如果删除失败：记录错误信息并继续处理其他模块
- 如果网络错误：提示用户并提供重试选项

### Step 7: 生成清理报告

```markdown
## 分支清理完成 ✓

### 成功清理的模块

1. **chatgpt-db-core**
   - ✓ 远程分支 origin/REQ-002 已删除
   - ✓ 本地分支 REQ-002 已删除

2. **llm-workflow-service**
   - ✓ 远程分支 origin/REQ-002 已删除
   - ✓ 本地分支 REQ-002 已删除

3. **chatdb-visual-service**
   - ✓ 远程分支 origin/REQ-002 已删除
   - ⊘ 本地分支不存在，无需删除

### 跳过的模块

- **module-x**: 远程分支不存在

### 失败的模块

- **module-y**: {error-message}

---

共清理 3 个模块的远程分支。
```

### Step 8: 更新需求状态（可选）

在需求状态文件中记录：
- 分支清理时间
- 清理状态

---

## 注意事项

1. **确认操作**：默认会要求用户确认，使用 --force 可跳过
2. **本地分支**：可选择是否同时删除本地分支
3. **当前分支**：如果当前在要删除的分支上，会自动切换到 develop 或 master
4. **网络连接**：删除远程分支需要网络连接
5. **权限检查**：确保有删除远程分支的权限

## 安全措施

1. **双重确认**：显示详细的删除列表供用户确认
2. **分步执行**：逐个模块处理，某个失败不影响其他
3. **错误恢复**：如果误删，可以从本地分支重新推送
4. **日志记录**：记录所有删除操作

## 使用场景

- 需求已合并到主分支，清理临时分支
- 需求被废弃，清理相关分支
- 定期维护，清理过期分支
- 分支命名错误，需要重新创建

## 错误处理

- **需求不存在**：提示用户检查需求ID
- **无远程分支**：提示用户该需求没有远程分支
- **网络错误**：提示用户检查网络连接并提供重试选项
- **权限错误**：提示用户检查 Git 权限
- **分支保护**：如果分支受保护，提示用户手动处理
