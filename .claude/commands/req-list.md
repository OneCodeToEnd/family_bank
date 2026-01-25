---
description: 列出所有需求及其状态
allowed-tools: ["Read", "Glob"]
---


# 需求列表命令

列出所有需求及其当前状态。

## 执行步骤

### Step 1: 读取需求索引

读取 `.claude/state/requirements/index.json`

### Step 2: 显示需求列表

以表格形式显示所有需求：

📋 需求列表

ID	标题	状态	阶段	最后更新
REQ-001	用户登录功能	in_progress	implementing	2024-01-17
REQ-002	商品发放	pending	-	2024-01-16
总计: 2 个需求

进行中: 1
待处理: 1
已完成: 0

### Step 3: 提供操作建议
可用操作:

/req-dev <需求描述> - 继续或开始需求开发
/req-status - 查看需求详情

