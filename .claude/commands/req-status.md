---
description: 查看指定需求的详细状态
allowed-tools: ["Read"]
argument-hint: <requirement-id>
---

# 需求状态命令

查看需求 $ARGUMENTS 的详细状态。

## 执行步骤

### Step 1: 读取需求状态

读取 `.claude/state/requirements/$ARGUMENTS.json`

### Step 2: 显示详细信息

📋 需求详情: $ARGUMENTS

基本信息:

标题: {title}
状态: {status}
当前阶段: {phase}
创建时间: {created_at}
最后更新: {updated_at}
关联文件:

设计文档: {design_doc}
测试报告: {test_report}
Git 分支: {branch}
历史记录:
{history}

### 下一步操作:

/req-dev {title} - 继续开发
/req-resume $ARGUMENTS - 恢复到上次状态