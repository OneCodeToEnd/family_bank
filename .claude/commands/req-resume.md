---
description: 恢复指定需求的开发
allowed-tools: ["Read", "Write", "Task"]
argument-hint: <requirement-id>
---

# 恢复需求命令

恢复需求 $ARGUMENTS 的开发。

## 执行步骤

### Step 1: 加载需求状态

读取 `.claude/state/requirements/$ARGUMENTS.json`

### Step 2: 恢复上下文

1. 加载需求相关的设计文档
2. 加载相关服务的技术文档
3. 加载历史坑点

### Step 3: 继续执行

根据需求当前阶段，调用对应的 Agent 继续执行：

- **designing** → 调用 @design-manager
- **implementing** → 调用 @implementation-executor
- **testing** → 调用 @test-agent

### Step 4: 确认恢复

✅ 需求已恢复

需求ID: $ARGUMENTS
当前阶段: {phase}
上次更新: {updated_at}

正在继续 {phase} 阶段...