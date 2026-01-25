---
description: 加载并分析服务代码，生成技术文档
allowed-tools: ["Bash", "Read", "Write", "Grep", "Glob"]
argument-hint: <service-name> [git-repo-url]
---


# Load Service

加载服务并生成技术文档。

## 执行步骤

### Step 1: 准备代码

如果提供了 Git 地址（$2），则克隆代码：

```bash
mkdir -p workspace/loadservice/
git clone $2 workspace/loadservice/$1 2>/dev/null || cd workspace/loadservice/$1 && git pull
```

**如果未提供 Git 地址，则分析当前 Flutter 项目目录**（/Users/xiedi/data/rh/code/family_bank）。

### Step 2: 分析代码

**分析目录**：
- 如果提供了 Git 地址：分析 `workspace/loadservice/$1` 目录
- 如果未提供 Git 地址：分析当前项目目录（/Users/xiedi/data/rh/code/family_bank）

**分析内容**：
- **基本信息**：服务名、版本、技术栈（Flutter 项目查看 pubspec.yaml）
- **核心模块**：主要类、接口、分层结构（lib/ 目录结构）
- **API**：对外接口列表（查找 API 调用、网络请求）
- **数据**：核心实体、数据模型（models/、entities/ 目录）
- **配置**：关键配置项（pubspec.yaml、配置文件）
- **路由**：页面路由结构（routes/ 或路由配置）
- **状态管理**：使用的状态管理方案（Provider、Riverpod、Bloc 等）

### Step 3: 生成文档

保存到 `context/tech/services/$1.md`，包含：
- 基本信息（名称、版本、技术栈）
- 业务定位
- 技术栈
- 核心模块说明
- API 列表
- 数据模型
- 配置要点

### Step 4: 记录坑点

如有发现，记录到 `context/experience/$1-注意事项.md`。

### Step 5: 更新索引

在 `context/INDEX.md` 添加服务引用。
