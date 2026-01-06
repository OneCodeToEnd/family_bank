# Family Bank 项目规则

## 🎯 代码规范

### 代码整洁之道

1. 使用日志打印来记录日志，而不是简单的 print
2. 在做任何任务的时候，请记住不要写重复性的代码，如果出现重复性的代码，请思考是否可以拆分模块便于复用。
3. 系统性地解决问题，而不是局部修修补补

### 代码分析

1. flutter analyze 解决 info/warning/error 级别的问题，保证代码简洁
2.  

### 1. 禁止使用正则表达式
- **原因**：CPU 性能问题，容易造成性能飙升
- **替代方案**：使用简单字符串操作
  - `String.contains()`
  - `String.startsWith()`
  - `String.endsWith()`
  - `String.indexOf()`

### 2. Late 变量初始化
- ❌ 禁止：`late final` + 构造函数 + 方法中多次调用 `_init()`
- ✅ 推荐方案 1：使用 getter
  ```dart
  Future<Database> get _db async => await _dbService.database;
  ```
- ✅ 推荐方案 2：可空类型 + 防重复初始化
  ```dart
  Database? _db;
  Future<void> _init() async {
    if (_db != null) return;
    _db = await _dbService.database;
  }
  ```

### 3. Flutter 生命周期
- ❌ 禁止在 `initState` 中直接调用可能触发 `setState` 的方法
- ✅ 使用 `addPostFrameCallback`：
  ```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  ```

### 4. 数据库升级
- ✅ 使用 `CREATE TABLE IF NOT EXISTS` 确保表存在
- ✅ 在 `_onUpgrade` 开始时创建关键表
- ✅ 考虑所有升级路径（V1→V3, V2→V3）

---


## 📂 文档管理规则（死命令）

### docs/ 目录规则
docs 目录下**只能有两类文档**：

1. **需求文档（多个）**
   - 描述功能需求、设计方案、技术规范
   - 例如：`REQUIREMENTS.md`、`category_matching_design.md`、`database_schema.md` 等
   - 可以有多个需求文档，按主题组织

2. **Bug 修复文档（仅一个）**
   - 文件名：`BUG_FIXES.md`
   - **新 Bug 必须登记在文档最前方**
   - 格式：
     ```markdown
     ## Bug #N: 标题 (日期)
     ### 问题描述
     ### 根本原因
     ### 解决方案
     ### 修复状态
     ```

### 禁止的文档类型
- ❌ 临时总结文档（如 `implementation_summary.md`）
- ❌ 进度报告（如 `progress_report.md`）
- ❌ 快速开始指南（如 `quick_start.md`）
- ❌ 阶段性总结（如 `phase1_completion_summary.md`）
- ❌ 单个 Bug 修复文档（如 `fix_*.md`）
- ❌ 测试数据文件（如 `.csv`、`.xlsx`）

### 执行原则
- 创建新文档前，先判断是否属于"需求文档"或"Bug 修复文档"
- 如果都不是，**不要创建**
- Bug 修复内容统一追加到 `BUG_FIXES.md` 最前方
- 定期检查并删除不符合规则的文档

---


## 🔐 安全规范

### API Key 存储
- ✅ 使用纯 Dart AES 加密（支持 Web 平台）
- ✅ 存储在本地数据库 `app_settings` 表
- ✅ 不上传到任何外部服务器
- ✅ 加密密钥基于应用标识和固定盐值

### 网络权限
- macOS 需要在 entitlements 中添加：
  ```xml
  <key>com.apple.security.network.client</key>
  <true/>
  ```

---

## 📝 Git 提交规范

### 提交信息格式
```
<type>: <subject>

<body>
```

### Type 类型
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具相关

### 示例
```
feat: 添加 AI 智能分类功能

- 实现 5 层级联匹配策略
- 支持 DeepSeek 和 Qwen API
- 自动学习规则机制
- 批量处理优化
```

---

## 🧪 测试要求

### 必须测试的场景
1. 数据库升级路径（V1→V3, V2→V3）
2. 跨平台兼容性（Web、iOS、Android、macOS）
3. 网络错误处理
4. API Key 加密解密
5. 批量处理性能（100+ 条交易）

### 性能基准
- 单条交易匹配：< 100ms（不含 AI）
- 批量处理（100 条）：< 10s（不含 AI）
- AI 分类：< 3s/条
- 配置加载：< 100ms

---

## 📚 参考文档

- 需求文档：`docs/REQUIREMENTS.md`
- Bug 修复记录：`docs/BUG_FIXES.md`
- 数据库架构：`docs/database_schema.md`
- 项目架构：`docs/project_architecture.md`
