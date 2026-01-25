---
description: 查看当前 Agent 系统状态
allowed-tools: ["Read", "Glob"]
---

# Agent 系统状态

查看多 Agent 系统的当前状态。

## 执行步骤

### Step 1: 读取系统状态

读取以下状态文件：
- `.claude/state/current-task.json`
- `.claude/state/current-design.json`
- `.claude/state/requirements/index.json`

### Step 2: 显示系统状态


🤖 Agent 系统状态

可用 Agents:
├── @phase-router - 就绪
├── @design-manager - 就绪
├── @implementation-executor - 就绪
└── @test-agent - 就绪

当前任务:

需求ID: {requirement_id}
任务类型: {task_type}
目标 Agent: {target_agent}
状态: {status}
当前设计:

功能: {feature_name}
设计文档: {design_doc_path}
状态: {status}
需求统计:

总计: {total}
进行中: {in_progress}
已完成: {completed}

上下文目录:
服务文档: {services_count} 个
经验文档: {experience_count} 个
业务规则: {business_count} 个


### Step 3: 提供操作建议

可用命令:

/req-dev <需求> - 开始新需求
/req-list - 查看所有需求
/agent-project-kit:load-service <服务> - 加载服务
/remember <内容> - 记录经验