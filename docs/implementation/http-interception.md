## 🔍 HTTP 调用拦截日志系统（V4 新增）

### 需求背景
为便于分析 AI 服务调用问题、监控 API 性能和排查网络错误，需要实现完整的 HTTP 调用拦截和日志记录功能。

### 核心功能

#### 1. 完整日志记录
- **请求信息**：
  - URL（完整路径）
  - HTTP 方法（GET/POST/PUT/DELETE）
  - 请求头（JSON 格式，包含 Authorization）
  - 请求体（完整内容）
  - 请求大小（字节数）

- **响应信息**：
  - HTTP 状态码（200/404/500 等）
  - 状态消息（OK/Not Found 等）
  - 响应头（JSON 格式）
  - 响应体（完整内容）
  - 响应大小（字节数）

- **性能指标**：
  - 请求开始时间（毫秒时间戳）
  - 请求结束时间（毫秒时间戳）
  - 总耗时（毫秒）

- **错误信息**：
  - 错误类型（timeout/network/api/parse/unknown）
  - 错误消息
  - 堆栈跟踪

- **元数据**：
  - 请求唯一 ID（UUID）
  - 服务名称（deepseek_classifier/qwen_classifier）
  - API 提供商（deepseek/qwen）
  - 创建时间/更新时间

#### 2. 异步记录机制
- 日志写入异步执行，不阻塞 HTTP 请求
- 先记录请求开始，后更新响应结果
- 即使日志写入失败也不影响原始请求

#### 3. 数据管理
- **存储策略**：手动清理，不自动清理
- **查询功能**：
  - 按请求 ID 查询
  - 查询最近日志（默认 100 条）
  - 按服务名过滤
  - 查询失败请求
- **清理功能**：
  - 删除指定日期之前的日志
  - 清空所有日志
- **统计功能**：
  - 总请求数/成功数/失败数
  - 平均/最大/最小耗时
  - 总请求/响应数据大小

#### 4. 技术实现

**HTTP 拦截器**：
```dart
class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;
  final HttpLogDbService _logService;
  final String? serviceName;
  final String? apiProvider;
  final bool enabled;

  // 继承 BaseClient，覆盖 send() 方法
  // 使用装饰器模式包装原始 Client
  // 支持启用/禁用日志记录
}
```

**数据库表结构**：
```sql
CREATE TABLE http_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  request_id TEXT NOT NULL UNIQUE,
  method TEXT NOT NULL,
  url TEXT NOT NULL,
  request_headers TEXT,
  request_body TEXT,
  request_size INTEGER,
  status_code INTEGER,
  status_message TEXT,
  response_headers TEXT,
  response_body TEXT,
  response_size INTEGER,
  start_time INTEGER NOT NULL,
  end_time INTEGER,
  duration_ms INTEGER,
  error_type TEXT,
  error_message TEXT,
  stack_trace TEXT,
  service_name TEXT,
  api_provider TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

**索引设计**：
- `request_id`：唯一索引，快速查找单个请求
- `created_at DESC`：时间倒序，支持分页查询最新日志
- `service_name`：按服务过滤
- `status_code`：快速查找失败请求（4xx, 5xx）

#### 5. 集成方式
- 通过依赖注入集成到 AI 服务
- 仅修改默认 Client 创建逻辑
- 测试代码可注入 mock Client 绕过日志
- 符合现有依赖注入模式

```dart
DeepSeekClassifierService(
  this.apiKey,
  this.modelId,
  this.config, {
  http.Client? client,
  this.timeout = const Duration(seconds: 10),
}) : _client = client ??
      LoggingHttpClient(
        http.Client(),
        serviceName: 'deepseek_classifier',
        apiProvider: 'deepseek',
      );
```

### 技术约束

#### 1. 不脱敏策略
- 记录完整的 API Key、Authorization 等敏感信息
- 用于调试和问题排查
- 数据仅存储在本地，不上传外部

#### 2. StreamedResponse 处理
- 使用 `Response.fromStream()` 转换
- 适用于小响应（AI API 响应通常 < 1MB）
- 避免流只能读取一次的问题

#### 3. 性能考虑
- 异步写入，单次请求额外开销 < 10ms
- 每条日志约 1-5 KB（取决于 body 大小）
- 1000 条请求约占 1-5 MB

### 安全注意事项
- ⚠️ 日志包含完整的 API Key 和敏感数据
- ⚠️ 仅用于开发调试和问题排查
- ⚠️ 定期清理日志，避免数据泄露
- ⚠️ 生产环境建议禁用或仅记录错误日志

### 实现文件清单

**新建文件**：
1. `lib/models/http_log.dart` - HTTP 日志模型
2. `lib/services/database/http_log_db_service.dart` - 数据库服务
3. `lib/services/http/logging_http_client.dart` - 拦截器

**修改文件**：
1. `lib/constants/db_constants.dart` - 添加常量定义
2. `lib/services/database/database_service.dart` - 数据库升级
3. `lib/services/ai/deepseek_classifier_service.dart` - 集成日志
4. `lib/services/ai/qwen_classifier_service.dart` - 集成日志
5. `pubspec.yaml` - 添加 uuid 依赖

### 未来扩展方向

1. **日志级别控制**：
   - ALL：记录所有请求
   - ERRORS_ONLY：仅记录失败请求
   - DISABLED：禁用日志

2. **UI 查询界面**：
   - 设置页面查看最近请求
   - 按服务、状态码过滤
   - 导出到 JSON/CSV

3. **智能脱敏**：
   - 配置敏感字段列表
   - 自动替换为 `***REDACTED***`

4. **性能分析**：
   - 按 API 统计平均耗时
   - 识别慢请求（> 3s）
   - 生成性能报告

---

## ✅ 验收标准

### 功能验收
- ✅ 支持 5 层级联匹配
- ✅ AI 配置正常保存和加载
- ✅ 规则自动学习和清理
- ✅ 批量处理性能达标
- ✅ 所有平台正常运行
- ✅ HTTP 日志完整记录（V4 新增）
- ✅ 日志异步写入不阻塞请求（V4 新增）

### 质量验收
- ✅ 无崩溃和严重 Bug
- ✅ 错误处理完善
- ✅ 用户体验流畅
- ✅ API Key 安全存储
- ✅ 代码分析无错误

### 文档验收
- ✅ 需求文档完整
- ✅ 使用文档清晰
- ✅ Bug 修复记录完整
- ✅ 代码注释充分
