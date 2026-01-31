# 邮箱账单导入账户选择功能

## 功能概述

实现了邮箱账单导入时的智能账户关联功能，用户可以在导入确认页面选择将账单关联到哪个账户（支付宝、微信等）。

## 实现日期

2026-01-31

## 架构设计

### 1. 数据模型层

#### ImportResult 模型增强
- **新增字段**：
  - `suggestedAccountId`: 推荐的账户ID（可选）
  - `platform`: 账单平台（alipay/wechat/unknown）

- **新增方法**：
  - `hasSuggestedAccount`: 判断是否有推荐账户
  - `copyWithAccount(accountId)`: 复制并更新账户ID

### 2. 服务层

#### AccountMatchService（新建）
**位置**: `lib/services/account_match_service.dart`

**核心功能**：
1. **智能匹配账户** (`matchAccounts`)
   - 根据平台（alipay/wechat）匹配对应类型的账户
   - 返回排序后的账户列表（匹配的在前，其他的在后）
   - 按创建时间倒序排序

2. **获取推荐账户** (`getSuggestedAccountId`)
   - 返回第一个匹配的账户ID
   - 如果没有匹配则返回 null

3. **辅助方法**：
   - `getAccountDisplayName`: 获取账户显示名称（带类型标签）
   - `isRecommendedAccount`: 判断账户是否为推荐账户

**匹配规则**：
```
1. 支付宝邮件 → 优先推荐支付宝类型账户
2. 微信邮件 → 优先推荐微信类型账户
3. 未知平台 → 返回所有非隐藏账户
4. 同类型账户按创建时间倒序排序（最新的在前）
```

### 3. UI 层改造

#### EmailBillSelectScreen（邮件选择页面）
**修改内容**：
- 引入 `AccountMatchService`
- 在 `_parseFileWithValidation` 方法中调用智能匹配
- 将推荐的账户ID和平台信息传递给 `ImportResult`

**关键代码**：
```dart
// 获取推荐的账户ID
final suggestedAccountId = await _accountMatchService.getSuggestedAccountId(platform);

// 返回带有推荐账户信息的结果
return ImportResult(
  transactions: result.transactions,
  validationResult: result.validationResult,
  source: result.source,
  suggestedAccountId: suggestedAccountId,
  platform: platform,
);
```

#### ImportConfirmationScreen（导入确认页面）
**修改内容**：
1. **新增状态变量**：
   - `_availableAccounts`: 可用账户列表
   - `_selectedAccountId`: 用户选择的账户ID
   - `_accountMatchService`: 账户匹配服务实例

2. **新增方法**：
   - `_loadAccounts()`: 加载账户列表并设置默认选中
   - `_buildAccountSelector()`: 构建账户选择器UI

3. **UI 增强**：
   - 在页面顶部增加账户选择卡片
   - 显示"智能推荐"标签（如果有推荐）
   - 推荐的账户前显示星标图标
   - 下拉框显示账户名称和类型

4. **保存逻辑更新**：
   - 保存前检查是否选择了账户
   - 更新所有交易的账户ID为用户选择的账户

## 数据流

```
1. 用户选择邮件 → 输入解压密码
2. 系统下载并解压账单文件
3. 解析账单，识别平台（alipay/wechat）
4. 调用 AccountMatchService 智能推荐账户
5. 跳转到导入确认页面
6. 显示推荐的账户（带星标）
7. 用户确认或修改账户选择
8. 保存时更新所有交易的账户ID
```

## 用户体验

### 智能推荐
- 支付宝账单自动推荐支付宝账户
- 微信账单自动推荐微信账户
- 推荐账户前显示星标图标
- 显示"智能推荐"标签提示用户

### 灵活选择
- 用户可以修改推荐的账户
- 下拉框显示所有可用账户
- 账户名称带类型标签（如"我的支付宝 (支付宝)"）

### 错误处理
- 如果没有选择账户，提示用户选择
- 如果没有可用账户，隐藏选择器

## 代码质量

### 复用性
- `AccountMatchService` 可复用于其他导入场景
- 匹配逻辑独立，易于扩展
- 支持新增账户类型

### 可维护性
- 清晰的职责分离（服务层、UI层）
- 完善的日志记录
- 详细的代码注释

### 向后兼容
- `ImportResult` 新增字段为可选
- 不影响现有的导入流程
- 如果没有推荐账户，使用默认值

## 测试建议

### 功能测试
1. 导入支付宝账单，验证是否推荐支付宝账户
2. 导入微信账单，验证是否推荐微信账户
3. 修改推荐的账户，验证是否生效
4. 没有对应类型账户时，验证是否显示所有账户
5. 保存后验证交易的账户ID是否正确

### 边界测试
1. 没有任何账户时的处理
2. 只有隐藏账户时的处理
3. 多个相同类型账户的排序
4. 未知平台的处理

## 相关文件

### 新建文件
- `lib/services/account_match_service.dart`

### 修改文件
- `lib/models/import_result.dart`
- `lib/screens/import/email_bill_select_screen.dart`
- `lib/screens/import/import_confirmation_screen.dart`

## 技术亮点

1. **智能推荐算法**：根据账单平台自动匹配账户类型
2. **清晰的架构**：服务层与UI层分离，职责明确
3. **良好的用户体验**：推荐 + 手动选择，灵活且智能
4. **代码复用性**：服务可用于其他导入场景
5. **向后兼容**：不影响现有功能

## 未来扩展

1. **记住用户选择**：记录用户的账户选择偏好
2. **多账户导入**：支持为不同邮件选择不同账户
3. **账户自动创建**：如果没有对应账户，提示创建
4. **更多平台支持**：支持银行卡、信用卡等平台
