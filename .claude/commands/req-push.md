---
description: 为需求相关的模块创建分支并推送到远程仓库
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
argument-hint: <requirement-id> [branch-name]
---

# 需求分支推送命令

为需求 **$ARGUMENTS** 创建分支并推送到远程仓库。

## 命令说明

此命令用于：
1. 读取需求状态文件，获取涉及的模块列表
2. 为每个有变更的模块创建分支
3. 提交变更并推送到远程仓库
4. 生成 Merge Request 链接

## 使用方法

```bash
/req-push REQ-001                    # 使用需求ID作为分支名
/req-push REQ-001 feature/user-auth  # 指定自定义分支名
```

---

## 执行步骤

### Step 1: 解析参数

从 $ARGUMENTS 中解析：
- 第一个参数：需求ID（必需）
- 第二个参数：分支名（可选，默认使用需求ID）

示例：
- `REQ-001` → 需求ID=REQ-001, 分支名=REQ-002
- `REQ-001 feature/auth` → 需求ID=REQ-001, 分支名=feature/auth

### Step 2: 读取需求状态

读取 `.claude/state/requirements/{requirement-id}.json` 文件，获取：
- 需求标题
- 涉及的模块列表（modifiedServices）
- 需求描述

如果文件不存在，提示用户需求不存在并退出。

### Step 3: 检查模块变更

对于每个涉及的模块：

1. 进入模块目录
2. 执行 `git status` 检查是否有变更
3. 如果有变更，记录该模块需要推送

如果没有任何模块有变更，提示用户并退出。

### Step 4: 创建分支并推送

对于每个有变更的模块，按顺序执行：

#### 4.1 检查当前分支

```bash
cd {module-path}
git branch --show-current
```

#### 4.2 创建新分支

```bash
git checkout -b {branch-name}
```

如果分支已存在，询问用户是否切换到该分支。

#### 4.3 添加变更文件

```bash
git add .
```

或者只添加已修改的文件（不包括 untracked 的 context/ 等目录）。

#### 4.4 生成提交信息

根据需求信息生成提交信息：

```
feat: {需求标题}

{需求描述摘要}

涉及模块：{module-name}

🤖 Generated with Claude Code
```

#### 4.5 提交变更

```bash
git commit -m "{commit-message}"
```

#### 4.6 推送到远程

```bash
git push -u origin {branch-name}
```

如果推送失败（如网络问题），提示用户并询问是否重试。

### Step 5: 生成报告

生成推送结果报告，包括：

```markdown
## Git 推送完成 ✓

### 成功推送的模块

1. **{module-1}**
   - 分支：{branch-name}
   - 提交：{commit-message-title}
   - MR 链接：{merge-request-url}

2. **{module-2}**
   - 分支：{branch-name}
   - 提交：{commit-message-title}
   - MR 链接：{merge-request-url}

### 失败的模块

- **{module-3}**: {error-message}

---

您可以通过上述链接创建 Merge Request 进行代码审查。
```

### Step 6: 更新需求状态

在需求状态文件中记录：
- 推送的分支名
- 推送时间
- 推送的模块列表

---

## 注意事项

1. **网络连接**：推送前确保 VPN 已关闭或网络连接正常
2. **未提交的变更**：只推送已修改的文件，不包括 untracked 的临时文件
3. **分支冲突**：如果分支已存在，会提示用户选择操作
4. **提交信息**：自动生成规范的提交信息，包含需求上下文
5. **错误处理**：如果某个模块推送失败，继续处理其他模块

## 错误处理

- 需求不存在：提示用户检查需求ID
- 无变更文件：提示用户没有需要推送的内容
- 网络错误：提示用户检查网络连接并提供重试选项
- Git 错误：显示详细错误信息并提供解决建议
